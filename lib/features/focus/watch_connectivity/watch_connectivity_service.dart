/// Mirrors focus session start/stop between the phone and the Apple Watch
/// companion (#46). Each call is best effort: on web, Android, desktop,
/// tests and iOS with no paired watch the calls do nothing, and a failure
/// never reaches the focus controller.
///
/// The watch target itself and the Swift WatchConnectivity bridge come in
/// later slices of the epic — this interface is what the phone side will
/// call, and what tests can fake without depending on any plugin.
abstract interface class WatchConnectivityService {
  /// Tells a paired watch a focus session is now running on the phone. The
  /// watch mirrors it on its Pip screen and starts its own ticking timer.
  ///
  /// [taskTitle] is what the watch shows for the session; [endDate] is when
  /// the timer reaches zero if it keeps running. [pausedAt] starts the
  /// mirror frozen (used after a restart).
  ///
  /// Returns false when nothing was mirrored (no paired watch, the plugin
  /// is missing, the session is unreachable).
  Future<bool> startSession({
    required String taskTitle,
    required DateTime endDate,
    DateTime? pausedAt,
  });

  /// Pause, resume or +5 min on the watch side. [endDate] is when the timer
  /// reaches zero if it keeps running; [pausedAt] is when the pause began
  /// (now when null).
  Future<void> updateSession({
    required bool paused,
    required DateTime endDate,
    DateTime? pausedAt,
  });

  /// Ends the mirrored session (finished or stopped early). Safe to call
  /// when nothing is showing.
  Future<void> endSession();

  /// A stream of session-control events the watch raised (Start, Pause,
  /// Resume, Stop). The focus controller listens and drives the phone-side
  /// session to match. Broadcast so widgets can also subscribe when needed.
  Stream<WatchSessionEvent> events();
}

/// A control event raised by the watch and relayed through WatchConnectivity.
/// The phone decides what to do: start a focus session for [taskId] when the
/// watch asked to start, or pause/resume/stop the current one.
class WatchSessionEvent {
  const WatchSessionEvent({required this.kind, this.taskId, this.at});

  final WatchSessionEventKind kind;

  /// The task the watch asked to focus on (Start only). The watch picks it
  /// from the next-reminder snapshot the complication reads, so the id is
  /// one the phone's task repository already knows.
  final String? taskId;

  /// When the watch raised the event (UTC). The phone uses it to ignore an
  /// event delivered long after the session has already changed.
  final DateTime? at;

  @override
  bool operator ==(Object other) =>
      other is WatchSessionEvent &&
      other.kind == kind &&
      other.taskId == taskId &&
      other.at == at;

  @override
  int get hashCode => Object.hash(kind, taskId, at);

  @override
  String toString() =>
      'WatchSessionEvent(kind: $kind, taskId: $taskId, at: $at)';
}

enum WatchSessionEventKind { start, pause, resume, stop }

/// Off iOS, or when nothing is paired: does nothing and emits no events.
class NoopWatchConnectivityService implements WatchConnectivityService {
  const NoopWatchConnectivityService();

  @override
  Future<bool> startSession({
    required String taskTitle,
    required DateTime endDate,
    DateTime? pausedAt,
  }) async => false;

  @override
  Future<void> updateSession({
    required bool paused,
    required DateTime endDate,
    DateTime? pausedAt,
  }) async {}

  @override
  Future<void> endSession() async {}

  @override
  Stream<WatchSessionEvent> events() => const Stream.empty();
}
