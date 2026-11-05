import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../theme/app_text.dart';
import '../../theme/tokens.dart';
import '../../widgets/focus_tap.dart';
import '../../l10n/l10n.dart';

/// "09:00" style label for minutes after midnight (1440 shows as 24:00).
String formatMinutes(int minutes) {
  final h = (minutes ~/ 60).toString().padLeft(2, '0');
  final m = (minutes % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

/// Asks the user for a time of day; returns minutes after midnight or null.
typedef MinutesPicker =
    Future<int?> Function(BuildContext context, int initialMinutes);

Future<int?> pickMinutes(BuildContext context, int initialMinutes) async {
  final t = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(
      hour: (initialMinutes ~/ 60).clamp(0, 23),
      minute: initialMinutes % 60,
    ),
  );
  return t == null ? null : t.hour * 60 + t.minute;
}

/// Small pill showing a time; tapping it opens the picker.
class TimePill extends StatelessWidget {
  const TimePill({
    super.key,
    required this.minutes,
    required this.onTap,
    required this.semanticLabel,
  });

  final int minutes;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$semanticLabel ${formatMinutes(minutes)}',
      excludeSemantics: true,
      child: FocusTap(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 68),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: AppColors.ink, width: AppStroke.border),
          ),
          child: Text(
            formatMinutes(minutes),
            style: AppText.bold(size: 14, height: 1),
          ),
        ),
      ),
    );
  }
}

/// One row per weekday: on/off switch plus start and end time.
/// Days are ordered starting at [weekStart].
class WeekdayHoursEditor extends StatelessWidget {
  const WeekdayHoursEditor({
    super.key,
    required this.value,
    required this.onChanged,
    this.weekStart = DateTime.sunday,
    this.defaultRange = const TimeRange(
      startMinutes: 9 * 60,
      endMinutes: 18 * 60,
    ),
    this.picker = pickMinutes,
  });

  final Map<int, List<TimeRange>> value;
  final ValueChanged<Map<int, List<TimeRange>>> onChanged;
  final int weekStart;
  final TimeRange defaultRange;
  final MinutesPicker picker;

  List<int> get _days => [
    for (var i = 0; i < 7; i++) (weekStart - 1 + i) % 7 + 1,
  ];

  void _set(int day, List<TimeRange>? ranges) {
    final next = Map<int, List<TimeRange>>.of(value);
    if (ranges == null || ranges.isEmpty) {
      next.remove(day);
    } else {
      next[day] = ranges;
    }
    onChanged(next);
  }

  Future<void> _edit(BuildContext context, int day, bool start) async {
    final range = value[day]!.first;
    final picked = await picker(
      context,
      start ? range.startMinutes : range.endMinutes,
    );
    if (picked == null) return;
    var s = range.startMinutes;
    var e = range.endMinutes;
    if (start) {
      s = picked;
      if (e <= s) e = (s + 60).clamp(s + 1, 24 * 60);
    } else {
      e = picked;
      if (e <= s) s = (e - 60).clamp(0, e - 1);
    }
    if (s >= 24 * 60 || e <= s) return;
    // Keep any further ranges of the day (a split shift from a backup).
    _set(day, [
      TimeRange(startMinutes: s, endMinutes: e),
      ...value[day]!.skip(1),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final day in _days)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: _row(context, day),
          ),
      ],
    );
  }

  Widget _row(BuildContext context, int day) {
    final ranges = value[day];
    final on = ranges != null && ranges.isNotEmpty;
    final name = _dayShort(context, day);
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(name, style: AppText.bold(size: 15, height: 1)),
        ),
        Semantics(
          label: name,
          child: Switch(
            key: ValueKey('day-switch-$day'),
            value: on,
            activeThumbColor: AppColors.card,
            activeTrackColor: AppColors.violet,
            inactiveThumbColor: AppColors.ink,
            inactiveTrackColor: AppColors.lilac,
            trackOutlineColor: const WidgetStatePropertyAll(AppColors.ink),
            onChanged: (v) => _set(day, v ? [defaultRange] : null),
          ),
        ),
        const Spacer(),
        if (on) ...[
          TimePill(
            key: ValueKey('day-start-$day'),
            minutes: ranges.first.startMinutes,
            semanticLabel: '$name ${context.l10n.onboardingStartTime}',
            onTap: () => _edit(context, day, true),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text('-'),
          ),
          TimePill(
            key: ValueKey('day-end-$day'),
            minutes: ranges.first.endMinutes,
            semanticLabel: '$name ${context.l10n.onboardingEndTime}',
            onTap: () => _edit(context, day, false),
          ),
        ] else
          Text(
            context.l10n.onboardingDayOff,
            style: AppText.body(
              size: 14,
              weight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
      ],
    );
  }
}

/// Localized short weekday name; [day] 1 = Monday ... 7 = Sunday.
String _dayShort(BuildContext context, int day) {
  final l = context.l10n;
  return [
    l.commonWeekdayShortMon,
    l.commonWeekdayShortTue,
    l.commonWeekdayShortWed,
    l.commonWeekdayShortThu,
    l.commonWeekdayShortFri,
    l.commonWeekdayShortSat,
    l.commonWeekdayShortSun,
  ][day - 1];
}
