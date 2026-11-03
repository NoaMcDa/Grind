import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/notifications/notifications.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  late tz.Location jlm;
  setUpAll(() {
    ensureTimeZones();
    jlm = tz.getLocation('Asia/Jerusalem');
  });

  // November 2026: Asia/Jerusalem is UTC+2.
  DateTime local(int month, int day, int h, [int m = 0]) =>
      tz.TZDateTime(jlm, 2026, month, day, h, m).toUtc();

  group('tonight', () {
    test('before 20:00 moves to 20:00 today', () {
      expect(
        RescheduleTimes.tonight(local(11, 3, 18), jlm),
        DateTime.utc(2026, 11, 3, 18),
      );
      expect(
        RescheduleTimes.tonight(local(11, 3, 19, 59), jlm),
        local(11, 3, 20),
      );
    });

    test('at or after 20:00 moves to 20:00 tomorrow', () {
      expect(RescheduleTimes.tonight(local(11, 3, 20), jlm), local(11, 4, 20));
      expect(
        RescheduleTimes.tonight(local(11, 3, 23, 30), jlm),
        DateTime.utc(2026, 11, 4, 18),
      );
    });

    test('just after midnight means tonight of the new day', () {
      // 00:30 local on 4 Nov is still 3 Nov in UTC.
      final now = local(11, 4, 0, 30);
      expect(now.day, 3);
      expect(RescheduleTimes.tonight(now, jlm), local(11, 4, 20));
    });

    test('keeps 20:00 local across the autumn DST change', () {
      // 24 Oct 21:00 (+3) -> 25 Oct 20:00 (+2).
      expect(
        RescheduleTimes.tonight(local(10, 24, 21), jlm),
        DateTime.utc(2026, 10, 25, 18),
      );
    });
  });

  group('tomorrow', () {
    test('same local time on the next day', () {
      expect(
        RescheduleTimes.tomorrow(local(11, 3, 9), local(11, 3, 8, 55), jlm),
        DateTime.utc(2026, 11, 4, 6, 55),
      );
    });

    test('across midnight in UTC and local time', () {
      // 23:30 local is 21:30Z; the reminder was 23:15 local.
      expect(
        RescheduleTimes.tomorrow(
          local(11, 3, 23, 30),
          local(11, 3, 23, 15),
          jlm,
        ),
        local(11, 4, 23, 15),
      );
      // 00:30 local on the 4th: "tomorrow" is the 5th.
      expect(
        RescheduleTimes.tomorrow(
          local(11, 4, 0, 30),
          local(11, 3, 23, 50),
          jlm,
        ),
        local(11, 5, 23, 50),
      );
    });

    test('07:00 stays 07:00 across DST', () {
      expect(
        RescheduleTimes.tomorrow(local(10, 24, 9), local(10, 24, 7), jlm),
        DateTime.utc(2026, 10, 25, 5),
      );
    });
  });
}
