import 'package:flutter/material.dart';

import '../../theme/app_text.dart';
import '../../theme/tokens.dart';
import '../../widgets/pill.dart';
import '../../widgets/pip_avatar.dart';
import '../../widgets/sticker_card.dart';

const _hourHeight = 48.0;
const _startHour = 8;
const _endHour = 18;

enum _Kind { deep, light, mint, lunch }

class _Block {
  const _Block(
    this.id,
    this.title,
    this.time,
    this.start,
    this.end,
    this.kind, {
    this.focus = false,
  });
  final String id, title, time;
  final double start, end;
  final _Kind kind;
  final bool focus;
}

class _Event {
  const _Event(this.title, this.time, this.start, this.end);
  final String title, time;
  final double start, end;
}

const _events = [
  _Event('Lecture: Computer Vision', '10:00–11:30', 10, 11.5),
  _Event('Seminar with supervisor', '14:00–15:30', 14, 15.5),
];

const _blocks = [
  _Block(
    'thesis',
    'Thesis: write related-work section',
    '08:00–09:30',
    8,
    9.5,
    _Kind.deep,
    focus: true,
  ),
  _Block('lunch', 'Lunch break', '12:00', 12, 12.5, _Kind.lunch),
  _Block('lab', 'Deep learning lab 4', '12:30–13:15', 12.5, 13.25, _Kind.deep),
  _Block('read', 'Read 2 papers', '16:00–16:45', 16, 16.75, _Kind.light),
  _Block('gym', 'Gym', '17:15–18:00', 17.25, 18, _Kind.mint),
];

/// Productive layer: the day drafted by Pip around calendar events.
class PlanScreen extends StatefulWidget {
  const PlanScreen({
    super.key,
    required this.onStartFocus,
    required this.onAdd,
  });

  final VoidCallback onStartFocus;
  final VoidCallback onAdd;

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  final Set<String> _done = {'thesis', 'lunch'};

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(20, 18 + top, 20, 90),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Pill(
                    label: 'Thu, Oct 29',
                    height: 30,
                    fontSize: 13,
                    border: AppStroke.border,
                    icon: Icon(Icons.calendar_today_outlined),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Pill(
                    label: '${_done.length} of 5 done',
                    color: AppColors.mint,
                    height: 30,
                    fontSize: 13,
                    shadow: 2,
                    border: AppStroke.border,
                    icon: const Icon(Icons.check),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your day, drafted',
                        style: AppText.display(letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pip arranged 5 tasks around 2 classes. Drag to tweak.',
                        style: AppText.body(
                          size: 13,
                          color: AppColors.muted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const PipAvatar(size: 48),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: const [
                SectionLabel('Energy'),
                Pill(
                  label: 'Deep focus',
                  color: AppColors.violet,
                  textColor: Colors.white,
                  height: 24,
                  icon: Icon(Icons.bolt),
                ),
                Pill(
                  label: 'Light',
                  color: AppColors.sky,
                  height: 24,
                  icon: Icon(Icons.cloud_outlined),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: (_endHour - _startHour) * _hourHeight + 16,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var h = _startHour; h <= _endHour; h++) ...[
                    Positioned(
                      left: 0,
                      top: (h - _startHour) * _hourHeight - 7,
                      child: Text(
                        '${h.toString().padLeft(2, '0')}:00',
                        style: AppText.bold(
                          size: 11,
                          color: AppColors.muted,
                          height: 1.3,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 42,
                      right: 0,
                      top: (h - _startHour) * _hourHeight,
                      child: const Divider(
                        height: 1.5,
                        thickness: 1.5,
                        color: AppColors.rule,
                      ),
                    ),
                  ],
                  for (final e in _events) _eventCard(e),
                  for (final b in _blocks) _blockCard(b),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00F5F2FF), AppColors.ground],
                stops: [0, 0.4],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: PillButton(
                    label: 'Re-plan with Pip',
                    color: AppColors.violet,
                    textColor: Colors.white,
                    height: 52,
                    shadow: 4,
                    fontSize: 17,
                    display: true,
                    icon: const Icon(Icons.auto_awesome),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 10),
                PillButton(
                  label: 'Add task',
                  color: AppColors.sun,
                  height: 52,
                  shadow: 4,
                  fontSize: 15,
                  icon: const Icon(Icons.add),
                  onPressed: widget.onAdd,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _eventCard(_Event e) {
    return Positioned(
      left: 44,
      right: 4,
      top: (e.start - _startHour) * _hourHeight + 2,
      height: (e.end - e.start) * _hourHeight - 4,
      child: StickerCard(
        dashed: true,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.ground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.ink,
                  width: AppStroke.borderThin,
                ),
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FROM CALENDAR', style: AppText.label(size: 11)),
                  Text(
                    e.title,
                    style: AppText.bold(size: 14, height: 1.2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    e.time,
                    style: AppText.body(
                      size: 12,
                      color: AppColors.muted,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blockCard(_Block b) {
    final done = _done.contains(b.id);
    final top = (b.start - _startHour) * _hourHeight;
    final height = (b.end - b.start) * _hourHeight;
    final bg = switch (b.kind) {
      _Kind.deep => AppColors.violet,
      _Kind.light => AppColors.sky,
      _Kind.mint => AppColors.mint,
      _Kind.lunch => AppColors.pink,
    };
    final fg = b.kind == _Kind.deep ? Colors.white : AppColors.ink;
    final deco = done ? TextDecoration.lineThrough : null;

    void toggle() =>
        setState(() => done ? _done.remove(b.id) : _done.add(b.id));

    if (b.kind == _Kind.lunch) {
      return Positioned(
        left: 44,
        top: top - 11,
        child: GestureDetector(
          onTap: toggle,
          child: Container(
            height: 24,
            padding: const EdgeInsets.fromLTRB(6, 0, 10, 0),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(
                color: AppColors.ink,
                width: AppStroke.borderThin,
              ),
              boxShadow: AppShadows.hard(2),
            ),
            child: Row(
              children: [
                _circle(14, done, fg, AppColors.card),
                const SizedBox(width: 6),
                Text(
                  b.title,
                  style: AppText.bold(
                    size: 12,
                    height: 1,
                  ).copyWith(decoration: deco),
                ),
                const SizedBox(width: 6),
                Text(
                  b.time,
                  style: AppText.body(
                    size: 11,
                    weight: FontWeight.w500,
                    height: 1,
                  ).copyWith(decoration: deco),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final tall = height >= 60;
    return Positioned(
      left: 44,
      right: 4,
      top: top + 2,
      height: height - 4,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(
            tall ? AppRadii.card : AppRadii.cardSmall,
          ),
          border: Border.all(color: AppColors.ink, width: AppStroke.border),
          boxShadow: AppShadows.hard(tall ? 4 : 3),
        ),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                checked: done,
                label: '${b.title}, ${b.time}',
                child: GestureDetector(
                  onTap: toggle,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        _circle(
                          20,
                          done,
                          fg,
                          b.kind == _Kind.deep ? AppColors.sun : AppColors.card,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: tall
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      b.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          AppText.bold(
                                            size: 14,
                                            color: fg,
                                            height: 1.2,
                                          ).copyWith(
                                            decoration: deco,
                                            decorationColor: fg,
                                          ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      b.time,
                                      style:
                                          AppText.body(
                                            size: 12,
                                            weight: FontWeight.w500,
                                            color: fg,
                                            height: 1.2,
                                          ).copyWith(
                                            decoration: deco,
                                            decorationColor: fg,
                                          ),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        b.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            AppText.bold(
                                              size: 14,
                                              color: fg,
                                              height: 1.2,
                                            ).copyWith(
                                              decoration: deco,
                                              decorationColor: fg,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      b.time,
                                      style:
                                          AppText.body(
                                            size: 12,
                                            weight: FontWeight.w500,
                                            color: fg,
                                            height: 1.2,
                                          ).copyWith(
                                            decoration: deco,
                                            decorationColor: fg,
                                          ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (b.focus)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: PillButton(
                  label: 'Start focus',
                  color: AppColors.sun,
                  shadow: 3,
                  fontSize: 13,
                  horizontalPadding: 12,
                  icon: const Icon(Icons.play_arrow),
                  onPressed: widget.onStartFocus,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _circle(double size, bool done, Color fg, Color doneFill) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? doneFill : Colors.transparent,
        border: Border.all(color: done ? AppColors.ink : fg, width: 2),
      ),
      child: done
          ? Icon(Icons.check, size: size * 0.6, color: AppColors.ink)
          : null,
    );
  }
}
