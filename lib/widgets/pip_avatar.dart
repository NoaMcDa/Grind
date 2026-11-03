import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum PipAccessory { none, scarf, sunglasses }

/// Pip, the companion: a sun-yellow blob with an ink outline, oval eyes
/// with glints, pink cheeks and a mint leaf. Drawn in a 100×100 box.
class PipAvatar extends StatelessWidget {
  const PipAvatar({
    super.key,
    this.size = 58,
    this.cheering = false,
    this.accessory = PipAccessory.none,
    this.semanticLabel = 'Pip, your companion',
  });

  final double size;

  /// Arms raised (focus screen).
  final bool cheering;
  final PipAccessory accessory;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticLabel,
      child: CustomPaint(
        size: Size.square(size),
        painter: _PipPainter(cheering: cheering, accessory: accessory),
      ),
    );
  }
}

class _PipPainter extends CustomPainter {
  _PipPainter({required this.cheering, required this.accessory});

  final bool cheering;
  final PipAccessory accessory;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    canvas.scale(s);

    Paint fill(Color c) => Paint()..color = c;
    Paint stroke(double w, [Color c = AppColors.ink]) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (cheering) {
      // Arms up with little round hands.
      final left = Path()
        ..moveTo(26, 56)
        ..quadraticBezierTo(12, 46, 15, 30);
      final right = Path()
        ..moveTo(74, 56)
        ..quadraticBezierTo(88, 46, 85, 30);
      canvas.drawPath(left, stroke(3));
      canvas.drawPath(right, stroke(3));
      for (final c in const [Offset(15, 28), Offset(85, 28)]) {
        canvas.drawCircle(c, 5, fill(AppColors.sun));
        canvas.drawCircle(c, 5, stroke(2.5));
      }
    }

    // Leaf + stem.
    final leaf = Path()
      ..moveTo(50, 22)
      ..cubicTo(50, 12, 56, 6, 66, 6)
      ..cubicTo(66, 16, 60, 22, 50, 22)
      ..close();
    canvas.drawPath(leaf, fill(AppColors.mint));
    canvas.drawPath(leaf, stroke(4));
    canvas.drawLine(const Offset(50, 22), const Offset(50, 28), stroke(4));

    // Body.
    const center = Offset(50, 60);
    canvas.drawCircle(center, 34, fill(AppColors.sun));
    canvas.drawCircle(center, 34, stroke(5));

    // Cheeks.
    canvas.drawCircle(const Offset(30, 68), 4.5, fill(AppColors.pink));
    canvas.drawCircle(const Offset(70, 68), 4.5, fill(AppColors.pink));

    // Eyes.
    if (accessory == PipAccessory.sunglasses) {
      final glass = fill(AppColors.ink);
      for (final cx in [39.0, 61.0]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, 56), width: 18, height: 12),
            const Radius.circular(5),
          ),
          glass,
        );
      }
      canvas.drawLine(const Offset(48, 56), const Offset(52, 56), stroke(2.5));
      canvas.drawLine(const Offset(30, 55), const Offset(20, 52), stroke(2.5));
      canvas.drawLine(const Offset(70, 55), const Offset(80, 52), stroke(2.5));
      canvas.drawLine(
        const Offset(34, 54),
        const Offset(38, 54),
        stroke(1.8, AppColors.sky),
      );
      canvas.drawLine(
        const Offset(56, 54),
        const Offset(60, 54),
        stroke(1.8, AppColors.sky),
      );
    } else {
      for (final cx in [39.0, 61.0]) {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, 56), width: 10, height: 14),
          fill(AppColors.ink),
        );
        canvas.drawCircle(Offset(cx + 2, 53), 1.8, fill(Colors.white));
      }
    }

    // Smile.
    final smile = Path()
      ..moveTo(42, 70)
      ..quadraticBezierTo(50, 78, 58, 70);
    canvas.drawPath(smile, stroke(4));

    if (accessory == PipAccessory.scarf) {
      final band = Path()
        ..moveTo(22, 80)
        ..quadraticBezierTo(50, 96, 78, 80)
        ..lineTo(80, 88)
        ..quadraticBezierTo(50, 106, 20, 88)
        ..close();
      final tail = Path()
        ..moveTo(64, 92)
        ..lineTo(71, 104)
        ..lineTo(62, 106)
        ..lineTo(57, 94)
        ..close();
      canvas.drawPath(band, fill(AppColors.violet));
      canvas.drawPath(band, stroke(2.5));
      canvas.drawPath(tail, fill(AppColors.violet));
      canvas.drawPath(tail, stroke(2.5));
      canvas.drawLine(
        const Offset(34, 88),
        const Offset(37, 92),
        stroke(2, Colors.white),
      );
      canvas.drawLine(
        const Offset(44, 91),
        const Offset(47, 95),
        stroke(2, Colors.white),
      );
    }
  }

  @override
  bool shouldRepaint(_PipPainter old) =>
      old.cheering != cheering || old.accessory != accessory;
}

/// Tab-bar sized outline of Pip (a circle with a leaf and a smile).
class PipIcon extends StatelessWidget {
  const PipIcon({super.key, this.color = AppColors.muted, this.size = 24});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _PipIconPainter(color),
    );
  }
}

class _PipIconPainter extends CustomPainter {
  _PipIconPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.scale(s);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(const Offset(12, 14), 8, p);
    canvas.drawPath(
      Path()
        ..moveTo(12, 6)
        ..cubicTo(12, 4, 13.5, 2, 16, 2),
      p,
    );
    canvas.drawPath(
      Path()
        ..moveTo(9, 15.5)
        ..quadraticBezierTo(12, 18, 15, 15.5),
      p,
    );
  }

  @override
  bool shouldRepaint(_PipIconPainter old) => old.color != color;
}
