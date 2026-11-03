import 'package:flutter/material.dart';

/// Visual system "playful & bold" (see docs/handoff/HANDOFF.md §5).
abstract final class AppColors {
  static const ground = Color(0xFFF5F2FF);
  static const ink = Color(0xFF17123A);
  static const muted = Color(0xFF5A5478);
  static const card = Color(0xFFFFFFFF);
  static const violet = Color(0xFF5B3DF5);
  static const violetDark = Color(0xFF3A22C7);
  static const sun = Color(0xFFFFC83D);
  static const mint = Color(0xFF2EC4A6);
  static const pink = Color(0xFFFF7AB0);
  static const sky = Color(0xFF7FC8FF);

  /// Tint used for "done" cards and the active tab background.
  static const lilac = Color(0xFFEDE9FF);

  /// Hour rules on the day timeline.
  static const rule = Color(0xFFDCD6F2);
}

abstract final class AppRadii {
  static const card = 22.0;
  static const cardSmall = 16.0;
  static const row = 18.0;
  static const pill = 999.0;
}

abstract final class AppStroke {
  static const border = 2.5;
  static const borderThin = 2.0;
}

abstract final class AppShadows {
  /// The hard "sticker" drop shadow: no blur, ink coloured, offset by [size].
  static List<BoxShadow> hard([double size = 4]) => [
    BoxShadow(color: AppColors.ink, offset: Offset(size, size)),
  ];
}
