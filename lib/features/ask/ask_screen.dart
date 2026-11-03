import 'package:flutter/material.dart';

import '../../theme/app_text.dart';
import '../../theme/tokens.dart';
import '../../widgets/pill.dart';
import '../../widgets/pip_avatar.dart';
import '../../widgets/sticker_card.dart';

/// Assistant layer: natural-language capture and gentle re-planning.
class AskScreen extends StatefulWidget {
  const AskScreen({super.key});

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> {
  bool _added = false;
  bool _planned = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
              for (final q in const [
                'Plan my day',
                'Move gym to evening',
                "What's next?",
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: PillButton(
                    label: q,
                    height: 36,
                    shadow: 0,
                    fontSize: 13,
                    horizontalPadding: 13,
                    onPressed: () => _controller.text = q,
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
                  padding: const EdgeInsets.only(left: 16, right: 4),
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
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.violet,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(6),
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
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: 0.88,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(6),
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
