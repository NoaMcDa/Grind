import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/theme/app_theme.dart';
import 'package:grind/theme/tokens.dart';

double _lum(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double contrast(Color a, Color b) {
  final l1 = _lum(a), l2 = _lum(b);
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

void main() {
  Map<String, dynamic> load(String l) =>
      json.decode(File('lib/l10n/app_$l.arb').readAsStringSync())
          as Map<String, dynamic>;
  Set<String> keys(Map<String, dynamic> m) =>
      m.keys.where((k) => !k.startsWith('@')).toSet();
  // Brace tokens such as `{count}` or `{count, plural, ...}`. Plural branch
  // words in braces (`other{days}`) also match, so compare against declared
  // placeholders rather than expecting an exact set.
  Set<String> tokens(String v) => RegExp(
    r'\{([A-Za-z_]\w*)\s*[,}]',
  ).allMatches(v).map((m) => m.group(1)!).toSet();
  Set<String> declared(Map<String, dynamic> en, String k) =>
      (((en['@$k'] as Map<String, dynamic>?)?['placeholders']
                  as Map<String, dynamic>?) ??
              {})
          .keys
          .toSet();

  test('ARB files have identical key sets and no empty values', () {
    final en = load('en'), he = load('he');
    expect(keys(he), keys(en));
    for (final k in keys(en)) {
      expect((en[k] as String).trim(), isNotEmpty, reason: k);
      expect((he[k] as String).trim(), isNotEmpty, reason: k);
    }
  });

  test('every EN key has a description and uses its declared placeholders', () {
    final en = load('en');
    for (final k in keys(en)) {
      final meta = en['@$k'] as Map<String, dynamic>?;
      expect(meta?['description'], isNotNull, reason: '@$k description');
      expect(
        tokens(en[k] as String).containsAll(declared(en, k)),
        isTrue,
        reason: k,
      );
    }
  });

  test('every placeholder in EN exists in HE, and HE adds none', () {
    final en = load('en'), he = load('he');
    for (final k in keys(en)) {
      final used = tokens(he[k] as String);
      final d = declared(en, k);
      expect(used.containsAll(d), isTrue, reason: '$k missing in HE');
      expect(d.containsAll(used), isTrue, reason: '$k has extra in HE');
    }
  });

  test('copy never uses guilt words (EN and HE)', () {
    final enBanned = RegExp(
      r'\b(should|failed|fail|again|missed|miss|behind|overdue|lazy|late|'
      r'must|forgot|you broke)\b',
      caseSensitive: false,
    );
    // Whole Hebrew words only (no adjacent Hebrew letters).
    final heWords = RegExp(
      r'(?<![א-ת])(שוב|צריך|צריכה|חייב|חייבת|נכשלת|פספסת)(?![א-ת])',
    );
    final heStems = RegExp('נכשל|פספס|כישלון|איחור');
    for (final l in ['en', 'he']) {
      final m = load(l);
      for (final k in keys(m)) {
        final v = m[k] as String;
        if (l == 'en') {
          expect(enBanned.hasMatch(v), isFalse, reason: '$l/$k: $v');
        } else {
          expect(heWords.hasMatch(v), isFalse, reason: '$l/$k: $v');
          expect(heStems.hasMatch(v), isFalse, reason: '$l/$k: $v');
        }
      }
    }
  });

  test('text colours meet WCAG AA (4.5:1) on their backgrounds', () {
    const ink = AppColors.ink;
    for (final bg in [
      AppColors.card,
      AppColors.ground,
      AppColors.sun,
      AppColors.mint,
      AppColors.sky,
      AppColors.pink,
      AppColors.lilac,
    ]) {
      expect(contrast(ink, bg), greaterThanOrEqualTo(4.5), reason: '$bg');
    }
    expect(contrast(Colors.white, AppColors.violet), greaterThanOrEqualTo(4.5));
    expect(contrast(AppColors.muted, AppColors.ground), greaterThan(4.5));
    expect(contrast(AppColors.muted, AppColors.card), greaterThan(4.5));
    expect(contrast(AppColors.error, AppColors.card), greaterThan(4.5));
    expect(
      contrast(AppColors.violetDark, AppColors.card),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('theme carries the sticker component themes', () {
    final t = buildAppTheme();
    expect(t.inputDecorationTheme.filled, isTrue);
    expect(t.bottomSheetTheme.backgroundColor, AppColors.card);
    expect(t.snackBarTheme.behavior, SnackBarBehavior.floating);
    expect(t.datePickerTheme.headerBackgroundColor, AppColors.violet);
    expect(t.timePickerTheme.dialHandColor, AppColors.violet);
  });
}
