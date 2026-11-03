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
  test('ARB files have identical key sets and no empty values', () {
    Map<String, dynamic> load(String l) =>
        json.decode(File('lib/l10n/app_$l.arb').readAsStringSync())
            as Map<String, dynamic>;
    Set<String> keys(Map<String, dynamic> m) =>
        m.keys.where((k) => !k.startsWith('@')).toSet();
    final en = load('en'), he = load('he');
    expect(keys(he), keys(en));
    for (final k in keys(en)) {
      expect((en[k] as String).trim(), isNotEmpty, reason: k);
      expect((he[k] as String).trim(), isNotEmpty, reason: k);
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
