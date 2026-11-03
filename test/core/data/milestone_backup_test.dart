import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/data/connection/memory.dart';
import 'package:grind/core/data/data.dart';
import 'package:grind/core/data/mappers.dart';

void main() {
  final now = DateTime.utc(2026, 11, 3, 8, 30, 15, 123);
  final clock = FixedClock(now);
  late AppDatabase source;
  late AppDatabase target;

  setUp(() {
    source = openInMemoryDatabase();
    target = openInMemoryDatabase();
  });
  tearDown(() async {
    await source.close();
    await target.close();
  });

  Future<void> fill(AppDatabase db) async {
    await db
        .into(db.goals)
        .insert(
          Goal(
            id: 'g1',
            title: 'PM course',
            createdAt: now,
            updatedAt: now,
          ).toCompanion(),
        );
    await DriftTaskRepository(db, clock: clock).upsertAll([
      Task(
        id: 't1',
        title: 'Lesson 7',
        goalId: 'g1',
        createdAt: now,
        updatedAt: now,
      ),
      Task(
        id: 't2',
        title: 'Lesson 8',
        goalId: 'g1',
        createdAt: now,
        updatedAt: now,
      ),
    ]);
    for (final m in [
      Milestone(
        id: 'm1',
        goalId: 'g1',
        title: 'Module 3',
        dueAt: DateTime.utc(2026, 12, 1, 21, 59),
        status: MilestoneStatus.done,
        completedAt: now,
        createdAt: now,
        updatedAt: now,
      ),
      Milestone(
        id: 'm2',
        goalId: 'g1',
        title: 'Module 4',
        sortOrder: 1,
        createdAt: now,
        updatedAt: now,
        deletedAt: now,
      ),
    ]) {
      await db.into(db.milestones).insert(m.toCompanion());
    }
    await db
        .into(db.milestoneTasks)
        .insert(
          MilestoneTaskLink(
            taskId: 't1',
            milestoneId: 'm1',
            createdAt: now,
          ).toCompanion(),
        );
  }

  Map<String, Object?> withoutStamp(String json) =>
      (jsonDecode(json) as Map<String, Object?>)..remove('exportedAt');

  test('milestones and their task links round-trip', () async {
    await fill(source);
    final exported = await BackupService(source, clock: clock).exportJson();
    final map = jsonDecode(exported) as Map<String, Object?>;
    expect(map['format'], 3);
    expect((map['milestones'] as List).length, 2, reason: 'tombstones too');
    expect(map['milestoneTasks'], [
      {'taskId': 't1', 'milestoneId': 'm1', 'createdAt': now.toIso8601String()},
    ]);

    final summary = await BackupService(
      target,
      clock: clock,
    ).importJson(exported);
    expect(summary.milestones, 2);
    final reExported = await BackupService(target, clock: clock).exportJson();
    expect(withoutStamp(reExported), withoutStamp(exported));

    final m1 = (await target.select(target.milestones).get())
        .map((r) => r.toDomain())
        .firstWhere((m) => m.id == 'm1');
    expect(m1.status, MilestoneStatus.done);
    expect(m1.dueAt, DateTime.utc(2026, 12, 1, 21, 59));
  });

  test('a format 2 backup imports with no milestones', () async {
    final summary = await BackupService(target, clock: clock).importJson(
      jsonEncode({'format': 2, 'schemaVersion': 3, 'tasks': [], 'goals': []}),
    );
    expect(summary.milestones, 0);
    expect(await target.select(target.milestones).get(), isEmpty);
  });

  test('delete all data removes milestones and links', () async {
    await fill(source);
    await BackupService(source, clock: clock).deleteAllData();
    expect(await source.select(source.milestones).get(), isEmpty);
    expect(await source.select(source.milestoneTasks).get(), isEmpty);
  });

  group('rejects', () {
    final stamp = now.toIso8601String();
    Future<void> expectRejected(Map<String, Object?> lists, String saying) =>
        expectLater(
          BackupService(target, clock: clock).importJson(
            jsonEncode({'format': 3, 'tasks': [], 'goals': [], ...lists}),
          ),
          throwsA(
            isA<BackupFormatException>().having(
              (e) => e.message,
              'message',
              contains(saying),
            ),
          ),
        );

    Map<String, Object?> milestone(String goalId) => {
      'id': 'm',
      'goalId': goalId,
      'title': 'M',
      'createdAt': stamp,
      'updatedAt': stamp,
    };

    test(
      'a milestone of a goal not in the file',
      () => expectRejected({
        'milestones': [milestone('nope')],
      }, 'milestones[0]: its goal "nope"'),
    );

    test(
      'an unknown milestone status',
      () => expectRejected({
        'goals': [
          {'id': 'g', 'title': 'G', 'createdAt': stamp, 'updatedAt': stamp},
        ],
        'milestones': [
          {...milestone('g'), 'status': 'missed'},
        ],
      }, 'milestones[0]'),
    );

    test(
      'a link to a milestone not in the file',
      () => expectRejected({
        'tasks': [
          {'id': 't', 'title': 'T', 'createdAt': stamp, 'updatedAt': stamp},
        ],
        'milestoneTasks': [
          {'taskId': 't', 'milestoneId': 'm9', 'createdAt': stamp},
        ],
      }, 'milestoneTasks[0]: its milestone "m9"'),
    );

    test(
      'a link to a task not in the file',
      () => expectRejected({
        'milestoneTasks': [
          {'taskId': 't9', 'milestoneId': 'm', 'createdAt': stamp},
        ],
      }, 'milestoneTasks[0]: its task "t9"'),
    );
  });
}
