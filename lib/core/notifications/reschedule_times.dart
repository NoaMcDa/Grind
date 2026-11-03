import 'package:timezone/timezone.dart' as tz;

/// Time math for the smart-snooze moves (#12). Pure; inputs and outputs are
/// UTC instants, day boundaries are read in the user's zone.
abstract final class RescheduleTimes {
  /// "Tonight" means 20:00 local.
  static const tonightHour = 20;

  /// Today at 20:00 local, or tomorrow at 20:00 when that is not after
  /// [now]. After midnight "today" is the new local day, so a tap at 00:30
  /// moves to 20:00 of that same day.
  static DateTime tonight(DateTime now, tz.Location location) {
    final utcNow = now.toUtc();
    final local = tz.TZDateTime.from(utcNow, location);
    var at = tz.TZDateTime(
      location,
      local.year,
      local.month,
      local.day,
      tonightHour,
    );
    if (!at.isAfter(utcNow)) {
      at = tz.TZDateTime(
        location,
        local.year,
        local.month,
        local.day + 1,
        tonightHour,
      );
    }
    return at.toUtc();
  }

  /// The local clock time of [reference] (the task's reminder) on the
  /// calendar day after [now]'s local date. DST-safe: 07:00 stays 07:00.
  static DateTime tomorrow(
    DateTime now,
    DateTime reference,
    tz.Location location,
  ) {
    final local = tz.TZDateTime.from(now.toUtc(), location);
    final ref = tz.TZDateTime.from(reference.toUtc(), location);
    return tz.TZDateTime(
      location,
      local.year,
      local.month,
      local.day + 1,
      ref.hour,
      ref.minute,
    ).toUtc();
  }
}
