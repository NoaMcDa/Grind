/// User-facing copy for calendar sync, kept here until the integrator moves
/// it into the ARB files (see docs/plans/ownership.md).
abstract final class CalendarSyncStrings {
  static const genericError =
      "Pip couldn't reach your calendar just now. It will try again soon.";
  static const reconnect =
      'Pip needs a fresh hello from your calendar. Reconnect it in Settings.';
  static const untitledEvent = '(No title)';
  static const writtenByGrind = 'Planned with Grind.';
}
