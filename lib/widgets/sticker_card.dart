import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A white (or coloured) card with the ink border and hard shadow.
class StickerCard extends StatelessWidget {
  const StickerCard({
    super.key,
    required this.child,
    this.color = AppColors.card,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppRadii.card,
    this.shadow = 4,
    this.dashed = false,
    this.clip = false,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Hard shadow offset. 0 removes the shadow.
  final double shadow;

  /// Dashed border (used for calendar events "from calendar").
  final bool dashed;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final inner = Padding(padding: padding, child: child);
    if (dashed) {
      return CustomPaint(
        painter: _DashedBorderPainter(radius: radius, color: color),
        child: inner,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.ink, width: AppStroke.border),
        boxShadow: shadow > 0 ? AppShadows.hard(shadow) : null,
      ),
      child: clip
          ? ClipRRect(
              borderRadius: BorderRadius.circular(radius - AppStroke.border),
              child: inner,
            )
          : inner,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.radius, required this.color});

  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(AppStroke.border / 2),
      Radius.circular(radius),
    );
    canvas.drawRRect(rrect, Paint()..color = color);
    final path = Path()..addRRect(rrect);
    final stroke = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppStroke.border
      ..strokeCap = StrokeCap.round;
    const dash = 7.0, gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), stroke);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.radius != radius || old.color != color;
}
