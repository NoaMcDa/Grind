import 'package:flutter/material.dart';

import 'app_text.dart';
import 'tokens.dart';

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: AppText.bodyFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.violet,
      primary: AppColors.violet,
      surface: AppColors.ground,
      onSurface: AppColors.ink,
    ),
    scaffoldBackgroundColor: AppColors.ground,
    splashFactory: NoSplash.splashFactory,
  );
  const display = TextStyle(
    fontFamily: AppText.displayFamily,
    fontWeight: FontWeight.w800,
  );
  final text = base.textTheme.apply(
    bodyColor: AppColors.ink,
    displayColor: AppColors.ink,
  );
  return base.copyWith(
    textTheme: text.copyWith(
      displayLarge: text.displayLarge?.merge(display),
      displayMedium: text.displayMedium?.merge(display),
      displaySmall: text.displaySmall?.merge(display),
      headlineLarge: text.headlineLarge?.merge(display),
      headlineMedium: text.headlineMedium?.merge(display),
      headlineSmall: text.headlineSmall?.merge(display),
    ),
  );
}
