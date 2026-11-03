import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/core.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_text.dart';
import '../../theme/tokens.dart';
import '../../widgets/pill.dart';
import '../../widgets/sticker_card.dart';
import '../today/today_providers.dart' show formatClock;
import 'plan_layout.dart';

const planHourHeight = 48.0;
const _gutter = 44.0;

enum _Kind { deep, light, mint, lunch }

class _Item {
  const _Item.task(Task t, this.start, this.end) : task = t, event = null;
  const _Item.event(CalendarEvent e, this.start, this.end)
    : event = e,
      task = null;

  final Task? task;
  final CalendarEvent? event;
  final int start, end;

  bool get isEvent => event != null;
  String get title => isEvent ? event!.title : task!.title;
}

_Kind _kindOf(Task t) => switch (t.category) {
  'break' => _Kind.lunch,
  'light' => _Kind.light,
  'move' => _Kind.mint,
  _ => _Kind.deep,
};

/// One day's events and tasks on an hour grid. Long-press a task to drag it.
class PlanTimeline extends StatefulWidget {
  const PlanTimeline({
    super.key,
    required this.day,
    required this.tasks,
    required this.events,
    required this.prefs,
    required this.now,
    required this.nowKey,
    required this.onToggle,
    required this.onOpenTask,
    required this.onOpenEvent,
    required this.onStartFocus,
    required this.onMove,
    this.onRejectedDrop,
    this.onSwipe,
    this.location,
  });

  final DateTime day;

  /// The user's zone: instants are drawn on its wall clock (the device zone
  /// when null).
  final tz.Location? location;
  final List<Task> tasks;
  final List<CalendarEvent> events;
  final Preferences prefs;

  /// Null when [day] is not today (no now-line).
  final DateTime? now;
  final GlobalKey nowKey;
  final void Function(Task) onToggle;
  final void Function(Task) onOpenTask;
  final void Function(CalendarEvent) onOpenEvent;
  final VoidCallback onStartFocus;

  /// Called with the dropped task and its new local start.
  final void Function(Task, DateTime) onMove;
  final VoidCallback? onRejectedDrop;

  /// +1 / -1 when the timeline is swiped to the next / previous day.
  final void Function(int)? onSwipe;

  @override
  State<PlanTimeline> createState() => _PlanTimelineState();
}

class _PlanTimelineState extends State<PlanTimeline> {
  String? _dragId;
  double _dragDy = 0;

  DateTime get _dayStart => dateOnly(widget.day);

  List<_Item> get _timed => [
    for (final e in widget.events)
      if (!e.isAllDay)
        _Item.event(
          e,
          minutesIntoDay(e.start, _dayStart, widget.location),
          minutesIntoDay(e.end, _dayStart, widget.location),
        ),
  ];

  _Item _taskItem(Task t) => _Item.task(
    t,
    minutesIntoDay(t.scheduledStart!, _dayStart, widget.location),
    minutesIntoDay(t.scheduledEnd!, _dayStart, widget.location),
  );

  // ---- drag ------------------------------------------------------------

  ({int start, bool valid}) _dragTarget(_Item item, int minMin, int maxMin) {
    final dur = item.end - item.start;
    var s = snapMinutes(item.start + _dragDy / planHourHeight * 60);
    s = s.clamp(minMin, (maxMin - dur).clamp(minMin, maxMin));
    final e = s + dur;
    final clash = _timed.any(
      (o) => o.event!.isBusy && s < o.end && e > o.start,
    );
    return (start: s, valid: !clash);
  }

  void _endDrag(_Item item, int minMin, int maxMin) {
    final target = _dragTarget(item, minMin, maxMin);
    setState(() {
      _dragId = null;
      _dragDy = 0;
    });
    if (!target.valid) {
      widget.onRejectedDrop?.call();
      return;
    }
    if (target.start == item.start) return;
    final d = _dayStart;
    widget.onMove(
      item.task!,
      DateTime(d.year, d.month, d.day, 0, target.start),
    );
  }

  // ---- build -----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final allDay = widget.events.where((e) => e.isAllDay).toList();
    final taskItems = [for (final t in widget.tasks) _taskItem(t)];
    final range = planHourRange(widget.prefs, [
      for (final i in [..._timed, ...taskItems]) (i.start, i.end),
    ]);
    final minMin = range.start * 60;
    final maxMin = range.end * 60;
    final hours = range.end - range.start;
    double y(num minutes) => (minutes - minMin) / 60 * planHourHeight;

    final packed = packColumns<_Item>(
      [..._timed, ...taskItems.where((i) => _kindOf(i.task!) != _Kind.lunch)],
      (i) => i.start,
      (i) => i.end,
    );
    final lunches = taskItems.where((i) => _kindOf(i.task!) == _Kind.lunch);
    final dragging = _dragId == null
        ? null
        : taskItems.where((i) => i.task!.id == _dragId).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (allDay.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final e in allDay) _allDayChip(e)],
          ),
          const SizedBox(height: 12),
        ],
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: _dragId != null ? null : _onSwipe,
          child: SizedBox(
            height: hours * planHourHeight + 16,
            child: LayoutBuilder(
              builder: (context, c) {
                final textDir = Directionality.of(context);
                final w = c.maxWidth - _gutter - 4;
                Widget at(
                  Placed<_Item> p,
                  Widget child, {
                  double? topOverride,
                }) {
                  final cols = p.columns;
                  final colW = w / cols;
                  final h = ((p.item.end - p.item.start) / 60 * planHourHeight)
                      .clamp(32.0, double.infinity);
                  return Positioned.directional(
                    textDirection: textDir,
                    start: _gutter + p.column * colW,
                    width: colW - (cols > 1 ? 4 : 0),
                    top: topOverride ?? y(p.item.start) + 2,
                    height: h - 4,
                    child: child,
                  );
                }

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var h = range.start; h <= range.end; h++) ...[
                      Positioned.directional(
                        textDirection: textDir,
                        start: 0,
                        top: (h - range.start) * planHourHeight - 7,
                        child: Text(
                          '${(h % 24).toString().padLeft(2, '0')}:00',
                          style: AppText.bold(
                            size: 11,
                            color: AppColors.muted,
                            height: 1.3,
                          ),
                        ),
                      ),
                      Positioned.directional(
                        textDirection: textDir,
                        start: 42,
                        end: 0,
                        top: (h - range.start) * planHourHeight,
                        child: const Divider(
                          height: 1.5,
                          thickness: 1.5,
                          color: AppColors.rule,
                        ),
                      ),
                    ],
                    for (final p in packed.where((p) => p.item.isEvent))
                      at(p, _eventCard(p)),
                    for (final p in packed.where((p) => !p.item.isEvent))
                      at(
                        p,
                        _taskCard(
                          p.item,
                          p.columns,
                          dimmed: p.item.task!.id == _dragId,
                          minMin: minMin,
                          maxMin: maxMin,
                        ),
                      ),
                    for (final l in lunches)
                      Positioned.directional(
                        textDirection: textDir,
                        start: _gutter,
                        top: y(l.start) - 11,
                        child: _lunchPill(l),
                      ),
                    if (dragging != null &&
                        _kindOf(dragging.task!) != _Kind.lunch)
                      _ghost(
                        textDir,
                        dragging,
                        w,
                        _dragTarget(dragging, minMin, maxMin),
                        y,
                      ),
                    if (widget.now != null) _nowLine(textDir, y),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _onSwipe(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (v.abs() < 300) return;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // Swiping towards the start edge moves forward in time.
    final forward = rtl ? v > 0 : v < 0;
    widget.onSwipe?.call(forward ? 1 : -1);
  }

  Widget _nowLine(TextDirection textDir, double Function(num) y) {
    final now = widget.now!;
    final m = widget.location == null
        ? now.difference(_dayStart).inMinutes
        : minutesIntoDay(now, _dayStart, widget.location);
    final top = y(m);
    if (top < 0 || top > (y(24 * 60))) return const SizedBox.shrink();
    return Positioned.directional(
      textDirection: textDir,
      start: _gutter - 6,
      end: 0,
      top: top - 4,
      height: 8,
      child: IgnorePointer(
        child: Semantics(
          label: context.l10n.planNowLabel,
          child: Row(
            key: widget.nowKey,
            children: [
              Container(
                key: const Key('plan-now-dot'),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.ink,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Container(
                  key: const Key('plan-now-line'),
                  height: 2,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- cards -----------------------------------------------------------

  Widget _allDayChip(CalendarEvent e) {
    return GestureDetector(
      key: Key('plan-event-${e.id}'),
      onTap: () => widget.onOpenEvent(e),
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: StickerCard(
          dashed: true,
          radius: AppRadii.cardSmall,
          shadow: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppColors.ink,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  e.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bold(size: 14, height: 1.2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.planAllDay,
                style: AppText.body(size: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eventCard(Placed<_Item> p) {
    final e = p.item.event!;
    final h = ((p.item.end - p.item.start) / 60 * planHourHeight).clamp(
      32.0,
      double.infinity,
    );
    final time =
        '${formatClock(e.start, widget.location)}–'
        '${formatClock(e.end, widget.location)}';
    final compact = h < 52 || p.columns > 1;
    final roomy = h >= 66 && p.columns == 1;
    return GestureDetector(
      key: Key('plan-event-${e.id}'),
      onTap: () => widget.onOpenEvent(e),
      behavior: HitTestBehavior.opaque,
      child: StickerCard(
        dashed: true,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 2 : 6,
        ),
        child: Row(
          children: [
            if (roomy) ...[
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
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (roomy)
                    Text(
                      context.l10n.fromCalendar.toUpperCase(),
                      style: AppText.label(size: 11),
                    ),
                  Text(
                    e.title,
                    style: AppText.bold(size: 14, height: 1.2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!compact)
                    Text(
                      time,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _lunchPill(_Item i) {
    final t = i.task!;
    final deco = t.isDone ? TextDecoration.lineThrough : null;
    return GestureDetector(
      key: Key('plan-task-${t.id}'),
      onTap: () => widget.onOpenTask(t),
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Center(
          widthFactor: 1,
          child: Container(
            height: 24,
            padding: const EdgeInsetsDirectional.fromSTEB(6, 0, 10, 0),
            decoration: BoxDecoration(
              color: AppColors.pink,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(
                color: AppColors.ink,
                width: AppStroke.borderThin,
              ),
              boxShadow: AppShadows.hard(2),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => widget.onToggle(t),
                  child: _circle(14, t.isDone, AppColors.ink, AppColors.card),
                ),
                const SizedBox(width: 6),
                Text(
                  t.title,
                  style: AppText.bold(
                    size: 12,
                    height: 1,
                  ).copyWith(decoration: deco),
                ),
                const SizedBox(width: 6),
                Text(
                  formatClock(t.scheduledStart!, widget.location),
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
      ),
    );
  }

  Widget _taskCard(
    _Item i,
    int columns, {
    bool dimmed = false,
    bool ghost = false,
    bool valid = true,
    String? timeOverride,
    int minMin = 0,
    int maxMin = 24 * 60,
  }) {
    final t = i.task!;
    final kind = _kindOf(t);
    final done = t.isDone;
    final h = ((i.end - i.start) / 60 * planHourHeight).clamp(
      32.0,
      double.infinity,
    );
    final tall = h >= 64 && columns == 1;
    final bg = switch (kind) {
      _Kind.deep => AppColors.violet,
      _Kind.light => AppColors.sky,
      _Kind.mint => AppColors.mint,
      _Kind.lunch => AppColors.pink,
    };
    final fg = kind == _Kind.deep ? Colors.white : AppColors.ink;
    final deco = done ? TextDecoration.lineThrough : null;
    final time =
        timeOverride ??
        '${formatClock(t.scheduledStart!, widget.location)}–'
            '${formatClock(t.scheduledEnd!, widget.location)}';
    TextStyle bold() => AppText.bold(
      size: 14,
      color: fg,
      height: 1.2,
    ).copyWith(decoration: deco, decorationColor: fg);
    TextStyle small() => AppText.body(
      size: 12,
      weight: FontWeight.w500,
      color: fg,
      height: 1.2,
    ).copyWith(decoration: deco, decorationColor: fg);

    final card = Opacity(
      opacity: dimmed ? 0.35 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(
            tall ? AppRadii.card : AppRadii.cardSmall,
          ),
          border: Border.all(
            color: ghost && !valid ? AppColors.error : AppColors.ink,
            width: AppStroke.border,
          ),
          boxShadow: AppShadows.hard(tall ? 4 : 3),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: ghost ? null : () => widget.onToggle(t),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  height: 44,
                  child: Center(
                    child: _circle(
                      columns > 1 ? 16 : 20,
                      done,
                      fg,
                      kind == _Kind.deep ? AppColors.sun : AppColors.card,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: tall
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: bold(),
                          ),
                          const SizedBox(height: 3),
                          Text(time, style: small()),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Text(
                              t.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: bold(),
                            ),
                          ),
                          if (columns == 1) ...[
                            const SizedBox(width: 8),
                            Text(time, style: small()),
                          ],
                        ],
                      ),
              ),
            ),
            if (t.priority == 1 && columns == 1 && h >= 52 && !ghost && !done)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: PillButton(
                  label: context.l10n.startFocus,
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

    if (ghost) return IgnorePointer(child: card);
    return Semantics(
      button: true,
      checked: done,
      label: '${t.title}, $time',
      child: GestureDetector(
        key: Key('plan-task-${t.id}'),
        onTap: () => widget.onOpenTask(t),
        onLongPressStart: (_) => setState(() {
          _dragId = t.id;
          _dragDy = 0;
        }),
        onLongPressMoveUpdate: (d) =>
            setState(() => _dragDy = d.offsetFromOrigin.dy),
        onLongPressEnd: (_) => _endDrag(i, minMin, maxMin),
        onLongPressCancel: () => setState(() {
          _dragId = null;
          _dragDy = 0;
        }),
        child: card,
      ),
    );
  }

  Widget _ghost(
    TextDirection textDir,
    _Item item,
    double w,
    ({int start, bool valid}) target,
    double Function(num) y,
  ) {
    final dur = item.end - item.start;
    final s = DateTime(
      _dayStart.year,
      _dayStart.month,
      _dayStart.day,
      0,
      target.start,
    );
    final e = s.add(Duration(minutes: dur));
    final h = (dur / 60 * planHourHeight).clamp(32.0, double.infinity);
    return Positioned.directional(
      textDirection: textDir,
      start: _gutter,
      width: w,
      top: y(target.start) + 2,
      height: h - 4,
      child: Opacity(
        key: const Key('plan-drag-ghost'),
        opacity: 0.85,
        child: _taskCard(
          item,
          1,
          ghost: true,
          valid: target.valid,
          timeOverride: '${formatClock(s)}–${formatClock(e)}',
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
