import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../theme/app_text.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/widgets.dart';
import '../domain/goal_area.dart';
import '../domain/goal_metric.dart';
import '../domain/goal_record.dart';
import '../goal_providers.dart';
import '../goals_strings.dart';
import 'goal_widgets.dart';

/// Opens the new-goal sheet, or the edit sheet when [existing] is given.
/// Resolves to the saved goal, or null when dismissed.
Future<GoalRecord?> showGoalSheet(
  BuildContext context, {
  GoalRecord? existing,
  GoalHorizon? initialHorizon,
}) => showStickerSheet<GoalRecord>(
  context,
  (_) => GoalFormSheet(existing: existing, initialHorizon: initialHorizon),
);

class GoalFormSheet extends ConsumerStatefulWidget {
  const GoalFormSheet({super.key, this.existing, this.initialHorizon});

  final GoalRecord? existing;
  final GoalHorizon? initialHorizon;

  @override
  ConsumerState<GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends ConsumerState<GoalFormSheet> {
  late final TextEditingController _title;
  late final TextEditingController _customArea;
  late final TextEditingController _target;
  late final TextEditingController _unit;
  late final TextEditingController _notes;

  /// A preset id, or null with [_customMode] for a custom area.
  String? _area;
  bool _customMode = false;
  late GoalHorizon _horizon;
  late int _importance;
  DateTime? _targetDate;
  late MetricSource _source;
  late GoalStatus _status;
  bool _showErrors = false;

  GoalRecord? get _existing => widget.existing;

  @override
  void initState() {
    super.initState();
    final g = _existing;
    final m = g?.finite;
    _title = TextEditingController(text: g?.title ?? '');
    final area = GoalArea.resolve(g?.area);
    _customMode = area != null && !area.isPreset;
    _area = _customMode ? null : area?.id;
    _customArea = TextEditingController(text: _customMode ? area!.label : '');
    _target = TextEditingController(text: m == null ? '' : '${m.target}');
    _unit = TextEditingController(text: m?.unit ?? '');
    _notes = TextEditingController(text: g?.notes ?? '');
    _horizon = g?.horizon ?? widget.initialHorizon ?? GoalHorizon.month;
    _importance = g?.importance ?? 3;
    _targetDate = g?.targetDate?.toLocal();
    _source = m?.source ?? MetricSource.manual;
    _status = g?.status ?? GoalStatus.active;
  }

  @override
  void dispose() {
    _title.dispose();
    _customArea.dispose();
    _target.dispose();
    _unit.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? get _titleError => _showErrors && _title.text.trim().isEmpty
      ? GoalsStrings.titleRequired
      : null;

  /// Null when the field is empty (no metric).
  int? get _targetValue => int.tryParse(_target.text.trim());

  String? get _targetError {
    if (!_showErrors || _target.text.trim().isEmpty) return null;
    final v = _targetValue;
    return v == null || v <= 0 ? GoalsStrings.targetInvalid : null;
  }

  Future<void> _save() async {
    setState(() => _showErrors = true);
    if (_titleError != null || _targetError != null) return;
    final title = _title.text.trim();
    final custom = _customArea.text.trim();
    final area = _customMode ? (custom.isEmpty ? null : custom) : _area;
    final notes = _notes.text.trim();
    final target = _targetValue;
    final unitText = _unit.text.trim();
    final unit = unitText.isNotEmpty
        ? unitText
        : _source == MetricSource.linkedTasks
        ? GoalsStrings.linkedUnit
        : GoalsStrings.defaultUnit;
    final old = _existing?.finite;
    final GoalMetric? metric = target == null
        ? null
        : FiniteMetric(
            target: target,
            unit: unit,
            current: old?.current ?? 0,
            source: _source,
          );
    final d = _targetDate;
    final targetDate = d == null
        ? null
        : DateTime(d.year, d.month, d.day, 23, 59).toUtc();

    final actions = ref.read(goalActionsProvider);
    final existing = _existing;
    final goal = existing == null
        ? actions.draft(
            title: title,
            area: area,
            horizon: _horizon,
            importance: _importance,
            targetDate: targetDate,
            notes: notes.isEmpty ? null : notes,
            metric: metric,
          )
        : existing.copyWith(
            title: title,
            area: area,
            horizon: _horizon,
            importance: _importance,
            targetDate: targetDate,
            notes: notes.isEmpty ? null : notes,
            metric: metric,
            status: _status,
          );
    await actions.save(goal);
    if (mounted) Navigator.of(context).pop(goal);
  }

  Future<void> _pickDate() async {
    final now = ref.read(clockProvider).now().toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final base = _targetDate ?? today;
    final picked = await showStickerDatePicker(
      context,
      initialDate: base,
      firstDate: base.isBefore(today) ? base : today,
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final editing = _existing != null;
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
                    editing ? GoalsStrings.editGoal : GoalsStrings.newGoal,
                    style: AppText.display(size: 22),
                  ),
                  const SizedBox(height: 12),
                  StickerTextField(
                    controller: _title,
                    autofocus: !editing,
                    label: GoalsStrings.titleLabel,
                    hint: GoalsStrings.titleHint,
                    errorText: _titleError,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) {
                      if (_showErrors) setState(() {});
                    },
                    onSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 16),
                  const SectionLabel(GoalsStrings.areaLabel),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final a in GoalArea.presets)
                        ChoicePill(
                          label: a.label,
                          icon: a.icon,
                          selected: !_customMode && _area == a.id,
                          selectedColor: a.color,
                          selectedTextColor: a.onColor,
                          onTap: () => setState(() {
                            _customMode = false;
                            _area = _area == a.id ? null : a.id;
                          }),
                        ),
                      ChoicePill(
                        label: GoalsStrings.customArea,
                        icon: Icons.star_outline,
                        selected: _customMode,
                        selectedColor: AppColors.sky,
                        selectedTextColor: AppColors.ink,
                        onTap: () => setState(() => _customMode = !_customMode),
                      ),
                    ],
                  ),
                  if (_customMode) ...[
                    const SizedBox(height: 8),
                    StickerTextField(
                      controller: _customArea,
                      pill: true,
                      label: GoalsStrings.customAreaHint,
                    ),
                  ],
                  const SizedBox(height: 14),
                  const SectionLabel(GoalsStrings.horizonLabel),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final h in GoalHorizon.values)
                        ChoicePill(
                          label: GoalsStrings.horizonShort(h),
                          selected: _horizon == h,
                          onTap: () => setState(() => _horizon = h),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const SectionLabel(GoalsStrings.importanceLabel),
                  const SizedBox(height: 4),
                  _ImportancePicker(
                    value: _importance,
                    onChanged: (v) => setState(() => _importance = v),
                  ),
                  const SizedBox(height: 14),
                  const SectionLabel(GoalsStrings.targetDateLabel),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ChoicePill(
                        label: _targetDate == null
                            ? GoalsStrings.pickDate
                            : GoalsStrings.date(_targetDate!),
                        icon: Icons.calendar_today_outlined,
                        selected: _targetDate != null,
                        onTap: _pickDate,
                      ),
                      if (_targetDate != null)
                        ChoicePill(
                          label: GoalsStrings.clear,
                          icon: Icons.close,
                          selected: false,
                          onTap: () => setState(() => _targetDate = null),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const SectionLabel(GoalsStrings.metricLabel),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: StickerTextField(
                          controller: _target,
                          label: GoalsStrings.targetLabel,
                          hint: GoalsStrings.targetHint,
                          errorText: _targetError,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (_) {
                            if (_showErrors) setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: StickerTextField(
                          controller: _unit,
                          label: GoalsStrings.unitLabel,
                          hint: GoalsStrings.unitHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoicePill(
                        label: GoalsStrings.countManual,
                        selected: _source == MetricSource.manual,
                        onTap: () =>
                            setState(() => _source = MetricSource.manual),
                      ),
                      ChoicePill(
                        label: GoalsStrings.countLinked,
                        icon: Icons.checklist,
                        selected: _source == MetricSource.linkedTasks,
                        onTap: () =>
                            setState(() => _source = MetricSource.linkedTasks),
                      ),
                    ],
                  ),
                  if (editing) ...[
                    const SizedBox(height: 14),
                    const SectionLabel(GoalsStrings.statusLabel),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final s in GoalStatus.values)
                          ChoicePill(
                            label: GoalsStrings.status(s),
                            selected: _status == s,
                            onTap: () => setState(() => _status = s),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  StickerTextField(
                    controller: _notes,
                    label: GoalsStrings.notesLabel,
                    maxLines: 3,
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
                  label: GoalsStrings.cancel,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PillButton(
                  label: GoalsStrings.save,
                  color: AppColors.violet,
                  textColor: Colors.white,
                  display: true,
                  fontSize: 16,
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

/// Five 44 px dots; tapping one sets importance 1..5.
class _ImportancePicker extends StatelessWidget {
  const _ImportancePicker({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 1; i <= 5; i++)
        Semantics(
          button: true,
          selected: i == value,
          label: '${GoalsStrings.importanceLabel} $i',
          excludeSemantics: true,
          onTap: () => onChanged(i),
          child: GestureDetector(
            onTap: () => onChanged(i),
            behavior: HitTestBehavior.opaque,
            child: SizedBox.square(
              dimension: 44,
              child: Center(
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i <= value ? AppColors.sun : AppColors.card,
                    border: Border.all(
                      color: AppColors.ink,
                      width: AppStroke.borderThin,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      const SizedBox(width: 6),
      Text(
        GoalsStrings.importanceValue(value),
        style: AppText.bold(size: 13, color: AppColors.muted),
      ),
    ],
  );
}
