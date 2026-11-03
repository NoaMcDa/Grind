import 'dart:math' as math;

import '../../core/core.dart';

/// Pure layout maths for the Plan timeline. Easy to unit-test.

/// Dragging snaps to this many minutes.
const planSnapMinutes = 15;

/// Rounds [minutes] to the nearest [planSnapMinutes].
int snapMinutes(double minutes) =>
    (minutes / planSnapMinutes).round() * planSnapMinutes;

/// Local midnight of [d].
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Local midnight of the day after [d] (DST safe).
DateTime nextDay(DateTime d) => DateTime(d.year, d.month, d.day + 1);

/// Minutes from [dayStart] (local midnight) to [t], converting UTC to local
/// first, clamped to the day (0..1440).
int minutesIntoDay(DateTime t, DateTime dayStart) {
  final m = t.toLocal().difference(dayStart).inMinutes;
  return m.clamp(0, 24 * 60);
}

/// An item placed in a column inside a group of overlapping items.
class Placed<T> {
  const Placed(this.item, this.column, this.columns);
  final T item;
  final int column;
  final int columns;
}

/// Simple column packing: items that overlap (transitively) share a cluster
/// and sit side by side, each in the first free column.
List<Placed<T>> packColumns<T>(
  Iterable<T> items,
  int Function(T) start,
  int Function(T) end,
) {
  final sorted = items.toList()
    ..sort((a, b) {
      final c = start(a).compareTo(start(b));
      return c != 0 ? c : end(b).compareTo(end(a));
    });
  final out = <Placed<T>>[];
  var cluster = <(T, int)>[];
  final columnEnds = <int>[];
  var clusterEnd = -1;

  void flush() {
    for (final (item, col) in cluster) {
      out.add(Placed(item, col, columnEnds.length));
    }
    cluster = [];
    columnEnds.clear();
  }

  for (final item in sorted) {
    if (cluster.isNotEmpty && start(item) >= clusterEnd) flush();
    var col = columnEnds.indexWhere((e) => e <= start(item));
    if (col < 0) {
      col = columnEnds.length;
      columnEnds.add(end(item));
    } else {
      columnEnds[col] = end(item);
    }
    cluster.add((item, col));
    clusterEnd = cluster.length == 1
        ? end(item)
        : math.max(clusterEnd, end(item));
  }
  flush();
  return out;
}

/// Hours shown on the timeline: working hours (over all days) padded by one
/// hour each side, never narrower than 08:00-18:00, widened to fit [spans]
/// (start/end minutes of the day's items).
({int start, int end}) planHourRange(
  Preferences prefs, [
  Iterable<(int, int)> spans = const [],
]) {
  var lo = 8;
  var hi = 18;
  final ranges = prefs.workingHours.values.expand((r) => r).toList();
  if (ranges.isNotEmpty) {
    lo = math.min(
      lo,
      ranges.map((r) => r.startMinutes).reduce(math.min) ~/ 60 - 1,
    );
    hi = math.max(
      hi,
      (ranges.map((r) => r.endMinutes).reduce(math.max) / 60).ceil() + 1,
    );
  }
  for (final (s, e) in spans) {
    lo = math.min(lo, s ~/ 60);
    hi = math.max(hi, (e / 60).ceil());
  }
  lo = lo.clamp(0, 23);
  return (start: lo, end: hi.clamp(lo + 1, 24));
}

int _overlap(DateTime s, DateTime e, DateTime dayStart) {
  final a = s.toLocal();
  final b = e.toLocal();
  final from = a.isBefore(dayStart) ? dayStart : a;
  final dayEnd = nextDay(dayStart);
  final to = b.isAfter(dayEnd) ? dayEnd : b;
  return to.isAfter(from) ? to.difference(from).inMinutes : 0;
}

/// Booked share of the day's working time, 0..1 (capped).
double dayLoad({
  required DateTime day,
  required Iterable<Task> tasks,
  required Iterable<CalendarEvent> events,
  required Preferences prefs,
}) {
  final start = dateOnly(day);
  var booked = 0;
  for (final t in tasks) {
    if (!t.isScheduled) continue;
    booked += _overlap(t.scheduledStart!, t.scheduledEnd!, start);
  }
  for (final e in events) {
    if (e.isAllDay || !e.isBusy) continue;
    booked += _overlap(e.start, e.end, start);
  }
  final cap = (prefs.workingHours[start.weekday] ?? const <TimeRange>[]).fold(
    0,
    (sum, r) => sum + r.durationMinutes,
  );
  final capacity = cap > 0 ? cap : 8 * 60;
  return (booked / capacity).clamp(0.0, 1.0);
}

/// The 7 local dates of the week containing [day], starting on [weekStart]
/// ([DateTime.monday]..[DateTime.sunday]).
List<DateTime> weekOf(DateTime day, int weekStart) {
  final d = dateOnly(day);
  final back = (d.weekday - weekStart + 7) % 7;
  return [
    for (var i = 0; i < 7; i++) DateTime(d.year, d.month, d.day - back + i),
  ];
}
