import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../l10n/l10n.dart';
import '../../../theme/app_text.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/widgets.dart';
import '../domain/highlights.dart';
import '../domain/weekly_recap.dart';
import '../goal_providers.dart';
import 'goal_l10n.dart';
import 'goals_screen.dart';

/// Shares [text] through the system share sheet.
Future<void> shareRecapText(String text) =>
    SharePlus.instance.share(ShareParams(text: text));

/// Every goal by state, under the weekly recap (#28). Routed as
/// `/highlights`; linked from the Goals header and the Pip screen
/// ([HighlightsLinkCard]).
class HighlightsScreen extends ConsumerWidget {
  const HighlightsScreen({super.key, this.onShare = shareRecapText});

  /// Hands the plain-text recap to the share sheet (tests replace it).
  final Future<void> Function(String text) onShare;

  void _leave(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/goals');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final loading = ref.watch(goalsProvider).isLoading;
    final groups = ref.watch(highlightsProvider);
    final recap = ref.watch(weeklyRecapProvider);
    final empty = groups.values.every((g) => g.isEmpty);

    final children = <Widget>[
      Text(l.highlightsTitle, style: AppText.display(size: 30)),
      const SizedBox(height: 4),
      Text(l.highlightsSubtitle, style: AppText.body(color: AppColors.muted)),
      const SizedBox(height: 16),
      RecapCard(recap: recap, onShare: onShare),
      const SizedBox(height: 20),
    ];
    if (loading) {
      children.add(const Center(child: CircularProgressIndicator()));
    } else if (empty) {
      children.add(
        EmptyState(
          title: l.highlightsEmptyTitle,
          body: l.highlightsEmptyBody,
          pipSize: 72,
        ),
      );
    } else {
      for (final group in HighlightGroup.values) {
        final items = groups[group]!;
        if (items.isEmpty) continue;
        children
          ..add(SectionLabel('${l.highlightGroup(group)} · ${items.length}'))
          ..add(const SizedBox(height: 10));
        for (final h in items) {
          children
            ..add(
              GoalCard(
                goal: h.goal,
                footer: group == HighlightGroup.stalled
                    ? l.highlightsStalledNote(h.quietDays)
                    : null,
                onTap: () => context.push('/goals/${h.goal.id}'),
              ),
            )
            ..add(const SizedBox(height: 12));
        }
        children.add(const SizedBox(height: 8));
      }
    }

    return Scaffold(
      backgroundColor: AppColors.ground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8),
                    child: Semantics(
                      button: true,
                      label: l.commonBack,
                      excludeSemantics: true,
                      onTap: () => _leave(context),
                      child: GestureDetector(
                        onTap: () => _leave(context),
                        behavior: HitTestBehavior.opaque,
                        child: const SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            size: 20,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      20,
                      0,
                      20,
                      32,
                    ),
                    children: children,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The weekly recap in Pip's voice: headline (the biggest win), four
/// counts, the logged wins, what moved on, and Share.
class RecapCard extends StatelessWidget {
  const RecapCard({super.key, required this.recap, required this.onShare});

  final WeeklyRecap recap;
  final Future<void> Function(String text) onShare;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return StickerCard(
      color: AppColors.sun,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PipAvatar(
                size: 64,
                cheering: !recap.isEmpty,
                semanticLabel: l.pipSemanticLabel,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.recapTitle(recap),
                      style: AppText.display(size: 20, height: 1.1),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.recapRangeOf(recap),
                      style: AppText.bold(size: 13, color: AppColors.muted),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.recapHeadline(recap),
                      style: AppText.body(size: 16, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _Stat(recap.doneCount, l.recapStatDone)),
              const SizedBox(width: 8),
              Expanded(child: _Stat(recap.movedGoals.length, l.recapStatMoved)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _Stat(recap.metricHits.length, l.recapStatHit)),
              const SizedBox(width: 8),
              Expanded(child: _Stat(recap.rolledOver, l.recapStatRolled)),
            ],
          ),
          if (recap.wins.isNotEmpty) ...[
            const SizedBox(height: 14),
            SectionLabel(l.recapWins, color: AppColors.ink),
            const SizedBox(height: 6),
            for (final w in recap.wins.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsetsDirectional.only(top: 2, end: 6),
                      child: Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: AppColors.ink,
                      ),
                    ),
                    Expanded(child: Text(w, style: AppText.bold(size: 14))),
                  ],
                ),
              ),
          ],
          if (recap.rolledOver > 0) ...[
            const SizedBox(height: 10),
            Text(
              l.recapRolledOverLine(recap.rolledOver),
              style: AppText.body(size: 13, color: AppColors.ink),
            ),
          ],
          const SizedBox(height: 14),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: PillButton(
              label: l.recapShare,
              icon: const Icon(Icons.ios_share),
              onPressed: () => onShare(l.recapShareText(recap)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$value $label',
    excludeSemantics: true,
    child: Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.cardSmall),
        border: Border.all(color: AppColors.ink, width: AppStroke.borderThin),
      ),
      child: Row(
        children: [
          Text('$value', style: AppText.display(size: 22)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              style: AppText.bold(size: 12, color: AppColors.muted),
            ),
          ),
        ],
      ),
    ),
  );
}

/// A sticker link to `/highlights` for the Pip screen (integrator places
/// it): the recap headline under the title.
class HighlightsLinkCard extends ConsumerWidget {
  const HighlightsLinkCard({super.key, this.onTap});

  /// Defaults to pushing `/highlights`.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final recap = ref.watch(weeklyRecapProvider);
    void open() => onTap != null ? onTap!() : context.push('/highlights');
    return Semantics(
      button: true,
      label: '${l.highlightsTitle}. ${l.recapHeadline(recap)}',
      excludeSemantics: true,
      onTap: open,
      child: GestureDetector(
        onTap: open,
        behavior: HitTestBehavior.opaque,
        child: StickerCard(
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.sun,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppStroke.borderThin,
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.highlightsTitle, style: AppText.display(size: 18)),
                    const SizedBox(height: 2),
                    Text(
                      l.recapHeadline(recap),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(size: 13, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.ink),
            ],
          ),
        ),
      ),
    );
  }
}
