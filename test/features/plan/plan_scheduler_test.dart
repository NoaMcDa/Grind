import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/plan/plan_providers.dart';
import 'package:grind/features/plan/plan_scheduler.dart';
import 'package:grind/features/plan/plan_strings.dart';

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

ProviderContainer _container({List<Task>? tasks, DateTime? now}) {
  final c = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(FixedClock(now ?? _now)),
      taskRepositoryProvider.overrideWithValue(
        InMemoryTaskRepository(tasks ?? _tasks()),
      ),
      calendarRepositoryProvider.overrideWithValue(
        InMemoryCalendarRepository(_events()),
      ),
      preferencesRepositoryProvider.overrideWithValue(
        InMemoryPreferencesRepository(const Preferences(onboardingDone: true)),
      ),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

bool _overlaps(DateTime s, DateTime e, DateTime s2, DateTime e2) =>
    s.isBefore(e2) && s2.isBefore(e);

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
    expect(cap.freeMinutes, greaterThan(20 * 60));
    expect(
      c.read(planCapacityLineProvider),
      PlanStrings.capacityLine(
        freeMinutes: cap.freeMinutes,
        plannedMinutes: 60,
      ),
    );
  });

  test('capacity line copy', () {
    expect(
      PlanStrings.capacityLine(freeMinutes: 14 * 60, plannedMinutes: 9 * 60),
      '14 h free · 9 h planned',
    );
    expect(
      PlanStrings.capacityLine(freeMinutes: 90, plannedMinutes: 45),
      '1.5 h free · 45 min planned',
    );
    expect(
      PlanStrings.capacityLine(freeMinutes: 10 * 60, plannedMinutes: 12 * 60),
      'A full week: over by 2 h. Pip can help trim it.',
    );
  });
}
