import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_text.dart';
import '../../theme/tokens.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/sticker_card.dart';
import 'analytics_providers.dart';
import 'stats.dart';

/// One-letter weekday for the bar labels (weekday 1 = Monday).
String _dayInitial(AppLocalizations l, int weekday) => switch (weekday) {
  DateTime.monday => l.commonWeekdayLetterMon,
  DateTime.tuesday => l.commonWeekdayLetterTue,
  DateTime.wednesday => l.commonWeekdayLetterWed,
  DateTime.thursday => l.commonWeekdayLetterThu,
  DateTime.friday => l.commonWeekdayLetterFri,
  DateTime.saturday => l.commonWeekdayLetterSat,
  _ => l.commonWeekdayLetterSun,
};

/// "2 h 5 min of focus in two weeks"; a quiet stretch reads as patience.
String _focusTotal(AppLocalizations l, int minutes) {
  if (minutes == 0) return l.analyticsFocusTotalNone;
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return l.analyticsFocusTotalMinutes(m);
  if (m == 0) return l.analyticsFocusTotalHours(h);
  return l.analyticsFocusTotalHoursMinutes(h, m);
}

/// "study tasks usually run 1.4x longer".
String _accuracyLine(AppLocalizations l, String category, double ratio) {
  final r = ratio.toStringAsFixed(1);
  if (ratio >= 1.1) return l.analyticsAccuracyLonger(category, r);
  if (ratio <= 0.9) return l.analyticsAccuracyShorter(category, r);
  return l.analyticsAccuracyOnTarget(category);
}

/// "Your numbers": the detailed view behind the Pip screen's week bars.
/// Route `/analytics`.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final focus = ref.watch(focusWeekProvider).value ?? const <DayMinutes>[];
    final weeks = ref.watch(completionTrendProvider);
    final accuracy = ref.watch(estimateAccuracyProvider);

    final hasData =
        focus.any((d) => !d.isRest) ||
        weeks.any((w) => w.completed > 0) ||
        accuracy.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.ground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(
              children: [
                Semantics(
                  button: true,
                  label: l.commonBack,
                  child: InkResponse(
                    onTap: () => Navigator.maybePop(context),
                    radius: 24,
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    l.analyticsTitle,
                    style: AppText.display(height: 1.2),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 48, bottom: 14),
              child: Text(
                l.analyticsSubtitle,
                style: AppText.body(color: AppColors.muted),
              ),
            ),
            if (!hasData)
              EmptyState(
                title: l.analyticsEmptyTitle,
                body: l.analyticsEmptyBody,
              )
            else ...[
              _FocusCard(days: focus),
              const SizedBox(height: 18),
              _CompletionCard(weeks: weeks),
              const SizedBox(height: 18),
              _AccuracyCard(items: accuracy),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader(this.title, this.sub);
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.display(size: 20, height: 1.2)),
          Text(sub, style: AppText.body(size: 13, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({required this.days});
  final List<DayMinutes> days;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final total = days.fold<int>(0, (s, d) => s + d.minutes);
    final rest = days.where((d) => d.isRest).length;
    final peak = days.fold<int>(0, (m, d) => d.minutes > m ? d.minutes : m);
    return Semantics(
      container: true,
      label: l.analyticsSemanticsFocus(total, rest),
      child: ExcludeSemantics(
        child: StickerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardHeader(l.analyticsFocusTitle, l.analyticsFocusSub),
              SizedBox(
                height: 120,
                width: double.infinity,
                child: CustomPaint(
                  painter: BarsPainter(
                    values: [
                      for (final d in days)
                        d.isRest ? null : d.minutes.toDouble(),
                    ],
                    max: peak.toDouble(),
                    color: AppColors.violet,
                    textDirection: Directionality.of(context),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (final d in days)
                    Expanded(
                      child: Text(
                        _dayInitial(l, d.day.weekday),
                        textAlign: TextAlign.center,
                        style: AppText.label(size: 11),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(_focusTotal(l, total), style: AppText.bold(size: 14)),
              if (rest > 0)
                Text(
                  l.analyticsRestLegend,
                  style: AppText.body(size: 13, color: AppColors.muted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.weeks});
  final List<WeekRate> weeks;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final done = weeks.fold<int>(0, (s, w) => s + w.completed);
    final planned = weeks.fold<int>(0, (s, w) => s + w.planned);
    return Semantics(
      container: true,
      label: l.analyticsSemanticsCompletion(done, planned),
      child: ExcludeSemantics(
        child: StickerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardHeader(l.analyticsCompletionTitle, l.analyticsCompletionSub),
              SizedBox(
                height: 110,
                width: double.infinity,
                child: CustomPaint(
                  painter: BarsPainter(
                    values: [for (final w in weeks) w.rate],
                    max: 1,
                    color: AppColors.mint,
                    textDirection: Directionality.of(context),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (final w in weeks)
                    Expanded(
                      child: Text(
                        w.rate == null ? '–' : '${(w.rate! * 100).round()}%',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: AppText.bold(size: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                l.analyticsCompletionNote,
                style: AppText.body(size: 13, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccuracyCard extends StatelessWidget {
  const _AccuracyCard({required this.items});
  final List<CategoryAccuracy> items;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final trusted = items.where((c) => c.trusted).toList();
    return StickerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(l.analyticsAccuracyTitle, l.analyticsAccuracySub),
          if (trusted.isEmpty)
            Text(l.analyticsAccuracyWaiting, style: AppText.bold())
          else ...[
            for (final c in trusted)
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _accuracyLine(l, c.category, c.ratio),
                        style: AppText.bold(size: 15),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l.analyticsSamples(c.n),
                      style: AppText.body(size: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            Text(
              l.analyticsAccuracyHow,
              style: AppText.body(size: 13, color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}

/// Rounded, ink-bordered bars in the sticker style. A null value is a rest
/// slot: a short pale bar, never red and never a zero.
class BarsPainter extends CustomPainter {
  BarsPainter({
    required this.values,
    required this.max,
    required this.color,
    required this.textDirection,
  });

  final List<double?> values;
  final double max;
  final Color color;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final slot = size.width / values.length;
    final barW = slot * 0.62;
    const restH = 8.0;
    const minH = 14.0;
    final fill = Paint()..style = PaintingStyle.fill;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.ink
      ..strokeWidth = AppStroke.borderThin;
    for (var i = 0; i < values.length; i++) {
      final idx = textDirection == TextDirection.rtl
          ? values.length - 1 - i
          : i;
      final v = values[i];
      final h = v == null || max <= 0
          ? restH
          : minH + (size.height - minH - 2) * (v / max).clamp(0.0, 1.0);
      final x = idx * slot + (slot - barW) / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - h - 1, barW, h),
        Radius.circular(barW.clamp(0, 12) / 2.5),
      );
      fill.color = v == null ? AppColors.lilac : color;
      canvas.drawRRect(rect, fill);
      canvas.drawRRect(rect, line);
    }
  }

  @override
  bool shouldRepaint(BarsPainter old) =>
      old.values != values ||
      old.max != max ||
      old.color != color ||
      old.textDirection != textDirection;
}
