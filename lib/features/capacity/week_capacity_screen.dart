import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_text.dart';
import '../../theme/tokens.dart';
import '../../widgets/widgets.dart';
import 'capacity_format.dart';
import 'capacity_math.dart';
import 'capacity_providers.dart';
import 'priority_list.dart';
import 'week_bars.dart';

/// "Is this week realistic?" Routed as `/week`. Two tabs: the week (free vs
/// planned per day, a verdict and what could move) and the priorities (the
/// ranked list with pins, drag and the weights).
class WeekCapacityScreen extends ConsumerStatefulWidget {
  const WeekCapacityScreen({super.key, this.initialTab = 0});

  /// 0 = Week, 1 = Priorities.
  final int initialTab;

  @override
  ConsumerState<WeekCapacityScreen> createState() => _WeekCapacityScreenState();
}

class _WeekCapacityScreenState extends ConsumerState<WeekCapacityScreen> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.ground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              children: [
                if (Navigator.of(context).canPop())
                  IconButton(
                    tooltip: l.capacityBack,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const BackButtonIcon(),
                  ),
                Expanded(
                  child: Text(
                    l.capacityTitle,
                    style: AppText.display(size: 30),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l.capacitySubtitle,
              style: AppText.body(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: PillButton(
                    label: l.capacityTabWeek,
                    color: _tab == 0 ? AppColors.violet : AppColors.card,
                    textColor: _tab == 0 ? Colors.white : AppColors.ink,
                    onPressed: () => setState(() => _tab = 0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PillButton(
                    label: l.capacityTabPriorities,
                    color: _tab == 1 ? AppColors.violet : AppColors.card,
                    textColor: _tab == 1 ? Colors.white : AppColors.ink,
                    onPressed: () => setState(() => _tab = 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_tab == 0) const _WeekTab() else const _PrioritiesTab(),
          ],
        ),
      ),
    );
  }
}

class _PrioritiesTab extends StatelessWidget {
  const _PrioritiesTab();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.capacityPrioTitle, style: AppText.display(size: 22)),
        const SizedBox(height: 4),
        Text(l.capacityPrioIntro, style: AppText.body(color: AppColors.muted)),
        const SizedBox(height: 14),
        const PriorityList(),
        const SizedBox(height: 8),
        const WeightsSection(),
      ],
    );
  }
}

class _WeekTab extends ConsumerWidget {
  const _WeekTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final report = ref.watch(weekReportProvider);
    final verdict = report.verdict;
    final (verdictText, verdictColor) = switch (verdict) {
      LoadState.calm => (l.capacityVerdictFits, AppColors.mint),
      LoadState.tight => (l.capacityVerdictTight, AppColors.sun),
      LoadState.overbooked => (
        l.capacityVerdictOver(formatSpan(context, report.overMinutes)),
        AppColors.pink,
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StickerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.capacityTotals(
                        formatSpan(context, report.freeMinutes),
                        formatSpan(context, report.plannedMinutes),
                      ),
                      style: AppText.display(size: 22),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Pill(
                    label: stateLabel(context, verdict),
                    color: verdictColor,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(verdictText, style: AppText.body(color: AppColors.muted)),
              const SizedBox(height: 16),
              WeekBars(days: report.days),
            ],
          ),
        ),
        const SizedBox(height: 22),
        if (verdict == LoadState.overbooked && report.deferrals.isNotEmpty)
          _MoveList(report: report)
        else
          StickerCard(
            color: AppColors.lilac,
            shadow: 0,
            child: Text(
              l.capacityNothingToMove,
              style: AppText.body(color: AppColors.muted),
            ),
          ),
      ],
    );
  }
}

class _MoveList extends ConsumerWidget {
  const _MoveList({required this.report});

  final WeekReport report;

  Future<void> _move(
    BuildContext context,
    WidgetRef ref,
    List<String> ids,
  ) async {
    final l = context.l10n;
    final n = await ref.read(capacityActionsProvider).deferToNextWeek(ids);
    if (!context.mounted || n == 0) return;
    showPipToast(
      context,
      n == 1 ? l.capacityMovedOne : l.capacityMovedMany(n),
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(l.capacityMoveTitle),
        const SizedBox(height: 6),
        Text(
          l.capacityMoveIntro,
          style: AppText.body(size: 13, color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        for (final item in report.deferrals)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: StickerCard(
              shadow: 3,
              radius: AppRadii.row,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.task.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.bold(size: 16),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Pill(label: formatSpan(context, item.minutes)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.task.dueAt == null
                        ? l.capacityReasonNoDeadline
                        : l.capacityReasonDue(
                            dayLong(context, item.task.dueAt!),
                          ),
                    style: AppText.body(size: 13, color: AppColors.muted),
                  ),
                  if (item.slackDays != null)
                    Text(
                      l.capacitySlack(item.slackDays!),
                      style: AppText.body(size: 13, color: AppColors.muted),
                    ),
                  const SizedBox(height: 10),
                  PillButton(
                    label: l.capacityMoveOne,
                    onPressed: () => _move(context, ref, [item.task.id]),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 4),
        PillButton(
          label: l.capacityMoveAll,
          color: AppColors.violet,
          textColor: Colors.white,
          onPressed: () => _move(context, ref, [
            for (final d in report.deferrals) d.task.id,
          ]),
        ),
      ],
    );
  }
}
