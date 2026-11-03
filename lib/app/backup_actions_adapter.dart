import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/data/data.dart';
import '../features/settings/backup_actions.dart';

/// Settings "Data" actions backed by the Drift [BackupService] and the
/// platform file gateway (share sheet on iOS, download / picker on web).
class DriftBackupActions implements BackupActions {
  const DriftBackupActions(
    this._service, {
    this.gateway = const PlatformBackupFileGateway(),
  });

  final BackupService _service;
  final BackupFileGateway gateway;

  @override
  Future<void> exportBackup() => _service.exportToFile(gateway);

  @override
  Future<void> importBackup() async {
    await _service.importFromFile(gateway);
  }

  @override
  Future<void> deleteAllData() => _service.deleteAllData();
}

/// Override for `main.dart`: routes the settings screen's data actions to
/// the real database.
Override backupActionsOverride() => backupActionsProvider.overrideWith(
  (ref) => DriftBackupActions(ref.watch(backupServiceProvider)),
);
