import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// Which shapes a burst uses. Rotated so repeat celebrations look new.
enum ConfettiShapes {
  /// Dots, triangles and squares.
  classic,

  /// Ribbons, diamonds and rings.
  ribbons,
}

/// Look of one burst.
class ConfettiStyle {
  const ConfettiStyle({
    required this.colors,
    this.shapes = ConfettiShapes.classic,
    this.count = 24,
  });

  final List<Color> colors;
  final ConfettiShapes shapes;
  final int count;
}

/// Palette rotations: each burst starts one step further round.
const confettiPalette = [
  AppColors.violet,
  AppColors.pink,
  AppColors.mint,
  AppColors.sun,
  AppColors.sky,
];

/// A short sticker-style confetti burst: ink-outlined shapes fly up from
/// near the bottom centre and fall, in [duration] (900 ms at most).
///
/// Purely visual: wrapped in [IgnorePointer] and excluded from semantics,
/// so it never blocks input. Pass the burst only when animations are on
/// (see `MediaQuery.disableAnimationsOf`); this widget itself always runs.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({
    super.key,
    required this.style,
    this.seed = 1,
    this.duration = const Duration(milliseconds: 900),
    this.onDone,
  }) : assert(duration <= const Duration(milliseconds: 900));

  final ConfettiStyle style;
  final int seed;
  final Duration duration;
  final VoidCallback? onDone;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(widget.seed);
    final colors = widget.style.colors;
    _particles = [
      for (var i = 0; i < widget.style.count; i++)
        _Particle(
          angle: -math.pi / 2 + (rnd.nextDouble() - 0.5) * math.pi * 0.9,
          speed: 0.45 + rnd.nextDouble() * 0.55,
          spin: (rnd.nextDouble() - 0.5) * 8,
          size: 5 + rnd.nextDouble() * 5,
          color: colors[(i + widget.seed) % colors.length],
          shape: i % 3,
        ),
    ];
    _c = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDone?.call();
      })
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(_particles, widget.style.shapes, _c),
          ),
        ),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.angle,
    required this.speed,
    required this.spin,
    required this.size,
    required this.color,
    required this.shape,
  });
  final double angle, speed, spin, size;
  final Color color;
  final int shape;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, this.shapes, this.t) : super(repaint: t);

  final List<_Particle> particles;
  final ConfettiShapes shapes;
  final Animation<double> t;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Curves.easeOut.transform(t.value);
    final fade = t.value < 0.75 ? 1.0 : (1 - t.value) / 0.25;
    final origin = Offset(size.width / 2, size.height * 0.78);
    final reach = size.height * 0.6;
    for (final e in particles) {
      final dx = math.cos(e.angle) * e.speed * reach * p * 0.8;
      final dy =
          math.sin(e.angle) * e.speed * reach * p +
          0.9 * reach * t.value * t.value * 0.6;
      final c = origin + Offset(dx, dy);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(e.spin * t.value);
      final fill = Paint()..color = e.color.withValues(alpha: fade);
      final line = Paint()
        ..color = AppColors.ink.withValues(alpha: fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round;
      _shape(canvas, e, fill, line);
      canvas.restore();
    }
  }

  void _shape(Canvas canvas, _Particle e, Paint fill, Paint line) {
    final s = e.size;
    if (shapes == ConfettiShapes.classic) {
      switch (e.shape) {
        case 0:
          canvas.drawCircle(Offset.zero, s / 2, fill);
          canvas.drawCircle(Offset.zero, s / 2, line);
        case 1:
          final path = Path()
            ..moveTo(0, -s / 2)
            ..lineTo(s / 2, s / 2)
            ..lineTo(-s / 2, s / 2)
            ..close();
          canvas.drawPath(path, fill);
          canvas.drawPath(path, line);
        default:
          final r = Rect.fromCenter(center: Offset.zero, width: s, height: s);
          canvas.drawRect(r, fill);
          canvas.drawRect(r, line);
      }
    } else {
      switch (e.shape) {
        case 0:
          final r = RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: s * 1.8, height: s / 2),
            const Radius.circular(3),
          );
          canvas.drawRRect(r, fill);
          canvas.drawRRect(r, line);
        case 1:
          final path = Path()
            ..moveTo(0, -s * 0.6)
            ..lineTo(s * 0.5, 0)
            ..lineTo(0, s * 0.6)
            ..lineTo(-s * 0.5, 0)
            ..close();
          canvas.drawPath(path, fill);
          canvas.drawPath(path, line);
        default:
          canvas.drawCircle(
            Offset.zero,
            s / 2,
            Paint()
              ..color = fill.color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3,
          );
      }
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) =>
      old.particles != particles || old.shapes != shapes;
}
