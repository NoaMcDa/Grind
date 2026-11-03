/// What the calendar sync is doing right now, for a small status line.
enum SyncPhase { idle, syncing, error }

class SyncStatus {
  const SyncStatus._(this.phase, {this.message, this.lastSyncedAt});

  const SyncStatus.idle({DateTime? lastSyncedAt})
    : this._(SyncPhase.idle, lastSyncedAt: lastSyncedAt);

  const SyncStatus.syncing({DateTime? lastSyncedAt})
    : this._(SyncPhase.syncing, lastSyncedAt: lastSyncedAt);

  /// [message] is user-facing copy (Pip's tone).
  const SyncStatus.error(String message, {DateTime? lastSyncedAt})
    : this._(SyncPhase.error, message: message, lastSyncedAt: lastSyncedAt);

  final SyncPhase phase;

  /// User-facing copy, set for [SyncPhase.error].
  final String? message;

  /// UTC time of the last successful sync, if any.
  final DateTime? lastSyncedAt;

  bool get isSyncing => phase == SyncPhase.syncing;
  bool get isError => phase == SyncPhase.error;

  @override
  bool operator ==(Object other) =>
      other is SyncStatus &&
      other.phase == phase &&
      other.message == message &&
      other.lastSyncedAt == lastSyncedAt;

  @override
  int get hashCode => Object.hash(phase, message, lastSyncedAt);

  @override
  String toString() => 'SyncStatus($phase, $message, $lastSyncedAt)';
}
