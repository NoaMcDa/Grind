import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/core.dart';
import '../../core/notifications/time_zones.dart';

/// "Today" and "this day" in the user's zone (`Preferences.timeZoneName`),
/// not the device's. Today, tasks, Plan and the scheduler wiring all take
/// their day boundaries from here, so the Today list and the reminders
/// agree on what day it is even when the device sits in another zone.

/// One local day in a zone: `[start, end)`, both midnights in [location].
class DayBounds {
  const DayBounds(this.start, this.end);

  final tz.TZDateTime start;
  final tz.TZDateTime end;

  tz.Location get location => start.location;

  /// The day's date as a floating `DateTime(y, m, d)` (device-local fields,
  /// the form Plan uses for "a day").
  DateTime get date => DateTime(start.year, start.month, start.day);

  /// Whether the instant [t] falls inside the day.
  bool contains(DateTime? t) {
    if (t == null) return false;
    return !t.isBefore(start) && t.isBefore(end);
  }

  /// The day [days] later (DST safe: by calendar date, not 24 h steps).
  DayBounds shift(int days) =>
      dayBoundsOf(DateTime(date.year, date.month, date.day + days), location);

  @override
  bool operator ==(Object other) =>
      other is DayBounds &&
      other.start.isAtSameMomentAs(start) &&
      other.end.isAtSameMomentAs(end) &&
      other.location.name == location.name;

  @override
  int get hashCode => Object.hash(start.millisecondsSinceEpoch, location.name);

  @override
  String toString() => 'DayBounds($start, $end)';
}

/// The local day in [tzName] that contains the instant [nowUtc].
DayBounds localDayBounds(DateTime nowUtc, String tzName) =>
    localDayBoundsIn(nowUtc, locationFor(tzName));

/// [localDayBounds] for an already resolved [location].
DayBounds localDayBoundsIn(DateTime now, tz.Location location) {
  final l = tz.TZDateTime.from(now, location);
  return dayBoundsOf(DateTime(l.year, l.month, l.day), location);
}

/// The bounds of the calendar date [date] (its y/m/d fields only) in
/// [location].
DayBounds dayBoundsOf(DateTime date, tz.Location location) => DayBounds(
  tz.TZDateTime(location, date.year, date.month, date.day),
  tz.TZDateTime(location, date.year, date.month, date.day + 1),
);

/// The instant [t] as wall-clock fields in [location], carried in a
/// device-local `DateTime`. The Plan screens and the scheduler core compute
/// in "local" `DateTime`s; feeding them zone wall-clock values makes their
/// days and working hours the user's zone. Convert back with [fromZoneWall].
///
/// Limitation: a wall time that does not exist on the device (its own
/// spring-forward hour, when the device zone differs from [location]) is
/// normalised by `DateTime` one hour later.
DateTime zoneWall(DateTime t, tz.Location location) {
  final l = tz.TZDateTime.from(t, location);
  return DateTime(
    l.year,
    l.month,
    l.day,
    l.hour,
    l.minute,
    l.second,
    l.millisecond,
  );
}

/// The UTC instant of the wall-clock fields of [wall] in [location]; the
/// inverse of [zoneWall].
DateTime fromZoneWall(DateTime wall, tz.Location location) => utcOf(
  tz.TZDateTime(
    location,
    wall.year,
    wall.month,
    wall.day,
    wall.hour,
    wall.minute,
    wall.second,
    wall.millisecond,
  ),
);

/// [t] as a plain UTC `DateTime` (a `TZDateTime` never equals one, so
/// values stored on tasks are always plain).
DateTime utcOf(DateTime t) =>
    DateTime.fromMicrosecondsSinceEpoch(t.microsecondsSinceEpoch, isUtc: true);

/// The user's zone from preferences (the default zone while they load).
final zoneLocationProvider = Provider<tz.Location>((ref) {
  final name = ref.watch(
    preferencesProvider.select(
      (p) => p.valueOrNull?.timeZoneName ?? const Preferences().timeZoneName,
    ),
  );
  return locationFor(name);
});

/// The clock, re-read every minute so "today" rolls over at midnight.
final minuteTickProvider = StreamProvider.autoDispose<DateTime>((ref) async* {
  final clock = ref.watch(clockProvider);
  yield clock.now();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => clock.now());
});

/// Today in the user's zone. Only changes when the day does.
final todayBoundsProvider = Provider.autoDispose<DayBounds>((ref) {
  final location = ref.watch(zoneLocationProvider);
  final now =
      ref.watch(minuteTickProvider).valueOrNull ??
      ref.watch(clockProvider).now();
  return localDayBoundsIn(now, location);
});
