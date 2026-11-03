import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_text.dart';
import '../../theme/tokens.dart';
import '../../widgets/pill.dart';
import '../../widgets/pip_avatar.dart';
import '../../widgets/pip_toast.dart';
import '../../widgets/sticker_bottom_sheet.dart';
import 'plan_l10n.dart';
import 'plan_scheduler.dart';
import 'plan_reasons_l10n.dart';

/// "Re-plan with Pip" for the week of [day]: runs the scheduler, shows the
/// review sheet and applies the draft when the user says so.
Future<void> replanWithPip(
  BuildContext context,
  WidgetRef ref,
  DateTime day,
) async {
  final scheduler = ref.read(planSchedulerProvider);
  final proposal = await scheduler.proposeWeek(day);
  if (!context.mounted) return;
  final apply = await showReplanSheet(context, proposal);
  if (apply != true) return;
  final n = await scheduler.apply(proposal);
  if (context.mounted) showPipToast(context, context.l10n.planApplied(n));
}

/// "Schedule it for me" on one task: places it and says why in a toast.
Future<SingleSchedule> scheduleTaskForMe(
  BuildContext context,
  WidgetRef ref,
  String taskId,
) async {
  final result = await ref.read(planSchedulerProvider).scheduleOne(taskId);
  if (context.mounted) {
    final l = context.l10n;
    final p = result.placement;
    final reason = localizePlanReason(l, result.reason);
    showPipToast(
      context,
      p == null
          ? l.planNotScheduled(reason)
          : l.planScheduledAt(formatPlanSlot(l, p.start, p.end), reason),
    );
  }
  return result;
}

/// The review sheet: each placement with its reasons, each task that did
/// not fit with why. Resolves to true for "Apply".
Future<bool?> showReplanSheet(BuildContext context, PlanProposal proposal) =>
    showStickerSheet<bool>(context, (ctx) => ReplanSheet(proposal: proposal));

class ReplanSheet extends StatelessWidget {
  const ReplanSheet({super.key, required this.proposal});

  final PlanProposal proposal;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final changes = proposal.changes;
    final unplaced = proposal.unplaced;
    final past = proposal.plan.capacity.days.isEmpty;
    final nothing = changes.isEmpty && unplaced.isEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const PipAvatar(size: 44),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.planReplanTitle,
                        style: AppText.display(size: 22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  past
                      ? l.planReplanPast
                      : nothing
                      ? l.planReplanNothing
                      : planCapacitySummary(
                          l,
                          proposal.plan.capacity,
                          deferrals: proposal.plan.deferralSuggestions.length,
                        ),
                  style: AppText.body(color: AppColors.muted, height: 1.35),
                ),
                if (proposal.keptCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    l.planReplanKept(proposal.keptCount),
                    style: AppText.body(size: 13, color: AppColors.muted),
                  ),
                ],
                if (changes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SectionLabel(l.planReplanPlacedLabel),
                  const SizedBox(height: 8),
                  for (final p in changes)
                    _Row(
                      key: Key('replan-placed-${p.taskId}'),
                      title: proposal.titleOf(p.taskId),
                      when: formatPlanSlot(l, p.start, p.end),
                      reasons: [
                        for (final r in p.reasons) localizePlanReason(l, r),
                      ],
                      color: AppColors.lilac,
                    ),
                ],
                if (unplaced.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SectionLabel(l.planReplanUnplacedLabel),
                  const SizedBox(height: 8),
                  for (final u in unplaced)
                    _Row(
                      key: Key('replan-unplaced-${u.taskId}'),
                      title: proposal.titleOf(u.taskId),
                      reasons: [localizePlanReason(l, u.reason)],
                      color: AppColors.card,
                    ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: PillButton(
                label: l.planNotNow,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PillButton(
                key: const Key('replan-apply'),
                label: l.planApply,
                color: AppColors.violet,
                textColor: Colors.white,
                onPressed: changes.isEmpty
                    ? null
                    : () => Navigator.of(context).pop(true),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.title,
    required this.reasons,
    required this.color,
    this.when,
  });

  final String title;
  final String? when;
  final List<String> reasons;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadii.row),
          border: Border.all(color: AppColors.ink, width: AppStroke.border),
          boxShadow: AppShadows.hard(2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(title, style: AppText.bold(size: 15))),
                if (when != null) ...[
                  const SizedBox(width: 8),
                  Text(when!, style: AppText.bold(size: 13)),
                ],
              ],
            ),
            const SizedBox(height: 3),
            Text(
              reasons.join(' · '),
              style: AppText.body(size: 13, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
