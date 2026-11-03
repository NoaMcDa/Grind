import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../theme/app_text.dart';
import '../../../theme/tokens.dart';
import '../domain/metric_period.dart';
import 'goal_l10n.dart';

/// The last periods of a recurring metric as sticker bars, oldest at the
/// start edge, the current period at the end. Bars that reached the quota
/// are mint, others sky; a quiet period is a short lilac stub and a period
/// before the goal existed an empty slot. Nothing is ever red.
class MetricTrend extends StatelessWidget {
  const MetricTrend({super.key, required this.history, this.height = 76});

  final List<PeriodCount> history;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();
    final l = context.l10n;
    final quota = history.last.quota;
    final top = math.max(quota, history.map((p) => p.count).fold(0, math.max));
    final semantics = [
      for (final p in history)
        p.tracked ? l.goalOfTarget(p.count, p.quota, '') : l.goalsTrendBefore,
    ].join(', ');

    return Semantics(
      label: semantics,
      excludeSemantics: true,
      child: SizedBox(
        height: height + 18,
        child: Stack(
          children: [
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: height * quota / top,
              child: Container(height: 1.5, color: AppColors.rule),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < history.length; i++)
                  Expanded(
                    child: _Bar(
                      p: history[i],
                      maxHeight: height,
                      top: top,
                      current: i == history.length - 1,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.p,
    required this.maxHeight,
    required this.top,
    required this.current,
  });

  final PeriodCount p;
  final double maxHeight;
  final int top;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final h = !p.tracked
        ? 0.0
        : p.count == 0
        ? 8.0
        : math.max(10.0, maxHeight * p.count / top);
    final color = p.hit
        ? AppColors.mint
        : p.count == 0
        ? AppColors.lilac
        : AppColors.sky;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          p.tracked ? '${p.count}' : '',
          style: AppText.bold(
            size: 11,
            color: current ? AppColors.ink : AppColors.muted,
          ),
        ),
        const SizedBox(height: 3),
        if (p.tracked)
          Container(
            width: 18,
            height: h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.ink,
                width: current ? AppStroke.border : AppStroke.borderThin,
              ),
            ),
          )
        else
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.rule,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}
