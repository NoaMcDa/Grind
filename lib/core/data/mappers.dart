import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/domain.dart';
import 'database.dart';

/// Mapping between Drift rows, domain objects and the backup JSON.
///
/// Storage format: times are UTC milliseconds since the epoch. Reading
/// always yields UTC [DateTime]s; sub-millisecond precision is dropped.
/// Backup JSON: times are ISO-8601 UTC strings, enums are their `name`.

// ---------------------------------------------------------------- time

int toMillis(DateTime t) => t.millisecondsSinceEpoch;
int? toMillisOrNull(DateTime? t) => t?.millisecondsSinceEpoch;
DateTime fromMillis(int ms) =>
    DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
DateTime? fromMillisOrNull(int? ms) => ms == null ? null : fromMillis(ms);

String _iso(DateTime t) => t.toUtc().toIso8601String();
String? _isoOrNull(DateTime? t) => t == null ? null : _iso(t);

/// Parses and normalises to UTC at millisecond precision (the storage
/// precision), so an imported value equals the value read back.
DateTime _parse(Object? v) {
  final t = DateTime.parse(v as String).toUtc();
  return fromMillis(t.millisecondsSinceEpoch);
}

DateTime? _parseOrNull(Object? v) => v == null ? null : _parse(v);

T _enum<T extends Enum>(List<T> values, Object? name) =>
    values.firstWhere((e) => e.name == name);

// ---------------------------------------------------------------- Task

extension TaskRowMapper on TaskRow {
  Task toDomain() => Task(
    id: id,
    title: title,
    notes: notes,
    goalId: goalId,
    dueAt: fromMillisOrNull(dueAt),
    remindAt: fromMillisOrNull(remindAt),
    scheduledStart: fromMillisOrNull(scheduledStart),
    scheduledEnd: fromMillisOrNull(scheduledEnd),
    lockedStart: lockedStart,
    estimatedMinutes: estimatedMinutes,
    energy: energy,
    firstAction: firstAction,
    priority: priority,
    category: category,
    splittable: splittable,
    minChunkMinutes: minChunkMinutes,
    status: status,
    completedAt: fromMillisOrNull(completedAt),
    actualMinutes: actualMinutes,
    snoozeCount: snoozeCount,
    calendarEventId: calendarEventId,
    createdAt: fromMillis(createdAt),
    updatedAt: fromMillis(updatedAt),
    deletedAt: fromMillisOrNull(deletedAt),
  );
}

extension TaskMapper on Task {
  TasksCompanion toCompanion() => TasksCompanion.insert(
    id: id,
    title: title,
    notes: Value(notes),
    goalId: Value(goalId),
    dueAt: Value(toMillisOrNull(dueAt)),
    remindAt: Value(toMillisOrNull(remindAt)),
    scheduledStart: Value(toMillisOrNull(scheduledStart)),
    scheduledEnd: Value(toMillisOrNull(scheduledEnd)),
    lockedStart: Value(lockedStart),
    estimatedMinutes: Value(estimatedMinutes),
    energy: Value(energy),
    firstAction: Value(firstAction),
    priority: Value(priority),
    category: Value(category),
    splittable: Value(splittable),
    minChunkMinutes: Value(minChunkMinutes),
    status: Value(status),
    completedAt: Value(toMillisOrNull(completedAt)),
    actualMinutes: Value(actualMinutes),
    snoozeCount: Value(snoozeCount),
    calendarEventId: Value(calendarEventId),
    createdAt: toMillis(createdAt),
    updatedAt: toMillis(updatedAt),
    deletedAt: Value(toMillisOrNull(deletedAt)),
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'notes': notes,
    'goalId': goalId,
    'dueAt': _isoOrNull(dueAt),
    'remindAt': _isoOrNull(remindAt),
    'scheduledStart': _isoOrNull(scheduledStart),
    'scheduledEnd': _isoOrNull(scheduledEnd),
    'lockedStart': lockedStart,
    'estimatedMinutes': estimatedMinutes,
    'energy': energy.name,
    'firstAction': firstAction,
    'priority': priority,
    'category': category,
    'splittable': splittable,
    'minChunkMinutes': minChunkMinutes,
    'status': status.name,
    'completedAt': _isoOrNull(completedAt),
    'actualMinutes': actualMinutes,
    'snoozeCount': snoozeCount,
    'calendarEventId': calendarEventId,
    'createdAt': _iso(createdAt),
    'updatedAt': _iso(updatedAt),
    'deletedAt': _isoOrNull(deletedAt),
  };
}

Task taskFromJson(Map<String, Object?> j) => Task(
  id: j['id'] as String,
  title: j['title'] as String,
  notes: j['notes'] as String?,
  goalId: j['goalId'] as String?,
  dueAt: _parseOrNull(j['dueAt']),
  remindAt: _parseOrNull(j['remindAt']),
  scheduledStart: _parseOrNull(j['scheduledStart']),
  scheduledEnd: _parseOrNull(j['scheduledEnd']),
  lockedStart: j['lockedStart'] as bool? ?? false,
  estimatedMinutes: j['estimatedMinutes'] as int? ?? 30,
  energy: _enum(Energy.values, j['energy'] ?? Energy.light.name),
  firstAction: j['firstAction'] as String?,
  priority: j['priority'] as int? ?? 2,
  category: j['category'] as String?,
  splittable: j['splittable'] as bool? ?? false,
  minChunkMinutes: j['minChunkMinutes'] as int? ?? 25,
  status: _enum(TaskStatus.values, j['status'] ?? TaskStatus.open.name),
  completedAt: _parseOrNull(j['completedAt']),
  actualMinutes: j['actualMinutes'] as int?,
  snoozeCount: j['snoozeCount'] as int? ?? 0,
  calendarEventId: j['calendarEventId'] as String?,
  createdAt: _parse(j['createdAt']),
  updatedAt: _parse(j['updatedAt']),
  deletedAt: _parseOrNull(j['deletedAt']),
);

// ---------------------------------------------------------------- ReminderRule

extension ReminderRuleRowMapper on ReminderRuleRow {
  ReminderRule toDomain() => ReminderRule(
    id: id,
    taskId: taskId,
    rrule: rrule,
    leadMinutes: leadMinutes,
    until: fromMillisOrNull(until),
    createdAt: fromMillis(createdAt),
    updatedAt: fromMillis(updatedAt),
    deletedAt: fromMillisOrNull(deletedAt),
  );
}

extension ReminderRuleMapper on ReminderRule {
  ReminderRulesCompanion toCompanion() => ReminderRulesCompanion.insert(
    id: id,
    taskId: taskId,
    rrule: rrule,
    leadMinutes: Value(leadMinutes),
    until: Value(toMillisOrNull(until)),
    createdAt: toMillis(createdAt),
    updatedAt: toMillis(updatedAt),
    deletedAt: Value(toMillisOrNull(deletedAt)),
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'taskId': taskId,
    'rrule': rrule,
    'leadMinutes': leadMinutes,
    'until': _isoOrNull(until),
    'createdAt': _iso(createdAt),
    'updatedAt': _iso(updatedAt),
    'deletedAt': _isoOrNull(deletedAt),
  };
}

ReminderRule reminderRuleFromJson(Map<String, Object?> j) => ReminderRule(
  id: j['id'] as String,
  taskId: j['taskId'] as String,
  rrule: j['rrule'] as String,
  leadMinutes: j['leadMinutes'] as int? ?? 0,
  until: _parseOrNull(j['until']),
  createdAt: _parse(j['createdAt']),
  updatedAt: _parse(j['updatedAt']),
  deletedAt: _parseOrNull(j['deletedAt']),
);

// ---------------------------------------------------------------- CalendarEvent

extension CalendarEventRowMapper on CalendarEventRow {
  CalendarEvent toDomain() => CalendarEvent(
    id: id,
    source: source,
    externalId: externalId,
    calendarId: calendarId,
    title: title,
    start: fromMillis(startAt),
    end: fromMillis(endAt),
    isAllDay: isAllDay,
    isBusy: isBusy,
    taskId: taskId,
    createdAt: fromMillis(createdAt),
    updatedAt: fromMillis(updatedAt),
    deletedAt: fromMillisOrNull(deletedAt),
  );
}

extension CalendarEventMapper on CalendarEvent {
  CalendarEventsCompanion toCompanion() => CalendarEventsCompanion.insert(
    id: id,
    source: source,
    externalId: externalId,
    calendarId: Value(calendarId),
    title: title,
    startAt: toMillis(start),
    endAt: toMillis(end),
    isAllDay: Value(isAllDay),
    isBusy: Value(isBusy),
    taskId: Value(taskId),
    createdAt: toMillis(createdAt),
    updatedAt: toMillis(updatedAt),
    deletedAt: Value(toMillisOrNull(deletedAt)),
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'source': source.name,
    'externalId': externalId,
    'calendarId': calendarId,
    'title': title,
    'start': _iso(start),
    'end': _iso(end),
    'isAllDay': isAllDay,
    'isBusy': isBusy,
    'taskId': taskId,
    'createdAt': _iso(createdAt),
    'updatedAt': _iso(updatedAt),
    'deletedAt': _isoOrNull(deletedAt),
  };
}

CalendarEvent calendarEventFromJson(Map<String, Object?> j) => CalendarEvent(
  id: j['id'] as String,
  source: _enum(CalendarSource.values, j['source']),
  externalId: j['externalId'] as String,
  calendarId: j['calendarId'] as String?,
  title: j['title'] as String,
  start: _parse(j['start']),
  end: _parse(j['end']),
  isAllDay: j['isAllDay'] as bool? ?? false,
  isBusy: j['isBusy'] as bool? ?? true,
  taskId: j['taskId'] as String?,
  createdAt: _parse(j['createdAt']),
  updatedAt: _parse(j['updatedAt']),
  deletedAt: _parseOrNull(j['deletedAt']),
);

// ---------------------------------------------------------------- FocusSession

extension FocusSessionRowMapper on FocusSessionRow {
  FocusSession toDomain() => FocusSession(
    id: id,
    taskId: taskId,
    plannedMinutes: plannedMinutes,
    startedAt: fromMillis(startedAt),
    endedAt: fromMillisOrNull(endedAt),
    completed: completed,
    createdAt: fromMillis(createdAt),
    updatedAt: fromMillis(updatedAt),
  );
}

extension FocusSessionMapper on FocusSession {
  /// [FocusSession] has no `deletedAt` yet; the column stays null.
  FocusSessionsCompanion toCompanion() => FocusSessionsCompanion.insert(
    id: id,
    taskId: Value(taskId),
    plannedMinutes: plannedMinutes,
    startedAt: toMillis(startedAt),
    endedAt: Value(toMillisOrNull(endedAt)),
    completed: Value(completed),
    createdAt: toMillis(createdAt),
    updatedAt: toMillis(updatedAt),
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'taskId': taskId,
    'plannedMinutes': plannedMinutes,
    'startedAt': _iso(startedAt),
    'endedAt': _isoOrNull(endedAt),
    'completed': completed,
    'createdAt': _iso(createdAt),
    'updatedAt': _iso(updatedAt),
  };
}

FocusSession focusSessionFromJson(Map<String, Object?> j) => FocusSession(
  id: j['id'] as String,
  taskId: j['taskId'] as String?,
  plannedMinutes: j['plannedMinutes'] as int,
  startedAt: _parse(j['startedAt']),
  endedAt: _parseOrNull(j['endedAt']),
  completed: j['completed'] as bool? ?? false,
  createdAt: _parse(j['createdAt']),
  updatedAt: _parse(j['updatedAt']),
);

// ---------------------------------------------------------------- Goal

extension GoalRowMapper on GoalRow {
  Goal toDomain() => Goal(
    id: id,
    title: title,
    area: area,
    horizon: horizon,
    importance: importance,
    progress: progress,
    lastProgressAt: fromMillisOrNull(lastProgressAt),
    createdAt: fromMillis(createdAt),
    updatedAt: fromMillis(updatedAt),
    deletedAt: fromMillisOrNull(deletedAt),
  );
}

extension GoalMapper on Goal {
  GoalsCompanion toCompanion() => GoalsCompanion.insert(
    id: id,
    title: title,
    area: Value(area),
    horizon: Value(horizon),
    importance: Value(importance),
    progress: Value(progress),
    lastProgressAt: Value(toMillisOrNull(lastProgressAt)),
    createdAt: toMillis(createdAt),
    updatedAt: toMillis(updatedAt),
    deletedAt: Value(toMillisOrNull(deletedAt)),
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'area': area,
    'horizon': horizon.name,
    'importance': importance,
    'progress': progress,
    'lastProgressAt': _isoOrNull(lastProgressAt),
    'createdAt': _iso(createdAt),
    'updatedAt': _iso(updatedAt),
    'deletedAt': _isoOrNull(deletedAt),
  };
}

Goal goalFromJson(Map<String, Object?> j) => Goal(
  id: j['id'] as String,
  title: j['title'] as String,
  area: j['area'] as String?,
  horizon: _enum(GoalHorizon.values, j['horizon'] ?? GoalHorizon.month.name),
  importance: (j['importance'] as num?)?.toDouble() ?? 0.5,
  progress: (j['progress'] as num?)?.toDouble() ?? 0,
  lastProgressAt: _parseOrNull(j['lastProgressAt']),
  createdAt: _parse(j['createdAt']),
  updatedAt: _parse(j['updatedAt']),
  deletedAt: _parseOrNull(j['deletedAt']),
);

// ---------------------------------------------------------------- Preferences

List<Map<String, Object?>> _rangesToJson(List<TimeRange> ranges) => [
  for (final r in ranges) r.toJson(),
];

List<TimeRange> _rangesFromJson(Object? json) => [
  for (final r in json as List) TimeRange.fromJson(_map(r)),
];

Map<String, Object?> _workingHoursToJson(Map<int, List<TimeRange>> wh) => {
  for (final e in wh.entries) '${e.key}': _rangesToJson(e.value),
};

Map<int, List<TimeRange>> _workingHoursFromJson(Object? json) => {
  for (final e in _map(json).entries)
    int.parse(e.key): _rangesFromJson(e.value),
};

Map<String, Object?> _map(Object? v) => (v as Map).cast<String, Object?>();

extension PreferencesRowMapper on PreferencesRow {
  Preferences toDomain() => Preferences(
    workingHours: _workingHoursFromJson(jsonDecode(workingHours)),
    deepWindows: _rangesFromJson(jsonDecode(deepWindows)),
    lunch: _rangesFromJson(jsonDecode(lunch)),
    maxDeepBlocksPerDay: maxDeepBlocksPerDay,
    deepBlockMinutes: deepBlockMinutes,
    bufferBetweenEventsMinutes: bufferBetweenEventsMinutes,
    dailyCushionMinutes: dailyCushionMinutes,
    weekStart: weekStart,
    defaultReminderLeadMinutes: defaultReminderLeadMinutes,
    quietHours: quietHours == null
        ? null
        : TimeRange.fromJson(_map(jsonDecode(quietHours!))),
    timeZoneName: timeZoneName,
    localeCode: localeCode,
    onboardingDone: onboardingDone,
  );
}

extension PreferencesMapper on Preferences {
  PreferencesTableCompanion toCompanion({
    required DateTime createdAt,
    required DateTime updatedAt,
  }) => PreferencesTableCompanion.insert(
    id: PreferencesRows.singletonId,
    workingHours: jsonEncode(_workingHoursToJson(workingHours)),
    deepWindows: jsonEncode(_rangesToJson(deepWindows)),
    lunch: jsonEncode(_rangesToJson(lunch)),
    maxDeepBlocksPerDay: maxDeepBlocksPerDay,
    deepBlockMinutes: deepBlockMinutes,
    bufferBetweenEventsMinutes: bufferBetweenEventsMinutes,
    dailyCushionMinutes: dailyCushionMinutes,
    weekStart: weekStart,
    defaultReminderLeadMinutes: defaultReminderLeadMinutes,
    quietHours: Value(
      quietHours == null ? null : jsonEncode(quietHours!.toJson()),
    ),
    timeZoneName: timeZoneName,
    localeCode: localeCode,
    onboardingDone: onboardingDone,
    createdAt: toMillis(createdAt),
    updatedAt: toMillis(updatedAt),
  );

  Map<String, Object?> toJson() => {
    'workingHours': _workingHoursToJson(workingHours),
    'deepWindows': _rangesToJson(deepWindows),
    'lunch': _rangesToJson(lunch),
    'maxDeepBlocksPerDay': maxDeepBlocksPerDay,
    'deepBlockMinutes': deepBlockMinutes,
    'bufferBetweenEventsMinutes': bufferBetweenEventsMinutes,
    'dailyCushionMinutes': dailyCushionMinutes,
    'weekStart': weekStart,
    'defaultReminderLeadMinutes': defaultReminderLeadMinutes,
    'quietHours': quietHours?.toJson(),
    'timeZoneName': timeZoneName,
    'localeCode': localeCode,
    'onboardingDone': onboardingDone,
  };
}

/// Missing keys fall back to the [Preferences] defaults, so older backups
/// keep importing when fields are added.
Preferences preferencesFromJson(Map<String, Object?> j) {
  const d = Preferences();
  return Preferences(
    workingHours: j.containsKey('workingHours')
        ? _workingHoursFromJson(j['workingHours'])
        : d.workingHours,
    deepWindows: j.containsKey('deepWindows')
        ? _rangesFromJson(j['deepWindows'])
        : d.deepWindows,
    lunch: j.containsKey('lunch') ? _rangesFromJson(j['lunch']) : d.lunch,
    maxDeepBlocksPerDay:
        j['maxDeepBlocksPerDay'] as int? ?? d.maxDeepBlocksPerDay,
    deepBlockMinutes: j['deepBlockMinutes'] as int? ?? d.deepBlockMinutes,
    bufferBetweenEventsMinutes:
        j['bufferBetweenEventsMinutes'] as int? ?? d.bufferBetweenEventsMinutes,
    dailyCushionMinutes:
        j['dailyCushionMinutes'] as int? ?? d.dailyCushionMinutes,
    weekStart: j['weekStart'] as int? ?? d.weekStart,
    defaultReminderLeadMinutes:
        j['defaultReminderLeadMinutes'] as int? ?? d.defaultReminderLeadMinutes,
    quietHours: j['quietHours'] == null
        ? null
        : TimeRange.fromJson(_map(j['quietHours'])),
    timeZoneName: j['timeZoneName'] as String? ?? d.timeZoneName,
    localeCode: j['localeCode'] as String? ?? d.localeCode,
    onboardingDone: j['onboardingDone'] as bool? ?? d.onboardingDone,
  );
}
