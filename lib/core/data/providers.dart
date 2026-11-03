import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di.dart';
import 'backup/backup_service.dart';
import 'database.dart';
import 'repositories/drift_calendar_repository.dart';
import 'repositories/drift_preferences_repository.dart';
import 'repositories/drift_reminder_repository.dart';
import 'repositories/drift_task_repository.dart';

/// The open [AppDatabase]. Has no default: provided by
/// [dataProvidersOverrides].
final appDatabaseProvider = Provider<AppDatabase>(
  (_) => throw UnimplementedError(
    'appDatabaseProvider is set by dataProvidersOverrides(db) in main.dart.',
  ),
);

/// Export / import / delete-all, for the settings screen.
final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(
    ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Overrides that swap the in-memory defaults in `lib/core/di.dart` for the
/// Drift implementations on [db]. Apply in `main.dart`:
///
/// ```dart
/// final db = AppDatabase(openConnection());
/// runApp(ProviderScope(overrides: dataProvidersOverrides(db), child: ...));
/// ```
List<Override> dataProvidersOverrides(AppDatabase db) => [
  appDatabaseProvider.overrideWithValue(db),
  taskRepositoryProvider.overrideWith(
    (ref) => DriftTaskRepository(db, clock: ref.watch(clockProvider)),
  ),
  reminderRepositoryProvider.overrideWith(
    (ref) => DriftReminderRepository(db, clock: ref.watch(clockProvider)),
  ),
  calendarRepositoryProvider.overrideWith(
    (ref) => DriftCalendarRepository(db, clock: ref.watch(clockProvider)),
  ),
  preferencesRepositoryProvider.overrideWith(
    (ref) => DriftPreferencesRepository(db, clock: ref.watch(clockProvider)),
  ),
];
