import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/data/connection/memory.dart';
import 'package:grind/core/data/data.dart';
import 'package:grind/core/data/mappers.dart';

/// The schema v2 DDL exactly as Drift created it before v3 (copied from
/// `sqlite_master` of a v2 database). Do not edit: it is the past.
const _v2Schema = [
  'CREATE TABLE "tasks" ("id" TEXT NOT NULL, "created_at" INTEGER NOT NULL, '
      '"updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, '
      '"title" TEXT NOT NULL, "notes" TEXT NULL, "goal_id" TEXT NULL, '
      '"due_at" INTEGER NULL, "remind_at" INTEGER NULL, '
      '"scheduled_start" INTEGER NULL, "scheduled_end" INTEGER NULL, '
      '"locked_start" INTEGER NOT NULL DEFAULT 0 CHECK ("locked_start" IN (0, 1)), '
      '"not_before" INTEGER NULL, "minutes_done" INTEGER NOT NULL DEFAULT 0, '
      '"estimated_minutes" INTEGER NOT NULL DEFAULT 30, '
      '"energy" TEXT NOT NULL DEFAULT \'light\', "first_action" TEXT NULL, '
      '"priority" INTEGER NOT NULL DEFAULT 2, "category" TEXT NULL, '
      '"splittable" INTEGER NOT NULL DEFAULT 0 CHECK ("splittable" IN (0, 1)), '
      '"min_chunk_minutes" INTEGER NOT NULL DEFAULT 25, '
      '"status" TEXT NOT NULL DEFAULT \'open\', "completed_at" INTEGER NULL, '
      '"actual_minutes" INTEGER NULL, '
      '"snooze_count" INTEGER NOT NULL DEFAULT 0, '
      '"calendar_event_id" TEXT NULL, PRIMARY KEY ("id"))',
  'CREATE TABLE "reminder_rules" ("id" TEXT NOT NULL, '
      '"created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, '
      '"deleted_at" INTEGER NULL, '
      '"task_id" TEXT NOT NULL REFERENCES tasks (id) ON DELETE CASCADE, '
      '"rrule" TEXT NOT NULL, "lead_minutes" INTEGER NOT NULL DEFAULT 0, '
      '"until" INTEGER NULL, PRIMARY KEY ("id"))',
  'CREATE TABLE "calendar_events" ("id" TEXT NOT NULL, '
      '"created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, '
      '"deleted_at" INTEGER NULL, "source" TEXT NOT NULL, '
      '"external_id" TEXT NOT NULL, "calendar_id" TEXT NULL, '
      '"title" TEXT NOT NULL, "start_at" INTEGER NOT NULL, '
      '"end_at" INTEGER NOT NULL, '
      '"is_all_day" INTEGER NOT NULL DEFAULT 0 CHECK ("is_all_day" IN (0, 1)), '
      '"is_busy" INTEGER NOT NULL DEFAULT 1 CHECK ("is_busy" IN (0, 1)), '
      '"task_id" TEXT NULL, PRIMARY KEY ("id"))',
  'CREATE TABLE "focus_sessions" ("id" TEXT NOT NULL, '
      '"created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, '
      '"deleted_at" INTEGER NULL, '
      '"task_id" TEXT NULL REFERENCES tasks (id) ON DELETE SET NULL, '
      '"planned_minutes" INTEGER NOT NULL, "started_at" INTEGER NOT NULL, '
      '"ended_at" INTEGER NULL, '
      '"completed" INTEGER NOT NULL DEFAULT 0 CHECK ("completed" IN (0, 1)), '
      'PRIMARY KEY ("id"))',
  'CREATE TABLE "goals" ("id" TEXT NOT NULL, "created_at" INTEGER NOT NULL, '
      '"updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, '
      '"title" TEXT NOT NULL, "area" TEXT NULL, '
      '"horizon" TEXT NOT NULL DEFAULT \'month\', '
      '"importance" REAL NOT NULL DEFAULT 0.5, '
      '"progress" REAL NOT NULL DEFAULT 0.0, '
      '"last_progress_at" INTEGER NULL, PRIMARY KEY ("id"))',
  'CREATE TABLE "preferences" ("id" TEXT NOT NULL, '
      '"created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, '
      '"deleted_at" INTEGER NULL, "working_hours" TEXT NOT NULL, '
      '"deep_windows" TEXT NOT NULL, "lunch" TEXT NOT NULL, '
      '"max_deep_blocks_per_day" INTEGER NOT NULL, '
      '"deep_block_minutes" INTEGER NOT NULL, '
      '"buffer_between_events_minutes" INTEGER NOT NULL, '
      '"daily_cushion_minutes" INTEGER NOT NULL, '
      '"week_start" INTEGER NOT NULL, '
      '"default_reminder_lead_minutes" INTEGER NOT NULL, '
      '"quiet_hours" TEXT NULL, "time_zone_name" TEXT NOT NULL, '
      '"locale_code" TEXT NOT NULL, '
      '"onboarding_done" INTEGER NOT NULL CHECK ("onboarding_done" IN (0, 1)), '
      '"morning_prompt_minutes" INTEGER NULL, '
      '"evening_prompt_minutes" INTEGER NULL, '
      '"selected_calendar_ids" TEXT NOT NULL DEFAULT \'{}\', '
      '"backup_hint_shown" INTEGER NOT NULL DEFAULT 0 '
      'CHECK ("backup_hint_shown" IN (0, 1)), PRIMARY KEY ("id"))',
  'CREATE INDEX tasks_remind_at ON tasks (remind_at)',
  'CREATE INDEX tasks_scheduled_start ON tasks (scheduled_start)',
  'CREATE INDEX reminder_rules_task_id ON reminder_rules (task_id)',
  'CREATE INDEX calendar_events_start_at ON calendar_events (start_at)',
  'CREATE INDEX calendar_events_external ON calendar_events (source, external_id)',
];

/// One row per v2 table, as a v2 build wrote them.
const _v2Rows = [
  "INSERT INTO tasks (id, created_at, updated_at, title) "
      "VALUES ('t1', 1000, 1000, 'Thesis')",
  "INSERT INTO reminder_rules (id, created_at, updated_at, task_id, rrule) "
      "VALUES ('r1', 1000, 1000, 't1', 'FREQ=DAILY')",
  "INSERT INTO calendar_events (id, created_at, updated_at, source, "
      "external_id, title, start_at, end_at) "
      "VALUES ('e1', 1000, 1000, 'google', 'x', 'Lecture', 5000, 9000)",
  "INSERT INTO focus_sessions (id, created_at, updated_at, task_id, "
      "planned_minutes, started_at, ended_at, completed) "
      "VALUES ('f1', 1000, 1000, 't1', 25, 2000, 3000, 1)",
  "INSERT INTO goals (id, created_at, updated_at, title, horizon, "
      "importance, progress) "
      "VALUES ('g1', 1000, 1000, 'Finish MSc', 'year', 0.8, 0.25)",
  "INSERT INTO preferences (id, created_at, updated_at, working_hours, "
      "deep_windows, lunch, max_deep_blocks_per_day, deep_block_minutes, "
      "buffer_between_events_minutes, daily_cushion_minutes, week_start, "
      "default_reminder_lead_minutes, quiet_hours, time_zone_name, "
      "locale_code, onboarding_done) "
      "VALUES ('preferences', 1000, 1000, '{}', '[]', '[]', 2, 90, 10, 60, "
      "7, 0, '{\"start\":1320,\"end\":1440}', 'Asia/Jerusalem', 'he', 1)",
];

AppDatabase _openV2() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(
    NativeDatabase.memory(
      setup: (raw) {
        for (final s in [..._v2Schema, ..._v2Rows]) {
          raw.execute(s);
        }
        raw.execute('PRAGMA user_version = 2');
      },
    ),
  );
}

Future<Map<String, List<String>>> _columns(AppDatabase db) async {
  final tables = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%' ORDER BY name",
      )
      .get();
  return {
    for (final t in tables)
      t.read<String>('name'): [
        for (final c
            in await db
                .customSelect('PRAGMA table_info("${t.read<String>('name')}")')
                .get())
          '${c.read<String>('name')} ${c.read<String>('type')} '
              'notnull=${c.read<int>('notnull')} '
              'default=${c.readNullable<String>('dflt_value')} '
              'pk=${c.read<int>('pk')}',
      ]..sort(),
  };
}

void main() {
  late AppDatabase db;

  setUp(() => db = _openV2());
  tearDown(() => db.close());

  test('v2 -> current: user_version is bumped', () async {
    // Any query opens the database and runs the migration.
    final v = await db.customSelect('PRAGMA user_version').getSingle();
    expect(v.read<int>('user_version'), AppDatabase.currentSchemaVersion);
  });

  test('v2 -> current: the migrated schema equals a fresh one', () async {
    final fresh = openInMemoryDatabase();
    addTearDown(fresh.close);
    expect(await _columns(db), await _columns(fresh));
  });

  test('v2 -> v3: old rows survive with the new defaults', () async {
    final task = (await DriftTaskRepository(db).getById('t1'))!;
    expect(task.title, 'Thesis');

    final rule = (await DriftReminderRepository(db).getForTask('t1'))!;
    expect(rule.rrule, 'FREQ=DAILY');
    expect(rule.lastCompletedAt, isNull);

    final event = (await db.select(db.calendarEvents).getSingle()).toDomain();
    expect(event.title, 'Lecture');
    expect(event.htmlLink, isNull);

    final session = (await db.select(db.focusSessions).getSingle()).toDomain();
    expect(session.completed, isTrue);
    expect(session.pausedMs, 0);
    expect(session.pausedAt, isNull);
    expect(session.win, isNull);
    expect(session.kind, FocusSessionKind.focus);

    final goal = (await db.select(db.goals).getSingle()).toDomain();
    expect(goal.title, 'Finish MSc');
    expect(goal.horizon, GoalHorizon.year);
    expect(goal.status, GoalStatus.active);
    expect(goal.targetDate, isNull);
    expect(goal.metricKind, isNull);

    final prefs = await DriftPreferencesRepository(db).get();
    expect(prefs.localeCode, 'he');
    expect(prefs.onboardingDone, isTrue);
    expect(prefs.quietHours, TimeRange.hm(22, 0, 24, 0));
    expect(prefs.pipAccessory, 'scarf');

    expect(await db.select(db.reviewEntries).get(), isEmpty);
    expect(await db.select(db.reviewHandledDays).get(), isEmpty);
  });

  test('v2 -> v3: the new columns and tables take writes', () async {
    await db
        .into(db.reviewHandledDays)
        .insert(ReviewHandledDaysCompanion.insert(date: '2026-11-02'));
    await (db.update(db.goals)..where((g) => g.id.equals('g1'))).write(
      GoalsCompanion(
        status: const Value(GoalStatus.done),
        metricKind: const Value('finite'),
        metricTarget: const Value(12),
      ),
    );
    final goal = (await db.select(db.goals).getSingle()).toDomain();
    expect((goal.status, goal.metricTarget), (GoalStatus.done, 12));
    expect(
      (await db.select(db.reviewHandledDays).getSingle()).date,
      '2026-11-02',
    );
  });
}
