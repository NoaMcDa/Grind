import 'package:flutter/material.dart';

import 'tokens.dart';

/// Typography: Bricolage Grotesque for display, DM Sans for everything else.
/// Both are bundled in assets/fonts (SIL Open Font License).
abstract final class AppText {
  static const displayFamily = 'Bricolage Grotesque';
  static const bodyFamily = 'DM Sans';

  static TextStyle display({
    double size = 30,
    FontWeight weight = FontWeight.w800,
    Color color = AppColors.ink,
    double height = 1.1,
    double letterSpacing = 0,
  }) => TextStyle(
    fontFamily: displayFamily,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  static TextStyle body({
    double size = 15,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.ink,
    double height = 1.4,
  }) => TextStyle(
    fontFamily: bodyFamily,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );

  static TextStyle bold({
    double size = 15,
    Color color = AppColors.ink,
    double height = 1.3,
  }) => body(size: size, weight: FontWeight.w700, color: color, height: height);

  /// Small uppercase section label with wide tracking.
  static TextStyle label({double size = 13, Color color = AppColors.muted}) =>
      TextStyle(
        fontFamily: bodyFamily,
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: size * 0.08,
        height: 1.2,
      );
}
