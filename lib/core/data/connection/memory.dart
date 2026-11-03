import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../database.dart';

/// A fresh, empty in-memory database for tests (VM only: uses `dart:ffi`).
///
/// Drift warns when several databases are opened in one isolate; tests open
/// one per test on purpose, so the warning is turned off.
AppDatabase openInMemoryDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}
