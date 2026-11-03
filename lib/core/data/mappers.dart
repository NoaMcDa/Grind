import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/domain.dart';
import '../domain/milestone.dart';
import 'database.dart';

/// Mapping between Drift rows, domain objects and the backup JSON.
///
/// Storage format: times are UTC milliseconds since the epoch. Reading
/// always yields UTC [DateTime]s; sub-millisecond precision is dropped.
/// Backup JSON: times are ISO-8601 UTC strings, enums are their `name`.
///
/// The `*FromJson` readers validate every field they read and throw a
/// [FormatException] naming the field on a wrong type or value (a missing
/// optional field takes its default, so older backups keep importing).

// ---------------------------------------------------------------- time

int toMillis(DateTime t) => t.millisecondsSinceEpoch;
int? toMillisOrNull(DateTime? t) => t?.millisecondsSinceEpoch;
DateTime fromMillis(int ms) =>
    DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
DateTime? fromMillisOrNull(int? ms) => ms == null ? null : fromMillis(ms);

String _iso(DateTime t) => t.toUtc().toIso8601String();
String? _isoOrNull(DateTime? t) => t == null ? null : _iso(t);

// ---------------------------------------------------------------- JSON reader

/// Typed, validating access to one JSON object.
extension type const _Json(Map<String, Object?> j) {
  Never _bad(String key, String want) {
    final v = j[key];
    final got = v == null ? 'nothing' : '${v.runtimeType} ${jsonEncode(v)}';
    throw FormatException('"$key" should be $want, got $got.');
  }

  String str(String key) {
    final v = j[key];
    return v is String ? v : _bad(key, 'text');
  }

  String nonEmpty(String key) {
    final v = str(key);
    return v.isEmpty ? _bad(key, 'non-empty text') : v;
  }

  String? strOrNull(String key) {
    final v = j[key];
    if (v == null || v is String) return v as String?;
    _bad(key, 'text or null');
  }

  int? intOrNull(String key, {int min = 0}) {
    final v = j[key];
    if (v == null) return null;
    if (v is num && v == v.roundToDouble() && v >= min) return v.toInt();
    _bad(key, min == 0 ? 'a whole number >= 0' : 'a whole number >= $min');
  }

  int integer(String key, {int? or, int min = 0}) {
    final v = intOrNull(key, min: min);
    if (v != null) return v;
    return or ?? _bad(key, 'a whole number');
  }

  double fraction(String key, {required double or}) {
    final v = j[key];
    if (v == null) return or;
    if (v is num && v >= 0 && v <= 1) return v.toDouble();
    _bad(key, 'a number from 0 to 1');
  }

  bool boolean(String key, {required bool or}) {
    final v = j[key];
    if (v == null) return or;
    return v is bool ? v : _bad(key, 'true or false');
  }

  DateTime? timeOrNull(String key) {
    final v = j[key];
    if (v == null) return null;
    final t = v is String ? DateTime.tryParse(v) : null;
    if (t == null) _bad(key, 'an ISO-8601 time');
    // Normalise to UTC at storage (millisecond) precision, so an imported
    // value equals the value read back.
    return fromMillis(t.toUtc().millisecondsSinceEpoch);
  }

  DateTime time(String key) => timeOrNull(key) ?? _bad(key, 'a time');

  T enumOf<T extends Enum>(List<T> values, String key, {T? or}) {
    final v = j[key];
    if (v == null && or != null) return or;
    for (final e in values) {
      if (e.name == v) return e;
    }
    _bad(key, 'one of ${values.map((e) => e.name).join(', ')}');
  }

  Map<String, Object?> object(String key) {
    final v = j[key];
    return v is Map ? v.cast<String, Object?>() : _bad(key, 'an object');
  }
}

/// [v] as a JSON object, or a [FormatException].
Map<String, Object?> jsonObject(Object? v, String what) {
  if (v is Map) return v.cast<String, Object?>();
  throw FormatException('$what should be an object.');
}

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
    notBefore: fromMillisOrNull(notBefore),
    minutesDone: minutesDone,
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
    notBefore: Value(toMillisOrNull(notBefore)),
    minutesDone: Value(minutesDone),
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
    'notBefore': _isoOrNull(notBefore),
    'minutesDone': minutesDone,
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

Task taskFromJson(Map<String, Object?> map) {
  final j = _Json(map);
  final priority = j.integer('priority', or: 2, min: 1);
  if (priority > 3) {
    throw FormatException('"priority" should be 1, 2 or 3, got $priority.');
  }
  return Task(
    id: j.nonEmpty('id'),
    title: j.str('title'),
    notes: j.strOrNull('notes'),
    goalId: j.strOrNull('goalId'),
    dueAt: j.timeOrNull('dueAt'),
    remindAt: j.timeOrNull('remindAt'),
    scheduledStart: j.timeOrNull('scheduledStart'),
    scheduledEnd: j.timeOrNull('scheduledEnd'),
    lockedStart: j.boolean('lockedStart', or: false),
    notBefore: j.timeOrNull('notBefore'),
    minutesDone: j.integer('minutesDone', or: 0),
    estimatedMinutes: j.integer('estimatedMinutes', or: 30),
    energy: j.enumOf(Energy.values, 'energy', or: Energy.light),
    firstAction: j.strOrNull('firstAction'),
    priority: priority,
    category: j.strOrNull('category'),
    splittable: j.boolean('splittable', or: false),
    minChunkMinutes: j.integer('minChunkMinutes', or: 25),
    status: j.enumOf(TaskStatus.values, 'status', or: TaskStatus.open),
    completedAt: j.timeOrNull('completedAt'),
    actualMinutes: j.intOrNull('actualMinutes'),
    snoozeCount: j.integer('snoozeCount', or: 0),
    calendarEventId: j.strOrNull('calendarEventId'),
    createdAt: j.time('createdAt'),
    updatedAt: j.time('updatedAt'),
    deletedAt: j.timeOrNull('deletedAt'),
  );
}

// ---------------------------------------------------------------- ReminderRule

extension ReminderRuleRowMapper on ReminderRuleRow {
  ReminderRule toDomain() => ReminderRule(
    id: id,
    taskId: taskId,
    rrule: rrule,
    leadMinutes: leadMinutes,
    until: fromMillisOrNull(until),
    lastCompletedAt: fromMillisOrNull(lastCompletedAt),
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
    lastCompletedAt: Value(toMillisOrNull(lastCompletedAt)),
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
    'lastCompletedAt': _isoOrNull(lastCompletedAt),
    'createdAt': _iso(createdAt),
    'updatedAt': _iso(updatedAt),
    'deletedAt': _isoOrNull(deletedAt),
  };
}

ReminderRule reminderRuleFromJson(Map<String, Object?> map) {
  final j = _Json(map);
  return ReminderRule(
    id: j.nonEmpty('id'),
    taskId: j.nonEmpty('taskId'),
    rrule: j.nonEmpty('rrule'),
    leadMinutes: j.integer('leadMinutes', or: 0),
    until: j.timeOrNull('until'),
    lastCompletedAt: j.timeOrNull('lastCompletedAt'),
    createdAt: j.time('createdAt'),
    updatedAt: j.time('updatedAt'),
    deletedAt: j.timeOrNull('deletedAt'),
  );
}

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
    htmlLink: htmlLink,
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
    htmlLink: Value(htmlLink),
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
    'htmlLink': htmlLink,
    'createdAt': _iso(createdAt),
    'updatedAt': _iso(updatedAt),
    'deletedAt': _isoOrNull(deletedAt),
  };
}

CalendarEvent calendarEventFromJson(Map<String, Object?> map) {
  final j = _Json(map);
  final start = j.time('start');
  final end = j.time('end');
  if (end.isBefore(start)) {
    throw const FormatException('"end" is before "start".');
  }
  return CalendarEvent(
    id: j.nonEmpty('id'),
    source: j.enumOf(CalendarSource.values, 'source'),
    externalId: j.str('externalId'),
    calendarId: j.strOrNull('calendarId'),
    title: j.str('title'),
    start: start,
    end: end,
    isAllDay: j.boolean('isAllDay', or: false),
    isBusy: j.boolean('isBusy', or: true),
    taskId: j.strOrNull('taskId'),
    htmlLink: j.strOrNull('htmlLink'),
    createdAt: j.time('createdAt'),
    updatedAt: j.time('updatedAt'),
    deletedAt: j.timeOrNull('deletedAt'),
  );
}

// ---------------------------------------------------------------- FocusSession

extension FocusSessionRowMapper on FocusSessionRow {
  FocusSession toDomain() => FocusSession(
    id: id,
    taskId: taskId,
    plannedMinutes: plannedMinutes,
    startedAt: fromMillis(startedAt),
    endedAt: fromMillisOrNull(endedAt),
    completed: completed,
    pausedMs: pausedMs,
    pausedAt: fromMillisOrNull(pausedAt),
    win: win,
    kind: kind,
    createdAt: fromMillis(createdAt),
    updatedAt: fromMillis(updatedAt),
    deletedAt: fromMillisOrNull(deletedAt),
  );
}

extension FocusSessionMapper on FocusSession {
  FocusSessionsCompanion toCompanion() => FocusSessionsCompanion.insert(
    id: id,
    taskId: Value(taskId),
    plannedMinutes: plannedMinutes,
    startedAt: toMillis(startedAt),
    endedAt: Value(toMillisOrNull(endedAt)),
    completed: Value(completed),
    pausedMs: Value(pausedMs),
    pausedAt: Value(toMillisOrNull(pausedAt)),
    win: Value(win),
    kind: Value(kind),
    createdAt: toMillis(createdAt),
    updatedAt: toMillis(updatedAt),
    deletedAt: Value(toMillisOrNull(deletedAt)),
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'taskId': taskId,
    'plannedMinutes': plannedMinutes,
    'startedAt': _iso(startedAt),
    'endedAt': _isoOrNull(endedAt),
    'completed': completed,
    'pausedMs': pausedMs,
    'pausedAt': _isoOrNull(pausedAt),
    'win': win,
    'kind': kind.name,
    'createdAt': _iso(createdAt),
    'updatedAt': _iso(updatedAt),
    'deletedAt': _isoOrNull(deletedAt),
  };
}

FocusSession focusSessionFromJson(Map<String, Object?> map) {
  final j = _Json(map);
  return FocusSession(
    id: j.nonEmpty('id'),
    taskId: j.strOrNull('taskId'),
    plannedMinutes: j.integer('plannedMinutes', min: 1),
    startedAt: j.time('startedAt'),
    endedAt: j.timeOrNull('endedAt'),
    completed: j.boolean('completed', or: false),
    pausedMs: j.integer('pausedMs', or: 0),
    pausedAt: j.timeOrNull('pausedAt'),
    win: j.strOrNull('win'),
    kind: j.enumOf(FocusSessionKind.values, 'kind', or: FocusSessionKind.focus),
    createdAt: j.time('createdAt'),
    updatedAt: j.time('updatedAt'),
    deletedAt: j.timeOrNull('deletedAt'),
  );
}

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
    targetDate: fromMillisOrNull(targetDate),
    status: status,
    notes: notes,
    metricKind: metricKind,
    metricTarget: metricTarget,
    metricUnit: metricUnit,
    metricCurrent: metricCurrent,
    metricSource: metricSource,
    metricPeriod: metricPeriod,
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
    targetDate: Value(toMillisOrNull(targetDate)),
    status: Value(status),
    notes: Value(notes),
    metricKind: Value(metricKind),
    metricTarget: Value(metricTarget),
    metricUnit: Value(metricUnit),
    metricCurrent: Value(metricCurrent),
    metricSource: Value(metricSource),
    metricPeriod: Value(metricPeriod),
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
    'targetDate': _isoOrNull(targetDate),
    'status': status.name,
    'notes': notes,
    'metricKind': metricKind,
    'metricTarget': metricTarget,
    'metricUnit': metricUnit,
    'metricCurrent': metricCurrent,
    'metricSource': metricSource,
    'metricPeriod': metricPeriod,
    'createdAt': _iso(createdAt),
    'updatedAt': _iso(updatedAt),
    'deletedAt': _isoOrNull(deletedAt),
  };
}

Goal goalFromJson(Map<String, Object?> map) {
  final j = _Json(map);
  return Goal(
    id: j.nonEmpty('id'),
    title: j.str('title'),
    area: j.strOrNull('area'),
    horizon: j.enumOf(GoalHorizon.values, 'horizon', or: GoalHorizon.month),
    importance: j.fraction('importance', or: 0.5),
    progress: j.fraction('progress', or: 0),
    lastProgressAt: j.timeOrNull('lastProgressAt'),
    targetDate: j.timeOrNull('targetDate'),
    status: j.enumOf(GoalStatus.values, 'status', or: GoalStatus.active),
    notes: j.strOrNull('notes'),
    metricKind: j.strOrNull('metricKind'),
    metricTarget: j.intOrNull('metricTarget', min: 1),
    metricUnit: j.strOrNull('metricUnit'),
    metricCurrent: j.intOrNull('metricCurrent'),
    metricSource: j.strOrNull('metricSource'),
    metricPeriod: j.strOrNull('metricPeriod'),
    createdAt: j.time('createdAt'),
    updatedAt: j.time('updatedAt'),
    deletedAt: j.timeOrNull('deletedAt'),
  );
}

// ---------------------------------------------------------------- Milestone

extension MilestoneRowMapper on MilestoneRow {
  Milestone toDomain() => Milestone(
    id: id,
    goalId: goalId,
    title: title,
    dueAt: fromMillisOrNull(dueAt),
    sortOrder: sortOrder,
    status: status,
    completedAt: fromMillisOrNull(completedAt),
    createdAt: fromMillis(createdAt),
    updatedAt: fromMillis(updatedAt),
    deletedAt: fromMillisOrNull(deletedAt),
  );
}

extension MilestoneMapper on Milestone {
  MilestonesCompanion toCompanion() => MilestonesCompanion.insert(
    id: id,
    goalId: goalId,
    title: title,
    dueAt: Value(toMillisOrNull(dueAt)),
    sortOrder: Value(sortOrder),
    status: Value(status),
    completedAt: Value(toMillisOrNull(completedAt)),
    createdAt: toMillis(createdAt),
    updatedAt: toMillis(updatedAt),
    deletedAt: Value(toMillisOrNull(deletedAt)),
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'goalId': goalId,
    'title': title,
    'dueAt': _isoOrNull(dueAt),
    'sortOrder': sortOrder,
    'status': status.name,
    'completedAt': _isoOrNull(completedAt),
    'createdAt': _iso(createdAt),
    'updatedAt': _iso(updatedAt),
    'deletedAt': _isoOrNull(deletedAt),
  };
}

Milestone milestoneFromJson(Map<String, Object?> map) {
  final j = _Json(map);
  return Milestone(
    id: j.nonEmpty('id'),
    goalId: j.nonEmpty('goalId'),
    title: j.str('title'),
    dueAt: j.timeOrNull('dueAt'),
    sortOrder: j.integer('sortOrder', or: 0),
    status: j.enumOf(
      MilestoneStatus.values,
      'status',
      or: MilestoneStatus.open,
    ),
    completedAt: j.timeOrNull('completedAt'),
    createdAt: j.time('createdAt'),
    updatedAt: j.time('updatedAt'),
    deletedAt: j.timeOrNull('deletedAt'),
  );
}

extension MilestoneTaskRowMapper on MilestoneTaskRow {
  MilestoneTaskLink toDomain() => MilestoneTaskLink(
    taskId: taskId,
    milestoneId: milestoneId,
    createdAt: fromMillis(createdAt),
  );
}

extension MilestoneTaskLinkMapper on MilestoneTaskLink {
  MilestoneTasksCompanion toCompanion() => MilestoneTasksCompanion.insert(
    taskId: taskId,
    milestoneId: milestoneId,
    createdAt: toMillis(createdAt),
  );

  Map<String, Object?> toJson() => {
    'taskId': taskId,
    'milestoneId': milestoneId,
    'createdAt': _iso(createdAt),
  };
}

MilestoneTaskLink milestoneTaskLinkFromJson(Map<String, Object?> map) {
  final j = _Json(map);
  return MilestoneTaskLink(
    taskId: j.nonEmpty('taskId'),
    milestoneId: j.nonEmpty('milestoneId'),
    createdAt: j.time('createdAt'),
  );
}

// ---------------------------------------------------------------- Review

final _dayKey = RegExp(r'^\d{4}-\d{2}-\d{2}$');

String _day(_Json j, String key) {
  final v = j.str(key);
  if (_dayKey.hasMatch(v) && DateTime.tryParse(v) != null) return v;
  throw FormatException('"$key" should be a day like 2026-11-03, got "$v".');
}

extension ReviewEntryRowMapper on ReviewEntryRow {
  /// Not `toJson`: the generated row class has its own, which would win.
  Map<String, Object?> toBackupJson() => {
    'date': date,
    'win': win,
    'doneCount': doneCount,
    'movedCount': movedCount,
    'createdAt': _iso(fromMillis(createdAt)),
  };
}

/// A review entry from the backup, ready to insert.
ReviewEntriesCompanion reviewEntryFromJson(Map<String, Object?> map) {
  final j = _Json(map);
  return ReviewEntriesCompanion.insert(
    date: _day(j, 'date'),
    win: j.str('win'),
    doneCount: j.integer('doneCount', or: 0),
    movedCount: j.integer('movedCount', or: 0),
    createdAt: toMillis(j.time('createdAt')),
  );
}

/// A handled review day (`yyyy-MM-dd`) from the backup.
String reviewHandledDayFromJson(Object? v) => _day(_Json({'day': v}), 'day');

// ---------------------------------------------------------------- Preferences

List<Map<String, Object?>> _rangesToJson(List<TimeRange> ranges) => [
  for (final r in ranges) r.toJson(),
];

List<TimeRange> _rangesFromJson(Object? json, String key) {
  if (json is! List) throw FormatException('"$key" should be a list.');
  return [
    for (final (i, r) in json.indexed) _range(r, '$key[$i]', allowWrap: false),
  ];
}

TimeRange _range(Object? json, String where, {required bool allowWrap}) {
  try {
    return TimeRange.fromJson(
      jsonObject(json, '"$where"'),
      allowWrap: allowWrap,
    );
  } on FormatException catch (e) {
    throw FormatException('"$where": ${e.message}');
  }
}

Map<String, Object?> _workingHoursToJson(Map<int, List<TimeRange>> wh) => {
  for (final e in wh.entries) '${e.key}': _rangesToJson(e.value),
};

Map<int, List<TimeRange>> _workingHoursFromJson(Object? json) {
  final map = jsonObject(json, '"workingHours"');
  return {
    for (final e in map.entries)
      _weekday(e.key): _rangesFromJson(e.value, 'workingHours.${e.key}'),
  };
}

int _weekday(String key) {
  final d = int.tryParse(key);
  if (d == null || d < DateTime.monday || d > DateTime.sunday) {
    throw FormatException('"workingHours" has a day "$key"; use 1 to 7.');
  }
  return d;
}

TimeRange? _quietFromJson(Object? json) =>
    json == null ? null : _range(json, 'quietHours', allowWrap: true);

int? _minuteOfDay(_Json j, String key) {
  final v = j.intOrNull(key);
  if (v != null && v >= 24 * 60) {
    throw FormatException('"$key" should be under 1440 minutes, got $v.');
  }
  return v;
}

extension PreferencesRowMapper on PreferencesRow {
  Preferences toDomain() => Preferences(
    workingHours: _workingHoursFromJson(jsonDecode(workingHours)),
    deepWindows: _rangesFromJson(jsonDecode(deepWindows), 'deepWindows'),
    lunch: _rangesFromJson(jsonDecode(lunch), 'lunch'),
    maxDeepBlocksPerDay: maxDeepBlocksPerDay,
    deepBlockMinutes: deepBlockMinutes,
    bufferBetweenEventsMinutes: bufferBetweenEventsMinutes,
    dailyCushionMinutes: dailyCushionMinutes,
    weekStart: weekStart,
    defaultReminderLeadMinutes: defaultReminderLeadMinutes,
    quietHours: quietHours == null
        ? null
        : _quietFromJson(jsonDecode(quietHours!)),
    timeZoneName: timeZoneName,
    localeCode: localeCode,
    onboardingDone: onboardingDone,
    morningPromptMinutes: morningPromptMinutes,
    eveningPromptMinutes: eveningPromptMinutes,
    selectedCalendarIds: _calendarIdsFromJson(jsonDecode(selectedCalendarIds)),
    backupHintShown: backupHintShown,
    pipAccessory: pipAccessory,
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
    morningPromptMinutes: Value(morningPromptMinutes),
    eveningPromptMinutes: Value(eveningPromptMinutes),
    selectedCalendarIds: Value(
      jsonEncode(_calendarIdsToJson(selectedCalendarIds)),
    ),
    backupHintShown: Value(backupHintShown),
    pipAccessory: Value(pipAccessory),
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
    'morningPromptMinutes': morningPromptMinutes,
    'eveningPromptMinutes': eveningPromptMinutes,
    'selectedCalendarIds': _calendarIdsToJson(selectedCalendarIds),
    'backupHintShown': backupHintShown,
    'pipAccessory': pipAccessory,
  };
}

/// Missing keys fall back to the [Preferences] defaults, so older backups
/// keep importing when fields are added. Present keys are validated:
/// time ranges must lie inside one day (only quiet hours may wrap).
Preferences preferencesFromJson(Map<String, Object?> map) {
  const d = Preferences();
  final j = _Json(map);
  final weekStart = j.integer('weekStart', or: d.weekStart, min: 1);
  if (weekStart > DateTime.sunday) {
    throw FormatException('"weekStart" should be 1 to 7, got $weekStart.');
  }
  final accessory = j.strOrNull('pipAccessory');
  return Preferences(
    workingHours: map.containsKey('workingHours')
        ? _workingHoursFromJson(map['workingHours'])
        : d.workingHours,
    deepWindows: map.containsKey('deepWindows')
        ? _rangesFromJson(map['deepWindows'], 'deepWindows')
        : d.deepWindows,
    lunch: map.containsKey('lunch')
        ? _rangesFromJson(map['lunch'], 'lunch')
        : d.lunch,
    maxDeepBlocksPerDay: j.integer(
      'maxDeepBlocksPerDay',
      or: d.maxDeepBlocksPerDay,
    ),
    deepBlockMinutes: j.integer('deepBlockMinutes', or: d.deepBlockMinutes),
    bufferBetweenEventsMinutes: j.integer(
      'bufferBetweenEventsMinutes',
      or: d.bufferBetweenEventsMinutes,
    ),
    dailyCushionMinutes: j.integer(
      'dailyCushionMinutes',
      or: d.dailyCushionMinutes,
    ),
    weekStart: weekStart,
    defaultReminderLeadMinutes: j.integer(
      'defaultReminderLeadMinutes',
      or: d.defaultReminderLeadMinutes,
    ),
    quietHours: _quietFromJson(map['quietHours']),
    timeZoneName: j.strOrNull('timeZoneName') ?? d.timeZoneName,
    localeCode: j.strOrNull('localeCode') ?? d.localeCode,
    onboardingDone: j.boolean('onboardingDone', or: d.onboardingDone),
    morningPromptMinutes: map.containsKey('morningPromptMinutes')
        ? _minuteOfDay(j, 'morningPromptMinutes')
        : d.morningPromptMinutes,
    eveningPromptMinutes: map.containsKey('eveningPromptMinutes')
        ? _minuteOfDay(j, 'eveningPromptMinutes')
        : d.eveningPromptMinutes,
    selectedCalendarIds: map.containsKey('selectedCalendarIds')
        ? _calendarIdsFromJson(map['selectedCalendarIds'])
        : d.selectedCalendarIds,
    backupHintShown: j.boolean('backupHintShown', or: d.backupHintShown),
    pipAccessory: accessory == null || accessory.isEmpty
        ? d.pipAccessory
        : accessory,
  );
}

Map<String, Object?> _calendarIdsToJson(
  Map<CalendarSource, List<String>> ids,
) => {for (final e in ids.entries) e.key.name: e.value};

Map<CalendarSource, List<String>> _calendarIdsFromJson(Object? json) {
  final map = jsonObject(json, '"selectedCalendarIds"');
  final out = <CalendarSource, List<String>>{};
  for (final e in map.entries) {
    final source = _Json({
      'selectedCalendarIds': e.key,
    }).enumOf(CalendarSource.values, 'selectedCalendarIds');
    final ids = e.value;
    if (ids is! List || ids.any((id) => id is! String)) {
      throw FormatException(
        '"selectedCalendarIds.${e.key}" should be a list of ids.',
      );
    }
    out[source] = ids.cast<String>();
  }
  return out;
}
