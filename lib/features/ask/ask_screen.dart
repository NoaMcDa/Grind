import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_text.dart';
import '../../theme/tokens.dart';
import '../../widgets/pill.dart';
import '../../widgets/pip_avatar.dart';
import '../../widgets/sticker_card.dart';
import '../plan/draft/day_draft_sheet.dart';

/// Assistant layer: natural-language capture and gentle re-planning.
///
/// [onPlanMyDay] overrides the default action behind the "Plan my day"
/// quick prompt (opening the deterministic day draft sheet). Tests pass
/// it so they can verify the chip is wired without pulling the real
/// drafter providers into the widget tree.
class AskScreen extends ConsumerStatefulWidget {
  const AskScreen({super.key, this.onPlanMyDay});

  final VoidCallback? onPlanMyDay;

  @override
  ConsumerState<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends ConsumerState<AskScreen> {
  bool _added = false;
  bool _planned = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Runs the "Plan my day" chip's end-to-end action: opens the
  /// deterministic day draft sheet (`planMyDayWithPip` in
  /// `day_draft_sheet.dart`). The other quick prompts still fall back to
  /// populating the composer until their intents are wired up; see epic
  /// #40 for the follow-up work.
  void _onQuickPrompt(_QuickPrompt q) {
    switch (q.kind) {
      case _QuickPromptKind.planMyDay:
        final override = widget.onPlanMyDay;
        if (override != null) {
          override();
        } else {
          // Fire-and-forget: the sheet is pumped on the next frame and the
          // chip's tap returns straight away.
          unawaited(planMyDayWithPip(context, ref));
        }
      case _QuickPromptKind.populateComposer:
        _controller.text = q.label;
    }
  }

  List<_QuickPrompt> _quickPrompts(AppLocalizations l) => [
    _QuickPrompt(
      label: l.quickPlanMyDay,
      kind: _QuickPromptKind.planMyDay,
      widgetKey: const Key('ask-quick-plan-my-day'),
    ),
    _QuickPrompt(
      label: l.quickMoveGym,
      kind: _QuickPromptKind.populateComposer,
      widgetKey: const Key('ask-quick-move-gym'),
    ),
    _QuickPrompt(
      label: l.quickWhatsNext,
      kind: _QuickPromptKind.populateComposer,
      widgetKey: const Key('ask-quick-whats-next'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, 18 + top, 20, 10),
          child: Row(
            children: [
              const PipAvatar(size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Ask Pip', style: AppText.display(height: 1)),
              ),
              const Flexible(
                child: Pill(
                  label: 'Cloud assistant',
                  color: AppColors.mint,
                  height: 28,
                  fontSize: 12,
                  border: AppStroke.border,
                  icon: Icon(Icons.auto_awesome_outlined),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
            children: [
              const _UserBubble('gym tomorrow 7am, 45 min'),
              const SizedBox(height: 12),
              _PipBubble(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Got it! Here's the task:", style: AppText.body()),
                    const SizedBox(height: 9),
                    StickerCard(
                      radius: AppRadii.cardSmall,
                      shadow: 0,
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Gym', style: AppText.display(size: 19)),
                          const SizedBox(height: 6),
                          _meta(
                            Icons.calendar_today_outlined,
                            'Fri, Oct 30 · 07:00',
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _meta(Icons.schedule_outlined, '45 min'),
                              const SizedBox(width: 8),
                              const Pill(
                                label: 'Light',
                                color: AppColors.sky,
                                height: 22,
                                icon: Icon(Icons.bolt),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _meta(
                            Icons.notifications_none,
                            "If it's 06:45, then pack your bag",
                          ),
                          const SizedBox(height: 10),
                          if (_added)
                            PillButton(
                              label: 'Added to Friday',
                              color: AppColors.mint,
                              shadow: 3,
                              fontSize: 15,
                              icon: const Icon(Icons.check),
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: PillButton(
                                    label: 'Add',
                                    color: AppColors.violet,
                                    textColor: Colors.white,
                                    shadow: 3,
                                    fontSize: 15,
                                    onPressed: () =>
                                        setState(() => _added = true),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: PillButton(
                                    label: 'Edit',
                                    shadow: 3,
                                    fontSize: 15,
                                    onPressed: () {},
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const _UserBubble("I'm behind on my thesis, help"),
              const SizedBox(height: 12),
              _PipBubble(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "No stress, let's make it smaller. How about 2 short focus blocks today instead of 1 long one?",
                      style: AppText.body(),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        PillButton(
                          label: 'Yes, plan it',
                          color: AppColors.sun,
                          shadow: 3,
                          horizontalPadding: 14,
                          onPressed: () => setState(() => _planned = true),
                        ),
                        PillButton(
                          label: 'Just one block',
                          shadow: 3,
                          horizontalPadding: 14,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_planned) ...[
                const SizedBox(height: 12),
                _PipBubble(
                  child: Text(
                    "Done: 09:00–09:25 and 15:00–15:25. I'll nudge you gently.",
                    style: AppText.body(),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
            children: [
              for (final q in _quickPrompts(context.l10n))
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: PillButton(
                    key: q.widgetKey,
                    label: q.label,
                    height: 36,
                    shadow: 0,
                    fontSize: 13,
                    horizontalPadding: 13,
                    onPressed: () => _onQuickPrompt(q),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  padding: const EdgeInsetsDirectional.only(start: 16, end: 4),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    border: Border.all(
                      color: AppColors.ink,
                      width: AppStroke.border,
                    ),
                    boxShadow: AppShadows.hard(3),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: AppText.body(),
                          decoration: InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: 'Type or speak a task…',
                            hintStyle: AppText.body(color: AppColors.muted),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Speak a task',
                        onPressed: () {},
                        icon: const Icon(Icons.mic_none, color: AppColors.ink),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: 'Send message',
                child: GestureDetector(
                  onTap: () => _controller.clear(),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.violet,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.ink,
                        width: AppStroke.border,
                      ),
                      boxShadow: AppShadows.hard(3),
                    ),
                    child: const Icon(Icons.arrow_upward, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.ink),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            maxLines: 2,
            style: AppText.body(
              size: 13,
              weight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
        ),
      ],
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    // User bubble sits on the writing-end side (right in LTR, left in RTL)
    // with the tail pointing to the same end, so Hebrew conversations mirror
    // the English layout instead of putting the tail on the wrong corner.
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.violet,
          borderRadius: const BorderRadiusDirectional.only(
            topStart: Radius.circular(20),
            topEnd: Radius.circular(20),
            bottomStart: Radius.circular(20),
            bottomEnd: Radius.circular(6),
          ),
          border: Border.all(color: AppColors.ink, width: AppStroke.border),
          boxShadow: AppShadows.hard(3),
        ),
        child: Text(
          text,
          style: AppText.body(weight: FontWeight.w500, color: Colors.white),
        ),
      ),
    );
  }
}

class _PipBubble extends StatelessWidget {
  const _PipBubble({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Pip bubble sits on the writing-start side and keeps its tail on the
    // same corner, so it flips with the text direction.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: 0.88,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: const BorderRadiusDirectional.only(
              topStart: Radius.circular(20),
              topEnd: Radius.circular(20),
              bottomEnd: Radius.circular(20),
              bottomStart: Radius.circular(6),
            ),
            border: Border.all(color: AppColors.ink, width: AppStroke.border),
            boxShadow: AppShadows.hard(3),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// How a quick-prompt chip's tap is handled. Only [planMyDay] runs an
/// action; the others still fall through to populating the composer
/// until their intents are wired up end-to-end.
enum _QuickPromptKind { planMyDay, populateComposer }

class _QuickPrompt {
  const _QuickPrompt({
    required this.label,
    required this.kind,
    required this.widgetKey,
  });

  final String label;
  final _QuickPromptKind kind;
  final Key widgetKey;
}
