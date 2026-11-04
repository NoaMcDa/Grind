import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart' show TimeRange;
import 'package:grind/features/ask/unstick_block_split.dart';

DateTime _at(int hour, int minute) => DateTime(2026, 11, 4, hour, minute);

FocusBlock _b(int sh, int sm, int eh, int em) =>
    FocusBlock(_at(sh, sm), _at(eh, em));

void main() {
  group('even halves on the 5-minute grid', () {
    test(
      'a 60-minute block splits into 25 / 5 / 30 with a bumped first half',
      () {
        final res = splitLongBlock(_b(9, 0, 10, 0));
        expect(res.isOk, isTrue);
        final s = res.split!;
        // 60 - 5 (gap) = 55 focus minutes. Floor-half is 25, bumped first is 30
        // but 30 + 25 >= minPart (15), so the heavier half lands first.
        expect(s.first, _b(9, 0, 9, 30));
        expect(s.gap, _b(9, 30, 9, 35));
        expect(s.second, _b(9, 35, 10, 0));
        expect(s.totalFocusMinutes, 55);
        expect(s.blocks, [s.first, s.second]);
      },
    );

    test('a 50-minute block splits cleanly in half with a 5-minute gap', () {
      final res = splitLongBlock(_b(14, 0, 14, 50));
      expect(res.isOk, isTrue);
      final s = res.split!;
      // 50 - 5 (gap) = 45. Floor-half is 20, bumped first is 25, second 20.
      expect(s.first, _b(14, 0, 14, 25));
      expect(s.gap, _b(14, 25, 14, 30));
      expect(s.second, _b(14, 30, 14, 50));
    });

    test('a 90-minute block splits into 40 / 5 / 45', () {
      final res = splitLongBlock(_b(9, 0, 10, 30));
      expect(res.isOk, isTrue);
      final s = res.split!;
      // 90 - 5 = 85. Floor-half is 40, bumped first is 45 but 45 + 40 == 85
      // which keeps the second half >= 15, so first = 45 … then second = 40.
      // The tie-break prefers the heavier half first: first = 45.
      expect(s.first, _b(9, 0, 9, 45));
      expect(s.gap, _b(9, 45, 9, 50));
      expect(s.second, _b(9, 50, 10, 30));
    });

    test('result covers exactly the original window', () {
      const original = (9, 0, 10, 0);
      final res = splitLongBlock(_b(9, 0, 10, 0));
      final s = res.split!;
      expect(s.first.start, _at(original.$1, original.$2));
      expect(s.second.end, _at(original.$3, original.$4));
      expect(s.gap.start, s.first.end);
      expect(s.second.start, s.gap.end);
    });
  });

  group('too short to split', () {
    test('a 25-minute block is refused (needs 2 * 15 + 5 = 35)', () {
      final res = splitLongBlock(_b(9, 0, 9, 25));
      expect(res.isOk, isFalse);
      expect(res.refusal, SplitRefusal.tooShort);
    });

    test('a 30-minute block is refused at the default thresholds', () {
      final res = splitLongBlock(_b(9, 0, 9, 30));
      expect(res.refusal, SplitRefusal.tooShort);
    });

    test('a 35-minute block is the smallest that splits', () {
      final res = splitLongBlock(_b(9, 0, 9, 35));
      expect(res.isOk, isTrue);
      final s = res.split!;
      // 35 - 5 = 30 focus minutes. Both halves are 15.
      expect(s.first.minutes, 15);
      expect(s.second.minutes, 15);
    });

    test('empty and inverted blocks are refused', () {
      expect(splitLongBlock(_b(9, 0, 9, 0)).refusal, SplitRefusal.tooShort);
      expect(
        splitLongBlock(FocusBlock(_at(10, 0), _at(9, 0))).refusal,
        SplitRefusal.tooShort,
      );
    });
  });

  group('tunable gap and min-part', () {
    test('a longer gap still splits an hour cleanly on the grid', () {
      final res = splitLongBlock(_b(9, 0, 10, 0), gapMinutes: 10);
      expect(res.isOk, isTrue);
      final s = res.split!;
      // 60 - 10 = 50. Halves: 25 / 25.
      expect(s.first, _b(9, 0, 9, 25));
      expect(s.gap, _b(9, 25, 9, 35));
      expect(s.second, _b(9, 35, 10, 0));
    });

    test('gap and min-part round up to the 5-minute grid', () {
      // gap = 3 rounds to 5, minPart = 11 rounds to 15.
      final res = splitLongBlock(
        _b(9, 0, 9, 35),
        gapMinutes: 3,
        minPartMinutes: 11,
      );
      expect(res.isOk, isTrue);
      final s = res.split!;
      expect(s.gap.minutes, 5);
      expect(s.first.minutes, 15);
      expect(s.second.minutes, 15);
    });

    test('a bigger min-part refuses a block that the defaults would split', () {
      final res = splitLongBlock(_b(9, 0, 9, 40), minPartMinutes: 20);
      expect(res.refusal, SplitRefusal.tooShort);
    });
  });

  group('quiet hours', () {
    final overnight = const TimeRange.wrapping(
      startMinutes: 22 * 60,
      endMinutes: 7 * 60,
    );

    test('a split in the middle of the day is unaffected', () {
      final res = splitLongBlock(_b(10, 0, 11, 0), quietHours: overnight);
      expect(res.isOk, isTrue);
    });

    test('a block that starts in overnight quiet hours is refused', () {
      // 06:30–07:30 overlaps the overnight 22:00–07:00 window on the first
      // half (06:30–06:55).
      final res = splitLongBlock(_b(6, 30, 7, 30), quietHours: overnight);
      expect(res.refusal, SplitRefusal.quietHoursOverlap);
    });

    test('a block that spills into overnight quiet hours is refused', () {
      // 21:00–22:30 → second half crosses 22:00.
      final res = splitLongBlock(_b(21, 0, 22, 30), quietHours: overnight);
      expect(res.refusal, SplitRefusal.quietHoursOverlap);
    });

    test('a daytime quiet window inside a half is refused', () {
      // Lunch quiet hours: 12:30–13:00 overlap the second half of 12:00–13:00.
      final lunch = TimeRange.hm(12, 30, 13, 0);
      expect(
        splitLongBlock(_b(12, 0, 13, 0), quietHours: lunch).refusal,
        SplitRefusal.quietHoursOverlap,
      );
    });

    test('quiet-hours overlap is detected inside the second half', () {
      // 09:00–10:00 → first 09:00–09:30, gap 09:30–09:35, second 09:35–10:00.
      // Quiet hours 09:40–09:50 land in the second half only.
      final tiny = TimeRange.hm(9, 40, 9, 50);
      final res = splitLongBlock(_b(9, 0, 10, 0), quietHours: tiny);
      expect(res.refusal, SplitRefusal.quietHoursOverlap);
    });

    test(
      'quiet hours that fit exactly inside the gap still allow the split',
      () {
        // 09:00–10:00 → gap 09:30–09:35. A quiet-hours window that matches
        // the gap exactly leaves both halves clean.
        final gapOnly = TimeRange.hm(9, 30, 9, 35);
        final res = splitLongBlock(_b(9, 0, 10, 0), quietHours: gapOnly);
        expect(res.isOk, isTrue);
      },
    );
  });

  group('determinism and equality', () {
    test('the same input returns the same split', () {
      final a = splitLongBlock(_b(9, 0, 10, 30));
      final b = splitLongBlock(_b(9, 0, 10, 30));
      expect(a.split, b.split);
    });

    test('FocusBlockSplit value equality matches on all three fields', () {
      final s1 = FocusBlockSplit(
        first: _b(9, 0, 9, 30),
        second: _b(9, 35, 10, 0),
        gap: _b(9, 30, 9, 35),
      );
      final s2 = FocusBlockSplit(
        first: _b(9, 0, 9, 30),
        second: _b(9, 35, 10, 0),
        gap: _b(9, 30, 9, 35),
      );
      expect(s1, s2);
      expect(s1.hashCode, s2.hashCode);
    });
  });
}
