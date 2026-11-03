import 'package:flutter/material.dart';
import 'package:grind/theme/app_text.dart';
import 'package:grind/theme/tokens.dart';
import 'package:grind/widgets/widgets.dart';

import 'recurrence.dart';
import 'recurrence_strings.dart';
import 'package:grind/l10n/l10n.dart';

/// Repeat presets as pills, custom weekday toggles, an interval stepper and
/// an optional end date. Controlled: pass [value] (null = does not repeat)
/// and update it from [onChanged].
class RecurrencePicker extends StatelessWidget {
  const RecurrencePicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.anchor,
  });

  final Recurrence? value;
  final ValueChanged<Recurrence?> onChanged;

  /// The first occurrence; seeds the default weekday and day-of-month.
  final DateTime anchor;

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final v = value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionLabel(s.recurrenceRepeatLabel),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _choice(
              s.recurrenceDoesNotRepeat,
              v == null,
              () => onChanged(null),
            ),
            _choice(
              s.recurrenceDaily,
              v?.preset == RecurrencePreset.daily,
              () => onChanged(_with(v, RecurrencePreset.daily)),
            ),
            _choice(
              s.recurrenceWeekdays,
              v?.preset == RecurrencePreset.weekdays,
              () => onChanged(_with(v, RecurrencePreset.weekdays)),
            ),
            _choice(
              s.recurrenceWeekly,
              v?.preset == RecurrencePreset.weekly,
              () => onChanged(_with(v, RecurrencePreset.weekly)),
            ),
            _choice(
              s.recurrenceMonthly,
              v?.preset == RecurrencePreset.monthly,
              () => onChanged(_with(v, RecurrencePreset.monthly)),
            ),
          ],
        ),
        if (v != null && v.preset == RecurrencePreset.weekly) ...[
          const SizedBox(height: 16),
          SectionLabel(s.recurrenceOnDays),
          const SizedBox(height: 8),
          _weekdayToggles(s, v),
        ],
        if (v != null && v.preset != RecurrencePreset.weekdays) ...[
          const SizedBox(height: 16),
          _intervalRow(context, s, v),
        ],
        if (v != null) ...[
          const SizedBox(height: 16),
          SectionLabel(s.recurrenceEndsLabel),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _choice(
                s.recurrenceNever,
                v.until == null,
                () => onChanged(v.copyWith(until: null, count: null)),
              ),
              _choice(
                v.until == null
                    ? s.recurrenceOnDate
                    : RecurrenceStrings.of(
                        Localizations.localeOf(context),
                      ).dateLabel(v.until!),
                v.until != null,
                () => _pickUntil(context, v),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Recurrence _with(Recurrence? old, RecurrencePreset preset) {
    final keep = old?.copyWith(preset: preset);
    return switch (preset) {
      RecurrencePreset.daily => Recurrence.daily(
        interval: old?.interval ?? 1,
        until: old?.until,
      ),
      RecurrencePreset.weekdays => Recurrence.weekdays(until: old?.until),
      RecurrencePreset.weekly => Recurrence.weekly(
        keep != null && keep.weekdays.isNotEmpty
            ? keep.weekdays
            : {anchor.weekday},
        interval: old?.interval ?? 1,
        until: old?.until,
      ),
      RecurrencePreset.monthly => Recurrence.monthly(
        old?.monthDay ?? anchor.day,
        interval: old?.interval ?? 1,
        until: old?.until,
      ),
    };
  }

  Widget _choice(String label, bool selected, VoidCallback onTap) {
    return Semantics(
      selected: selected,
      child: PillButton(
        label: label,
        color: selected ? AppColors.violet : AppColors.card,
        textColor: selected ? Colors.white : AppColors.ink,
        shadow: selected ? 2 : 0,
        onPressed: onTap,
      ),
    );
  }

  Widget _weekdayToggles(AppLocalizations s, Recurrence v) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final d in const [7, 1, 2, 3, 4, 5, 6])
          _DayToggle(
            label: _weekdayLetter(s, d),
            semanticLabel: _weekdayFull(s, d),
            selected: v.weekdays.contains(d),
            onTap: () {
              final next = {...v.weekdays};
              if (!next.add(d)) {
                // Keep at least one day selected.
                if (next.length == 1) return;
                next.remove(d);
              }
              onChanged(v.copyWith(weekdays: next));
            },
          ),
      ],
    );
  }

  Widget _intervalRow(BuildContext context, AppLocalizations s, Recurrence v) {
    final String Function(int) unit = switch (v.preset) {
      RecurrencePreset.weekly => s.recurrenceUnitWeek,
      RecurrencePreset.monthly => s.recurrenceUnitMonth,
      _ => s.recurrenceUnitDay,
    };
    return Row(
      children: [
        Text(s.recurrenceEveryLabel, style: AppText.bold()),
        const SizedBox(width: 10),
        _StepButton(
          icon: Icons.remove_rounded,
          label: s.recurrenceDecrease,
          onTap: v.interval > 1
              ? () => onChanged(v.copyWith(interval: v.interval - 1))
              : null,
        ),
        SizedBox(
          width: 36,
          child: Text(
            '${v.interval}',
            textAlign: TextAlign.center,
            style: AppText.display(size: 18),
          ),
        ),
        _StepButton(
          icon: Icons.add_rounded,
          label: s.recurrenceIncrease,
          onTap: v.interval < 99
              ? () => onChanged(v.copyWith(interval: v.interval + 1))
              : null,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            unit(v.interval),
            style: AppText.bold(),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _pickUntil(BuildContext context, Recurrence v) async {
    final first = DateTime(anchor.year, anchor.month, anchor.day);
    final initial = v.until != null && !v.until!.isBefore(first)
        ? v.until!
        : first.add(const Duration(days: 30));
    final picked = await showStickerDatePicker(
      context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime(anchor.year + 10),
    );
    if (picked != null) {
      onChanged(
        v.copyWith(
          until: DateTime(picked.year, picked.month, picked.day),
          count: null,
        ),
      );
    }
  }
}

class _DayToggle extends StatelessWidget {
  const _DayToggle({
    required this.label,
    required this.semanticLabel,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.violet : AppColors.card,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.ink, width: AppStroke.border),
          ),
          child: Text(
            label,
            style: AppText.bold(
              size: 14,
              color: selected ? Colors.white : AppColors.ink,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.card,
            shape: BoxShape.circle,
            border: Border.all(
              color: onTap == null ? AppColors.rule : AppColors.ink,
              width: AppStroke.border,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: onTap == null ? AppColors.rule : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

/// Result of [showRecurrencePicker]: [value] is null for "does not repeat".
/// The sheet itself returns null when dismissed without confirming.
class RecurrencePick {
  const RecurrencePick(this.value);
  final Recurrence? value;
}

/// Bottom sheet around [RecurrencePicker] with a Done button.
Future<RecurrencePick?> showRecurrencePicker(
  BuildContext context,
  Recurrence? initial, {
  DateTime? anchor,
}) {
  final at = anchor ?? DateTime.now();
  return showStickerSheet<RecurrencePick>(
    context,
    (ctx) => _PickerSheet(initial: initial, anchor: at),
  );
}

class _PickerSheet extends StatefulWidget {
  const _PickerSheet({required this.initial, required this.anchor});

  final Recurrence? initial;
  final DateTime anchor;

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  late Recurrence? _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          RecurrencePicker(
            value: _value,
            anchor: widget.anchor,
            onChanged: (v) => setState(() => _value = v),
          ),
          const SizedBox(height: 20),
          PillButton(
            label: s.recurrenceDone,
            color: AppColors.violet,
            textColor: Colors.white,
            onPressed: () => Navigator.pop(context, RecurrencePick(_value)),
          ),
        ],
      ),
    );
  }
}

/// Compact tappable summary ("Every Mon, Wed, Fri") for the task form.
class RecurrenceSummaryChip extends StatelessWidget {
  const RecurrenceSummaryChip({super.key, this.recurrence, this.onTap});

  final Recurrence? recurrence;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label =
        recurrence?.describe(Localizations.localeOf(context)) ??
        context.l10n.recurrenceDoesNotRepeat;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: 1,
            child: Pill(
              label: label,
              height: 32,
              fontSize: 13,
              color: recurrence == null ? AppColors.card : AppColors.lilac,
              icon: const Icon(Icons.repeat_rounded),
            ),
          ),
        ),
      ),
    );
  }
}

String _weekdayLetter(AppLocalizations l, int weekday) => [
  l.commonWeekdayLetterMon,
  l.commonWeekdayLetterTue,
  l.commonWeekdayLetterWed,
  l.commonWeekdayLetterThu,
  l.commonWeekdayLetterFri,
  l.commonWeekdayLetterSat,
  l.commonWeekdayLetterSun,
][weekday - 1];

String _weekdayFull(AppLocalizations l, int weekday) => [
  l.commonWeekdayFullMon,
  l.commonWeekdayFullTue,
  l.commonWeekdayFullWed,
  l.commonWeekdayFullThu,
  l.commonWeekdayFullFri,
  l.commonWeekdayFullSat,
  l.commonWeekdayFullSun,
][weekday - 1];
