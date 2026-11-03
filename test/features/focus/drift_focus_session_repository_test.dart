import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/data/connection/memory.dart';
import 'package:grind/core/data/data.dart';
import 'package:grind/core/data/focus_session_repository.dart';
import 'package:grind/core/data/repositories/drift_focus_session_repository.dart';

void main() {
  final now = DateTime.utc(2026, 11, 3, 8);
  late AppDatabase db;

  FocusSession session(
    String id,
    DateTime start, {
    String? taskId = 't1',
    DateTime? endedAt,
    bool completed = false,
  }) => FocusSession(
    id: id,
    taskId: taskId,
    plannedMinutes: 25,
    startedAt: start,
    endedAt: endedAt,
    completed: completed,
    createdAt: start,
    updatedAt: start,
  );

  setUp(() async {
    db = openInMemoryDatabase();
    await DriftTaskRepository(
      db,
    ).upsert(Task(id: 't1', title: 't1', createdAt: now, updatedAt: now));
  });
  tearDown(() => db.close());

  // The same contract runs against both implementations.
  final impls = <String, FocusSessionRepository Function()>{
    'Drift': () => DriftFocusSessionRepository(db),
    'InMemory': InMemoryFocusSessionRepository.new,
  };

  for (final MapEntry(key: name, value: make) in impls.entries) {
    group(name, () {
      test('start, getActive, update, end', () async {
        final repo = make();
        expect(await repo.getActive(), isNull);

        await repo.start(session('a', now));
        final active = (await repo.getActive())!;
        expect(active.id, 'a');
        expect(active.taskId, 't1');
        expect(active.plannedMinutes, 25);
        expect(active.startedAt, now);
        expect(active.endedAt, isNull);

        await repo.update(
          FocusSession(
            id: 'a',
            taskId: 't1',
            plannedMinutes: 30,
            startedAt: now,
            endedAt: now.add(const Duration(minutes: 30)),
            completed: true,
            createdAt: now,
            updatedAt: now.add(const Duration(minutes: 30)),
          ),
        );
        expect(await repo.getActive(), isNull);
        final stored = (await repo.getBetween(now, now.add(_day))).single;
        expect(stored.plannedMinutes, 30);
        expect(stored.completed, isTrue);
        expect(stored.actualMinutes, 30);
      });

      test('getActive returns the latest open session', () async {
        final repo = make();
        await repo.start(session('old', now));
        await repo.start(session('new', now.add(const Duration(minutes: 5))));
        expect((await repo.getActive())!.id, 'new');
      });

      test('getBetween is [from, to) on startedAt, oldest first', () async {
        final repo = make();
        final end = now.add(const Duration(hours: 1));
        await repo.start(session('b', now.add(const Duration(minutes: 30))));
        await repo.start(session('a', now));
        await repo.start(session('out', end));
        await repo.start(
          session('before', now.subtract(const Duration(seconds: 1))),
        );
        final got = await repo.getBetween(now, end);
        expect(got.map((s) => s.id), ['a', 'b']);
      });

      test('v3 fields round-trip: pauses, win, kind', () async {
        final repo = make();
        final paused = now.add(const Duration(minutes: 10));
        await repo.start(
          session('a', now).copyWith(pausedMs: 60000, pausedAt: paused),
        );
        final active = (await repo.getActive())!;
        expect(active.pausedMs, 60000);
        expect(active.pausedAt, paused);
        expect(active.isPaused, isTrue);
        expect(active.kind, FocusSessionKind.focus);

        await repo.update(
          active.copyWith(
            pausedMs: 120000,
            pausedAt: null,
            endedAt: now.add(const Duration(minutes: 27)),
            completed: true,
            win: 'Outlined chapter 2',
          ),
        );
        final done = (await repo.getBetween(now, now.add(_day))).single;
        expect(done.pausedMs, 120000);
        expect(done.paused, const Duration(minutes: 2));
        expect(done.pausedAt, isNull);
        expect(done.win, 'Outlined chapter 2');

        await repo.start(
          session(
            'break',
            now.add(const Duration(minutes: 30)),
            taskId: null,
          ).copyWith(kind: FocusSessionKind.breakTime),
        );
        expect((await repo.getActive())!.kind, FocusSessionKind.breakTime);
      });

      test('soft-deleted sessions are hidden', () async {
        final repo = make();
        await repo.start(session('a', now));
        await repo.update(session('a', now).copyWith(deletedAt: now));
        expect(await repo.getActive(), isNull);
        expect(await repo.getBetween(now, now.add(_day)), isEmpty);
      });

      test('free sessions have no task', () async {
        final repo = make();
        await repo.start(session('free', now, taskId: null));
        expect((await repo.getActive())!.taskId, isNull);
      });

      test('watchActive and watchBetween emit on change', () async {
        final repo = make();
        final active = repo.watchActive();
        final between = repo.watchBetween(now, now.add(_day));
        final activeEvents = <String?>[];
        final betweenEvents = <int>[];
        final s1 = active.listen((s) => activeEvents.add(s?.id));
        final s2 = between.listen((l) => betweenEvents.add(l.length));
        await pumpEventQueue();

        await repo.start(session('a', now));
        await pumpEventQueue();
        await repo.update(
          session(
            'a',
            now,
            endedAt: now.add(const Duration(minutes: 25)),
            completed: true,
          ),
        );
        await pumpEventQueue();
        await s1.cancel();
        await s2.cancel();

        expect(activeEvents.first, isNull);
        expect(activeEvents, contains('a'));
        expect(activeEvents.last, isNull);
        expect(betweenEvents.first, 0);
        expect(betweenEvents.last, 1);
      });
    });
  }

  test(
    'Drift: deleting the task keeps the session, taskId goes null',
    () async {
      final repo = DriftFocusSessionRepository(db);
      await repo.start(session('a', now));
      await db.delete(db.tasks).go();
      expect((await repo.getActive())!.taskId, isNull);
    },
  );
}

const _day = Duration(days: 1);
