import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/l10n.dart';
import '../../../theme/app_text.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/sticker_card.dart';
import '../domain/goal_area.dart';
import '../domain/goal_progress.dart';
import '../domain/goal_record.dart';
import '../goal_providers.dart';
import 'goal_l10n.dart';

/// A labelled text link to `/goals` for the Pip screen, placed next to the
/// Highlights card. Reads as a sticker link and never a card, so it does
/// not compete with Highlights for weight.
class PipAllGoalsLink extends StatelessWidget {
  const PipAllGoalsLink({super.key, this.onTap});

  /// Defaults to pushing `/goals`.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    void open() => onTap != null ? onTap!() : context.push('/goals');
    return Semantics(
      button: true,
      label: l.goalsAllGoalsLink,
      excludeSemantics: true,
      onTap: open,
      child: GestureDetector(
        key: const Key('pip-all-goals'),
        onTap: open,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(end: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l.goalsAllGoalsLink,
                  style: AppText.bold(size: 13, color: AppColors.violet),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.violet,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A labelled sticker link to `/goals` for the Today screen (integrator
/// places it). Shows the top active goal's progress line, or the empty-state
/// copy when there are no goals. Mirrors [HighlightsLinkCard].
///
/// Keyed `today-goals` so the entry point stays discoverable to tests.
class GoalsLinkCard extends ConsumerWidget {
  const GoalsLinkCard({super.key, this.onTap});

  /// Defaults to pushing `/goals`.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final goals = ref.watch(goalsProvider).valueOrNull ?? const <GoalRecord>[];
    final top = _pickTopActive(goals);
    final GoalProgress? progress = top == null
        ? null
        : ref.watch(goalProgressProvider(top.id));
    final subtitle = _subtitle(l, top, progress);

    void open() => onTap != null ? onTap!() : context.push('/goals');

    final area = top == null ? null : GoalArea.resolve(top.area);
    final dotColor = area?.color ?? AppColors.violet;

    return Semantics(
      button: true,
      label: '${l.goalsTitle}. $subtitle',
      excludeSemantics: true,
      onTap: open,
      child: GestureDetector(
        key: const Key('today-goals'),
        onTap: open,
        behavior: HitTestBehavior.opaque,
        child: StickerCard(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.ink,
                      width: AppStroke.borderThin,
                    ),
                  ),
                  child: Icon(
                    Icons.flag_outlined,
                    color: area?.onColor ?? Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.goalsTitle, style: AppText.display(size: 18)),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(
                          size: 13,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.ink),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Picks the active goal to feature on Today: active status, metric
  /// present, highest importance, then most recently updated. Falls back to
  /// any active goal, then any goal at all; null when the list is empty.
  static GoalRecord? _pickTopActive(List<GoalRecord> goals) {
    if (goals.isEmpty) return null;
    final active = goals
        .where((g) => g.status == GoalStatus.active)
        .toList();
    int rank(GoalRecord g) => g.metric == null ? 1 : 0;
    final pool = active.isEmpty ? goals.toList() : active;
    pool.sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      if (r != 0) return r;
      final i = b.importance.compareTo(a.importance);
      if (i != 0) return i;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return pool.first;
  }

  /// The second line of the card: the top goal's progress, or the goals
  /// empty-state body when there are no goals. Falls back to the screen
  /// subtitle for a goal without a metric so the title does not duplicate
  /// what other screens already show. Follows the tone guide: no "behind"
  /// / "missed" language.
  static String _subtitle(
    AppLocalizations l,
    GoalRecord? top,
    GoalProgress? progress,
  ) {
    if (top == null || progress == null) return l.goalsEmptyBody;
    if (progress.hasMetric) return l.goalProgressLine(progress);
    return l.goalsSubtitle;
  }
}
