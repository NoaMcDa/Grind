import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/core.dart';
import '../../theme/app_text.dart';
import '../../theme/tokens.dart';
import 'plan_layout.dart';
import 'plan_providers.dart';
import 'plan_strings.dart';

/// Seven day tiles with a tiny load bar; tap to select the day.
class PlanWeekStrip extends ConsumerWidget {
  const PlanWeekStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = ref.watch(planWeekProvider);
    final load = ref.watch(planWeekLoadProvider);
    final selected = ref.watch(selectedDayProvider);
    final today = dateOnly(ref.watch(clockProvider).now());

    return Row(
      key: const Key('plan-week-strip'),
      children: [
        for (var i = 0; i < week.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: _DayTile(
              day: week[i],
              load: load[week[i]] ?? 0,
              selected: week[i] == selected,
              today: week[i] == today,
              onTap: () =>
                  ref.read(selectedDayProvider.notifier).select(week[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.day,
    required this.load,
    required this.selected,
    required this.today,
    required this.onTap,
  });

  final DateTime day;
  final double load;
  final bool selected, today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.ink;
    final bg = selected
        ? AppColors.violet
        : today
        ? AppColors.sun
        : AppColors.card;
    final name = PlanStrings.weekdayShort[day.weekday - 1];
    return Semantics(
      button: true,
      selected: selected,
      label: PlanStrings.dayLoad(formatPlanDay(day), (load * 100).round()),
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        key: Key('plan-day-${day.year}-${day.month}-${day.day}'),
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadii.cardSmall),
            border: Border.all(
              color: AppColors.ink,
              width: AppStroke.borderThin,
            ),
            boxShadow: selected ? AppShadows.hard(3) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name.toUpperCase(),
                maxLines: 1,
                style: AppText.label(size: 10, color: fg),
              ),
              const SizedBox(height: 2),
              Text(
                '${day.day}',
                style: AppText.display(size: 17, color: fg, height: 1.1),
              ),
              const SizedBox(height: 4),
              // Load bar: track + fill, full width of the tile.
              Container(
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: selected ? Colors.white24 : AppColors.rule,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FractionallySizedBox(
                    widthFactor: load,
                    child: Container(
                      key: Key('plan-load-${day.day}'),
                      decoration: BoxDecoration(
                        color: load >= 1
                            ? AppColors.pink
                            : (selected ? AppColors.sun : AppColors.violet),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
