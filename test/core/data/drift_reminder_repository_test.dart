import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/data/connection/memory.dart';
import 'package:grind/core/data/data.dart';

void main() {
  final now = DateTime.utc(2026, 11, 3, 8);
  late AppDatabase db;
  late DriftReminderRepository repo;

  ReminderRule rule(String id, String taskId) => ReminderRule(
    id: id,
    taskId: taskId,
    rrule: 'FREQ=WEEKLY;BYDAY=MO,WE,FR',
    leadMinutes: 10,
    until: now.add(const Duration(days: 30)),
    createdAt: now,
    updatedAt: now,
  );

  setUp(() async {
    db = openInMemoryDatabase();
    repo = DriftReminderRepository(db, clock: FixedClock(now));
    await DriftTaskRepository(db).upsertAll([
      for (final id in ['t1', 't2'])
        Task(id: id, title: id, createdAt: now, updatedAt: now),
    ]);
  });
  tearDown(() => db.close());

  test('upsert, getForTask, update, soft delete', () async {
    await repo.upsert(rule('r1', 't1'));
    final got = (await repo.getForTask('t1'))!;
    expect(got.rrule, 'FREQ=WEEKLY;BYDAY=MO,WE,FR');
    expect(got.leadMinutes, 10);
    expect(got.until, now.add(const Duration(days: 30)));
    expect(await repo.getForTask('t2'), isNull);

    await repo.upsert(got.copyWith(rrule: 'FREQ=DAILY', until: null));
    final updated = (await repo.getForTask('t1'))!;
    expect(updated.rrule, 'FREQ=DAILY');
    expect(updated.until, isNull);

    await repo.delete('r1');
    expect(await repo.getAll(), isEmpty);
    expect(await repo.getForTask('t1'), isNull);
    expect(
      (await db.select(db.reminderRules).getSingle()).deletedAt,
      isNotNull,
    );
  });

  test('a rule needs its task (foreign key)', () async {
    expect(repo.upsert(rule('r1', 'missing')), throwsA(anything));
  });

  test('watchAll emits current value then changes', () async {
    final emissions = <int>[];
    final sub = repo.watchAll().listen((l) => emissions.add(l.length));
    await pumpEventQueue();
    await repo.upsert(rule('r1', 't1'));
    await pumpEventQueue();
    await repo.upsert(rule('r2', 't2'));
    await pumpEventQueue();
    await repo.delete('r1');
    await pumpEventQueue();
    await sub.cancel();
    expect(emissions, [0, 1, 2, 1]);
  });
}
