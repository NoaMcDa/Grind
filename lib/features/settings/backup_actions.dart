import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Data actions behind the Settings "Data" section. The real implementation
/// comes from `lib/core/data/backup` (W1-B); the integrator overrides
/// [backupActionsProvider] with it.
abstract interface class BackupActions {
  Future<void> exportBackup();
  Future<void> importBackup();
  Future<void> deleteAllData();
}

/// No-op stand-in that records calls.
class FakeBackupActions implements BackupActions {
  int exports = 0;
  int imports = 0;
  int deletes = 0;

  @override
  Future<void> exportBackup() async => exports++;

  @override
  Future<void> importBackup() async => imports++;

  @override
  Future<void> deleteAllData() async => deletes++;
}

final backupActionsProvider = Provider<BackupActions>(
  (_) => FakeBackupActions(),
);
