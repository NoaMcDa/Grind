/// Local persistence (Drift/sqlite). Only `main.dart`, the settings screen
/// (backup) and tests import this; features read data through the
/// repository interfaces in `package:grind/core/core.dart`.
///
/// `connection/memory.dart` (tests) is deliberately not exported: it pulls in
/// `dart:ffi`, which does not compile for the web.
library;

export 'backup/backup_file.dart';
export 'backup/backup_service.dart';
export 'connection/connection.dart';
export 'database.dart';
export 'providers.dart';
export 'repositories/drift_calendar_repository.dart';
export 'repositories/drift_preferences_repository.dart';
export 'repositories/drift_reminder_repository.dart';
export 'repositories/drift_task_repository.dart';
export 'seed.dart';
export 'web_persistence.dart';
