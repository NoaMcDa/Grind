import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_text.dart';
import '../../theme/tokens.dart';
import '../../widgets/widgets.dart';
import 'capacity_format.dart';
import 'capacity_providers.dart';
import 'capacity_settings.dart';
import 'priority_math.dart';

/// Open tasks in Pip's order, each with its top reason, a pin control and a
/// drag handle. Dragging records a pairwise preference. Meant to sit inside
/// a scroll view (it does not scroll itself).
class PriorityList extends ConsumerWidget {
  const PriorityList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ranked = ref.watch(priorityRankProvider);
    final l = context.l10n;
    if (ranked.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            l.capacityPrioEmpty,
            textAlign: TextAlign.center,
            style: AppText.body(color: AppColors.muted),
          ),
        ),
      );
    }
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: ranked.length,
      proxyDecorator: (child, _, _) =>
          Material(color: Colors.transparent, child: child),
      onReorder: (from, to) {
        ref.read(capacityActionsProvider).reorder(ranked, from, to);
        showPipToast(
          context,
          l.capacityRemembered,
          duration: const Duration(seconds: 2),
        );
      },
      itemBuilder: (context, i) => Padding(
        key: ValueKey(ranked[i].task.id),
        padding: const EdgeInsets.only(bottom: 10),
        child: _PriorityRow(item: ranked[i], index: i),
      ),
    );
  }
}

class _PriorityRow extends ConsumerWidget {
  const _PriorityRow({required this.item, required this.index});

  final RankedTask item;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return StickerCard(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 2, 10),
      shadow: 3,
      radius: AppRadii.row,
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              l.capacityRank(item.rank),
              style: AppText.display(size: 16, color: AppColors.violet),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bold(size: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  reasonLabel(context, item.topReason),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(size: 13, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Semantics(
            button: true,
            label: l.capacityPinLabel(pinLabel(context, item.pin)),
            excludeSemantics: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              onTap: () => _pickPin(context, ref),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                child: Center(
                  child: Pill(
                    label: pinLabel(context, item.pin),
                    color: switch (item.pin) {
                      PriorityPin.top => AppColors.sun,
                      PriorityPin.high => AppColors.lilac,
                      PriorityPin.normal => AppColors.card,
                      PriorityPin.low => AppColors.card,
                    },
                  ),
                ),
              ),
            ),
          ),
          ReorderableDragStartListener(
            index: index,
            child: Semantics(
              label: l.capacityDragHandle,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.drag_handle_rounded, color: AppColors.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPin(BuildContext context, WidgetRef ref) async {
    final picked = await showStickerSheet<PriorityPin>(
      context,
      (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ctx.l10n.capacityPinTitle, style: AppText.display(size: 22)),
            const SizedBox(height: 4),
            Text(
              item.task.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final p in PriorityPin.values)
                  PillButton(
                    label: pinLabel(ctx, p),
                    color: p == item.pin ? AppColors.violet : AppColors.card,
                    textColor: p == item.pin ? Colors.white : AppColors.ink,
                    onPressed: () => Navigator.of(ctx).pop(p),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    if (picked != null && picked != item.pin) {
      await ref.read(capacityActionsProvider).setPin(item.task, picked);
    }
  }
}

/// Advanced: sliders for the scoring weights. Stored in `CapacityConfig`;
/// the plan scheduler reads them from `capacityConfigProvider`.
class WeightsSection extends ConsumerWidget {
  const WeightsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final w = ref.watch(capacityConfigProvider).weights;
    final notifier = ref.read(capacityConfigProvider.notifier);
    Widget slider(String label, double value, ValueChanged<double> onChanged) =>
        Row(
          children: [
            SizedBox(
              width: 112,
              // The slider announces the name itself (below).
              child: ExcludeSemantics(
                child: Text(label, style: AppText.body(size: 13)),
              ),
            ),
            Expanded(
              child: Slider(
                value: value.clamp(0.0, 1.0),
                divisions: 20,
                activeColor: AppColors.violet,
                inactiveColor: AppColors.rule,
                // The slider node has no label slot; the name rides on the
                // announced value ("Deadline 40%").
                semanticFormatterCallback: (v) =>
                    '$label ${(v * 100).round()}%',
                onChanged: onChanged,
              ),
            ),
            SizedBox(
              width: 34,
              child: ExcludeSemantics(
                child: Text(
                  value.toStringAsFixed(2),
                  textAlign: TextAlign.end,
                  style: AppText.body(size: 12, color: AppColors.muted),
                ),
              ),
            ),
          ],
        );
    return StickerCard(
      shadow: 3,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          title: Text(l.capacityWeightsTitle, style: AppText.bold(size: 16)),
          subtitle: Text(
            l.capacityWeightsHint,
            style: AppText.body(size: 13, color: AppColors.muted),
          ),
          children: [
            slider(
              l.capacityWeightUrgency,
              w.urgency,
              (v) => notifier.setWeights(SchedulerWeightsX.of(w, urgency: v)),
            ),
            slider(
              l.capacityWeightImportance,
              w.importance,
              (v) =>
                  notifier.setWeights(SchedulerWeightsX.of(w, importance: v)),
            ),
            slider(
              l.capacityWeightPriority,
              w.priority,
              (v) => notifier.setWeights(SchedulerWeightsX.of(w, priority: v)),
            ),
            slider(
              l.capacityWeightQuickWin,
              w.quickWin,
              (v) => notifier.setWeights(SchedulerWeightsX.of(w, quickWin: v)),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: PillButton(
                label: l.capacityWeightsReset,
                onPressed: notifier.resetWeights,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
