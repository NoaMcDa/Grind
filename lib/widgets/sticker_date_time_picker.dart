import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

Widget _themed(BuildContext context, Widget? child) {
  final base = Theme.of(context);
  return Theme(
    data: base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.violet,
        onPrimary: Colors.white,
        surface: AppColors.card,
        onSurface: AppColors.ink,
      ),
      datePickerTheme: stickerDatePickerTheme(),
      timePickerTheme: stickerTimePickerTheme(),
    ),
    child: child ?? const SizedBox.shrink(),
  );
}

/// Material date picker themed to the palette.
Future<DateTime?> showStickerDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) => showDatePicker(
  context: context,
  initialDate: initialDate,
  firstDate: firstDate ?? DateTime(initialDate.year - 1),
  lastDate: lastDate ?? DateTime(initialDate.year + 5),
  builder: _themed,
);

/// Material time picker themed to the palette.
Future<TimeOfDay?> showStickerTimePicker(
  BuildContext context, {
  required TimeOfDay initialTime,
}) => showTimePicker(
  context: context,
  initialTime: initialTime,
  builder: _themed,
);

/// Date, then time. Returns null if either step is cancelled.
Future<DateTime?> showStickerDateTimePicker(
  BuildContext context, {
  required DateTime initial,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  final date = await showStickerDatePicker(
    context,
    initialDate: initial,
    firstDate: firstDate,
    lastDate: lastDate,
  );
  if (date == null || !context.mounted) return null;
  final time = await showStickerTimePicker(
    context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
