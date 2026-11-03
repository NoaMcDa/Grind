import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Loads the IANA database once (the 10-year slice: enough for a 7-day
/// horizon and much smaller on web than `latest_all`). Safe to call often.
void ensureTimeZones() {
  if (!tz.timeZoneDatabase.isInitialized) tz_data.initializeTimeZones();
}

/// The user's zone, falling back to UTC for an unknown name so a bad
/// preference can never stop reminders from being scheduled.
tz.Location locationFor(String timeZoneName) {
  ensureTimeZones();
  try {
    return tz.getLocation(timeZoneName);
  } on tz.LocationNotFoundException {
    return tz.UTC;
  }
}
