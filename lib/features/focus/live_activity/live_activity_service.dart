/// What the Lock Screen / Dynamic Island shows for a focus session (#20).
/// See docs/adr/0007-live-activity.md.
///
/// Every call is best effort: on web, Android, desktop, tests and iOS below
/// 16.2 the calls do nothing, and a failure on iOS never reaches the timer.
abstract interface class LiveActivityService {
  /// Shows the activity for a session ending at [endDate]. Replaces any
  /// activity still on screen (e.g. from before a restart). Pass [pausedAt]
  /// to start frozen (a paused session restored after a restart).
  ///
  /// [focusingLabel] and [pausedLabel] are the status words in the user's
  /// language; the widget extension cannot read the app's ARB files.
  ///
  /// Returns false when nothing was shown (unsupported, or the user turned
  /// Live Activities off for Grind).
  Future<bool> start({
    required String taskTitle,
    required DateTime endDate,
    String accessory = 'none',
    DateTime? pausedAt,
    String focusingLabel = 'Focusing',
    String pausedLabel = 'Paused',
  });

  /// Pause, resume or +5 min: [endDate] is when the timer reaches zero if it
  /// keeps running; [pausedAt] is when the pause began (now when null).
  Future<void> update({
    required bool paused,
    required DateTime endDate,
    DateTime? pausedAt,
  });

  /// Removes the activity (session finished or ended early). Safe to call
  /// when none is showing.
  Future<void> end();
}

/// Off iOS: does nothing.
class NoopLiveActivityService implements LiveActivityService {
  const NoopLiveActivityService();

  @override
  Future<bool> start({
    required String taskTitle,
    required DateTime endDate,
    String accessory = 'none',
    DateTime? pausedAt,
    String focusingLabel = 'Focusing',
    String pausedLabel = 'Paused',
  }) async => false;

  @override
  Future<void> update({
    required bool paused,
    required DateTime endDate,
    DateTime? pausedAt,
  }) async {}

  @override
  Future<void> end() async {}
}
