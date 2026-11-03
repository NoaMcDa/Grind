import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/core.dart';
import '../../../theme/app_text.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/widgets.dart';
import '../domain/goal_area.dart';
import '../domain/goal_record.dart';
import '../goal_providers.dart';
import '../../../l10n/l10n.dart';
import 'goal_l10n.dart';
import 'goal_form.dart';
import 'goal_widgets.dart';

/// All goals by horizon: This week / month / quarter / year. Routed as
/// `/goals`. Tapping a card calls [onOpenGoal], by default pushing
/// `/goals/:id`.
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key, this.onOpenGoal});

  final void Function(BuildContext context, GoalRecord goal)? onOpenGoal;

  void _open(BuildContext context, GoalRecord goal) {
    final cb = onOpenGoal;
    if (cb != null) {
      cb(context, goal);
    } else {
      context.push('/goals/${goal.id}');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(goalsProvider).isLoading;
    final byHorizon = ref.watch(goalsByHorizonProvider);
    final empty = byHorizon.values.every((l) => l.isEmpty);

    final header = Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.goalsTitle, style: AppText.display(size: 30)),
                const SizedBox(height: 4),
                Text(
                  context.l10n.goalsSubtitle,
                  style: AppText.body(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          PillButton(
            label: context.l10n.goalsNewGoal,
            icon: const Icon(Icons.add),
            color: AppColors.violet,
            textColor: Colors.white,
            onPressed: () => showGoalSheet(context),
          ),
        ],
      ),
    );

    Widget body;
    if (loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (empty) {
      body = EmptyState(
        title: context.l10n.goalsEmptyTitle,
        body: context.l10n.goalsEmptyBody,
        actionLabel: context.l10n.goalsEmptyAction,
        onAction: () => showGoalSheet(context),
      );
    } else {
      body = ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 32),
        children: [
          for (final h in GoalHorizon.values)
            if (byHorizon[h]!.isNotEmpty) ...[
              SectionLabel(context.l10n.goalHorizon(h)),
              const SizedBox(height: 10),
              for (final g in byHorizon[h]!) ...[
                GoalCard(goal: g, onTap: () => _open(context, g)),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
            ],
        ],
      );
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
                header,
                Expanded(child: body),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A goal on the list: area chip, status pill, title, progress bar and
/// "8 of 12 lessons · 67%".
class GoalCard extends ConsumerWidget {
  const GoalCard({super.key, required this.goal, this.onTap});

  final GoalRecord goal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(goalProgressProvider(goal.id));
    final area = GoalArea.resolve(goal.area);
    final color = area?.color ?? AppColors.violet;
    final done = progress.isCompleted;
    final line = progress.hasMetric
        ? context.l10n.goalProgressLine(progress)
        : context.l10n.goalsNoMetric;

    return Semantics(
      button: onTap != null,
      label: '${goal.title}. $line',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: StickerCard(
          color: done ? AppColors.lilac : AppColors.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (area != null) Flexible(child: GoalAreaChip(area: area)),
                  const Spacer(),
                  GoalStatusPill(goal: goal, progress: progress),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                goal.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.display(size: 19, height: 1.15),
              ),
              const SizedBox(height: 12),
              if (progress.hasMetric) ...[
                GoalProgressBar(fraction: progress.fraction, color: color),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      line,
                      style: progress.hasMetric
                          ? AppText.bold(size: 14)
                          : AppText.body(size: 14, color: AppColors.muted),
                    ),
                  ),
                  if (goal.targetDate != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.goalByDate(goal.targetDate!),
                      style: AppText.body(size: 13, color: AppColors.muted),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
