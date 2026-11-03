import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'pill.dart';

/// Energy tag chip: deep focus = violet with a bolt, light = sky with a
/// cloud. The icon carries the meaning too, so it never relies on colour.
class IconChip extends StatelessWidget {
  const IconChip({
    super.key,
    required this.label,
    required this.icon,
    this.color = AppColors.card,
    this.textColor = AppColors.ink,
    this.height = 24,
  });

  factory IconChip.deep({
    Key? key,
    required String label,
    double height = 24,
  }) => IconChip(
    key: key,
    label: label,
    icon: Icons.bolt,
    color: AppColors.violet,
    textColor: Colors.white,
    height: height,
  );

  factory IconChip.light({
    Key? key,
    required String label,
    double height = 24,
  }) => IconChip(
    key: key,
    label: label,
    icon: Icons.cloud_outlined,
    color: AppColors.sky,
    height: height,
  );

  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Pill(
        label: label,
        color: color,
        textColor: textColor,
        height: height,
        icon: Icon(icon),
      ),
    );
  }
}
