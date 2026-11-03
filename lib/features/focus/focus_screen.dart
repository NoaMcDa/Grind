import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_text.dart';
import '../../theme/tokens.dart';
import '../../widgets/pill.dart';
import '../../widgets/pip_avatar.dart';
import '../../widgets/sticker_card.dart';

/// Productive layer: a full-screen focus session with Pip cheering.
class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  bool _paused = false;

  static const _remaining = '18:42';
  static const _progress = 1 - 171 / 678.58; // elapsed share, as in the mockup

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return ColoredBox(
      color: AppColors.violet,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 20 + top, 20, 16),
        children: [
          Text('FOCUS 2 OF 4', style: AppText.label(color: Colors.white)),
          const SizedBox(height: 6),
          Text(
            'Thesis: write related-work section',
            style: AppText.display(size: 22, color: Colors.white, height: 1.2),
          ),
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerLeft,
            child: Pill(
              label: 'Hard mode on · 3 apps shielded',
              color: AppColors.sun,
              height: 32,
              fontSize: 13,
              shadow: 3,
              border: AppStroke.border,
              icon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 52),
          Center(
            child: SizedBox(
              width: 250,
              height: 250,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size.square(250),
                    painter: _RingPainter(_progress),
                  ),
                  const Positioned(
                    top: -58,
                    child: PipAvatar(size: 76, cheering: true),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _remaining,
                        style: AppText.display(
                          size: 64,
                          color: Colors.white,
                          height: 1,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_paused)
                        const Pill(
                          label: 'PAUSED',
                          color: AppColors.sun,
                          height: 24,
                          fontSize: 12,
                        )
                      else
                        Text(
                          'of 25:00',
                          style: AppText.body(
                            size: 16,
                            weight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              StickerCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Pip: ', style: AppText.bold()),
                      TextSpan(
                        text:
                            "You're past halfway. Keep going, the first draft just needs to exist.",
                        style: AppText.body(weight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: -9,
                child: Transform.rotate(
                  angle: math.pi / 4,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: AppColors.card,
                      border: Border(
                        left: BorderSide(
                          color: AppColors.ink,
                          width: AppStroke.border,
                        ),
                        top: BorderSide(
                          color: AppColors.ink,
                          width: AppStroke.border,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PillButton(
                label: '+5 min',
                height: 48,
                shadow: 3,
                fontSize: 15,
                horizontalPadding: 20,
                onPressed: () {},
              ),
              const SizedBox(width: 16),
              Semantics(
                button: true,
                label: _paused ? 'Resume' : 'Pause',
                child: GestureDetector(
                  onTap: () => setState(() => _paused = !_paused),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.sun,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.ink,
                        width: AppStroke.border,
                      ),
                      boxShadow: AppShadows.hard(),
                    ),
                    child: Icon(
                      _paused ? Icons.play_arrow : Icons.pause,
                      size: 32,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              PillButton(
                label: 'End',
                height: 48,
                shadow: 3,
                fontSize: 15,
                horizontalPadding: 22,
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 18),
          Semantics(
            label: 'Sessions 1 and 2 done, 3 and 4 to go',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 4; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < 2 ? AppColors.sun : Colors.transparent,
                        border: Border.all(
                          color: i < 2 ? AppColors.ink : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LOCK SCREEN PREVIEW',
                style: AppText.label(color: Colors.white),
              ),
              Text(
                'Live Activity',
                style: AppText.body(size: 13, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 72,
            padding: const EdgeInsets.fromLTRB(12, 0, 18, 0),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                const PipAvatar(size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _paused ? 'PAUSED' : 'FOCUSING',
                        style: AppText.label(size: 12, color: AppColors.sun),
                      ),
                      Text(
                        'Thesis: write related-work section',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(
                          weight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _remaining,
                  style: AppText.display(
                    size: 28,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const r = 108.0;
    final rect = Rect.fromCircle(center: center, radius: r);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = AppColors.sun
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
