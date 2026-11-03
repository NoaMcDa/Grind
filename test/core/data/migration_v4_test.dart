import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/data/connection/memory.dart';
import 'package:grind/core/data/data.dart';
import 'package:grind/core/data/mappers.dart';

/// The schema v3 DDL exactly as Drift created it before v4 (copied from
/// `sqlite_master` of a v3 database). Do not edit: it is the past.
const _v3Schema = [
  'CREATE TABLE "calendar_events" ("id" TEXT NOT NULL, '
      '"created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, '
      '"deleted_at" INTEGER NULL, "source" TEXT NOT NULL, '
      '"external_id" TEXT NOT NULL, "calendar_id" TEXT NULL, '
      '"title" TEXT NOT NULL, "start_at" INTEGER NOT NULL, '
      '"end_at" INTEGER NOT NULL, '
      '"is_all_day" INTEGER NOT NULL DEFAULT 0 CHECK ("is_all_day" IN (0, 1)), '
      '"is_busy" INTEGER NOT NULL DEFAULT 1 CHECK ("is_busy" IN (0, 1)), '
      '"task_id" TEXT NULL, "html_link" TEXT NULL, PRIMARY KEY ("id"))',
  'CREATE TABLE "focus_sessions" ("id" TEXT NOT NULL, '
      '"created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, '
      '"deleted_at" INTEGER NULL, '
      '"task_id" TEXT NULL REFERENCES tasks (id) ON DELETE SET NULL, '
      '"planned_minutes" INTEGER NOT NULL, "started_at" INTEGER NOT NULL, '
      '"ended_at" INTEGER NULL, '
      '"completed" INTEGER NOT NULL DEFAULT 0 CHECK ("completed" IN (0, 1)), '
      '"paused_ms" INTEGER NOT NULL DEFAULT 0, "paused_at" INTEGER NULL, '
      '"win" TEXT NULL, "kind" TEXT NOT NULL DEFAULT \'focus\', '
      'PRIMARY KEY ("id"))',
  'CREATE TABLE "goals" ("id" TEXT NOT NULL, "created_at" INTEGER NOT NULL, '
      '"updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, '
      '"title" TEXT NOT NULL, "area" TEXT NULL, '
      '"horizon" TEXT NOT NULL DEFAULT \'month\', '
      '"importance" REAL NOT NULL DEFAULT 0.5, '
      '"progress" REAL NOT NULL DEFAULT 0.0, '
      '"last_progress_at" INTEGER NULL, "target_date" INTEGER NULL, '
      '"status" TEXT NOT NULL DEFAULT \'active\', "notes" TEXT NULL, '
      '"metric_kind" TEXT NULL, "metric_target" INTEGER NULL, '
      '"metric_unit" TEXT NULL, "metric_current" INTEGER NULL, '
      '"metric_source" TEXT NULL, "metric_period" TEXT NULL, '
      'PRIMARY KEY ("id"))',
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
      'CHECK ("backup_hint_shown" IN (0, 1)), '
      '"pip_accessory" TEXT NOT NULL DEFAULT \'scarf\', PRIMARY KEY ("id"))',
  'CREATE TABLE "reminder_rules" ("id" TEXT NOT NULL, '
      '"created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, '
      '"deleted_at" INTEGER NULL, '
      '"task_id" TEXT NOT NULL REFERENCES tasks (id) ON DELETE CASCADE, '
      '"rrule" TEXT NOT NULL, "lead_minutes" INTEGER NOT NULL DEFAULT 0, '
      '"until" INTEGER NULL, "last_completed_at" INTEGER NULL, '
      'PRIMARY KEY ("id"))',
  'CREATE TABLE "review_entries" ("date" TEXT NOT NULL, '
      '"win" TEXT NOT NULL, "done_count" INTEGER NOT NULL, '
      '"moved_count" INTEGER NOT NULL, "created_at" INTEGER NOT NULL, '
      'PRIMARY KEY ("date"))',
  'CREATE TABLE "review_handled_days" ("date" TEXT NOT NULL, '
      'PRIMARY KEY ("date"))',
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
  'CREATE INDEX calendar_events_external ON calendar_events (source, external_id)',
  'CREATE INDEX calendar_events_start_at ON calendar_events (start_at)',
  'CREATE INDEX reminder_rules_task_id ON reminder_rules (task_id)',
  'CREATE INDEX tasks_remind_at ON tasks (remind_at)',
  'CREATE INDEX tasks_scheduled_start ON tasks (scheduled_start)',
];

const _v3Rows = [
  "INSERT INTO tasks (id, created_at, updated_at, title, goal_id) "
      "VALUES ('t1', 1000, 1000, 'Watch lesson 7', 'g1')",
  "INSERT INTO goals (id, created_at, updated_at, title, horizon, status) "
      "VALUES ('g1', 1000, 1000, 'Finish the PM course', 'year', 'active')",
];

AppDatabase _openV3() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(
    NativeDatabase.memory(
      setup: (raw) {
        for (final s in [..._v3Schema, ..._v3Rows]) {
          raw.execute(s);
        }
        raw.execute('PRAGMA user_version = 3');
      },
    ),
  );
}

/// Table columns and every index, as SQLite reports them.
Future<Map<String, Object>> _shape(AppDatabase db) async {
  final tables = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%' ORDER BY name",
      )
      .get();
  final indexes = await db
      .customSelect(
        "SELECT name, tbl_name FROM sqlite_master WHERE type = 'index' "
        "AND name NOT LIKE 'sqlite_%' ORDER BY name",
      )
      .get();
  final out = <String, Object>{
    'indexes': [
      for (final i in indexes)
        '${i.read<String>('name')} on ${i.read<String>('tbl_name')}',
    ],
  };
  for (final t in tables) {
    final name = t.read<String>('name');
    out[name] = [
      for (final c in await db.customSelect('PRAGMA table_info("$name")').get())
        '${c.read<String>('name')} ${c.read<String>('type')} '
            'notnull=${c.read<int>('notnull')} '
            'default=${c.readNullable<String>('dflt_value')} '
            'pk=${c.read<int>('pk')}',
    ]..sort();
    out['$name fks'] = [
      for (final f
          in await db.customSelect('PRAGMA foreign_key_list("$name")').get())
        '${f.read<String>('from')} -> ${f.read<String>('table')}'
            '.${f.read<String>('to')} on delete ${f.read<String>('on_delete')}',
    ]..sort();
  }
  return out;
}

void main() {
  late AppDatabase db;

  setUp(() => db = _openV3());
  tearDown(() => db.close());

  test('v3 -> v4: user_version is bumped', () async {
    final v = await db.customSelect('PRAGMA user_version').getSingle();
    expect(v.read<int>('user_version'), 4);
  });

  test('v3 -> v4: the migrated schema equals a fresh v4 schema', () async {
    final fresh = openInMemoryDatabase();
    addTearDown(fresh.close);
    expect(await _shape(db), await _shape(fresh));
  });

  test('v3 -> v4: old rows survive and milestones start empty', () async {
    final task = (await DriftTaskRepository(db).getById('t1'))!;
    expect((task.title, task.goalId), ('Watch lesson 7', 'g1'));
    final goal = (await db.select(db.goals).getSingle()).toDomain();
    expect(goal.title, 'Finish the PM course');
    expect(await db.select(db.milestones).get(), isEmpty);
    expect(await db.select(db.milestoneTasks).get(), isEmpty);
  });

  test('v3 -> v4: the new tables take writes and keep their keys', () async {
    final t0 = DateTime.utc(2026, 11, 3);
    await db
        .into(db.milestones)
        .insert(
          Milestone(
            id: 'm1',
            goalId: 'g1',
            title: 'Module 3',
            dueAt: DateTime.utc(2026, 12, 1, 21, 59),
            createdAt: t0,
            updatedAt: t0,
          ).toCompanion(),
        );
    await db
        .into(db.milestoneTasks)
        .insert(
          MilestoneTaskLink(
            taskId: 't1',
            milestoneId: 'm1',
            createdAt: t0,
          ).toCompanion(),
        );
    final m = (await db.select(db.milestones).getSingle()).toDomain();
    expect(
      (m.title, m.status, m.sortOrder),
      ('Module 3', MilestoneStatus.open, 0),
    );
    expect((await db.select(db.milestoneTasks).getSingle()).taskId, 't1');

    // A milestone of an unknown goal is refused (foreign keys are on).
    await expectLater(
      db
          .into(db.milestones)
          .insert(
            Milestone(
              id: 'm2',
              goalId: 'nope',
              title: 'Orphan',
              createdAt: t0,
              updatedAt: t0,
            ).toCompanion(),
          ),
      throwsA(isA<Exception>()),
    );
  });
}
