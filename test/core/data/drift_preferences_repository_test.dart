import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/data/connection/memory.dart';
import 'package:grind/core/data/data.dart';

void main() {
  late AppDatabase db;
  late DriftPreferencesRepository repo;

  setUp(() {
    db = openInMemoryDatabase();
    repo = DriftPreferencesRepository(
      db,
      clock: FixedClock(DateTime.utc(2026, 11, 3)),
    );
  });
  tearDown(() => db.close());

  test('reads as defaults before the first save', () async {
    final p = await repo.get();
    expect(p.workingHours, const Preferences().workingHours);
    expect(p.onboardingDone, isFalse);
  });

  test('save then get round-trips every field, one row', () async {
    final custom = const Preferences().copyWith(
      workingHours: {
        DateTime.sunday: [
          TimeRange.hm(8, 0, 12, 0),
          TimeRange.hm(13, 0, 17, 0),
        ],
        DateTime.monday: [TimeRange.hm(10, 0, 18, 30)],
      },
      deepWindows: [TimeRange.hm(8, 0, 10, 0), TimeRange.hm(20, 0, 22, 0)],
      lunch: const [],
      maxDeepBlocksPerDay: 3,
      deepBlockMinutes: 60,
      bufferBetweenEventsMinutes: 5,
      dailyCushionMinutes: 30,
      weekStart: DateTime.monday,
      defaultReminderLeadMinutes: 15,
      quietHours: TimeRange.hm(22, 0, 24, 0),
      timeZoneName: 'Europe/Berlin',
      localeCode: 'he',
      onboardingDone: true,
    );
    await repo.save(custom);
    await repo.save(custom.copyWith(maxDeepBlocksPerDay: 4));
    final back = await repo.get();
    expect(back.workingHours, custom.workingHours);
    expect(back.deepWindows, custom.deepWindows);
    expect(back.lunch, isEmpty);
    expect(back.maxDeepBlocksPerDay, 4);
    expect(back.deepBlockMinutes, 60);
    expect(back.bufferBetweenEventsMinutes, 5);
    expect(back.dailyCushionMinutes, 30);
    expect(back.weekStart, DateTime.monday);
    expect(back.defaultReminderLeadMinutes, 15);
    expect(back.quietHours, TimeRange.hm(22, 0, 24, 0));
    expect(back.timeZoneName, 'Europe/Berlin');
    expect(back.localeCode, 'he');
    expect(back.onboardingDone, isTrue);
    expect((await db.select(db.preferencesTable).get()).length, 1);

    await repo.save(back.copyWith(quietHours: null));
    expect((await repo.get()).quietHours, isNull);
  });

  test('v3: pip accessory and quiet hours across midnight', () async {
    expect((await repo.get()).pipAccessory, 'scarf');
    await repo.save(
      const Preferences(
        pipAccessory: 'beanie',
        quietHours: TimeRange.wrapping(
          startMinutes: 22 * 60,
          endMinutes: 7 * 60,
        ),
      ),
    );
    final back = await repo.get();
    expect(back.pipAccessory, 'beanie');
    expect(back.quietHours!.startMinutes, 22 * 60);
    expect(back.quietHours!.endMinutes, 7 * 60);
    expect(back.quietHours!.wrapsMidnight, isTrue);
  });

  test('watch emits current value then saves', () async {
    final emissions = <bool>[];
    final sub = repo.watch().listen((p) => emissions.add(p.onboardingDone));
    await pumpEventQueue();
    await repo.save(const Preferences(onboardingDone: true));
    await pumpEventQueue();
    await sub.cancel();
    expect(emissions, [false, true]);
  });
}
