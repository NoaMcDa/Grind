import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/time_zones.dart';
import 'package:grind/features/calendar/sync/calendar_sync_engine.dart';
import 'package:grind/features/plan/plan_providers.dart';
import 'package:grind/features/plan/plan_scheduler.dart';
import 'package:grind/features/plan/plan_l10n.dart';
import 'package:grind/l10n/l10n.dart';
import 'package:timezone/timezone.dart' as tz;

import '../tasks/zone_test_support.dart';

/// Thursday 2026-10-29 09:00 local; the week (Sunday start) is Oct 25–31.
final _now = DateTime(2026, 10, 29, 9);
final _created = DateTime.utc(2026, 10, 1);

DateTime _at(int day, int h, [int m = 0]) => DateTime(2026, 10, day, h, m);

CalendarEvent _event(String id, DateTime s, DateTime e) => CalendarEvent(
  id: id,
  source: CalendarSource.google,
  externalId: id,
  title: id,
  start: s.toUtc(),
  end: e.toUtc(),
  createdAt: _created,
  updatedAt: _created,
);

Task _task(
  String id, {
  int minutes = 30,
  Energy energy = Energy.light,
  DateTime? due,
  DateTime? start,
  DateTime? end,
  bool locked = false,
  TaskStatus status = TaskStatus.open,
}) => Task(
  id: id,
  title: 'Task $id',
  estimatedMinutes: minutes,
  energy: energy,
  dueAt: due?.toUtc(),
  scheduledStart: start?.toUtc(),
  scheduledEnd: end?.toUtc(),
  lockedStart: locked,
  status: status,
  createdAt: _created,
  updatedAt: _created,
);

/// Two events and three tasks (the issue's acceptance fixture), plus a
/// pinned task, a done task and one that cannot fit.
List<Task> _tasks() => [
  _task('deep', minutes: 90, energy: Energy.deep, due: _at(30, 14)),
  _task('quick', minutes: 30, due: _at(29, 23, 59)),
  _task('undated', minutes: 45),
  _task('pinned', start: _at(29, 16), end: _at(29, 17), locked: true),
  _task('done', status: TaskStatus.done),
  _task('huge', minutes: 600, due: _at(29, 18)),
];

List<CalendarEvent> _events() => [
  _event('lecture', _at(29, 10), _at(29, 11, 30)),
  _event('seminar', _at(29, 14), _at(29, 15, 30)),
];

ProviderContainer _container({
  List<Task>? tasks,
  List<CalendarEvent>? events,
  DateTime? now,
}) {
  final c = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(FixedClock(now ?? _now)),
      taskRepositoryProvider.overrideWithValue(
        InMemoryTaskRepository(tasks ?? _tasks()),
      ),
      calendarRepositoryProvider.overrideWithValue(
        InMemoryCalendarRepository(events ?? _events()),
      ),
      devicePrefsOverride(),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

bool _overlaps(DateTime s, DateTime e, DateTime s2, DateTime e2) =>
    s.isBefore(e2) && s2.isBefore(e);

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  test('same inputs give the same placements, each with a reason', () async {
    final a = await _container().read(planSchedulerProvider).proposeWeek(_now);
    final b = await _container().read(planSchedulerProvider).proposeWeek(_now);
    expect(a.plan, b.plan);
    expect(a.plan.placed, isNotEmpty);
    expect(a.weekStart, DateTime(2026, 10, 25));
    expect(a.weekEnd, DateTime(2026, 11, 1));

    final ids = a.changes.map((p) => p.taskId).toSet();
    expect(ids, containsAll(['deep', 'quick', 'undated']));
    expect(ids, isNot(contains('done')));
    for (final p in a.changes) {
      expect(p.reasons, isNotEmpty);
      expect(p.start.isUtc, isFalse, reason: 'placements are local');
      expect(p.start.isBefore(_now), isFalse);
      for (final e in _events()) {
        expect(
          _overlaps(p.start, p.end, e.start.toLocal(), e.end.toLocal()),
          isFalse,
          reason: '${p.taskId} overlaps ${e.id}',
        );
      }
      expect(
        _overlaps(p.start, p.end, _at(29, 16), _at(29, 17)),
        isFalse,
        reason: '${p.taskId} overlaps the pinned task',
      );
    }
    // The pinned task is kept, not offered as a change.
    expect(a.keptCount, 1);
    expect(a.changes.where((p) => p.taskId == 'pinned'), isEmpty);
  });

  test('a task that cannot fit is reported with a reason', () async {
    final p = await _container().read(planSchedulerProvider).proposeWeek(_now);
    final huge = p.unplaced.where((u) => u.taskId == 'huge').single;
    expect(huge.reason, isNotEmpty);
    expect(p.titleOf('huge'), 'Task huge');
  });

  // A work-day event (09:30-18:00, busy) leaves no free slot, but the user
  // placed two tasks inside it by hand. They are kept, not reported as
  // "didn't fit".
  test('hand-placed tasks over a busy event are kept, not unplaced', () async {
    final c = _container(
      tasks: [
        _task(
          'lesson',
          minutes: 240,
          due: _at(30, 23, 59),
          start: _at(30, 10),
          end: _at(30, 14),
          locked: true,
        ),
        _task(
          'study',
          minutes: 120,
          due: _at(30, 23, 59),
          start: _at(30, 15),
          end: _at(30, 17),
          locked: true,
        ),
      ],
      events: [_event('work', _at(30, 9, 30), _at(30, 18))],
    );
    final p = await c.read(planSchedulerProvider).proposeWeek(_now);
    expect(p.unplaced, isEmpty);
    expect(p.keptCount, 2);
    expect(p.changes, isEmpty);
  });

  // The calendar copies of a task (a write-back with `taskId`, or the event
  // "Add as task" imported it from) do not block that task's own time.
  test('a task is not blocked by its own calendar copy', () async {
    final imported = _event('krav-ext', _at(30, 10), _at(30, 14));
    final writeBack = _event(
      'study-ext',
      _at(30, 15),
      _at(30, 17),
    ).copyWith(taskId: 'study');
    final c = _container(
      tasks: [
        _task(
          'krav',
          minutes: 240,
          due: _at(30, 14),
          start: _at(30, 10),
          end: _at(30, 14),
        ).copyWith(calendarEventId: importedCalendarEventIdFor('krav-ext')),
        _task(
          'study',
          minutes: 120,
          due: _at(30, 17),
          start: _at(30, 15),
          end: _at(30, 17),
        ).copyWith(calendarEventId: 'study-ext'),
      ],
      events: [imported, writeBack],
    );
    final p = await c.read(planSchedulerProvider).proposeWeek(_now);
    expect(p.unplaced, isEmpty);
    for (final id in ['krav', 'study']) {
      expect(p.plan.placementsFor(id), isNotEmpty, reason: id);
    }
  });

  test('apply writes UTC slots and leaves pinned tasks alone', () async {
    final c = _container();
    final s = c.read(planSchedulerProvider);
    final proposal = await s.proposeWeek(_now);
    final n = await s.apply(proposal);
    expect(n, proposal.changes.map((p) => p.taskId).toSet().length);

    final repo = c.read(taskRepositoryProvider);
    for (final p in proposal.changes) {
      final t = (await repo.getById(p.taskId))!;
      expect(t.scheduledStart, p.start.toUtc());
      expect(t.scheduledStart!.isUtc, isTrue);
      expect(t.scheduledEnd, p.end.toUtc());
      expect(t.lockedStart, isFalse);
    }
    final pinned = (await repo.getById('pinned'))!;
    expect(pinned.scheduledStart, _at(29, 16).toUtc());
    expect(pinned.lockedStart, isTrue);
    expect((await repo.getById('huge'))!.isScheduled, isFalse);

    // Applying the same draft again changes nothing.
    expect(await s.apply(proposal), 0);
  });

  test('apply skips a task pinned by hand after the proposal', () async {
    final c = _container();
    final s = c.read(planSchedulerProvider);
    final proposal = await s.proposeWeek(_now);
    final repo = c.read(taskRepositoryProvider);
    final quick = (await repo.getById('quick'))!;
    await repo.upsert(
      quick.copyWith(
        scheduledStart: _at(29, 17).toUtc(),
        scheduledEnd: _at(29, 17, 30).toUtc(),
        lockedStart: true,
      ),
    );
    await s.apply(proposal);
    expect((await repo.getById('quick'))!.scheduledStart, _at(29, 17).toUtc());
  });

  test('a past week gives an empty draft', () async {
    final s = _container().read(planSchedulerProvider);
    final p = await s.proposeWeek(DateTime(2026, 10, 20));
    expect(p.changes, isEmpty);
    expect(p.unplaced, isEmpty);
    expect(await s.apply(p), 0);
  });

  test('a later week is planned from its own start', () async {
    final s = _container().read(planSchedulerProvider);
    final p = await s.proposeWeek(DateTime(2026, 11, 3));
    expect(p.weekStart, DateTime(2026, 11, 1));
    final undated = p.changes.where((x) => x.taskId == 'undated').single;
    expect(undated.start.isBefore(DateTime(2026, 11, 1)), isFalse);
  });

  test('scheduleOne places just that task, around the others', () async {
    final c = _container(
      tasks: [
        _task('a', minutes: 45, due: _at(30, 23, 59)),
        _task('b', minutes: 30),
        _task('fixed', start: _at(29, 11, 45), end: _at(29, 13, 30)),
      ],
    );
    final repo = c.read(taskRepositoryProvider);
    final r1 = await c.read(planSchedulerProvider).scheduleOne('a');
    expect(r1.isPlaced, isTrue);
    expect(r1.reason, isNotEmpty);
    final a = (await repo.getById('a'))!;
    expect(a.scheduledStart, r1.placement!.start.toUtc());
    expect(a.scheduledEnd!.difference(a.scheduledStart!).inMinutes, 45);
    expect(a.lockedStart, isFalse);
    expect(
      _overlaps(
        a.scheduledStart!,
        a.scheduledEnd!,
        _at(29, 11, 45).toUtc(),
        _at(29, 13, 30).toUtc(),
      ),
      isFalse,
    );
    // Others are untouched.
    expect((await repo.getById('b'))!.isScheduled, isFalse);
    expect(
      (await repo.getById('fixed'))!.scheduledStart,
      _at(29, 11, 45).toUtc(),
    );
    expect((await repo.getById('fixed'))!.lockedStart, isFalse);

    // Deterministic: a fresh container gives the same slot.
    final c2 = _container(
      tasks: [
        _task('a', minutes: 45, due: _at(30, 23, 59)),
        _task('b', minutes: 30),
        _task('fixed', start: _at(29, 11, 45), end: _at(29, 13, 30)),
      ],
    );
    final r2 = await c2.read(planSchedulerProvider).scheduleOne('a');
    expect(r2.placement, r1.placement);
  });

  test('scheduleOne reports a task that cannot fit', () async {
    final c = _container(
      tasks: [_task('huge', minutes: 600, due: _at(29, 18))],
    );
    final r = await c.read(planSchedulerProvider).scheduleOne('huge');
    expect(r.isPlaced, isFalse);
    expect(r.reason, isNotEmpty);
    expect(
      (await c.read(taskRepositoryProvider).getById('huge'))!.isScheduled,
      isFalse,
    );
  });

  test('capacity for the shown week counts planned open tasks', () async {
    final c = _container();
    final sub = c.listen(planWeekCapacityProvider, (_, _) {});
    addTearDown(sub.close);
    await c.read(tasksProvider.future);
    await c.read(planWeekEventsProvider.future);
    await c.read(preferencesProvider.future);
    final cap = c.read(planWeekCapacityProvider);
    expect(cap.demandMinutes, 60); // only the pinned hour is scheduled
    // Same free time as the draft "Re-plan with Pip" shows: now → week end.
    final draft = await c.read(planSchedulerProvider).proposeWeek(_now);
    expect(cap.freeMinutes, draft.plan.capacity.freeMinutes);
    expect(cap.freeMinutes, greaterThan(5 * 60));
    expect(c.read(planCapacityMinutesProvider), (
      free: cap.freeMinutes,
      planned: 60,
    ));
  });

  test('capacity line copy', () {
    expect(
      planCapacityLine(_en, freeMinutes: 14 * 60, plannedMinutes: 9 * 60),
      '14 h free · 9 h planned',
    );
    expect(
      planCapacityLine(_en, freeMinutes: 90, plannedMinutes: 45),
      '1.5 h free · 45 min planned',
    );
    expect(
      planCapacityLine(_en, freeMinutes: 10 * 60, plannedMinutes: 12 * 60),
      'A full week: over by 2 h. Pip can help trim it.',
    );
    expect(
      planCapacityLine(_en, freeMinutes: 21 * 60, plannedMinutes: 0),
      '21 h free · nothing planned yet',
    );
  });

  group('day bounds follow Preferences.timeZoneName, not the device', () {
    ProviderContainer zoned(DateTime nowUtc, String zone, List<Task> tasks) {
      final c = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(FixedClock(nowUtc)),
          taskRepositoryProvider.overrideWithValue(
            InMemoryTaskRepository(tasks),
          ),
          calendarRepositoryProvider.overrideWithValue(
            InMemoryCalendarRepository(),
          ),
          preferencesRepositoryProvider.overrideWithValue(
            InMemoryPreferencesRepository(
              Preferences(onboardingDone: true, timeZoneName: zone),
            ),
          ),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    tz.TZDateTime inZone(DateTime t, String zone) =>
        tz.TZDateTime.from(t, tz.getLocation(zone));

    setUpAll(ensureTimeZones);

    test('Sat 23:30 UTC is Sunday in Jerusalem: the capacity line and the '
        'Re-plan sheet both plan the new week', () async {
      final now = DateTime.utc(2026, 11, 7, 23, 30); // Sun Nov 8, 01:30 there
      final c = zoned(now, 'Asia/Jerusalem', [_task('t', minutes: 30)]);
      await c.read(preferencesProvider.future);
      final sub = c.listen(planWeekCapacityProvider, (_, _) {});
      addTearDown(sub.close);
      await c.read(tasksProvider.future);
      await c.read(planWeekEventsProvider.future);

      final day = c.read(selectedDayProvider);
      expect(day, DateTime(2026, 11, 8));
      expect(c.read(planWeekProvider).first, DateTime(2026, 11, 8));
      final cap = c.read(planWeekCapacityProvider);
      // Mon–Thu 9–18 and Fri 9–14, less lunch and cushion: plenty.
      expect(cap.freeMinutes, greaterThan(20 * 60));

      final draft = await c.read(planSchedulerProvider).proposeWeek(day);
      expect(draft.weekStart, DateTime(2026, 11, 8));
      expect(draft.plan.capacity.freeMinutes, cap.freeMinutes);
      expect(draft.changes.single.start, DateTime(2026, 11, 9, 9));
      await c.read(planSchedulerProvider).apply(draft);
      final placed = (await c.read(taskRepositoryProvider).getById('t'))!;
      final start = inZone(placed.scheduledStart!, 'Asia/Jerusalem');
      // Monday 09:00 in Jerusalem, never before "today" there.
      expect([start.month, start.day, start.hour], [11, 9, 9]);
      expect(placed.scheduledStart!.isBefore(now), isFalse);
    });

    test('Schedule it for me: Tokyo is a day ahead of a UTC device', () async {
      // Tue Nov 3 20:00 UTC = Wed Nov 4 05:00 in Tokyo.
      final now = DateTime.utc(2026, 11, 3, 20);
      final c = zoned(now, 'Asia/Tokyo', [_task('t', minutes: 30)]);
      final r = await c.read(planSchedulerProvider).scheduleOne('t');
      expect(r.isPlaced, isTrue);
      final t = (await c.read(taskRepositoryProvider).getById('t'))!;
      final start = inZone(t.scheduledStart!, 'Asia/Tokyo');
      // The start of Wednesday's working hours there, not 09:00 UTC (18:00).
      expect([start.month, start.day, start.hour], [11, 4, 9]);
      expect(t.scheduledStart, DateTime.utc(2026, 11, 4));
    });

    test('Schedule it for me: New York is still on the previous day', () async {
      // Wed Nov 4 02:00 UTC = Tue Nov 3 21:00 in New York.
      final now = DateTime.utc(2026, 11, 4, 2);
      final c = zoned(now, 'America/New_York', [_task('t', minutes: 30)]);
      await c.read(planSchedulerProvider).scheduleOne('t');
      final t = (await c.read(taskRepositoryProvider).getById('t'))!;
      final start = inZone(t.scheduledStart!, 'America/New_York');
      expect([start.month, start.day, start.hour], [11, 4, 9]);
      expect(t.scheduledStart, DateTime.utc(2026, 11, 4, 14));
      expect(t.scheduledStart!.isBefore(now), isFalse);
    });
  });
}
