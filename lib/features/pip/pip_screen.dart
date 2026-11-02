import 'package:flutter/material.dart';

import '../../theme/app_text.dart';
import '../../theme/tokens.dart';
import '../../widgets/momentum_meter.dart';
import '../../widgets/pill.dart';
import '../../widgets/pip_avatar.dart';
import '../../widgets/sticker_card.dart';

/// Cheering layer: Pip's mood, momentum, the week, wins and cosmetic unlocks.
class PipScreen extends StatefulWidget {
  const PipScreen({super.key});

  @override
  State<PipScreen> createState() => _PipScreenState();
}

class _PipScreenState extends State<PipScreen> {
  PipAccessory _equipped = PipAccessory.scarf;

  static const _week = <double>[62, 48, 14, 72, 54, 36, 44];
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 14 + top, 20, 16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pip', style: AppText.display(height: 1.2)),
            Text(
              'Your cheering squad of one',
              style: AppText.body(
                size: 13,
                weight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StickerCard(
          color: AppColors.sun,
          clip: true,
          padding: const EdgeInsets.fromLTRB(6, 12, 14, 12),
          child: Stack(
            children: [
              const Positioned.fill(
                child: CustomPaint(painter: _ConfettiPainter()),
              ),
              Row(
                children: [
                  PipAvatar(size: 150, accessory: _equipped),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Pill(
                          label: 'wearing: ${_equipped.name}',
                          height: 22,
                          fontSize: 12,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Pip is glowing',
                          style: AppText.display(size: 24, height: 1.1),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "You showed up 5 of the last 7 days. That's real momentum.",
                          style: AppText.body(
                            size: 14,
                            weight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SectionLabel('Momentum'),
            Pill(
              label: 'Strong',
              color: AppColors.violet,
              textColor: Colors.white,
              height: 24,
              fontSize: 13,
              border: AppStroke.border,
            ),
          ],
        ),
        const SizedBox(height: 6),
        const MomentumMeter(
          value: 0.72,
          height: 24,
          shadow: 3,
          segments: [AppColors.violet, AppColors.pink],
        ),
        const SizedBox(height: 6),
        Text(
          "Momentum fades slowly, one quiet day won't reset it.",
          style: AppText.body(size: 13, color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        const SectionLabel('This week'),
        const SizedBox(height: 6),
        StickerCard(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Column(
            children: [
              Semantics(
                label:
                    'Focus minutes per day this week. Wednesday was a rest day.',
                child: SizedBox(
                  height: 84,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < 7; i++)
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (i == 2) ...[
                                Text(
                                  'rest day',
                                  style: AppText.body(
                                    size: 11,
                                    weight: FontWeight.w500,
                                    color: AppColors.muted,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                              Container(
                                width: 26,
                                height: _week[i],
                                decoration: BoxDecoration(
                                  color: AppColors.mint,
                                  borderRadius: BorderRadius.circular(
                                    i == 2 ? 7 : 9,
                                  ),
                                  border: Border.all(
                                    color: AppColors.ink,
                                    width: AppStroke.border,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (final d in _days)
                    Expanded(
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: AppText.bold(size: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Focus minutes per day',
                style: AppText.body(size: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SectionLabel('Wins you logged'),
        const SizedBox(height: 6),
        const IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _Win('Sent the thesis outline', AppColors.mint)),
              SizedBox(width: 10),
              Expanded(child: _Win('Finished DL lab 3', AppColors.sky)),
              SizedBox(width: 10),
              Expanded(child: _Win('Went to the gym twice', AppColors.pink)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SectionLabel('Unlocks'),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _unlock(
                'Scarf',
                PipAccessory.scarf,
                const Icon(Icons.checkroom_outlined, color: AppColors.violet),
              ),
            ),
            Expanded(
              child: _unlock(
                'Sunglasses',
                PipAccessory.sunglasses,
                const Icon(Icons.visibility_outlined, color: AppColors.ink),
              ),
            ),
            Expanded(
              child: _UnlockSlot(
                label: 'Party hat',
                caption: '3 more sessions',
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.square(
                      dimension: 52,
                      child: CircularProgressIndicator(
                        value: 0.29,
                        strokeWidth: 5,
                        color: AppColors.violet,
                        backgroundColor: const Color(0xFFE4DFF7),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    const Icon(
                      Icons.celebration_outlined,
                      color: AppColors.pink,
                    ),
                  ],
                ),
              ),
            ),
            const Expanded(
              child: _UnlockSlot(
                label: 'Rain boots',
                caption: 'Coming soon',
                locked: true,
                child: Icon(Icons.lock_outline, color: AppColors.muted),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _unlock(String label, PipAccessory a, Widget icon) {
    final on = _equipped == a;
    return _UnlockSlot(
      label: label,
      caption: on ? 'Wearing' : 'Tap to wear',
      captionColor: on ? AppColors.violet : AppColors.muted,
      onTap: () => setState(() => _equipped = a),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: on ? AppColors.sun : AppColors.card,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.ink, width: AppStroke.border),
          boxShadow: AppShadows.hard(3),
        ),
        foregroundDecoration: on
            ? BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.violet, width: 3),
              )
            : null,
        child: icon,
      ),
    );
  }
}

class _Win extends StatelessWidget {
  const _Win(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return StickerCard(
      radius: AppRadii.cardSmall,
      shadow: 3,
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.ink, width: 2),
            ),
            child: const Icon(Icons.check, size: 11, color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(text, style: AppText.bold(size: 13, height: 1.25)),
        ],
      ),
    );
  }
}

class _UnlockSlot extends StatelessWidget {
  const _UnlockSlot({
    required this.label,
    required this.caption,
    required this.child,
    this.captionColor = AppColors.muted,
    this.locked = false,
    this.onTap,
  });

  final String label, caption;
  final Widget child;
  final Color captionColor;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final token = locked
        ? Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFECE8F8),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.muted,
                width: AppStroke.border,
                style: BorderStyle.solid,
              ),
            ),
            child: child,
          )
        : SizedBox(width: 56, height: 56, child: Center(child: child));
    return Semantics(
      button: onTap != null,
      label: '$label, $caption',
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            token,
            const SizedBox(height: 5),
            Text(label, style: AppText.bold(size: 11, height: 1.2)),
            Text(
              caption,
              textAlign: TextAlign.center,
              style: AppText.body(
                size: 11,
                weight: captionColor == AppColors.violet
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: captionColor,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Little confetti shapes behind the hero card.
class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;
    void dot(Offset c, Color color) {
      canvas.drawCircle(c, 5, Paint()..color = color);
      canvas.drawCircle(c, 5, stroke);
    }

    void tri(Offset a, Offset b, Offset c, Color color) {
      final p = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(c.dx, c.dy)
        ..close();
      canvas.drawPath(p, Paint()..color = color);
      canvas.drawPath(p, stroke);
    }

    final w = size.width, h = size.height;
    dot(const Offset(16, 18), AppColors.violet);
    tri(
      Offset(w * 0.45, 10),
      Offset(w * 0.45 + 10, 24),
      Offset(w * 0.45 - 8, 24),
      AppColors.pink,
    );
    dot(Offset(w * 0.42, h - 20), AppColors.mint);
    tri(
      Offset(14, h - 30),
      Offset(26, h - 24),
      Offset(14, h - 16),
      AppColors.sky,
    );
    dot(Offset(w - 16, 16), AppColors.pink);
    tri(
      Offset(w * 0.8, 8),
      Offset(w * 0.8 + 10, 20),
      Offset(w * 0.8 - 6, 22),
      AppColors.mint,
    );
    tri(
      Offset(w - 30, h - 20),
      Offset(w - 18, h - 14),
      Offset(w - 30, h - 6),
      AppColors.violet,
    );
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}
