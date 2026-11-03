import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/settings/quiet_hours.dart';

void main() {
  test('the default is overnight', () {
    expect(defaultQuietHours.wrapsMidnight, isTrue);
    expect(defaultQuietHours.contains(23 * 60), isTrue);
    expect(defaultQuietHours.contains(6 * 60 + 59), isTrue);
    expect(defaultQuietHours.contains(7 * 60), isFalse);
    expect(formatQuietHours(defaultQuietHours), '22:00 – 07:00');
  });

  test('changing one end keeps the other, in any order', () {
    final r = changeQuietHours(defaultQuietHours, end: 6 * 60)!;
    expect((r.startMinutes, r.endMinutes), (22 * 60, 6 * 60));
    final day = changeQuietHours(defaultQuietHours, start: 5 * 60)!;
    expect((day.startMinutes, day.endMinutes), (5 * 60, 7 * 60));
    expect(day.wrapsMidnight, isFalse);
  });

  test('an empty range is refused', () {
    expect(changeQuietHours(defaultQuietHours, start: 7 * 60), isNull);
  });

  test('a stored 22:00–24:00 can be moved past midnight', () {
    const old = TimeRange(startMinutes: 22 * 60, endMinutes: 24 * 60);
    final r = changeQuietHours(old, end: 7 * 60)!;
    expect(r, defaultQuietHours);
  });
}
