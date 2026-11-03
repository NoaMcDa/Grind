/// Internal helpers: interval arithmetic on local [DateTime]s and the
/// English date words used in reasons. Not exported from the barrel.
library;

import 'package:grind/core/domain/domain.dart';

import 'models.dart';

bool sameList<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

String _two(int n) => n.toString().padLeft(2, '0');

/// `09:05`
String hm(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

/// `2026-11-03`
String ymd(DateTime t) => '${t.year}-${_two(t.month)}-${_two(t.day)}';

/// Local midnight of [t]'s calendar day.
DateTime startOfDay(DateTime t) {
  final l = t.toLocal();
  return DateTime(l.year, l.month, l.day);
}

/// Local midnight [days] calendar days after [day] (DST-safe).
DateTime addDays(DateTime day, int days) =>
    DateTime(day.year, day.month, day.day + days);

/// Local wall-clock time [minutes] after midnight on [day] (DST-safe).
DateTime atMinutes(DateTime day, int minutes) =>
    DateTime(day.year, day.month, day.day, 0, minutes);

Slot rangeOn(DateTime day, TimeRange r) =>
    Slot(atMinutes(day, r.startMinutes), atMinutes(day, r.endMinutes));

DateTime maxTime(DateTime a, DateTime b) => a.isAfter(b) ? a : b;
DateTime minTime(DateTime a, DateTime b) => a.isBefore(b) ? a : b;

int compareSlots(Slot a, Slot b) {
  final c = a.start.compareTo(b.start);
  return c != 0 ? c : a.end.compareTo(b.end);
}

/// Sorted, non-overlapping union of [slots]; touching slots are joined.
List<Slot> mergeSlots(Iterable<Slot> slots) {
  final sorted = slots.where((s) => !s.isEmpty).toList()..sort(compareSlots);
  final out = <Slot>[];
  for (final s in sorted) {
    if (out.isNotEmpty && !s.start.isAfter(out.last.end)) {
      final last = out.removeLast();
      out.add(Slot(last.start, maxTime(last.end, s.end)));
    } else {
      out.add(s);
    }
  }
  return out;
}

/// [base] minus the union of [cuts]. Result is sorted.
List<Slot> subtractSlots(Iterable<Slot> base, Iterable<Slot> cuts) {
  final merged = mergeSlots(cuts);
  final out = <Slot>[];
  for (final b in mergeSlots(base)) {
    var cursor = b.start;
    for (final c in merged) {
      if (!c.end.isAfter(cursor)) continue;
      if (!c.start.isBefore(b.end)) break;
      if (c.start.isAfter(cursor)) out.add(Slot(cursor, c.start));
      cursor = maxTime(cursor, c.end);
      if (!cursor.isBefore(b.end)) break;
    }
    if (cursor.isBefore(b.end)) out.add(Slot(cursor, b.end));
  }
  return out;
}

/// Intersection of [a] and [b], or null when they do not overlap.
Slot? intersect(Slot a, Slot b) {
  final s = maxTime(a.start, b.start);
  final e = minTime(a.end, b.end);
  return e.isAfter(s) ? Slot(s, e) : null;
}

/// Whole calendar days from local midnight [a] to local midnight [b]
/// (rounded, so a 23- or 25-hour DST day still counts as one).
int calendarDaysBetween(DateTime a, DateTime b) =>
    (b.difference(a).inMinutes / (24 * 60)).round();

int totalMinutes(Iterable<Slot> slots) =>
    slots.fold(0, (sum, s) => sum + s.minutes);

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String weekdayName(DateTime t) => _weekdays[t.weekday - 1];

/// "today", "tomorrow", "Thursday" (within the next 6 days) or "Nov 12".
/// A deadline at exactly midnight reads as the day before ("due Thursday"
/// for Friday 00:00), because that is how a date-only due date is stored.
String dayWord(DateTime target, DateTime now) {
  var t = target.toLocal();
  if (t.hour == 0 && t.minute == 0 && t.second == 0) {
    t = t.subtract(const Duration(minutes: 1));
  }
  final d = calendarDaysBetween(startOfDay(now), startOfDay(t));
  if (d == 0) return 'today';
  if (d == 1) return 'tomorrow';
  if (d > 1 && d < 7) return weekdayName(t);
  return '${_months[t.month - 1]} ${t.day}';
}

/// "the Thursday deadline", "today's deadline", "the Nov 12 deadline".
String deadlineWord(DateTime due, DateTime now) {
  final w = dayWord(due, now);
  if (w == 'today' || w == 'tomorrow') return "$w's deadline";
  return 'the $w deadline';
}
