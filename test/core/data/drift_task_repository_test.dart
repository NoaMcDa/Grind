import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/data/connection/memory.dart';
import 'package:grind/core/data/data.dart';
import 'package:grind/core/data/mappers.dart';

void main() {
  final now = DateTime.utc(2026, 11, 3, 8);
  late AppDatabase db;
  late DriftTaskRepository repo;

  Task task(
    String id, {
    DateTime? remindAt,
    DateTime? dueAt,
    DateTime? start,
    DateTime? end,
    Duration age = Duration.zero,
  }) => Task(
    id: id,
    title: 'T$id',
    remindAt: remindAt,
    dueAt: dueAt,
    scheduledStart: start,
    scheduledEnd: end,
    createdAt: now.add(age),
    updatedAt: now.add(age),
  );

  setUp(() {
    db = openInMemoryDatabase();
    repo = DriftTaskRepository(db, clock: FixedClock(now));
  });
  tearDown(() => db.close());

  test('upsert, get, update, soft delete', () async {
    await repo.upsert(task('a'));
    expect((await repo.getAll()).length, 1);

    await repo.upsert(
      (await repo.getById('a'))!.copyWith(title: 'renamed', priority: 1),
    );
    final updated = await repo.getById('a');
    expect(updated!.title, 'renamed');
    expect(updated.priority, 1);
    expect((await repo.getAll()).length, 1);

    await repo.delete('a');
    expect(await repo.getAll(), isEmpty);
    expect(await repo.getById('a'), isNull);

    // Soft: the row is still there, with a tombstone.
    final row = await db.select(db.tasks).getSingle();
    expect(row.deletedAt, now.millisecondsSinceEpoch);
  });

  test('delete of a missing id is a no-op', () async {
    await repo.delete('nope');
    expect(await repo.getAll(), isEmpty);
  });

  test('every field round-trips', () async {
    final full = Task(
      id: 'full',
      title: 'Thesis',
      notes: 'chapter 2',
      goalId: 'g1',
      dueAt: now.add(const Duration(days: 2)),
      remindAt: now.add(const Duration(hours: 1)),
      scheduledStart: now.add(const Duration(hours: 2)),
      scheduledEnd: now.add(const Duration(hours: 3)),
      lockedStart: true,
      estimatedMinutes: 90,
      energy: Energy.deep,
      firstAction: 'open the file',
      priority: 1,
      category: 'study',
      splittable: true,
      minChunkMinutes: 45,
      status: TaskStatus.done,
      completedAt: now.add(const Duration(hours: 4)),
      actualMinutes: 80,
      snoozeCount: 3,
      calendarEventId: 'ev1',
      createdAt: now,
      updatedAt: now.add(const Duration(minutes: 5)),
    );
    await repo.upsert(full);
    final back = (await repo.getById('full'))!;
    expect(back.toJson(), full.toJson());
    expect(back.dueAt!.isUtc, isTrue);
  });

  test('getAll is ordered by createdAt', () async {
    await repo.upsertAll([
      task('late', age: const Duration(hours: 2)),
      task('early'),
      task('mid', age: const Duration(hours: 1)),
    ]);
    expect((await repo.getAll()).map((t) => t.id), ['early', 'mid', 'late']);
  });

  test('getDueBetween filters by remindAt and open status', () async {
    await repo.upsertAll([
      task('in', remindAt: now.add(const Duration(hours: 1))),
      task('out', remindAt: now.add(const Duration(days: 9))),
      task(
        'done',
        remindAt: now.add(const Duration(hours: 2)),
      ).copyWith(status: TaskStatus.done),
    ]);
    final due = await repo.getDueBetween(now, now.add(const Duration(days: 7)));
    expect(due.map((t) => t.id), ['in']);
  });

  test('getDueBetween falls back to dueAt, [from, to) bounds', () async {
    final to = now.add(const Duration(days: 1));
    await repo.upsertAll([
      task('due', dueAt: now.add(const Duration(hours: 3))),
      // remindAt wins over dueAt even when dueAt would match.
      task(
        'remindOutside',
        remindAt: now.add(const Duration(days: 3)),
        dueAt: now.add(const Duration(hours: 1)),
      ),
      task('atFrom', remindAt: now),
      task('atTo', remindAt: to),
      task('none'),
      task('deleted', remindAt: now.add(const Duration(hours: 1))),
    ]);
    await repo.delete('deleted');
    final due = await repo.getDueBetween(now, to);
    expect(due.map((t) => t.id).toSet(), {'due', 'atFrom'});
  });

  test('getScheduledBetween returns overlaps only', () async {
    DateTime h(int hours) => now.add(Duration(hours: hours));
    await repo.upsertAll([
      task('inside', start: h(1), end: h(2)),
      task('overlapStart', start: h(-1), end: h(1)),
      task('endsAtFrom', start: h(-1), end: h(0)),
      task('startsAtTo', start: h(4), end: h(5)),
      task('halfScheduled', start: h(1)),
      task('unscheduled'),
    ]);
    final got = await repo.getScheduledBetween(h(0), h(4));
    expect(got.map((t) => t.id).toSet(), {'inside', 'overlapStart'});
  });

  test('watchAll emits current value then changes', () async {
    final emissions = <int>[];
    final sub = repo.watchAll().listen((l) => emissions.add(l.length));
    await pumpEventQueue();
    await repo.upsert(task('a'));
    await pumpEventQueue();
    await repo.delete('a');
    await pumpEventQueue();
    await sub.cancel();
    expect(emissions, [0, 1, 0]);
  });
}
