import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/data/connection/memory.dart';
import 'package:grind/core/data/data.dart';
import 'package:grind/core/data/mappers.dart';

class _MemoryGateway implements BackupFileGateway {
  String? savedName;
  String? saved;
  String? toPick;

  @override
  Future<void> save({
    required String fileName,
    required String contents,
  }) async {
    savedName = fileName;
    saved = contents;
  }

  @override
  Future<String?> pick() async => toPick;
}

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
    final tasks = DriftTaskRepository(db, clock: clock);
    await tasks.upsertAll([
      Task(
        id: 't1',
        title: 'Thesis',
        notes: 'ünïcødé ✓',
        goalId: 'g1',
        remindAt: now.add(const Duration(hours: 1)),
        scheduledStart: now.add(const Duration(hours: 2)),
        scheduledEnd: now.add(const Duration(hours: 3)),
        energy: Energy.deep,
        status: TaskStatus.done,
        completedAt: now,
        createdAt: now,
        updatedAt: now,
      ),
      Task(id: 't2', title: 'Gone', createdAt: now, updatedAt: now),
    ]);
    await tasks.delete('t2');
    await DriftReminderRepository(db).upsert(
      ReminderRule(
        id: 'r1',
        taskId: 't1',
        rrule: 'FREQ=DAILY',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await DriftCalendarRepository(db).upsert(
      CalendarEvent(
        id: 'e1',
        source: CalendarSource.apple,
        externalId: 'x1',
        title: 'Lecture',
        start: now,
        end: now.add(const Duration(minutes: 90)),
        isAllDay: true,
        taskId: 't1',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db
        .into(db.goals)
        .insert(
          Goal(
            id: 'g1',
            title: 'Finish MSc',
            horizon: GoalHorizon.year,
            importance: 0.9,
            progress: 0.25,
            createdAt: now,
            updatedAt: now,
          ).toCompanion(),
        );
    await db
        .into(db.focusSessions)
        .insert(
          FocusSession(
            id: 'f1',
            taskId: 't1',
            plannedMinutes: 25,
            startedAt: now,
            endedAt: now.add(const Duration(minutes: 25)),
            completed: true,
            createdAt: now,
            updatedAt: now,
          ).toCompanion(),
        );
    await DriftPreferencesRepository(db, clock: clock).save(
      const Preferences(
        onboardingDone: true,
        localeCode: 'he',
      ).copyWith(quietHours: TimeRange.hm(22, 0, 24, 0)),
    );
  }

  Map<String, Object?> withoutStamp(String json) =>
      (jsonDecode(json) as Map<String, Object?>)..remove('exportedAt');

  test('export -> import round trip is identical', () async {
    await fill(source);
    final exported = await BackupService(source, clock: clock).exportJson();
    final map = jsonDecode(exported) as Map<String, Object?>;
    expect(map['format'], 1);
    expect(map['app'], 'grind');
    expect(map['schemaVersion'], AppDatabase.currentSchemaVersion);
    expect(map['exportedAt'], now.toIso8601String());
    expect((map['tasks'] as List).length, 2, reason: 'tombstones included');

    final summary = await BackupService(
      target,
      clock: clock,
    ).importJson(exported);
    expect(summary.tasks, 2);
    expect(summary.reminderRules, 1);
    expect(summary.calendarEvents, 1);
    expect(summary.focusSessions, 1);
    expect(summary.goals, 1);
    expect(summary.hasPreferences, isTrue);

    final reExported = await BackupService(target, clock: clock).exportJson();
    expect(withoutStamp(reExported), withoutStamp(exported));

    // And through the repository interfaces.
    final tasks = await DriftTaskRepository(target).getAll();
    expect(tasks.map((t) => t.id), ['t1']);
    expect(tasks.single.notes, 'ünïcødé ✓');
    expect(tasks.single.remindAt, now.add(const Duration(hours: 1)));
    expect(
      (await DriftReminderRepository(target).getForTask('t1'))!.rrule,
      'FREQ=DAILY',
    );
    final prefs = await DriftPreferencesRepository(target).get();
    expect(prefs.localeCode, 'he');
    expect(prefs.quietHours, TimeRange.hm(22, 0, 24, 0));
  });

  test('import replaces existing data', () async {
    await fill(source);
    final exported = await BackupService(source).exportJson();
    await DriftTaskRepository(target).upsert(
      Task(id: 'local', title: 'Local only', createdAt: now, updatedAt: now),
    );
    await BackupService(target).importJson(exported);
    final ids = (await target.select(target.tasks).get()).map((r) => r.id);
    expect(ids.toSet(), {'t1', 't2'});
  });

  test('importing an empty backup clears everything', () async {
    await fill(target);
    final empty = await BackupService(source).exportJson();
    await BackupService(target).importJson(empty);
    expect(
      withoutStamp(await BackupService(target).exportJson()),
      withoutStamp(empty),
    );
    expect(
      (await DriftPreferencesRepository(target).get()).onboardingDone,
      isFalse,
    );
  });

  group('invalid files are rejected and change nothing', () {
    Future<void> expectRejected(String json) async {
      await fill(target);
      final before = withoutStamp(await BackupService(target).exportJson());
      await expectLater(
        BackupService(target).importJson(json),
        throwsA(isA<BackupFormatException>()),
      );
      expect(withoutStamp(await BackupService(target).exportJson()), before);
    }

    test('not JSON', () => expectRejected('not json'));
    test('not an object', () => expectRejected('[1, 2]'));
    test('no format', () => expectRejected('{"tasks": []}'));
    test('newer format', () => expectRejected('{"format": 2, "tasks": []}'));
    test(
      'bad row',
      () => expectRejected('{"format": 1, "tasks": [{"id": "x"}]}'),
    );
    test(
      'rule pointing at a missing task',
      () => expectRejected(
        jsonEncode({
          'format': 1,
          'tasks': [],
          'reminderRules': [
            {
              'id': 'r',
              'taskId': 'missing',
              'rrule': 'FREQ=DAILY',
              'createdAt': now.toIso8601String(),
              'updatedAt': now.toIso8601String(),
            },
          ],
        }),
      ),
    );
  });

  test('deleteAllData wipes every table', () async {
    await fill(target);
    await BackupService(target).deleteAllData();
    for (final t in target.allTables) {
      expect(await target.select(t).get(), isEmpty, reason: t.actualTableName);
    }
  });

  test('file gateway: export saves, import picks', () async {
    await fill(source);
    final gateway = _MemoryGateway();
    await BackupService(source, clock: clock).exportToFile(gateway);
    expect(gateway.savedName, 'grind-backup-2026-11-03.json');

    expect(await BackupService(target).importFromFile(gateway), isNull);
    gateway.toPick = gateway.saved;
    final summary = await BackupService(target).importFromFile(gateway);
    expect(summary!.tasks, 2);
  });
}
