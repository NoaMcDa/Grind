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
        lastCompletedAt: now.subtract(const Duration(days: 1)),
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
        htmlLink: 'https://calendar.example/e1',
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
            targetDate: DateTime.utc(2027, 6, 30, 20, 59),
            status: GoalStatus.paused,
            notes: 'Chapter 3 next',
            metricKind: 'finite',
            metricTarget: 12,
            metricUnit: 'chapters',
            metricCurrent: 3,
            metricSource: 'manual',
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
            pausedMs: 90000,
            win: 'Drafted section 2',
            createdAt: now,
            updatedAt: now,
          ).toCompanion(),
        );
    await db
        .into(db.focusSessions)
        .insert(
          FocusSession(
            id: 'f2',
            plannedMinutes: 5,
            startedAt: now.add(const Duration(minutes: 25)),
            pausedAt: now.add(const Duration(minutes: 27)),
            kind: FocusSessionKind.breakTime,
            createdAt: now,
            updatedAt: now,
            deletedAt: now,
          ).toCompanion(),
        );
    await db
        .into(db.reviewEntries)
        .insert(
          ReviewEntriesCompanion.insert(
            date: '2026-11-02',
            win: 'Shipped the draft',
            doneCount: 3,
            movedCount: 1,
            createdAt: now.millisecondsSinceEpoch,
          ),
        );
    await db
        .into(db.reviewHandledDays)
        .insert(ReviewHandledDaysCompanion.insert(date: '2026-11-02'));
    await DriftPreferencesRepository(db, clock: clock).save(
      const Preferences(
        onboardingDone: true,
        localeCode: 'he',
        pipAccessory: 'beanie',
        quietHours: TimeRange.wrapping(
          startMinutes: 22 * 60,
          endMinutes: 7 * 60,
        ),
      ),
    );
  }

  Map<String, Object?> withoutStamp(String json) =>
      (jsonDecode(json) as Map<String, Object?>)..remove('exportedAt');

  test('export -> import round trip is identical', () async {
    await fill(source);
    final exported = await BackupService(source, clock: clock).exportJson();
    final map = jsonDecode(exported) as Map<String, Object?>;
    expect(map['format'], BackupService.format);
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
    expect(summary.focusSessions, 2);
    expect(summary.goals, 1);
    expect(summary.hasPreferences, isTrue);
    expect(summary.reviewEntries, 1);

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
    final rule = (await DriftReminderRepository(target).getForTask('t1'))!;
    expect(rule.lastCompletedAt, now.subtract(const Duration(days: 1)));
    final events = await DriftCalendarRepository(target).getBetween(
      now.subtract(const Duration(days: 1)),
      now.add(const Duration(days: 1)),
    );
    expect(events.single.htmlLink, 'https://calendar.example/e1');
    final prefs = await DriftPreferencesRepository(target).get();
    expect(prefs.localeCode, 'he');
    expect(prefs.pipAccessory, 'beanie');
    expect(prefs.quietHours!.wrapsMidnight, isTrue);
    expect(prefs.quietHours!.endMinutes, 7 * 60);

    final goal = (await target.select(target.goals).getSingle()).toDomain();
    expect(goal.status, GoalStatus.paused);
    expect(goal.targetDate, DateTime.utc(2027, 6, 30, 20, 59));
    expect(goal.notes, 'Chapter 3 next');
    expect(
      (goal.metricKind, goal.metricTarget, goal.metricUnit, goal.metricCurrent),
      ('finite', 12, 'chapters', 3),
    );

    final sessions = [
      for (final r in await target.select(target.focusSessions).get())
        r.toDomain(),
    ]..sort((a, b) => a.id.compareTo(b.id));
    expect(sessions[0].pausedMs, 90000);
    expect(sessions[0].win, 'Drafted section 2');
    expect(sessions[0].kind, FocusSessionKind.focus);
    expect(sessions[1].kind, FocusSessionKind.breakTime);
    expect(sessions[1].pausedAt, now.add(const Duration(minutes: 27)));
    expect(sessions[1].deletedAt, now);

    final review = await target.select(target.reviewEntries).getSingle();
    expect(
      (review.date, review.win, review.doneCount, review.movedCount),
      ('2026-11-02', 'Shipped the draft', 3, 1),
    );
    expect(
      (await target.select(target.reviewHandledDays).get()).map((r) => r.date),
      ['2026-11-02'],
    );
  });

  test('a format 1 backup (schema v2, no v3 fields) still imports', () async {
    final stamp = now.toIso8601String();
    final v1 = jsonEncode({
      'app': 'grind',
      'format': 1,
      'schemaVersion': 2,
      'exportedAt': stamp,
      'tasks': [
        {'id': 't1', 'title': 'Old', 'createdAt': stamp, 'updatedAt': stamp},
      ],
      'reminderRules': [
        {
          'id': 'r1',
          'taskId': 't1',
          'rrule': 'FREQ=DAILY',
          'leadMinutes': 0,
          'until': null,
          'createdAt': stamp,
          'updatedAt': stamp,
          'deletedAt': null,
        },
      ],
      'calendarEvents': [],
      'focusSessions': [
        {
          'id': 'f1',
          'taskId': 't1',
          'plannedMinutes': 25,
          'startedAt': stamp,
          'endedAt': null,
          'completed': false,
          'createdAt': stamp,
          'updatedAt': stamp,
        },
      ],
      'goals': [
        {
          'id': 'g1',
          'title': 'Old goal',
          'area': null,
          'horizon': 'month',
          'importance': 0.5,
          'progress': 0.0,
          'lastProgressAt': null,
          'createdAt': stamp,
          'updatedAt': stamp,
          'deletedAt': null,
        },
      ],
      'preferences': {
        'onboardingDone': true,
        'quietHours': {'start': 1320, 'end': 1440},
      },
    });
    final summary = await BackupService(target).importJson(v1);
    expect(summary.tasks, 1);
    expect(summary.reviewEntries, 0);
    final session = (await target.select(target.focusSessions).getSingle())
        .toDomain();
    expect(
      (session.pausedMs, session.kind, session.win),
      (0, FocusSessionKind.focus, null),
    );
    final goal = (await target.select(target.goals).getSingle()).toDomain();
    expect((goal.status, goal.metricKind), (GoalStatus.active, null));
    final prefs = await DriftPreferencesRepository(target).get();
    expect(prefs.pipAccessory, 'scarf');
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
    Future<void> expectRejected(String json, {String? saying}) async {
      await fill(target);
      final before = withoutStamp(await BackupService(target).exportJson());
      await expectLater(
        BackupService(target).importJson(json),
        throwsA(
          isA<BackupFormatException>().having(
            (e) => e.message,
            'message',
            saying == null ? anything : contains(saying),
          ),
        ),
      );
      expect(withoutStamp(await BackupService(target).exportJson()), before);
    }

    final stamp = now.toIso8601String();
    Map<String, Object?> task([Map<String, Object?> patch = const {}]) => {
      'id': 't',
      'title': 'T',
      'createdAt': stamp,
      'updatedAt': stamp,
      ...patch,
    };
    String backup(Map<String, Object?> lists) =>
        jsonEncode({'format': 2, 'tasks': [], ...lists});
    Map<String, Object?> session([Map<String, Object?> patch = const {}]) => {
      'id': 'f',
      'plannedMinutes': 25,
      'startedAt': stamp,
      'createdAt': stamp,
      'updatedAt': stamp,
      ...patch,
    };

    test('not JSON', () => expectRejected('not json'));
    test('not an object', () => expectRejected('[1, 2]'));
    test('no format', () => expectRejected('{"tasks": []}'));
    test(
      'newer format',
      () => expectRejected('{"format": 99, "tasks": []}', saying: 'newer'),
    );
    final garbage = <String, (Map<String, Object?>, String)>{
      'a row that is not an object': (
        {
          'tasks': ['oops'],
        },
        'tasks[0]',
      ),
      'a field of the wrong type': (
        {
          'tasks': [
            task({'title': 42}),
          ],
        },
        '"title" should be text',
      ),
      'a time that is not a time': (
        {
          'tasks': [
            task({'remindAt': 'tomorrow-ish'}),
          ],
        },
        '"remindAt"',
      ),
      'an unknown enum name': (
        {
          'tasks': [
            task({'energy': 'turbo'}),
          ],
        },
        '"energy" should be one of deep, light',
      ),
      'a negative count': (
        {
          'tasks': [
            task({'snoozeCount': -1}),
          ],
        },
        '"snoozeCount"',
      ),
      'a duplicate id': (
        {
          'tasks': [task(), task()],
        },
        'appears twice',
      ),
      'a focus session pointing at a missing task': (
        {
          'focusSessions': [
            session({'taskId': 'missing'}),
          ],
        },
        'focusSessions[0]: its task "missing" is not in the backup',
      ),
      'an unknown focus session kind': (
        {
          'focusSessions': [
            session({'kind': 'nap'}),
          ],
        },
        '"kind"',
      ),
      'a negative pause': (
        {
          'focusSessions': [
            session({'pausedMs': -5}),
          ],
        },
        '"pausedMs"',
      ),
      'a goal importance outside 0..1': (
        {
          'goals': [
            {
              'id': 'g',
              'title': 'G',
              'importance': 7,
              'createdAt': stamp,
              'updatedAt': stamp,
            },
          ],
        },
        '"importance"',
      ),
      'an unknown goal status': (
        {
          'goals': [
            {
              'id': 'g',
              'title': 'G',
              'status': 'someday',
              'createdAt': stamp,
              'updatedAt': stamp,
            },
          ],
        },
        '"status"',
      ),
      'working hours that end before they start (release skips asserts)': (
        {
          'preferences': {
            'workingHours': {
              '1': [
                {'start': 600, 'end': 540},
              ],
            },
          },
        },
        'workingHours.1[0]',
      ),
      'a time range past midnight': (
        {
          'preferences': {
            'deepWindows': [
              {'start': 540, 'end': 2000},
            ],
          },
        },
        'deepWindows[0]',
      ),
      'a weekday that does not exist': (
        {
          'preferences': {
            'workingHours': {'9': []},
          },
        },
        'workingHours',
      ),
      'quiet hours with equal start and end': (
        {
          'preferences': {
            'quietHours': {'start': 600, 'end': 600},
          },
        },
        'quietHours',
      ),
      'a pip accessory that is not text': (
        {
          'preferences': {'pipAccessory': 3},
        },
        '"pipAccessory"',
      ),
      'a review day that is not a day': (
        {
          'reviewHandledDays': ['yesterday'],
        },
        'reviewHandledDays[0]',
      ),
      'a review entry with a bad count': (
        {
          'reviewEntries': [
            {
              'date': '2026-11-02',
              'win': 'w',
              'doneCount': 'three',
              'createdAt': stamp,
            },
          ],
        },
        '"doneCount"',
      ),
    };
    for (final MapEntry(key: name, value: (lists, saying)) in garbage.entries) {
      test(name, () => expectRejected(backup(lists), saying: saying));
    }
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
