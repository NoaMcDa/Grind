import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/core.dart';
import '../../../core/notifications/time_zones.dart';
import '../../calendar/google/key_value_store.dart';
import 'device_time_zone_stub.dart'
    if (dart.library.js_interop) 'device_time_zone_web.dart'
    if (dart.library.io) 'device_time_zone_io.dart';

/// The IANA zone the device is set to ("Europe/London"), if it can tell.
abstract interface class DeviceTimeZone {
  /// Null when the platform cannot say (tests, unsupported platforms).
  Future<String?> current();
}

/// iOS: `FlutterTimezone.getLocalTimezone()`. Web:
/// `Intl.DateTimeFormat().resolvedOptions().timeZone`. Elsewhere: null.
class PlatformDeviceTimeZone implements DeviceTimeZone {
  const PlatformDeviceTimeZone();

  @override
  Future<String?> current() async {
    try {
      return await readDeviceTimeZone();
    } catch (_) {
      return null;
    }
  }
}

/// Test double: set [zone] to what the "device" reports.
class FakeDeviceTimeZone implements DeviceTimeZone {
  FakeDeviceTimeZone([this.zone]);

  String? zone;
  int reads = 0;

  @override
  Future<String?> current() async {
    reads++;
    return zone;
  }
}

final deviceTimeZoneProvider = Provider<DeviceTimeZone>(
  (_) => const PlatformDeviceTimeZone(),
);

/// Remembers the device zone seen at the last launch, so a zone the user
/// picked by hand survives restarts until the device zone itself changes.
/// Keychain on iOS, localStorage on web.
final deviceTimeZoneMemoryProvider = Provider<KeyValueStore>(
  (_) => platformKeyValueStore(),
);

/// Key under [deviceTimeZoneMemoryProvider].
const lastDeviceTimeZoneKey = 'grind.timeZone.lastDevice';

/// Every zone name in the bundled IANA database, sorted.
List<String> timeZoneNames() {
  ensureTimeZones();
  return tz.timeZoneDatabase.locations.keys.toList()..sort();
}

/// Whether [name] is a zone in the bundled database (what the planner and
/// the notification scheduler can use).
bool isKnownTimeZone(String? name) {
  if (name == null || name.isEmpty) return false;
  ensureTimeZones();
  return tz.timeZoneDatabase.locations.containsKey(name);
}

/// Saves [name] as `Preferences.timeZoneName` if it is a known zone.
/// Returns false (and saves nothing) for an unknown name.
Future<bool> saveTimeZone(
  PreferencesRepository preferences,
  String name,
) async {
  if (!isKnownTimeZone(name)) return false;
  final prefs = await preferences.get();
  if (prefs.timeZoneName != name) {
    await preferences.save(prefs.copyWith(timeZoneName: name));
  }
  return true;
}

/// Sets `Preferences.timeZoneName` from the device when the device zone is
/// new: on the first run, and whenever it differs from the zone seen at the
/// previous launch (the user travelled or changed it in iOS Settings).
/// A zone picked by hand in Settings is kept while the device zone stays
/// the same. [force] (onboarding) applies the device zone regardless.
///
/// Returns the zone it saved, or null when nothing changed. Never throws:
/// an unknown or missing device zone leaves the preference alone.
Future<String?> applyDeviceTimeZone({
  required DeviceTimeZone device,
  required PreferencesRepository preferences,
  KeyValueStore? memory,
  bool force = false,
}) async {
  try {
    final zone = await device.current();
    if (!isKnownTimeZone(zone)) return null;
    String? last;
    try {
      last = await memory?.read(lastDeviceTimeZoneKey);
    } catch (_) {
      last = null;
    }
    if (!force && last == zone) return null;
    try {
      await memory?.write(lastDeviceTimeZoneKey, zone!);
    } catch (_) {
      // Without the memory the next launch simply checks again.
    }
    final prefs = await preferences.get();
    if (prefs.timeZoneName == zone) return null;
    await preferences.save(prefs.copyWith(timeZoneName: zone));
    return zone;
  } catch (_) {
    return null;
  }
}

/// Call once on launch from `GrindApp`'s `initState`:
///
/// ```dart
/// unawaited(syncDeviceTimeZone(ref));
/// ```
Future<String?> syncDeviceTimeZone(WidgetRef ref, {bool force = false}) =>
    applyDeviceTimeZone(
      device: ref.read(deviceTimeZoneProvider),
      preferences: ref.read(preferencesRepositoryProvider),
      memory: ref.read(deviceTimeZoneMemoryProvider),
      force: force,
    );
