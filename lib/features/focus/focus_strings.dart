/// Focus tab strings that are not in the ARB files yet. The integrator moves
/// these into `lib/l10n` after the wave. Pip's tone: warm, never guilt.
abstract final class FocusStrings {
  static const freeFocus = 'Free focus';
  static const breakLabel = 'BREAK';
  static const longBreakLabel = 'LONG BREAK';
  static const ready = 'READY';
  static String ofTotal(String total) => 'of $total';
  static const hardModeSoon = 'Hard mode · coming soon';
  static String minusMinutes(int m) => '−$m min';
  static const shorter = 'Shorter session';
  static const longer = 'Longer session';
  static const startNext = 'Start next focus';
  static const endBreak = 'End break';
  static const onBreak = 'ON A BREAK';

  // End-of-session sheet.
  static const doneTitle = 'Session done. Nice work.';
  static const earlyTitle = 'Session ended. It still counts.';
  static String focusedFor(int minutes, String? task) {
    final m = minutes == 1 ? '1 minute' : '$minutes minutes';
    return task == null
        ? 'You focused for $m.'
        : 'You focused for $m on $task.';
  }

  static const markDone = 'Mark task done';
  static const keepGoing = 'Keep going';
  static const logWin = 'Log a win';
  static const winLogged = 'Win logged. Pip saw that.';
  static const taskDone = 'Task done. Pip is proud of you.';

  // In-app alerts (stand-ins for the Lock Screen notification).
  static const sessionOverToast = 'Time! Session done, take a breather.';
  static const breakOverToast = "Break's over. Ready when you are.";

  // Pip's cheering pool, by where the session is.
  static const cheerIdle = [
    'Pick a length and press play. Pip will keep time.',
    'One small step is enough to start. Pip is right here.',
  ];
  static const cheerStart = [
    'The first minutes are the hardest, and you already started.',
    'Just the next small step. Nothing else matters right now.',
  ];
  static const cheerMiddle = [
    'Nice rhythm. Keep it simple.',
    'You are doing the thing. Pip is cheering quietly.',
  ];
  static const cheerPastHalf = [
    "You're past halfway. Keep going, the first draft just needs to exist.",
    'More than half done. Steady wins this.',
  ];
  static const cheerNearEnd = [
    'Almost there. Finish the sentence you are on.',
    'A few minutes left. Land it gently.',
  ];
  static const cheerPaused = [
    'Paused. Take a breath, Pip will wait.',
    'Little pauses are fine. Come back when you are ready.',
  ];
  static const cheerBreak = [
    'Break time. Stand up, stretch, drink some water.',
    'Rest is part of the work. Look at something far away.',
  ];

  /// A line for [progress] (0..1). [seed] picks within the pool so the line
  /// stays put for a session instead of flickering every tick.
  static String cheer({
    required bool idle,
    required bool paused,
    required bool onBreak,
    required double progress,
    int seed = 0,
  }) {
    final List<String> pool;
    if (onBreak) {
      pool = cheerBreak;
    } else if (idle) {
      pool = cheerIdle;
    } else if (paused) {
      pool = cheerPaused;
    } else if (progress < 0.25) {
      pool = cheerStart;
    } else if (progress < 0.5) {
      pool = cheerMiddle;
    } else if (progress < 0.85) {
      pool = cheerPastHalf;
    } else {
      pool = cheerNearEnd;
    }
    return pool[seed.abs() % pool.length];
  }
}
