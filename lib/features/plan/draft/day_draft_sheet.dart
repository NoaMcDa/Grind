import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/app_text.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/pill.dart';
import '../../../widgets/pip_avatar.dart';
import '../../../widgets/pip_toast.dart';
import '../../../widgets/sticker_bottom_sheet.dart';
import '../plan_reasons_l10n.dart';
import 'day_draft.dart';
import 'day_drafter.dart';

/// "Plan my day with Pip": drafts today, shows the review sheet and writes
/// the blocks the user kept when they accept.
Future<void> planMyDayWithPip(BuildContext context, WidgetRef ref) async {
  final drafter = ref.read(dayDrafterProvider);
  final proposal = await drafter.propose();
  if (!context.mounted) return;
  final accepted = await showDayDraftSheet(context, proposal);
  if (accepted == null) return;
  final n = await drafter.apply(proposal, accepted);
  if (context.mounted) showPipToast(context, context.l10n.planApplied(n));
}

/// The review sheet. Resolves to the edited draft on "Accept all", null
/// otherwise.
Future<DayDraft?> showDayDraftSheet(
  BuildContext context,
  DayDraftProposal proposal,
) => showStickerSheet<DayDraft>(
  context,
  (ctx) => DayDraftSheet(proposal: proposal),
);

/// "Your day, drafted": the day's blocks in order, between the calendar
/// events, each with its reason line. Every block can move earlier or
/// later (the day re-fits around it) or come out of the draft.
class DayDraftSheet extends StatefulWidget {
  const DayDraftSheet({super.key, required this.proposal});

  final DayDraftProposal proposal;

  @override
  State<DayDraftSheet> createState() => _DayDraftSheetState();
}

class _DayDraftSheetState extends State<DayDraftSheet> {
  late DayDraft _draft = widget.proposal.draft;

  void _move(String taskId, int delta) {
    final next = _draft.move(taskId, delta);
    if (next == null) {
      showPipToast(context, context.l10n.draftNoRoom);
      return;
    }
    setState(() => _draft = next);
  }

  void _remove(String taskId) => setState(() => _draft = _draft.remove(taskId));

  String _summary(AppLocalizations l) {
    if (_draft.items.isEmpty && _draft.unplaced.isEmpty) {
      return _draft.freeMinutes == 0 ? l.draftNoTime : l.draftNothing;
    }
    if (_draft.freeMinutes == 0) return l.draftNoTime;
    return l.draftSummary(
      _duration(l, _draft.freeMinutes),
      _duration(l, _draft.plannedMinutes),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = widget.proposal;
    final items = _draft.items;
    // Blocks and events in one timeline, by start (events first on ties).
    final rows = <({DateTime at, Widget child})>[
      for (final e in p.events)
        (at: e.start, child: _EventRow(key: Key('draft-event-${e.id}'), e)),
      for (var i = 0; i < items.length; i++)
        (
          at: items[i].start,
          child: _ItemRow(
            key: Key('draft-item-${items[i].taskId}'),
            title: p.titleOf(items[i].taskId),
            when: _span(items[i].start, items[i].end),
            reasons: [
              for (final r in items[i].reasons) localizePlanReason(l, r),
            ],
            onEarlier: i == 0 ? null : () => _move(items[i].taskId, -1),
            onLater: i == items.length - 1
                ? null
                : () => _move(items[i].taskId, 1),
            onRemove: () => _remove(items[i].taskId),
          ),
        ),
    ];
    final ordered = [for (var i = 0; i < rows.length; i++) (i: i, row: rows[i])]
      ..sort((a, b) {
        final c = a.row.at.compareTo(b.row.at);
        return c != 0 ? c : a.i.compareTo(b.i);
      });
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
                        l.draftTitle,
                        style: AppText.display(size: 22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _summary(l),
                  key: const Key('draft-summary'),
                  style: AppText.body(color: AppColors.muted, height: 1.35),
                ),
                if (_draft.kept.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    l.planReplanKept(_draft.kept.length),
                    style: AppText.body(size: 13, color: AppColors.muted),
                  ),
                ],
                if (items.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SectionLabel(l.draftOrderLabel),
                  const SizedBox(height: 8),
                  for (final o in ordered) o.row.child,
                ],
                if (_draft.unplaced.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SectionLabel(l.planReplanUnplacedLabel),
                  const SizedBox(height: 8),
                  for (final u in _draft.unplaced)
                    _ItemRow(
                      key: Key('draft-unplaced-${u.taskId}'),
                      title: p.titleOf(u.taskId),
                      reasons: [localizePlanReason(l, u.reason)],
                      color: AppColors.card,
                    ),
                ],
                if (_draft.laterCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    l.draftLater(_draft.laterCount),
                    style: AppText.body(size: 13, color: AppColors.muted),
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
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PillButton(
                key: const Key('draft-accept'),
                label: l.draftAcceptAll,
                color: AppColors.violet,
                textColor: Colors.white,
                onPressed: items.isEmpty
                    ? null
                    : () => Navigator.of(context).pop(_draft),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String _hm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:'
    '${t.minute.toString().padLeft(2, '0')}';

String _span(DateTime s, DateTime e) => '${_hm(s)}–${_hm(e)}';

/// "45 min", "3 h", "4.5 h" (to the nearest half hour).
String _duration(AppLocalizations l, int minutes) {
  if (minutes < 60) return l.commonMinutes(minutes);
  final h = (minutes / 30).round() / 2;
  return l.planHoursShort(h == h.roundToDouble() ? '${h.toInt()}' : '$h');
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    super.key,
    required this.title,
    required this.reasons,
    this.when,
    this.color = AppColors.lilac,
    this.onEarlier,
    this.onLater,
    this.onRemove,
  });

  final String title;
  final String? when;
  final List<String> reasons;
  final Color color;
  final VoidCallback? onEarlier;
  final VoidCallback? onLater;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final editable = onRemove != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: EdgeInsets.fromLTRB(12, 10, editable ? 4 : 12, 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadii.row),
          border: Border.all(color: AppColors.ink, width: AppStroke.border),
          boxShadow: AppShadows.hard(2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.bold(size: 15)),
                  if (when != null) ...[
                    const SizedBox(height: 2),
                    Text(when!, style: AppText.bold(size: 13)),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    reasons.join(' · '),
                    style: AppText.body(size: 13, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            if (editable) ...[
              _IconAction(
                icon: Icons.keyboard_arrow_up,
                label: l.draftMoveEarlier(title),
                onTap: onEarlier,
              ),
              _IconAction(
                icon: Icons.keyboard_arrow_down,
                label: l.draftMoveLater(title),
                onTap: onLater,
              ),
              _IconAction(
                icon: Icons.close,
                label: l.draftRemove(title),
                onTap: onRemove,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            size: 22,
            color: enabled ? AppColors.ink : AppColors.rule,
          ),
        ),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow(this.event, {super.key});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.row),
          border: Border.all(
            color: AppColors.rule,
            width: AppStroke.borderThin,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_outlined, size: 18, color: AppColors.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                event.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(size: 13, color: AppColors.muted),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _span(event.start, event.end),
              style: AppText.body(size: 13, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
