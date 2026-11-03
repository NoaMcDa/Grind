import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_text.dart';
import '../../theme/tokens.dart';
import 'capacity_format.dart';
import 'capacity_math.dart';

/// One bar per day: free time as a lilac track, planned time on top of it.
/// Calm = mint, tight = sun, overbooked = a pink outline that rises above
/// the track with a calm "Packed" label. Never red.
class WeekBars extends StatelessWidget {
  const WeekBars({super.key, required this.days});

  final List<DayBar> days;

  static const _trackHeight = 110.0;

  @override
  Widget build(BuildContext context) {
    var scale = 60;
    for (final d in days) {
      if (d.freeMinutes > scale) scale = d.freeMinutes;
      if (d.plannedMinutes > scale) scale = d.plannedMinutes;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final d in days)
          Expanded(
            child: _DayColumn(day: d, scale: scale),
          ),
      ],
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({required this.day, required this.scale});

  final DayBar day;
  final int scale;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final name = weekdayShort(context, day.date);
    final free = day.freeMinutes / scale * WeekBars._trackHeight;
    final planned = day.plannedMinutes / scale * WeekBars._trackHeight;
    final state = day.state;
    final over = state == LoadState.overbooked;
    final fill = switch (state) {
      LoadState.calm => AppColors.mint,
      LoadState.tight => AppColors.sun,
      LoadState.overbooked => AppColors.card,
    };
    return Semantics(
      label: l.capacityDaySemantics(
        name,
        formatSpan(context, day.freeMinutes),
        formatSpan(context, day.plannedMinutes),
      ),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: WeekBars._trackHeight,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    height: free.clamp(4, WeekBars._trackHeight),
                    decoration: BoxDecoration(
                      color: AppColors.lilac,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.rule,
                        width: AppStroke.borderThin,
                      ),
                    ),
                  ),
                  if (planned > 0)
                    Container(
                      height: planned.clamp(6, WeekBars._trackHeight),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: fill,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: over ? AppColors.pink : AppColors.ink,
                          width: over ? AppStroke.border : AppStroke.borderThin,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: AppText.bold(size: 12),
            ),
            SizedBox(
              height: 14,
              child: over
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        l.capacityDayPacked,
                        style: AppText.bold(size: 10, color: AppColors.muted),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
