import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/util/duration_input.dart';
import 'package:grind/l10n/app_localizations.dart';

void main() {
  group('parseDuration', () {
    test('plain minutes', () {
      expect(parseDuration('90'), 90);
      expect(parseDuration(' 45 '), 45);
      expect(parseDuration('1'), 1);
      expect(parseDuration('240'), 240);
    });

    test('hours with h suffix', () {
      expect(parseDuration('4h'), 240);
      expect(parseDuration('4 h'), 240);
      expect(parseDuration('4H'), 240);
      expect(parseDuration('1hr'), 60);
      expect(parseDuration('2hrs'), 120);
      expect(parseDuration('2hour'), 120);
      expect(parseDuration('2hours'), 120);
    });

    test('hours + minutes', () {
      expect(parseDuration('1h30'), 90);
      expect(parseDuration('1 h 30'), 90);
      expect(parseDuration('1h30m'), 90);
      expect(parseDuration('1h30min'), 90);
      expect(parseDuration('2h5'), 125);
    });

    test('colon form', () {
      expect(parseDuration('1:30'), 90);
      expect(parseDuration('0:45'), 45);
      expect(parseDuration('02:05'), 125);
      expect(parseDuration('4:00'), 240);
    });

    test('minutes with m suffix', () {
      expect(parseDuration('90m'), 90);
      expect(parseDuration('90min'), 90);
      expect(parseDuration('90 min'), 90);
      expect(parseDuration('90minutes'), 90);
    });

    test('returns null for malformed or empty', () {
      expect(parseDuration(''), isNull);
      expect(parseDuration('   '), isNull);
      expect(parseDuration('abc'), isNull);
      expect(parseDuration('1:60'), isNull); // minutes overflow
      expect(parseDuration('1:300'), isNull);
      expect(parseDuration('1h60'), isNull);
      expect(parseDuration('-30'), isNull);
    });

    test('rejects out-of-bounds durations', () {
      expect(parseDuration('0'), isNull);
      expect(parseDuration('25h'), isNull); // over one day
      expect(parseDuration('1441'), isNull);
      expect(parseDuration('1440'), 1440); // right at the cap
    });
  });

  group('formatDuration', () {
    late AppLocalizations en;
    late AppLocalizations he;

    setUpAll(() {
      en = lookupAppLocalizations(const Locale('en'));
      he = lookupAppLocalizations(const Locale('he'));
    });

    test('under an hour reads as minutes', () {
      expect(formatDuration(0, en), '0 min');
      expect(formatDuration(45, en), '45 min');
      expect(formatDuration(59, en), '59 min');
    });

    test('whole hours read as hours', () {
      expect(formatDuration(60, en), '1 h');
      expect(formatDuration(120, en), '2 h');
      expect(formatDuration(240, en), '4 h');
    });

    test('hours + leftover minutes', () {
      expect(formatDuration(90, en), '1 h 30 min');
      expect(formatDuration(125, en), '2 h 5 min');
    });

    test('negative input clamps to zero minutes', () {
      expect(formatDuration(-5, en), '0 min');
    });

    test('Hebrew locale uses דק׳ and שע׳', () {
      expect(formatDuration(45, he), '45 דק׳');
      expect(formatDuration(60, he), '1 שע׳');
      expect(formatDuration(90, he), '1 שע׳ 30 דק׳');
    });
  });
}
