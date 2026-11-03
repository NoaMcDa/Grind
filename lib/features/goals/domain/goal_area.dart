import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';

/// A life area a goal belongs to. The presets come from Noa's spec
/// (HANDOFF.md §2.2); any other string stored in `Goal.area` is a
/// user-defined area and gets a stable palette colour from its name.
@immutable
class GoalArea {
  const GoalArea({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    this.onColor = AppColors.ink,
    this.isPreset = false,
  });

  /// What is stored in `Goal.area`: the preset id, or the custom label.
  final String id;
  final String label;
  final IconData icon;

  /// Chip and progress fill colour (from the palette).
  final Color color;

  /// Text/icon colour on top of [color].
  final Color onColor;
  final bool isPreset;

  static const learning = GoalArea(
    id: 'learning',
    label: 'Learning',
    icon: Icons.school_outlined,
    color: AppColors.violet,
    onColor: Colors.white,
    isPreset: true,
  );

  static const investing = GoalArea(
    id: 'investing',
    label: 'Investing',
    icon: Icons.trending_up,
    color: AppColors.mint,
    isPreset: true,
  );

  static const fitness = GoalArea(
    id: 'fitness',
    label: 'Fitness',
    icon: Icons.monitor_heart_outlined,
    color: AppColors.pink,
    isPreset: true,
  );

  static const nutrition = GoalArea(
    id: 'nutrition',
    label: 'Nutrition',
    icon: Icons.eco_outlined,
    color: AppColors.sun,
    isPreset: true,
  );

  static const presets = [learning, investing, fitness, nutrition];

  /// Colours a custom area may get, chosen by a stable hash of its name.
  static const customPalette = [
    AppColors.sky,
    AppColors.lilac,
    AppColors.sun,
    AppColors.mint,
    AppColors.pink,
  ];

  /// A user-defined area named [label].
  factory GoalArea.custom(String label) {
    final name = label.trim();
    var hash = 0;
    for (final unit in name.toLowerCase().codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return GoalArea(
      id: name,
      label: name,
      icon: Icons.star_outline,
      color: customPalette[hash % customPalette.length],
    );
  }

  /// The area for a stored `Goal.area` value; null when there is none.
  static GoalArea? resolve(String? stored) {
    if (stored == null || stored.trim().isEmpty) return null;
    for (final p in presets) {
      if (p.id == stored) return p;
    }
    return GoalArea.custom(stored);
  }

  @override
  bool operator ==(Object other) => other is GoalArea && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
