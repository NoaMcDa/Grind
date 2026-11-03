import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/calendar/google/key_value_store.dart';
import 'package:grind/features/settings/time_zone/device_time_zone.dart';
import 'package:grind/features/settings/time_zone/time_zone_picker.dart';

void main() {
  late InMemoryPreferencesRepository prefs;
  late InMemoryKeyValueStore memory;
  late FakeDeviceTimeZone device;

  Future<String?> apply({bool force = false}) => applyDeviceTimeZone(
    device: device,
    preferences: prefs,
    memory: memory,
    force: force,
  );

  setUp(() {
    prefs = InMemoryPreferencesRepository();
    memory = InMemoryKeyValueStore();
    device = FakeDeviceTimeZone('Europe/London');
  });

  test('first launch takes the device zone instead of the default', () async {
    expect((await prefs.get()).timeZoneName, 'Asia/Jerusalem');
    expect(await apply(), 'Europe/London');
    expect((await prefs.get()).timeZoneName, 'Europe/London');
    expect(memory.values[lastDeviceTimeZoneKey], 'Europe/London');
  });

  test(
    'a zone picked by hand survives launches on the same device zone',
    () async {
      await apply();
      await saveTimeZone(prefs, 'Asia/Tokyo');
      expect(await apply(), isNull);
      expect((await prefs.get()).timeZoneName, 'Asia/Tokyo');
    },
  );

  test('a new device zone on launch replaces the saved one', () async {
    await apply();
    device.zone = 'America/New_York';
    expect(await apply(), 'America/New_York');
    expect((await prefs.get()).timeZoneName, 'America/New_York');
  });

  test('force (onboarding) applies even when the zone was seen', () async {
    await apply();
    await saveTimeZone(prefs, 'Asia/Tokyo');
    expect(await apply(force: true), 'Europe/London');
  });

  test('unknown or missing device zones change nothing', () async {
    device.zone = 'Mars/Olympus_Mons';
    expect(await apply(), isNull);
    device.zone = null;
    expect(await apply(), isNull);
    expect((await prefs.get()).timeZoneName, 'Asia/Jerusalem');
    expect(memory.values, isEmpty);
  });

  test('a failing memory store still applies the zone', () async {
    expect(
      await applyDeviceTimeZone(
        device: device,
        preferences: prefs,
        memory: _ThrowingStore(),
      ),
      'Europe/London',
    );
  });

  test('saveTimeZone validates against the database', () async {
    expect(await saveTimeZone(prefs, 'Not/AZone'), isFalse);
    expect((await prefs.get()).timeZoneName, 'Asia/Jerusalem');
    expect(await saveTimeZone(prefs, 'Europe/Paris'), isTrue);
    expect((await prefs.get()).timeZoneName, 'Europe/Paris');
  });

  test('the platform reader reports null off iOS and web', () async {
    expect(await const PlatformDeviceTimeZone().current(), isNull);
  });

  test('names come from the database; search ignores case and spaces', () {
    final names = timeZoneNames();
    expect(names, contains('Asia/Jerusalem'));
    expect(names.every(isKnownTimeZone), isTrue);
    expect(filterTimeZones(names, 'new york'), ['America/New_York']);
    expect(filterTimeZones(names, 'TOKYO'), ['Asia/Tokyo']);
    expect(timeZoneLabel('America/New_York'), 'America/New York');
  });
}

class _ThrowingStore implements KeyValueStore {
  @override
  Future<String?> read(String key) => throw StateError('no keychain');
  @override
  Future<void> write(String key, String value) => throw StateError('no');
  @override
  Future<void> delete(String key) => throw StateError('no');
  @override
  Future<void> deletePrefix(String prefix) => throw StateError('no');
}
