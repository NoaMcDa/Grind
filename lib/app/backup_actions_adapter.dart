import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/data/data.dart';
import '../features/settings/backup_actions.dart';
import '../features/settings/data_reset_service.dart';

/// Settings "Data" actions backed by the Drift [BackupService] and the
/// platform file gateway (share sheet on iOS, download / picker on web).
class DriftBackupActions implements BackupActions {
  const DriftBackupActions(
    this._service, {
    this.gateway = const PlatformBackupFileGateway(),
    this.reset,
  });

  final BackupService _service;
  final BackupFileGateway gateway;

  /// Disconnects calendars and clears sync state after a restore or wipe.
  final DataResetService? reset;

  @override
  Future<void> exportBackup() => _service.exportToFile(gateway);

  @override
  Future<void> importBackup() async {
    final summary = await _service.importFromFile(gateway);
    // Sync tokens and mirrored events describe a database that no longer
    // exists; a cancelled picker (null) changes nothing.
    if (summary != null) await reset?.resetCalendars();
  }

  @override
  Future<void> deleteAllData() async {
    await _service.deleteAllData();
    await reset?.resetCalendars();
  }
}

/// Override for `main.dart`: routes the settings screen's data actions to
/// the real database.
Override backupActionsOverride() => backupActionsProvider.overrideWith(
  (ref) => DriftBackupActions(
    ref.watch(backupServiceProvider),
    reset: ref.watch(dataResetServiceProvider),
  ),
);
