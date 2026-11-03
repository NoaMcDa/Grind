import 'package:grind/core/domain/domain.dart';

import 'models.dart';
import 'time_math.dart';

/// Shortest gap worth offering. Anything shorter is dropped.
const minSlotMinutes = 15;

/// Free time between [from] and [to], sorted by start.
///
/// For each local calendar day touched by the range:
/// working hours for that weekday, minus busy events (merged; `isBusy ==
/// false`, deleted events and Grind write-backs of tasks are ignored) each
/// padded by `bufferBetweenEventsMinutes` on both sides, minus lunch, minus
/// [lockedTasks] (their `scheduledStart`–`scheduledEnd`), then
/// `dailyCushionMinutes` are taken from the end of the day. Only then is the
/// day clipped to `[from, to)` and gaps shorter than [minSlotMinutes] dropped,
/// so the cushion stays at the end of the day even when planning starts at
/// 15:00.
///
/// Time zone: every [DateTime] is compared as an instant, but day boundaries
/// and `Preferences` clock ranges are read in the device's local time.
/// Callers pass local times; converting from another zone is their job.
List<Slot> freeSlots({
  required DateTime from,
  required DateTime to,
  required Preferences prefs,
  required List<CalendarEvent> events,
  required List<Task> lockedTasks,
}) {
  final out = <Slot>[];
  if (!to.isAfter(from)) return out;
  final window = Slot(from.toLocal(), to.toLocal());
  for (var day = startOfDay(from); day.isBefore(to); day = addDays(day, 1)) {
    final daySlots = freeSlotsForDay(
      day: day,
      prefs: prefs,
      events: events,
      lockedTasks: lockedTasks,
    );
    for (final s in daySlots) {
      final clipped = intersect(s, window);
      if (clipped != null && clipped.minutes >= minSlotMinutes) {
        out.add(clipped);
      }
    }
  }
  return out;
}

/// Free time on one local calendar [day] (any time on that day), before
/// clipping to a planning window. Includes gaps shorter than 15 minutes.
List<Slot> freeSlotsForDay({
  required DateTime day,
  required Preferences prefs,
  required List<CalendarEvent> events,
  required List<Task> lockedTasks,
}) {
  final d = startOfDay(day);
  final working = (prefs.workingHours[d.weekday] ?? const <TimeRange>[]).map(
    (r) => rangeOn(d, r),
  );
  final buffer = Duration(minutes: prefs.bufferBetweenEventsMinutes);
  final cuts = <Slot>[
    for (final e in events)
      if (blocksTime(e))
        Slot(e.start.toLocal().subtract(buffer), e.end.toLocal().add(buffer)),
    for (final r in prefs.lunch) rangeOn(d, r),
    for (final t in lockedTasks)
      if (t.isScheduled)
        Slot(t.scheduledStart!.toLocal(), t.scheduledEnd!.toLocal()),
  ];
  final free = subtractSlots(working, cuts);
  return takeCushion(free, prefs.dailyCushionMinutes);
}

/// True when [e] should block time: busy, not deleted, and not the calendar
/// copy of a Grind task (the task itself carries that placement).
bool blocksTime(CalendarEvent e) =>
    e.isBusy && e.deletedAt == null && e.taskId == null;

/// Removes [cushionMinutes] from the end of the day's free time.
List<Slot> takeCushion(List<Slot> free, int cushionMinutes) {
  var left = cushionMinutes;
  final out = [...free];
  while (left > 0 && out.isNotEmpty) {
    final last = out.removeLast();
    if (last.minutes > left) {
      out.add(Slot(last.start, last.end.subtract(Duration(minutes: left))));
      left = 0;
    } else {
      left -= last.minutes;
    }
  }
  return out;
}
