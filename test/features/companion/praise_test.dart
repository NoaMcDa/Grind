import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/companion/praise.dart';

void main() {
  test('50 lines, 50 in each language, 4 events', () {
    expect(PraisePool.total, 50);
    expect(PraisePool.lines.keys, containsAll(PraiseEvent.values));
    final hebrew = RegExp(r'[֐-׿]');
    for (final l in PraisePool.lines.values.expand((e) => e)) {
      expect(hebrew.hasMatch(l.he), isTrue, reason: l.he);
      expect(hebrew.hasMatch(l.en), isFalse, reason: l.en);
      expect(l.en.length, lessThan(60));
      expect(l.he.length, lessThan(60));
    }
    for (final e in PraiseEvent.values) {
      final pool = PraisePool.lines[e]!;
      expect(pool.length, greaterThanOrEqualTo(11), reason: '$e');
      expect(pool.map((l) => l.en).toSet(), hasLength(pool.length));
      expect(pool.map((l) => l.he).toSet(), hasLength(pool.length));
    }
  });

  test('no banned words in either language', () {
    for (final l in PraisePool.lines.values.expand((e) => e)) {
      final en = l.en.toLowerCase();
      for (final w in PraisePool.bannedEn) {
        expect(RegExp('\\b$w\\b').hasMatch(en), isFalse, reason: '"$w" in $en');
      }
      for (final w in PraisePool.bannedHe) {
        expect(l.he.contains(w), isFalse, reason: '"$w" in ${l.he}');
      }
      expect(l.en, isNot(contains('!!')));
      expect(l.en, isNot(contains('?')), reason: 'Pip never asks');
    }
  });

  test('rotation never repeats within the last 10 per event', () {
    final r = PraiseRotation();
    final day = DateTime(2026, 11, 3);
    for (final e in PraiseEvent.values) {
      final seen = <String>[];
      for (var i = 0; i < 60; i++) {
        final line = praiseFor(e, now: day, rotation: r);
        final window = seen.length > 10 ? seen.sublist(seen.length - 10) : seen;
        expect(window, isNot(contains(line)), reason: '$e #$i');
        seen.add(line);
      }
    }
  });

  test('deterministic for the same date and counter', () {
    final day = DateTime(2026, 11, 3);
    List<String> run() {
      final r = PraiseRotation();
      return [
        for (var i = 0; i < 12; i++)
          praiseFor(PraiseEvent.taskDone, now: day, rotation: r),
      ];
    }

    expect(run(), run());
  });

  test('locale and intensity are honoured', () {
    final r = PraiseRotation();
    final day = DateTime(2026, 11, 3);
    final he = praiseFor(
      PraiseEvent.sessionDone,
      locale: const Locale('he'),
      now: day,
      rotation: r,
    );
    expect(RegExp(r'[֐-׿]').hasMatch(he), isTrue);
    final big = PraiseRotation().pick(
      PraiseEvent.taskDone,
      intensity: PraiseIntensity.big,
      now: day,
    );
    expect(big.intensity, PraiseIntensity.big);
  });

  test('global praiseFor works without arguments', () {
    expect(praiseFor(PraiseEvent.showedUp), isNotEmpty);
  });
}
