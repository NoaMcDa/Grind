import 'package:drift/drift.dart';

import '../domain/domain.dart'
    show
        CalendarSource,
        Energy,
        FocusSessionKind,
        GoalHorizon,
        GoalStatus,
        TaskStatus;
import '../domain/milestone.dart' show MilestoneStatus;

part 'database.g.dart';

/// Columns every table carries. Times are stored as UTC milliseconds since
/// the epoch (integers), so comparisons in SQL are exact and cheap and the
/// format is identical on iOS (sqlite3 native) and web (sqlite3 wasm).
mixin _Row on Table {
  TextColumn get id => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TaskRow')
@TableIndex(name: 'tasks_remind_at', columns: {#remindAt})
@TableIndex(name: 'tasks_scheduled_start', columns: {#scheduledStart})
class Tasks extends Table with _Row {
  TextColumn get title => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get goalId => text().nullable()();
  IntColumn get dueAt => integer().nullable()();
  IntColumn get remindAt => integer().nullable()();
  IntColumn get scheduledStart => integer().nullable()();
  IntColumn get scheduledEnd => integer().nullable()();
  BoolColumn get lockedStart => boolean().withDefault(const Constant(false))();
  IntColumn get notBefore => integer().nullable()();
  IntColumn get minutesDone => integer().withDefault(const Constant(0))();
  IntColumn get estimatedMinutes => integer().withDefault(const Constant(30))();
  TextColumn get energy =>
      textEnum<Energy>().withDefault(Constant(Energy.light.name))();
  TextColumn get firstAction => text().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(2))();
  TextColumn get category => text().nullable()();
  BoolColumn get splittable => boolean().withDefault(const Constant(false))();
  IntColumn get minChunkMinutes => integer().withDefault(const Constant(25))();
  TextColumn get status =>
      textEnum<TaskStatus>().withDefault(Constant(TaskStatus.open.name))();
  IntColumn get completedAt => integer().nullable()();
  IntColumn get actualMinutes => integer().nullable()();
  IntColumn get snoozeCount => integer().withDefault(const Constant(0))();
  TextColumn get calendarEventId => text().nullable()();
}

@DataClassName('ReminderRuleRow')
@TableIndex(name: 'reminder_rules_task_id', columns: {#taskId})
class ReminderRules extends Table with _Row {
  TextColumn get taskId =>
      text().references(Tasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get rrule => text()();
  IntColumn get leadMinutes => integer().withDefault(const Constant(0))();
  IntColumn get until => integer().nullable()();
  IntColumn get lastCompletedAt => integer().nullable()();
}

@DataClassName('CalendarEventRow')
@TableIndex(name: 'calendar_events_start_at', columns: {#startAt})
@TableIndex(name: 'calendar_events_external', columns: {#source, #externalId})
class CalendarEvents extends Table with _Row {
  TextColumn get source => textEnum<CalendarSource>()();
  TextColumn get externalId => text()();
  TextColumn get calendarId => text().nullable()();
  TextColumn get title => text()();
  IntColumn get startAt => integer()();
  IntColumn get endAt => integer()();
  BoolColumn get isAllDay => boolean().withDefault(const Constant(false))();
  BoolColumn get isBusy => boolean().withDefault(const Constant(true))();

  /// No foreign key: sync may mirror an event before its task exists.
  TextColumn get taskId => text().nullable()();
  TextColumn get htmlLink => text().nullable()();
}

@DataClassName('FocusSessionRow')
class FocusSessions extends Table with _Row {
  TextColumn get taskId =>
      text().nullable().references(Tasks, #id, onDelete: KeyAction.setNull)();
  IntColumn get plannedMinutes => integer()();
  IntColumn get startedAt => integer()();
  IntColumn get endedAt => integer().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  IntColumn get pausedMs => integer().withDefault(const Constant(0))();
  IntColumn get pausedAt => integer().nullable()();
  TextColumn get win => text().nullable()();
  TextColumn get kind => textEnum<FocusSessionKind>().withDefault(
    Constant(FocusSessionKind.focus.name),
  )();
}

@DataClassName('GoalRow')
class Goals extends Table with _Row {
  TextColumn get title => text()();
  TextColumn get area => text().nullable()();
  TextColumn get horizon =>
      textEnum<GoalHorizon>().withDefault(Constant(GoalHorizon.month.name))();
  RealColumn get importance => real().withDefault(const Constant(0.5))();
  RealColumn get progress => real().withDefault(const Constant(0.0))();
  IntColumn get lastProgressAt => integer().nullable()();
  IntColumn get targetDate => integer().nullable()();
  TextColumn get status =>
      textEnum<GoalStatus>().withDefault(Constant(GoalStatus.active.name))();
  TextColumn get notes => text().nullable()();
  TextColumn get metricKind => text().nullable()();
  IntColumn get metricTarget => integer().nullable()();
  TextColumn get metricUnit => text().nullable()();
  IntColumn get metricCurrent => integer().nullable()();
  TextColumn get metricSource => text().nullable()();
  TextColumn get metricPeriod => text().nullable()();
}

/// Steps of a long goal (#25, schema v4). Soft-deleted like goals.
@DataClassName('MilestoneRow')
@TableIndex(name: 'milestones_goal_id', columns: {#goalId})
class Milestones extends Table with _Row {
  TextColumn get goalId =>
      text().references(Goals, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  IntColumn get dueAt => integer().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get status => textEnum<MilestoneStatus>().withDefault(
    Constant(MilestoneStatus.open.name),
  )();
  IntColumn get completedAt => integer().nullable()();
}

/// Which milestone a task is a weekly step of (#25, schema v4). One row per
/// task; removing the link is a hard delete.
@DataClassName('MilestoneTaskRow')
@TableIndex(name: 'milestone_tasks_milestone_id', columns: {#milestoneId})
class MilestoneTasks extends Table {
  TextColumn get taskId =>
      text().references(Tasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get milestoneId =>
      text().references(Milestones, #id, onDelete: KeyAction.cascade)();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {taskId};
}

/// One finished evening review per local day (`yyyy-MM-dd`).
@DataClassName('ReviewEntryRow')
class ReviewEntries extends Table {
  TextColumn get date => text()();
  TextColumn get win => text()();
  IntColumn get doneCount => integer()();
  IntColumn get movedCount => integer()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {date};
}

/// Days whose evening review was shown (finished or skipped).
@DataClassName('ReviewHandledDayRow')
class ReviewHandledDays extends Table {
  TextColumn get date => text()();

  @override
  Set<Column<Object>> get primaryKey => {date};
}

/// The single preferences row (id [PreferencesRows.singletonId]). Maps and
/// lists of [TimeRange] are stored as JSON text.
@DataClassName('PreferencesRow')
class PreferencesTable extends Table with _Row {
  @override
  String get tableName => 'preferences';

  /// JSON: `{"1": [{"start": 540, "end": 1080}], ...}` keyed by weekday.
  TextColumn get workingHours => text()();

  /// JSON: `[{"start": 540, "end": 720}]`.
  TextColumn get deepWindows => text()();
  TextColumn get lunch => text()();
  IntColumn get maxDeepBlocksPerDay => integer()();
  IntColumn get deepBlockMinutes => integer()();
  IntColumn get bufferBetweenEventsMinutes => integer()();
  IntColumn get dailyCushionMinutes => integer()();
  IntColumn get weekStart => integer()();
  IntColumn get defaultReminderLeadMinutes => integer()();

  /// JSON `{"start": .., "end": ..}` or null.
  TextColumn get quietHours => text().nullable()();
  TextColumn get timeZoneName => text()();
  TextColumn get localeCode => text()();
  BoolColumn get onboardingDone => boolean()();
  IntColumn get morningPromptMinutes => integer().nullable()();
  IntColumn get eveningPromptMinutes => integer().nullable()();

  /// JSON: `{"google": ["id", ...], "apple": [...]}`.
  TextColumn get selectedCalendarIds =>
      text().withDefault(const Constant('{}'))();
  BoolColumn get backupHintShown =>
      boolean().withDefault(const Constant(false))();
  TextColumn get pipAccessory => text().withDefault(const Constant('scarf'))();
}

abstract final class PreferencesRows {
  static const singletonId = 'preferences';
}

/// Grind's local database: the permanent home of the user's data.
///
/// Open with a platform connection from `connection/connection.dart`, or
/// `NativeDatabase.memory()` in tests.
@DriftDatabase(
  tables: [
    Tasks,
    ReminderRules,
    CalendarEvents,
    FocusSessions,
    Goals,
    PreferencesTable,
    ReviewEntries,
    ReviewHandledDays,
    Milestones,
    MilestoneTasks,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Bump on every schema change and add a step in [migration].
  static const currentSchemaVersion = 4;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // One `if (from < N)` block per version, in order.
      if (from < 2) {
        await m.addColumn(tasks, tasks.notBefore);
        await m.addColumn(tasks, tasks.minutesDone);
        await m.addColumn(
          preferencesTable,
          preferencesTable.morningPromptMinutes,
        );
        await m.addColumn(
          preferencesTable,
          preferencesTable.eveningPromptMinutes,
        );
        await m.addColumn(
          preferencesTable,
          preferencesTable.selectedCalendarIds,
        );
        await m.addColumn(preferencesTable, preferencesTable.backupHintShown);
      }
      if (from < 3) {
        await m.addColumn(reminderRules, reminderRules.lastCompletedAt);
        await m.addColumn(calendarEvents, calendarEvents.htmlLink);
        await m.addColumn(focusSessions, focusSessions.pausedMs);
        await m.addColumn(focusSessions, focusSessions.pausedAt);
        await m.addColumn(focusSessions, focusSessions.win);
        await m.addColumn(focusSessions, focusSessions.kind);
        await m.addColumn(goals, goals.targetDate);
        await m.addColumn(goals, goals.status);
        await m.addColumn(goals, goals.notes);
        await m.addColumn(goals, goals.metricKind);
        await m.addColumn(goals, goals.metricTarget);
        await m.addColumn(goals, goals.metricUnit);
        await m.addColumn(goals, goals.metricCurrent);
        await m.addColumn(goals, goals.metricSource);
        await m.addColumn(goals, goals.metricPeriod);
        await m.addColumn(preferencesTable, preferencesTable.pipAccessory);
        await m.createTable(reviewEntries);
        await m.createTable(reviewHandledDays);
      }
      if (from < 4) {
        await m.createTable(milestones);
        await m.createTable(milestoneTasks);
        await m.createIndex(milestonesGoalId);
        await m.createIndex(milestoneTasksMilestoneId);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Every table, children first: the order for hard deletes. Reverse it
  /// for inserts.
  List<TableInfo<Table, Object?>> get tablesChildrenFirst => [
    reviewEntries,
    reviewHandledDays,
    milestoneTasks,
    milestones,
    reminderRules,
    focusSessions,
    calendarEvents,
    tasks,
    goals,
    preferencesTable,
  ];
}
