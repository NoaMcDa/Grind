import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/core.dart';
import '../../theme/app_text.dart';
import '../../theme/tokens.dart';
import '../../widgets/widgets.dart';
import 'task_actions.dart';
import 'tasks_strings.dart';

/// Opens the quick-add sheet, or the edit sheet when [existing] is given.
/// Resolves to the saved task, or null when dismissed.
Future<Task?> showTaskSheet(BuildContext context, {Task? existing}) {
  return showStickerSheet<Task>(
    context,
    (_) => TaskFormSheet(existing: existing),
  );
}

const _presets = [15, 30, 45, 60, 90];

class TaskFormSheet extends ConsumerStatefulWidget {
  const TaskFormSheet({super.key, this.existing});

  final Task? existing;

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

  Task? get _existing => widget.existing;

  @override
  void initState() {
    super.initState();
    final t = _existing;
    _title = TextEditingController(text: t?.title ?? '');
    _firstAction = TextEditingController(text: t?.firstAction ?? '');
    _notes = TextEditingController(text: t?.notes ?? '');
    _minutes = t?.estimatedMinutes ?? 30;
    _customMode = !_presets.contains(_minutes);
    _custom = TextEditingController(text: _customMode ? '$_minutes' : '');
    _energy = t?.energy ?? Energy.light;
    if (t == null) {
      final now = ref.read(clockProvider).now().toLocal();
      _date = DateTime(now.year, now.month, now.day);
    } else {
      final due = t.dueAt?.toLocal();
      if (due != null) {
        _date = DateTime(due.year, due.month, due.day);
        if (!(due.hour == 23 && due.minute == 59)) {
          _dueTime = TimeOfDay.fromDateTime(due);
        }
      }
      final remind = t.remindAt?.toLocal();
      if (remind != null) {
        _date ??= DateTime(remind.year, remind.month, remind.day);
        _remindTime = TimeOfDay.fromDateTime(remind);
        _remindTouched = _remindTime != _dueTime;
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _firstAction.dispose();
    _notes.dispose();
    _custom.dispose();
    super.dispose();
  }

  DateTime get _today {
    final n = ref.read(clockProvider).now().toLocal();
    return DateTime(n.year, n.month, n.day);
  }

  /// The reminder follows the due time until the user sets it themselves.
  TimeOfDay? get _effectiveRemind => _remindTouched ? _remindTime : _dueTime;

  DateTime _at(DateTime day, TimeOfDay t) =>
      DateTime(day.year, day.month, day.day, t.hour, t.minute).toUtc();

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    final minutes = _customMode ? int.tryParse(_custom.text.trim()) : _minutes;
    final estimate = (minutes == null || minutes <= 0) ? 30 : minutes;
    final day = _date;
    final dueAt = day == null
        ? null
        : (_dueTime == null
              ? DateTime(day.year, day.month, day.day, 23, 59).toUtc()
              : _at(day, _dueTime!));
    final remind = _effectiveRemind;
    final remindAt = remind == null ? null : _at(day ?? _today, remind);
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
      );
    }
    actions.save(task);
    Navigator.of(context).pop(task);
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
                    editing ? TasksStrings.editTask : TasksStrings.newTask,
                    style: AppText.display(size: 22),
                  ),
                  const SizedBox(height: 12),
                  StickerTextField(
                    controller: _title,
                    autofocus: true,
                    label: TasksStrings.titleLabel,
                    errorText: _showError && _title.text.trim().isEmpty
                        ? TasksStrings.titleRequired
                        : null,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) {
                      if (_showError) setState(() {});
                    },
                    onSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 16),
                  const SectionLabel(TasksStrings.dueLabel),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Choice(
                        label: TasksStrings.today,
                        selected: isToday,
                        onTap: () => setState(() => _date = today),
                      ),
                      _Choice(
                        label: TasksStrings.tomorrow,
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
                            ? TasksStrings.date(_date!)
                            : TasksStrings.pickDate,
                        selected: customDate,
                        icon: Icons.calendar_today_outlined,
                        onTap: _pickDate,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _TimeRow(
                    label: TasksStrings.dueTime,
                    value: _dueTime,
                    onPick: () async {
                      final t = await _pickTime(_dueTime);
                      if (t != null) setState(() => _dueTime = t);
                    },
                    onClear: () => setState(() => _dueTime = null),
                  ),
                  const SizedBox(height: 10),
                  _TimeRow(
                    label: TasksStrings.reminderTime,
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
                  const SizedBox(height: 16),
                  const SectionLabel(TasksStrings.estimateLabel),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final m in _presets)
                        _Choice(
                          label: TasksStrings.minutes(m),
                          selected: !_customMode && _minutes == m,
                          onTap: () => setState(() {
                            _customMode = false;
                            _minutes = m;
                          }),
                        ),
                      _Choice(
                        label: TasksStrings.custom,
                        selected: _customMode,
                        onTap: () => setState(() => _customMode = true),
                      ),
                    ],
                  ),
                  if (_customMode) ...[
                    const SizedBox(height: 8),
                    StickerTextField(
                      controller: _custom,
                      label: TasksStrings.customMinutes,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onSubmitted: (_) => _save(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const SectionLabel(TasksStrings.energyLabel),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _EnergyOption(
                        chip: IconChip.deep(
                          label: TasksStrings.deep,
                          height: 36,
                        ),
                        selected: _energy == Energy.deep,
                        onTap: () => setState(() => _energy = Energy.deep),
                      ),
                      _EnergyOption(
                        chip: IconChip.light(
                          label: TasksStrings.light,
                          height: 36,
                        ),
                        selected: _energy == Energy.light,
                        onTap: () => setState(() => _energy = Energy.light),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StickerTextField(
                    controller: _firstAction,
                    label: TasksStrings.firstActionLabel,
                    hint: TasksStrings.firstActionHint,
                  ),
                  const SizedBox(height: 12),
                  StickerTextField(
                    controller: _notes,
                    label: TasksStrings.notesLabel,
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
                  label: TasksStrings.cancel,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PillButton(
                  label: TasksStrings.save,
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
          child: Container(
            alignment: Alignment.center,
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
          alignment: Alignment.center,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(
              color: selected ? AppColors.ink : Colors.transparent,
              width: AppStroke.border,
            ),
          ),
          child: chip,
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
        ? TasksStrings.addTime
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
            label: '${TasksStrings.clear} $label',
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
