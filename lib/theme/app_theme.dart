import 'package:flutter/material.dart';

import 'app_text.dart';
import 'tokens.dart';

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: AppText.bodyFamily,
    fontFamilyFallback: AppText.fallback,
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
    fontFamilyFallback: AppText.fallback,
    fontWeight: FontWeight.w800,
  );
  final text = base.textTheme.apply(
    bodyColor: AppColors.ink,
    displayColor: AppColors.ink,
  );
  return base.copyWith(
    inputDecorationTheme: stickerInputDecorationTheme(),
    bottomSheetTheme: stickerBottomSheetTheme(),
    snackBarTheme: stickerSnackBarTheme(),
    datePickerTheme: stickerDatePickerTheme(),
    timePickerTheme: stickerTimePickerTheme(),
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

OutlineInputBorder _inkBorder(double radius, [Color color = AppColors.ink]) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: color, width: AppStroke.border),
    );

/// Ink-bordered, 16 px radius inputs. Error state turns the border pink-red
/// via the text, never colour alone.
InputDecorationTheme stickerInputDecorationTheme({
  double radius = AppRadii.cardSmall,
}) => InputDecorationTheme(
  filled: true,
  fillColor: AppColors.card,
  isDense: false,
  contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
  border: _inkBorder(radius),
  enabledBorder: _inkBorder(radius),
  focusedBorder: _inkBorder(radius, AppColors.violet),
  errorBorder: _inkBorder(radius, AppColors.error),
  focusedErrorBorder: _inkBorder(radius, AppColors.error),
  disabledBorder: _inkBorder(radius, AppColors.muted),
  labelStyle: AppText.body(color: AppColors.muted),
  hintStyle: AppText.body(color: AppColors.muted),
  errorStyle: AppText.bold(size: 12, color: AppColors.error),
);

BottomSheetThemeData stickerBottomSheetTheme() => const BottomSheetThemeData(
  backgroundColor: AppColors.card,
  modalBackgroundColor: AppColors.card,
  surfaceTintColor: Colors.transparent,
  showDragHandle: false,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
    side: BorderSide(color: AppColors.ink, width: AppStroke.border),
  ),
);

SnackBarThemeData stickerSnackBarTheme() => SnackBarThemeData(
  behavior: SnackBarBehavior.floating,
  backgroundColor: AppColors.card,
  contentTextStyle: AppText.bold(),
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadii.row),
    side: const BorderSide(color: AppColors.ink, width: AppStroke.border),
  ),
);

DatePickerThemeData stickerDatePickerTheme() => DatePickerThemeData(
  backgroundColor: AppColors.card,
  surfaceTintColor: Colors.transparent,
  headerBackgroundColor: AppColors.violet,
  headerForegroundColor: Colors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadii.card),
    side: const BorderSide(color: AppColors.ink, width: AppStroke.border),
  ),
  dayStyle: AppText.body(),
  todayBorder: const BorderSide(color: AppColors.ink, width: 2),
  todayForegroundColor: const WidgetStatePropertyAll(AppColors.ink),
  dayBackgroundColor: WidgetStateProperty.resolveWith(
    (s) => s.contains(WidgetState.selected) ? AppColors.violet : null,
  ),
  dayForegroundColor: WidgetStateProperty.resolveWith(
    (s) => s.contains(WidgetState.selected) ? Colors.white : AppColors.ink,
  ),
);

TimePickerThemeData stickerTimePickerTheme() => TimePickerThemeData(
  backgroundColor: AppColors.card,
  hourMinuteColor: AppColors.lilac,
  hourMinuteTextColor: AppColors.ink,
  dialBackgroundColor: AppColors.lilac,
  dialHandColor: AppColors.violet,
  dialTextColor: WidgetStateColor.resolveWith(
    (s) => s.contains(WidgetState.selected) ? Colors.white : AppColors.ink,
  ),
  dayPeriodColor: WidgetStateColor.resolveWith(
    (s) =>
        s.contains(WidgetState.selected) ? AppColors.violet : AppColors.lilac,
  ),
  dayPeriodTextColor: WidgetStateColor.resolveWith(
    (s) => s.contains(WidgetState.selected) ? Colors.white : AppColors.ink,
  ),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadii.card),
    side: const BorderSide(color: AppColors.ink, width: AppStroke.border),
  ),
);
