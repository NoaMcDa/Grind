import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_text.dart';
import '../../theme/tokens.dart';
import '../../widgets/pill.dart';
import '../../widgets/pip_avatar.dart';
import '../../widgets/sticker_card.dart';
import '../plan/draft/day_draft_sheet.dart';
import '../tasks/day_bounds.dart';
import 'today_providers.dart';

/// The quiet morning invitation at the top of Today: "Plan my day with
/// Pip". Shown while [planMyDayCardProvider] says so; tapping drafts the
/// day and opens the review sheet. The close button hides it for today.
///
/// [onPlan] replaces the default action (`planMyDayWithPip`) in tests.
class PlanMyDayCard extends ConsumerWidget {
  const PlanMyDayCard({super.key, this.onPlan});

  final VoidCallback? onPlan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(planMyDayCardProvider)) return const SizedBox.shrink();
    final l = context.l10n;
    void plan() => (onPlan ?? () => planMyDayWithPip(context, ref))();
    void hide() => ref.read(planMyDayHiddenProvider.notifier).state = ref
        .read(todayBoundsProvider)
        .date;
    return Padding(
      key: const Key('today-plan-my-day'),
      padding: const EdgeInsets.only(bottom: 18),
      child: StickerCard(
        color: AppColors.lilac,
        padding: const EdgeInsets.fromLTRB(14, 12, 4, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: PipAvatar(size: 40),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.todayPlanDayTitle,
                          style: AppText.display(size: 18),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          l.todayPlanDayBody,
                          style: AppText.body(
                            size: 13,
                            color: AppColors.muted,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: l.todayPlanDayHide,
                  excludeSemantics: true,
                  onTap: hide,
                  child: GestureDetector(
                    key: const Key('today-plan-my-day-hide'),
                    onTap: hide,
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: PillButton(
                key: const Key('today-plan-my-day-go'),
                label: l.todayPlanDayAction,
                color: AppColors.violet,
                textColor: Colors.white,
                onPressed: plan,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
