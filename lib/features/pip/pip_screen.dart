import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grind/core/core.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_text.dart';
import '../companion/mood.dart';
import '../companion/pip_providers.dart';
import '../companion/unlocks.dart';
import '../../theme/tokens.dart';
import '../../widgets/pill.dart';
import '../../widgets/pip_avatar.dart';
import '../../widgets/sticker_card.dart';

/// Cheering layer: Pip's mood, momentum, the week, wins and cosmetic unlocks.
class PipScreen extends ConsumerWidget {
  const PipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final top = MediaQuery.paddingOf(context).top;
    final score = ref.watch(effortScoreProvider);
    final mood = ref.watch(pipMoodProvider);
    final momentum = ref.watch(momentumProvider);
    final worn = ref.watch(companionPrefsProvider).accessory;
    final equipped = PipAccessory.values.firstWhere(
      (a) => a.name == worn,
      orElse: () => PipAccessory.none,
    );
    final now = ref.watch(clockProvider).now();
    final tasks = ref.watch(tasksProvider).value ?? const <Task>[];
    final wins =
        tasks
            .where((t) => t.status == TaskStatus.done && t.deletedAt == null)
            .toList()
          ..sort(
            (a, b) => (b.completedAt ?? b.updatedAt).compareTo(
              a.completedAt ?? a.updatedAt,
            ),
          );
    final counts = score.dayCounts;
    final maxCount = counts.fold<int>(1, (m, c) => c > m ? c : m);
    final dayLabels = [
      for (var i = 0; i < 7; i++)
        _dayShort(l, now.subtract(Duration(days: 6 - i)).weekday),
    ];
    final progress = ref.watch(unlockProgressProvider);
    void wear(PipAccessory a) =>
        ref.read(companionPrefsProvider.notifier).wear(a.name);

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 14 + top, 20, 16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l.tabPip, style: AppText.display(height: 1.2)),
            Flexible(
              child: Text(
                l.pipCheeringSquad,
                textAlign: TextAlign.end,
                style: AppText.body(
                  size: 13,
                  weight: FontWeight.w500,
                  color: AppColors.muted,
                ),
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
                  PipAvatar(size: 150, accessory: equipped),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Pill(
                          label: equipped == PipAccessory.none
                              ? l.pipNoAccessory
                              : l.pipWearing(accessoryName(l, equipped)),
                          height: 22,
                          fontSize: 12,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          MoodCopy.title(l, mood),
                          style: AppText.display(size: 24, height: 1.1),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          MoodCopy.line(l, mood, score.showedUpDays),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SectionLabel(l.sectionMomentum),
            Pill(
              label: MoodCopy.momentumLabel(l, momentum.level),
              color: AppColors.violet,
              textColor: Colors.white,
              height: 24,
              fontSize: 13,
              border: AppStroke.border,
            ),
          ],
        ),
        const SizedBox(height: 6),
        _TwoToneMeter(recent: momentum.recent, carry: momentum.carry),
        const SizedBox(height: 6),
        Text(
          l.pipMomentumNote,
          style: AppText.body(size: 13, color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        SectionLabel(l.sectionThisWeek),
        const SizedBox(height: 6),
        StickerCard(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Column(
            children: [
              Semantics(
                label: l.pipWeekSemantics,
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
                              if (counts[i] == 0)
                                Text(
                                  l.pipRestDay,
                                  textAlign: TextAlign.center,
                                  style: AppText.body(
                                    size: 10,
                                    weight: FontWeight.w500,
                                    color: AppColors.muted,
                                    height: 1,
                                  ),
                                )
                              else
                                Container(
                                  width: 26,
                                  height: 14 + 58 * counts[i] / maxCount,
                                  decoration: BoxDecoration(
                                    color: AppColors.mint,
                                    borderRadius: BorderRadius.circular(9),
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
                  for (final d in dayLabels)
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
                l.pipWeekCaption,
                style: AppText.body(size: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: PillButton(
                  key: const Key('pip-your-numbers'),
                  label: 'Your numbers',
                  height: 36,
                  shadow: 0,
                  fontSize: 13,
                  icon: const Icon(Icons.bar_chart_outlined),
                  onPressed: () =>
                      GoRouter.maybeOf(context)?.push('/analytics'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionLabel(l.sectionWins),
        const SizedBox(height: 6),
        if (wins.isEmpty)
          Text(
            l.pipFirstWin,
            style: AppText.body(size: 13, color: AppColors.muted),
          )
        else
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < wins.length && i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: _Win(
                      wins[i].title,
                      const [AppColors.mint, AppColors.sky, AppColors.pink][i],
                    ),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 12),
        SectionLabel(l.sectionUnlocks),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final p in progress)
              Expanded(
                child: _UnlockItem(
                  progress: p,
                  worn: equipped == p.accessory,
                  onTap: p.unlocked
                      ? () => wear(
                          equipped == p.accessory
                              ? PipAccessory.none
                              : p.accessory,
                        )
                      : null,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Momentum meter with the real split: violet is recent effort, pink is
/// decayed carry-over. An empty meter is just an empty track, never red.
class _TwoToneMeter extends StatelessWidget {
  const _TwoToneMeter({required this.recent, required this.carry});
  final double recent, carry;

  @override
  Widget build(BuildContext context) {
    final r = recent.clamp(0.0, 1.0);
    final c = carry.clamp(0.0, 1.0 - r);
    final pct = ((r + c) * 100).round();
    return Semantics(
      label: context.l10n.sectionMomentum,
      value: '$pct%',
      child: Container(
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: AppColors.ink, width: AppStroke.border),
          boxShadow: AppShadows.hard(3),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: LayoutBuilder(
            builder: (context, box) => Align(
              alignment: AlignmentDirectional.centerStart,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: box.maxWidth * r, color: AppColors.violet),
                  Container(width: box.maxWidth * c, color: AppColors.pink),
                ],
              ),
            ),
          ),
        ),
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

/// One accessory: locked (lock), in progress (ring), unlocked or worn.
class _UnlockItem extends StatelessWidget {
  const _UnlockItem({
    required this.progress,
    required this.worn,
    required this.onTap,
  });

  final UnlockProgress progress;
  final bool worn;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = progress.accessory;
    final name = accessoryName(l, a);
    final String caption;
    if (progress.unlocked) {
      caption = worn ? l.wearing : l.tapToWear;
    } else {
      caption = unlockHint(l, progress);
    }
    final Widget token;
    if (progress.unlocked) {
      token = Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: worn ? AppColors.sun : AppColors.card,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.ink, width: AppStroke.border),
          boxShadow: AppShadows.hard(3),
        ),
        foregroundDecoration: worn
            ? BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.violet, width: 3),
              )
            : null,
        child: Center(
          child: PipAvatar(size: 40, accessory: a, semanticLabel: name),
        ),
      );
    } else if (progress.untouched) {
      token = Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFECE8F8),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.muted, width: AppStroke.border),
        ),
        child: const Icon(Icons.lock_outline, color: AppColors.muted),
      );
    } else {
      token = SizedBox.square(
        dimension: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.square(
              dimension: 52,
              child: CircularProgressIndicator(
                value: progress.fraction,
                strokeWidth: 5,
                color: AppColors.violet,
                backgroundColor: const Color(0xFFE4DFF7),
                strokeCap: StrokeCap.round,
              ),
            ),
            Opacity(
              opacity: 0.5,
              child: PipAvatar(size: 32, accessory: a, semanticLabel: name),
            ),
          ],
        ),
      );
    }
    return Semantics(
      button: onTap != null,
      label: '$name, $caption',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Column(
            children: [
              token,
              const SizedBox(height: 5),
              Text(
                name,
                textAlign: TextAlign.center,
                style: AppText.bold(size: 11, height: 1.2),
              ),
              Text(
                caption,
                textAlign: TextAlign.center,
                style: AppText.body(
                  size: 11,
                  weight: worn ? FontWeight.w700 : FontWeight.w500,
                  color: worn ? AppColors.violet : AppColors.muted,
                  height: 1.2,
                ),
              ),
            ],
          ),
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

/// Short weekday name; [weekday] 1 = Monday ... 7 = Sunday.
String _dayShort(AppLocalizations l, int weekday) => [
  l.commonWeekdayShortMon,
  l.commonWeekdayShortTue,
  l.commonWeekdayShortWed,
  l.commonWeekdayShortThu,
  l.commonWeekdayShortFri,
  l.commonWeekdayShortSat,
  l.commonWeekdayShortSun,
][weekday - 1];
