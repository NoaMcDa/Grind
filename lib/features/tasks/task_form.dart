import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grind/features/goals/goals.dart'
    show GoalRecord, GoalStatus, goalsProvider;
import 'package:timezone/timezone.dart' as tz;

import '../../core/core.dart';
import '../../core/util/duration_input.dart';
import '../../theme/app_text.dart';
import '../../theme/tokens.dart';
import '../../widgets/widgets.dart';
import '../recurrence/occurrence_expander.dart' show RruleText;
import '../recurrence/recurrence.dart';
import '../recurrence/recurrence_picker.dart';
import 'day_bounds.dart';
import 'task_actions.dart';
import '../../l10n/l10n.dart';
import '../plan/plan_l10n.dart' show formatPlanDay;

/// Opens the quick-add sheet, or the edit sheet when [existing] is given.
/// [initialGoalId] presets the goal of a new task. Resolves to the saved
/// task, or null when dismissed.
Future<Task?> showTaskSheet(
  BuildContext context, {
  Task? existing,
  String? initialGoalId,
}) {
  return showStickerSheet<Task>(
    context,
    (_) => TaskFormSheet(existing: existing, initialGoalId: initialGoalId),
  );
}

/// The quick-add sheet with [goal] preset, in the shape of
/// `GoalDetailScreen.onAddTask`.
Future<Task?> taskSheetForGoal(BuildContext context, GoalRecord goal) =>
    showTaskSheet(context, initialGoalId: goal.id);

/// Estimate presets, in minutes. Hour presets (1 h, 2 h, 3 h, 4 h) sit after
/// the short ones so longer tasks don't need the custom field.
const _presets = [15, 30, 45, 60, 90, 120, 180, 240];

class TaskFormSheet extends ConsumerStatefulWidget {
  const TaskFormSheet({super.key, this.existing, this.initialGoalId});

  final Task? existing;

  /// The goal a new task starts linked to (ignored when editing).
  final String? initialGoalId;

  @override
  ConsumerState<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends ConsumerState<TaskFormSheet> {
  late final TextEditingController _title;
  late final TextEditingController _firstAction;
  late final TextEditingController _notes;
  late final TextEditingController _custom;

  DateTime? _date;
  TimeOfDay? _dueTime;
  TimeOfDay? _remindTime;
  bool _remindTouched = false;
  late int _minutes;
  bool _customMode = false;
  late Energy _energy;
  bool _showError = false;
  String? _goalId;

  /// The repeat rule as picked; [_rule] is the stored one when editing.
  Recurrence? _recurrence;
  ReminderRule? _rule;
  bool _recurrenceTouched = false;
  bool _saving = false;

  Task? get _existing => widget.existing;

  /// Days and times in the form are in the user's zone.
  tz.Location get _location => ref.read(zoneLocationProvider);

  @override
  void initState() {
    super.initState();
    final t = _existing;
    _title = TextEditingController(text: t?.title ?? '');
    _firstAction = TextEditingController(text: t?.firstAction ?? '');
    _notes = TextEditingController(text: t?.notes ?? '');
    _minutes = t?.estimatedMinutes ?? 30;
    _customMode = !_presets.contains(_minutes);
    // Pre-fill the custom field with a readable form (e.g. "1h30" for 90
    // min that isn't a preset), not raw minutes.
    _custom = TextEditingController(
      text: _customMode ? _initialCustomText(_minutes) : '',
    );
    _energy = t?.energy ?? Energy.light;
    _goalId = t == null ? widget.initialGoalId : t.goalId;
    if (t == null) {
      _date = _today;
    } else {
      _loadRule(t.id);
      final due = t.dueAt == null ? null : zoneWall(t.dueAt!, _location);
      if (due != null) {
        _date = DateTime(due.year, due.month, due.day);
        if (!(due.hour == 23 && due.minute == 59)) {
          _dueTime = TimeOfDay.fromDateTime(due);
        }
      }
      final remind = t.remindAt == null
          ? null
          : zoneWall(t.remindAt!, _location);
      if (remind != null) {
        _date ??= DateTime(remind.year, remind.month, remind.day);
        _remindTime = TimeOfDay.fromDateTime(remind);
        _remindTouched = _remindTime != _dueTime;
      }
    }
  }

  Future<void> _loadRule(String taskId) async {
    final rule = await ref.read(reminderRepositoryProvider).getForTask(taskId);
    if (!mounted || rule == null || _recurrenceTouched) return;
    Recurrence? parsed;
    try {
      parsed = Recurrence.parse(rule.rrule);
    } on FormatException {
      parsed = null;
    }
    setState(() {
      _rule = rule;
      _recurrence = parsed;
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _firstAction.dispose();
    _notes.dispose();
    _custom.dispose();
    super.dispose();
  }

  DateTime get _today =>
      localDayBoundsIn(ref.read(clockProvider).now(), _location).date;

  /// The reminder follows the due time until the user sets it themselves.
  TimeOfDay? get _effectiveRemind => _remindTouched ? _remindTime : _dueTime;

  /// [t] on [day] in the user's zone, as UTC.
  DateTime _at(DateTime day, TimeOfDay t) => fromZoneWall(
    DateTime(day.year, day.month, day.day, t.hour, t.minute),
    _location,
  );

  /// Where a series starts: the reminder, else the due time, else 09:00 on
  /// the task's day (as on the detail screen).
  DateTime _seriesAnchor() => _at(
    _date ?? _today,
    _effectiveRemind ?? _dueTime ?? const TimeOfDay(hour: 9, minute: 0),
  );

  Future<void> _pickRecurrence() async {
    final pick = await showRecurrencePicker(
      context,
      _recurrence,
      anchor: zoneWall(_seriesAnchor(), _location),
    );
    if (pick == null || !mounted) return;
    setState(() {
      _recurrence = pick.value;
      _recurrenceTouched = true;
    });
  }

  /// Writes, replaces or removes the task's rule after a change here.
  Future<void> _saveRule(Task task) async {
    final rules = ref.read(reminderRepositoryProvider);
    if (!_recurrenceTouched) {
      // A new reminder time restarts the series there: drop the pinned
      // start (DTSTART) so occurrences follow the edited time. Completions
      // (`lastCompletedAt`) stay.
      final before = _existing?.remindAt;
      if (before == null || before == task.remindAt) return;
      final rule = _rule ?? await rules.getForTask(task.id);
      if (rule == null) return;
      final text = RruleText.parse(rule.rrule);
      if (text.dtstart == null) return;
      await rules.upsert(
        rule.copyWith(
          rrule: text.withDtstart(null).toString(),
          updatedAt: ref.read(clockProvider).now().toUtc(),
        ),
      );
      return;
    }
    final rule = _rule ?? await rules.getForTask(task.id);
    final value = _recurrence;
    final now = ref.read(clockProvider).now().toUtc();
    if (value == null) {
      if (rule != null) await rules.delete(rule.id);
      return;
    }
    final rrule = value.toRRule();
    await rules.upsert(
      rule == null
          ? ReminderRule(
              id: 'rule-${task.id}',
              taskId: task.id,
              rrule: rrule,
              createdAt: now,
              updatedAt: now,
            )
          : rule.copyWith(rrule: rrule, updatedAt: now),
    );
  }

  /// How the custom field starts when an existing task's estimate is not a
  /// preset: whole hours come out as `"2h"`, mixed as `"1h30"`, otherwise
  /// as plain minutes. Parses back to the same minute count.
  static String _initialCustomText(int minutes) {
    if (minutes <= 0 || minutes < 60) return '$minutes';
    final h = minutes ~/ 60;
    final rem = minutes % 60;
    if (rem == 0) return '${h}h';
    return '${h}h$rem';
  }

  Future<void> _save() async {
    if (_saving) return;
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    final minutes = _customMode ? parseDuration(_custom.text) : _minutes;
    if (_customMode && minutes == null) {
      setState(() => _showError = true);
      return;
    }
    final estimate = (minutes == null || minutes <= 0) ? 30 : minutes;
    final day = _date;
    final dueAt = day == null
        ? null
        : _at(day, _dueTime ?? const TimeOfDay(hour: 23, minute: 59));
    final remind = _effectiveRemind;
    var remindAt = remind == null ? null : _at(day ?? _today, remind);
    // A series is anchored at its reminder.
    if (_recurrence != null) remindAt ??= _seriesAnchor();
    final first = _firstAction.text.trim();
    final notes = _notes.text.trim();

    final actions = ref.read(taskActionsProvider);
    final Task task;
    final existing = _existing;
    if (existing == null) {
      task = actions.create(
        title: title,
        dueAt: dueAt,
        remindAt: remindAt,
        estimatedMinutes: estimate,
        energy: _energy,
        firstAction: first.isEmpty ? null : first,
        notes: notes.isEmpty ? null : notes,
        goalId: _goalId,
      );
    } else {
      task = existing.copyWith(
        title: title,
        dueAt: dueAt,
        remindAt: remindAt,
        estimatedMinutes: estimate,
        energy: _energy,
        firstAction: first.isEmpty ? null : first,
        notes: notes.isEmpty ? null : notes,
        goalId: _goalId,
      );
    }
    _saving = true;
    await actions.save(task);
    await _saveRule(task);
    if (mounted) Navigator.of(context).pop(task);
  }

  /// "Goal": No goal plus the active goals (and the linked one, whatever
  /// its status). Hidden when there is nothing to link to.
  List<Widget> _goalPicker() {
    final goals = ref.watch(goalsProvider).valueOrNull ?? const <GoalRecord>[];
    final options = [
      for (final g in goals)
        if (g.deletedAt == null &&
            (g.status == GoalStatus.active || g.id == _goalId))
          g,
    ];
    if (options.isEmpty) return const [];
    return [
      const SizedBox(height: 16),
      SectionLabel(context.l10n.tasksGoalLabel),
      const SizedBox(height: 8),
      Wrap(
        key: const Key('task-form-goal'),
        spacing: 8,
        runSpacing: 8,
        children: [
          _Choice(
            label: context.l10n.tasksNoGoal,
            selected: _goalId == null,
            onTap: () => setState(() => _goalId = null),
          ),
          for (final g in options)
            _Choice(
              label: g.title,
              selected: _goalId == g.id,
              icon: Icons.flag_outlined,
              onTap: () => setState(() => _goalId = g.id),
            ),
        ],
      ),
    ];
  }

  Future<void> _pickDate() async {
    final base = _date ?? _today;
    final picked = await showStickerDatePicker(
      context,
      initialDate: base,
      firstDate: base.isBefore(_today) ? base : _today,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay? current) => showStickerTimePicker(
    context,
    initialTime: current ?? const TimeOfDay(hour: 9, minute: 0),
  );

  @override
  Widget build(BuildContext context) {
    final editing = _existing != null;
    final today = _today;
    final isToday = _date == today;
    final isTomorrow =
        _date == DateTime(today.year, today.month, today.day + 1);
    final customDate = _date != null && !isToday && !isTomorrow;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    editing
                        ? context.l10n.tasksEditTask
                        : context.l10n.tasksNewTask,
                    style: AppText.display(size: 22),
                  ),
                  const SizedBox(height: 12),
                  StickerTextField(
                    controller: _title,
                    autofocus: true,
                    label: context.l10n.tasksTitleLabel,
                    errorText: _showError && _title.text.trim().isEmpty
                        ? context.l10n.tasksTitleRequired
                        : null,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) {
                      if (_showError) setState(() {});
                    },
                    onSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 16),
                  SectionLabel(context.l10n.tasksDueLabel),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Choice(
                        label: context.l10n.commonToday,
                        selected: isToday,
                        onTap: () => setState(() => _date = today),
                      ),
                      _Choice(
                        label: context.l10n.commonTomorrow,
                        selected: isTomorrow,
                        onTap: () => setState(
                          () => _date = DateTime(
                            today.year,
                            today.month,
                            today.day + 1,
                          ),
                        ),
                      ),
                      _Choice(
                        label: customDate
                            ? formatPlanDay(context.l10n, _date!)
                            : context.l10n.tasksPickDate,
                        selected: customDate,
                        icon: Icons.calendar_today_outlined,
                        onTap: _pickDate,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _TimeRow(
                    label: context.l10n.tasksDueTime,
                    value: _dueTime,
                    onPick: () async {
                      final t = await _pickTime(_dueTime);
                      if (t != null) setState(() => _dueTime = t);
                    },
                    onClear: () => setState(() => _dueTime = null),
                  ),
                  const SizedBox(height: 10),
                  _TimeRow(
                    label: context.l10n.tasksReminderTime,
                    value: _effectiveRemind,
                    onPick: () async {
                      final t = await _pickTime(_effectiveRemind);
                      if (t != null) {
                        setState(() {
                          _remindTime = t;
                          _remindTouched = true;
                        });
                      }
                    },
                    onClear: () => setState(() {
                      _remindTime = null;
                      _remindTouched = true;
                    }),
                  ),
                  const SizedBox(height: 12),
                  SectionLabel(context.l10n.tasksRepeatsLabel),
                  const SizedBox(height: 2),
                  RecurrenceSummaryChip(
                    key: const Key('task-form-recurrence'),
                    recurrence: _recurrence,
                    onTap: _pickRecurrence,
                  ),
                  const SizedBox(height: 16),
                  SectionLabel(context.l10n.tasksEstimateLabel),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final m in _presets)
                        _Choice(
                          label: formatDuration(m, context.l10n),
                          selected: !_customMode && _minutes == m,
                          onTap: () => setState(() {
                            _customMode = false;
                            _minutes = m;
                          }),
                        ),
                      _Choice(
                        label: context.l10n.tasksCustom,
                        selected: _customMode,
                        onTap: () => setState(() => _customMode = true),
                      ),
                    ],
                  ),
                  if (_customMode) ...[
                    const SizedBox(height: 8),
                    StickerTextField(
                      controller: _custom,
                      label: context.l10n.tasksCustomDuration,
                      hint: context.l10n.tasksCustomDurationHint,
                      // Text-mode keyboard so "h" and ":" are reachable; the
                      // filter still keeps the field to the shapes we parse.
                      keyboardType: TextInputType.text,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9hHmM:\s]'),
                        ),
                      ],
                      errorText:
                          _showError && parseDuration(_custom.text) == null
                          ? context.l10n.tasksCustomDurationInvalid
                          : null,
                      onChanged: (_) {
                        if (_showError) setState(() {});
                      },
                      onSubmitted: (_) => _save(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SectionLabel(context.l10n.sectionEnergy),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _EnergyOption(
                        chip: IconChip.deep(
                          label: context.l10n.energyDeep,
                          height: 36,
                        ),
                        selected: _energy == Energy.deep,
                        onTap: () => setState(() => _energy = Energy.deep),
                      ),
                      _EnergyOption(
                        chip: IconChip.light(
                          label: context.l10n.energyLight,
                          height: 36,
                        ),
                        selected: _energy == Energy.light,
                        onTap: () => setState(() => _energy = Energy.light),
                      ),
                    ],
                  ),
                  ..._goalPicker(),
                  const SizedBox(height: 16),
                  StickerTextField(
                    controller: _firstAction,
                    label: context.l10n.tasksFirstActionLabel,
                    hint: context.l10n.tasksFirstActionHint,
                  ),
                  const SizedBox(height: 12),
                  StickerTextField(
                    controller: _notes,
                    label: context.l10n.tasksNotesLabel,
                    maxLines: 3,
                    keyboardType: TextInputType.multiline,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: PillButton(
                  label: context.l10n.commonCancel,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PillButton(
                  label: context.l10n.commonSave,
                  color: AppColors.violet,
                  textColor: Colors.white,
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          // No `alignment` here: it would make each chip as wide as the Wrap.
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.violet : AppColors.card,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(
                color: AppColors.ink,
                width: AppStroke.borderThin,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: selected ? Colors.white : AppColors.ink,
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: AppText.bold(
                      size: 14,
                      color: selected ? Colors.white : AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EnergyOption extends StatelessWidget {
  const _EnergyOption({
    required this.chip,
    required this.selected,
    required this.onTap,
  });

  final Widget chip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(
              color: selected ? AppColors.ink : Colors.transparent,
              width: AppStroke.border,
            ),
          ),
          child: Center(widthFactor: 1, child: chip),
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final TimeOfDay? value;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? context.l10n.tasksAddTime
        : MaterialLocalizations.of(
            context,
          ).formatTimeOfDay(value!, alwaysUse24HourFormat: true);
    return Row(
      children: [
        Expanded(child: Text(label, style: AppText.bold(size: 14))),
        _Choice(
          label: text,
          selected: value != null,
          icon: Icons.schedule,
          onTap: onPick,
        ),
        if (value != null)
          Semantics(
            button: true,
            label: '${context.l10n.commonClear} $label',
            excludeSemantics: true,
            onTap: onClear,
            child: GestureDetector(
              onTap: onClear,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.close, size: 18, color: AppColors.muted),
              ),
            ),
          ),
      ],
    );
  }
}
