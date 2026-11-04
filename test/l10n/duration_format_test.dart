import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:grind/l10n/app_localizations.dart';
import 'package:grind/l10n/duration_format.dart';

void main() {
  group('parseDuration', () {
    test('plain digits are minutes', () {
      expect(parseDuration('90'), 90);
      expect(parseDuration(' 15 '), 15);
    });

    test('hour shapes', () {
      expect(parseDuration('4h'), 240);
      expect(parseDuration('4 h'), 240);
      expect(parseDuration('4hr'), 240);
      expect(parseDuration('4 hours'), 240);
      expect(parseDuration('1 hour'), 60);
    });

    test('colon shapes', () {
      expect(parseDuration('1:30'), 90);
      expect(parseDuration('0:45'), 45);
      expect(parseDuration('2:00'), 120);
      // Minutes field >= 60 is a bogus shape.
      expect(parseDuration('1:90'), isNull);
    });

    test('hour + minute shapes', () {
      expect(parseDuration('1h30'), 90);
      expect(parseDuration('1h30m'), 90);
      expect(parseDuration('1 h 30 m'), 90);
      expect(parseDuration('1 h 30 min'), 90);
      expect(parseDuration('30m'), 30);
      expect(parseDuration('30 min'), 30);
    });

    test('hebrew tokens', () {
      expect(parseDuration('4 שעות'), 240);
      expect(parseDuration('1 שעה'), 60);
      expect(parseDuration('90 דק׳'), 90);
      expect(parseDuration('1 ש׳ 30 דק׳'), 90);
    });

    test('invalid input returns null', () {
      expect(parseDuration(''), isNull);
      expect(parseDuration('abc'), isNull);
      expect(parseDuration('h'), isNull);
      expect(parseDuration('1:'), isNull);
    });
  });

  group('formatDuration', () {
    late AppLocalizations en;
    late AppLocalizations he;
    setUpAll(() async {
      en = await AppLocalizations.delegate.load(const Locale('en'));
      he = await AppLocalizations.delegate.load(const Locale('he'));
    });

    test('below an hour', () {
      expect(formatDuration(0, en), '0 min');
      expect(formatDuration(45, en), '45 min');
      expect(formatDuration(45, he), '45 דק׳');
    });

    test('round hours', () {
      expect(formatDuration(60, en), '1 h');
      expect(formatDuration(240, en), '4 h');
      expect(formatDuration(60, he), '1 ש׳');
    });

    test('hours + minutes', () {
      expect(formatDuration(90, en), '1 h 30 min');
      expect(formatDuration(135, en), '2 h 15 min');
      expect(formatDuration(90, he), '1 ש׳ 30 דק׳');
    });

    test('negative is clamped to zero', () {
      expect(formatDuration(-3, en), '0 min');
    });
  });
}
