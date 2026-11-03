import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/plan/plan_layout.dart';

void main() {
  test('snapMinutes rounds to 15', () {
    expect(snapMinutes(7), 0);
    expect(snapMinutes(8), 15);
    expect(snapMinutes(762.5), 765);
    expect(snapMinutes(-20), -15);
  });

  test('packColumns puts overlapping items side by side', () {
    final placed = packColumns<(int, int)>(
      [(600, 690), (630, 720), (720, 780), (900, 960)],
      (i) => i.$1,
      (i) => i.$2,
    );
    Placed<(int, int)> of(int s) => placed.firstWhere((p) => p.item.$1 == s);
    expect(of(600).columns, 2);
    expect(of(630).columns, 2);
    expect(of(600).column, isNot(of(630).column));
    expect(of(720).columns, 1);
    expect(of(900).columns, 1);
  });

  test('planHourRange pads working hours and is at least 08-18', () {
    final r = planHourRange(const Preferences());
    expect(r.start, 8);
    expect(r.end, 19);
    final wide = planHourRange(const Preferences(), [(6 * 60, 7 * 60)]);
    expect(wide.start, 6);
    final narrow = planHourRange(const Preferences(workingHours: {}));
    expect((narrow.start, narrow.end), (8, 18));
  });

  test('weekOf starts on the preferred weekday', () {
    final thu = DateTime(2026, 10, 29);
    expect(weekOf(thu, DateTime.sunday).first, DateTime(2026, 10, 25));
    expect(weekOf(thu, DateTime.monday).first, DateTime(2026, 10, 26));
    expect(weekOf(thu, DateTime.monday), hasLength(7));
  });

  test('events created in another zone are laid out in local time', () {
    // 13:00 local today, written as a Tokyo wall-clock instant.
    final local = DateTime(2026, 10, 29, 13);
    final tokyo = local.toUtc().add(const Duration(hours: 9));
    final iso = tokyo.toIso8601String().replaceAll('Z', '');
    final parsed = DateTime.parse('$iso+09:00');
    expect(parsed.isUtc, isTrue);
    expect(minutesIntoDay(parsed, DateTime(2026, 10, 29)), 13 * 60);
  });

  test('dayLoad caps at 1 and ignores all-day and free events', () {
    final day = DateTime(2026, 10, 29);
    final now = DateTime.utc(2026);
    CalendarEvent ev(bool allDay, bool busy, int h1, int h2) => CalendarEvent(
      id: '$allDay$busy$h1',
      source: CalendarSource.local,
      externalId: 'x',
      title: 't',
      start: DateTime(2026, 10, 29, h1).toUtc(),
      end: DateTime(2026, 10, 29, h2).toUtc(),
      isAllDay: allDay,
      isBusy: busy,
      createdAt: now,
      updatedAt: now,
    );
    const prefs = Preferences();
    expect(
      dayLoad(
        day: day,
        tasks: const [],
        events: [ev(true, true, 0, 23), ev(false, false, 9, 18)],
        prefs: prefs,
      ),
      0,
    );
    expect(
      dayLoad(
        day: day,
        tasks: const [],
        events: [ev(false, true, 9, 18), ev(false, true, 9, 18)],
        prefs: prefs,
      ),
      1,
    );
  });
}
