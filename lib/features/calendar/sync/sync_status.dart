import 'calendar_sync_errors.dart' show SyncErrorKind;

export 'calendar_sync_errors.dart' show SyncErrorKind;

/// What the calendar sync is doing right now, for a small status line.
enum SyncPhase { idle, syncing, error }

class SyncStatus {
  const SyncStatus._(this.phase, {this.error, this.lastSyncedAt});

  const SyncStatus.idle({DateTime? lastSyncedAt})
    : this._(SyncPhase.idle, lastSyncedAt: lastSyncedAt);

  const SyncStatus.syncing({DateTime? lastSyncedAt})
    : this._(SyncPhase.syncing, lastSyncedAt: lastSyncedAt);

  /// [error] picks the user-facing copy (Pip's tone), localized by the UI.
  const SyncStatus.error(SyncErrorKind error, {DateTime? lastSyncedAt})
    : this._(SyncPhase.error, error: error, lastSyncedAt: lastSyncedAt);

  final SyncPhase phase;

  /// Which message to show, set for [SyncPhase.error].
  final SyncErrorKind? error;

  /// UTC time of the last successful sync, if any.
  final DateTime? lastSyncedAt;

  bool get isSyncing => phase == SyncPhase.syncing;
  bool get isError => phase == SyncPhase.error;

  @override
  bool operator ==(Object other) =>
      other is SyncStatus &&
      other.phase == phase &&
      other.error == error &&
      other.lastSyncedAt == lastSyncedAt;

  @override
  int get hashCode => Object.hash(phase, error, lastSyncedAt);

  @override
  String toString() => 'SyncStatus($phase, $error, $lastSyncedAt)';
}
