import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/app_text.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/widgets.dart';
import '../domain/goal_area.dart';
import '../domain/goal_progress.dart';
import '../domain/goal_record.dart';
import '../goals_strings.dart';

/// Area tag: palette colour, stroke icon, label.
class GoalAreaChip extends StatelessWidget {
  const GoalAreaChip({super.key, required this.area, this.height = 26});

  final GoalArea area;
  final double height;

  @override
  Widget build(BuildContext context) => Pill(
    label: area.label,
    color: area.color,
    textColor: area.onColor,
    height: height,
    icon: Icon(area.icon),
  );
}

/// "Almost there" / "Completed" / "Resting", or nothing.
class GoalStatusPill extends StatelessWidget {
  const GoalStatusPill({super.key, required this.goal, required this.progress});

  final GoalRecord goal;
  final GoalProgress progress;

  @override
  Widget build(BuildContext context) {
    if (progress.isCompleted) {
      return const Pill(
        label: GoalsStrings.completed,
        color: AppColors.mint,
        icon: Icon(Icons.check),
      );
    }
    if (goal.status == GoalStatus.paused) {
      return const Pill(
        label: GoalsStrings.paused,
        icon: Icon(Icons.pause_outlined),
      );
    }
    if (progress.isCloseToDone) {
      return const Pill(
        label: GoalsStrings.closeToDone,
        color: AppColors.sun,
        icon: Icon(Icons.auto_awesome_outlined),
      );
    }
    return const SizedBox.shrink();
  }
}

/// Sticker progress bar: ink-bordered track, fill grows from the start
/// edge (right in RTL).
class GoalProgressBar extends StatelessWidget {
  const GoalProgressBar({
    super.key,
    required this.fraction,
    this.color = AppColors.violet,
    this.height = 16,
  });

  final double fraction;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final f = fraction.clamp(0.0, 1.0);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.lilac,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.ink, width: AppStroke.borderThin),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: FractionallySizedBox(
            widthFactor: f,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                border: f > 0 && f < 1
                    ? const BorderDirectional(
                        end: BorderSide(
                          color: AppColors.ink,
                          width: AppStroke.borderThin,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Progress ring with the percent in the middle.
class GoalProgressRing extends StatelessWidget {
  const GoalProgressRing({
    super.key,
    required this.fraction,
    required this.centerLabel,
    this.color = AppColors.violet,
    this.size = 112,
  });

  final double fraction;
  final String centerLabel;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _RingPainter(fraction.clamp(0.0, 1.0), color),
      child: Center(
        child: Text(centerLabel, style: AppText.display(size: size * 0.22)),
      ),
    ),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.fraction, this.color);

  final double fraction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - stroke / 2 - AppStroke.border;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = AppColors.lilac
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (fraction > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        2 * math.pi * fraction,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = fraction >= 1 ? StrokeCap.butt : StrokeCap.round,
      );
    }
    final ink = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppStroke.border;
    canvas.drawCircle(c, r + stroke / 2, ink);
    canvas.drawCircle(c, r - stroke / 2, ink);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.color != color;
}

/// A tappable choice pill (≥ 44 px target) for the goal form.
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.selectedColor = AppColors.violet,
    this.selectedTextColor = Colors.white,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color selectedColor;
  final Color selectedTextColor;

  @override
  Widget build(BuildContext context) => Semantics(
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
        child: Center(
          widthFactor: 1,
          child: Pill(
            label: label,
            height: 36,
            fontSize: 13,
            color: selected ? selectedColor : AppColors.card,
            textColor: selected ? selectedTextColor : AppColors.ink,
            shadow: selected ? 2 : 0,
            icon: icon == null ? null : Icon(icon),
          ),
        ),
      ),
    ),
  );
}
