import 'dart:convert';

import '../../domain/domain.dart';
import '../../services/clock.dart';
import '../database.dart';
import '../mappers.dart';

/// The backup file could not be imported. Nothing was changed.
class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  final String message;

  @override
  String toString() => 'BackupFormatException: $message';
}

/// Row counts of an imported or exported backup.
class BackupSummary {
  const BackupSummary({
    required this.tasks,
    required this.reminderRules,
    required this.calendarEvents,
    required this.focusSessions,
    required this.goals,
    required this.hasPreferences,
  });

  final int tasks;
  final int reminderRules;
  final int calendarEvents;
  final int focusSessions;
  final int goals;
  final bool hasPreferences;
}

/// Platform side of backups: where the JSON goes and where it comes from.
/// See `backup_file.dart` for the share sheet / download implementation.
abstract interface class BackupFileGateway {
  /// Hand the backup to the user (share sheet on iOS, download on web).
  Future<void> save({required String fileName, required String contents});

  /// Let the user pick a backup file; null when they cancelled.
  Future<String?> pick();
}

/// Export, import and wipe of the whole local database. Pure Dart: no
/// platform code, so it is tested against an in-memory database.
///
/// Format (version [format]):
/// ```json
/// {
///   "app": "grind", "format": 1, "schemaVersion": 1,
///   "exportedAt": "2026-11-03T08:00:00.000Z",
///   "tasks": [...], "reminderRules": [...], "calendarEvents": [...],
///   "focusSessions": [...], "goals": [...], "preferences": {...} | null
/// }
/// ```
/// Times are ISO-8601 UTC strings, enums their names. Soft-deleted rows
/// are included so a restore is an exact copy.
class BackupService {
  BackupService(this._db, {Clock clock = const SystemClock()}) : _clock = clock;

  /// Bump when the JSON shape changes incompatibly; teach [importJson] to
  /// read the older versions.
  static const format = 1;

  final AppDatabase _db;
  final Clock _clock;

  /// `grind-backup-2026-11-03.json`.
  String suggestedFileName() {
    final d = _clock.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return 'grind-backup-${d.year}-${two(d.month)}-${two(d.day)}.json';
  }

  Future<Map<String, Object?>> exportMap() => _db.transaction(() async {
    final tasks = await _db.select(_db.tasks).get();
    final rules = await _db.select(_db.reminderRules).get();
    final events = await _db.select(_db.calendarEvents).get();
    final sessions = await _db.select(_db.focusSessions).get();
    final goals = await _db.select(_db.goals).get();
    final prefs = await _db.select(_db.preferencesTable).getSingleOrNull();
    return {
      'app': 'grind',
      'format': format,
      'schemaVersion': _db.schemaVersion,
      'exportedAt': _clock.now().toUtc().toIso8601String(),
      'tasks': [for (final r in tasks) r.toDomain().toJson()],
      'reminderRules': [for (final r in rules) r.toDomain().toJson()],
      'calendarEvents': [for (final r in events) r.toDomain().toJson()],
      'focusSessions': [for (final r in sessions) r.toDomain().toJson()],
      'goals': [for (final r in goals) r.toDomain().toJson()],
      'preferences': prefs?.toDomain().toJson(),
    };
  });

  /// The whole database as pretty-printed JSON.
  Future<String> exportJson() async =>
      const JsonEncoder.withIndent('  ').convert(await exportMap());

  /// Validates [json] and replaces **all** local data with it, in one
  /// transaction. Throws [BackupFormatException] (and changes nothing) when
  /// the file is not a Grind backup, is from a newer version, or is
  /// inconsistent.
  Future<BackupSummary> importJson(String json) async {
    final parsed = _parse(json);
    try {
      await _db.transaction(() async {
        await _wipe();
        await _db.batch((b) {
          b.insertAll(_db.goals, [
            for (final g in parsed.goals) g.toCompanion(),
          ]);
          b.insertAll(_db.tasks, [
            for (final t in parsed.tasks) t.toCompanion(),
          ]);
          b.insertAll(_db.calendarEvents, [
            for (final e in parsed.events) e.toCompanion(),
          ]);
          b.insertAll(_db.reminderRules, [
            for (final r in parsed.rules) r.toCompanion(),
          ]);
          b.insertAll(_db.focusSessions, [
            for (final s in parsed.sessions) s.toCompanion(),
          ]);
          final p = parsed.preferences;
          if (p != null) {
            final now = _clock.now().toUtc();
            b.insert(
              _db.preferencesTable,
              p.toCompanion(createdAt: now, updatedAt: now),
            );
          }
        });
      });
    } on BackupFormatException {
      rethrow;
    } catch (e) {
      // Duplicate ids, a rule pointing at a missing task, ... The
      // transaction was rolled back, so the old data is intact.
      throw BackupFormatException('The backup is inconsistent: $e');
    }
    return parsed.summary;
  }

  /// "Delete all data": hard-deletes every row in every table.
  Future<void> deleteAllData() => _db.transaction(_wipe);

  /// Export and hand the file to [gateway].
  Future<void> exportToFile(BackupFileGateway gateway) async =>
      gateway.save(fileName: suggestedFileName(), contents: await exportJson());

  /// Pick a file with [gateway] and import it. Null when the user cancelled.
  Future<BackupSummary?> importFromFile(BackupFileGateway gateway) async {
    final json = await gateway.pick();
    return json == null ? null : importJson(json);
  }

  Future<void> _wipe() async {
    for (final t in _db.tablesChildrenFirst) {
      await _db.delete(t).go();
    }
  }

  _ParsedBackup _parse(String json) {
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      throw const BackupFormatException('This file is not valid JSON.');
    }
    if (decoded is! Map<String, Object?>) {
      throw const BackupFormatException('This file is not a Grind backup.');
    }
    final root = decoded;
    final version = root['format'];
    if (version is! int || !root.containsKey('tasks')) {
      throw const BackupFormatException('This file is not a Grind backup.');
    }
    if (version > format) {
      throw BackupFormatException(
        'This backup was made by a newer version of Grind (format $version). '
        'Update the app, then import again.',
      );
    }
    if (version < 1) {
      throw BackupFormatException('Unknown backup format $version.');
    }

    List<T> list<T>(String key, T Function(Map<String, Object?>) fromJson) {
      final v = root[key];
      if (v == null) return const [];
      if (v is! List) throw BackupFormatException('"$key" is not a list.');
      return [
        for (final (i, item) in v.indexed)
          _guard('$key[$i]', () => fromJson((item as Map).cast())),
      ];
    }

    final prefs = root['preferences'];
    return _ParsedBackup(
      tasks: list('tasks', taskFromJson),
      rules: list('reminderRules', reminderRuleFromJson),
      events: list('calendarEvents', calendarEventFromJson),
      sessions: list('focusSessions', focusSessionFromJson),
      goals: list('goals', goalFromJson),
      preferences: prefs == null
          ? null
          : _guard(
              'preferences',
              () => preferencesFromJson((prefs as Map).cast()),
            ),
    );
  }

  T _guard<T>(String where, T Function() read) {
    try {
      return read();
    } catch (e) {
      throw BackupFormatException('Could not read $where: $e');
    }
  }
}

class _ParsedBackup {
  const _ParsedBackup({
    required this.tasks,
    required this.rules,
    required this.events,
    required this.sessions,
    required this.goals,
    required this.preferences,
  });

  final List<Task> tasks;
  final List<ReminderRule> rules;
  final List<CalendarEvent> events;
  final List<FocusSession> sessions;
  final List<Goal> goals;
  final Preferences? preferences;

  BackupSummary get summary => BackupSummary(
    tasks: tasks.length,
    reminderRules: rules.length,
    calendarEvents: events.length,
    focusSessions: sessions.length,
    goals: goals.length,
    hasPreferences: preferences != null,
  );
}
