// Shared by the Today / tasks / Plan tests: a `Preferences.timeZoneName`
// that equals the device zone, for tests written in device-local times.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/time_zones.dart';
import 'package:timezone/timezone.dart' as tz;

/// A zone with the device's offset on the test day (2026-10-29), so a test
/// that builds times with `DateTime(...)` (device local) sees the same
/// wall clock in the app as in its expectations, on any machine. UTC on CI.
String deviceZoneName() {
  ensureTimeZones();
  final offset = DateTime(2026, 10, 29, 12).timeZoneOffset;
  if (offset == Duration.zero) return 'UTC';
  final name = 'Test/Device${offset.inMinutes}';
  try {
    tz.getLocation(name);
  } on tz.LocationNotFoundException {
    tz.timeZoneDatabase.add(
      tz.Location(name, const [], const [], [
        tz.TimeZone(offset.inMilliseconds, isDst: false, abbreviation: 'DEV'),
      ]),
    );
  }
  return name;
}

/// [base] with its zone set to [deviceZoneName].
Preferences devicePrefs([Preferences base = const Preferences()]) =>
    base.copyWith(timeZoneName: deviceZoneName());

/// The demo user's preferences in the device zone.
Override devicePrefsOverride([
  Preferences base = const Preferences(onboardingDone: true),
]) => preferencesRepositoryProvider.overrideWithValue(
  InMemoryPreferencesRepository(devicePrefs(base)),
);
