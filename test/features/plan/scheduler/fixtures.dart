// Shared fixtures for the scheduler tests. All times are local.
import 'package:grind/core/domain/domain.dart';

/// Monday 9 Nov 2026.
final monday = DateTime(2026, 11, 9);

DateTime at(int dayOffset, int hour, [int minute = 0]) =>
    DateTime(2026, 11, 9 + dayOffset, hour, minute);

final created = DateTime(2026, 11, 1);

/// Mon–Fri 09:00–17:00, focus 09:00–12:00, lunch 12:00–13:00,
/// 10-minute buffers, 60-minute daily cushion, 2 deep blocks a day.
const prefsFixture = Preferences(
  workingHours: {
    DateTime.monday: [TimeRange(startMinutes: 9 * 60, endMinutes: 17 * 60)],
    DateTime.tuesday: [TimeRange(startMinutes: 9 * 60, endMinutes: 17 * 60)],
    DateTime.wednesday: [TimeRange(startMinutes: 9 * 60, endMinutes: 17 * 60)],
    DateTime.thursday: [TimeRange(startMinutes: 9 * 60, endMinutes: 17 * 60)],
    DateTime.friday: [TimeRange(startMinutes: 9 * 60, endMinutes: 17 * 60)],
  },
  deepWindows: [TimeRange(startMinutes: 9 * 60, endMinutes: 12 * 60)],
  lunch: [TimeRange(startMinutes: 12 * 60, endMinutes: 13 * 60)],
  maxDeepBlocksPerDay: 2,
  deepBlockMinutes: 90,
  bufferBetweenEventsMinutes: 10,
  dailyCushionMinutes: 60,
  weekStart: DateTime.monday,
);

Task task(
  String id, {
  String? title,
  int minutes = 30,
  Energy energy = Energy.light,
  DateTime? due,
  int priority = 2,
  String? goalId,
  String? category,
  bool splittable = false,
  int minChunk = 25,
  DateTime? lockedStart,
  DateTime? lockedEnd,
  TaskStatus status = TaskStatus.open,
}) => Task(
  id: id,
  title: title ?? id,
  estimatedMinutes: minutes,
  energy: energy,
  dueAt: due,
  priority: priority,
  goalId: goalId,
  category: category,
  splittable: splittable,
  minChunkMinutes: minChunk,
  scheduledStart: lockedStart,
  scheduledEnd: lockedEnd,
  lockedStart: lockedStart != null,
  status: status,
  createdAt: created,
  updatedAt: created,
);

CalendarEvent event(
  String id,
  DateTime start,
  DateTime end, {
  String? title,
  bool busy = true,
}) => CalendarEvent(
  id: id,
  source: CalendarSource.google,
  externalId: id,
  title: title ?? id,
  start: start,
  end: end,
  isBusy: busy,
  createdAt: created,
  updatedAt: created,
);

Goal goal(
  String id,
  String title, {
  double importance = 0.5,
  double progress = 0,
  DateTime? lastProgressAt,
}) => Goal(
  id: id,
  title: title,
  importance: importance,
  progress: progress,
  lastProgressAt: lastProgressAt,
  createdAt: created,
  updatedAt: created,
);

final thesis = goal('thesis', 'Thesis', importance: 0.9, progress: 0.3);
final goalsFixture = {thesis.id: thesis};

/// Empty Monday.
final emptyDayEvents = <CalendarEvent>[];

/// Tuesday with four meetings and one "free" (non-blocking) event.
final meetingHeavyEvents = [
  event('standup', at(1, 9, 30), at(1, 10, 30), title: 'Standup'),
  event('sync', at(1, 11), at(1, 11, 30), title: 'Sync'),
  event('lunch-talk', at(1, 11, 30), at(1, 12), busy: false),
  event('review', at(1, 13, 30), at(1, 14, 30), title: 'Design review'),
  event('client', at(1, 15), at(1, 16), title: 'Client call'),
];

/// Mon–Fri wall-to-wall meetings, 09:00–12:00 and 13:00–17:00.
final backToBackWeek = [
  for (var d = 0; d < 5; d++) ...[
    event('am$d', at(d, 9), at(d, 12), title: 'Workshop'),
    event('pm$d', at(d, 13), at(d, 17), title: 'Workshop'),
  ],
];
