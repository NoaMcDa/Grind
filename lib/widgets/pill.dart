import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import '../theme/tokens.dart';
import 'focus_tap.dart';

/// Pill-shaped button, at least 44px tall, ink border, optional hard shadow.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color = AppColors.card,
    this.textColor = AppColors.ink,
    this.icon,
    this.height = 44,
    this.shadow = 2,
    this.fontSize = 14,
    this.display = false,
    this.horizontalPadding = 16,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final Widget? icon;
  final double height;
  final double shadow;
  final double fontSize;

  /// Use the display font (for big primary actions).
  final bool display;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final style = display
        ? AppText.display(size: fontSize, color: textColor, height: 1)
        : AppText.bold(size: fontSize, color: textColor, height: 1);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      excludeSemantics: true,
      onTap: onPressed,
      child: FocusTap(
        onTap: onPressed,
        child: _target(
          Container(
            height: height,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(color: AppColors.ink, width: AppStroke.border),
              boxShadow: shadow > 0 ? AppShadows.hard(shadow) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  IconTheme(
                    data: IconThemeData(color: textColor, size: fontSize + 4),
                    child: icon!,
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: style,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Visual height may be below 44, but the hit target never is.
  Widget _target(Widget pill) {
    if (height >= 44) return pill;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Center(widthFactor: 1, heightFactor: 1, child: pill),
    );
  }
}

/// Small non-interactive pill (tags, chips, status).
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    this.color = AppColors.card,
    this.textColor = AppColors.ink,
    this.icon,
    this.height = 26,
    this.fontSize = 12,
    this.shadow = 0,
    this.border = AppStroke.borderThin,
  });

  final String label;
  final Color color;
  final Color textColor;
  final Widget? icon;
  final double height;
  final double fontSize;
  final double shadow;
  final double border;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.ink, width: border),
        boxShadow: shadow > 0 ? AppShadows.hard(shadow) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            IconTheme(
              data: IconThemeData(color: textColor, size: fontSize + 2),
              child: icon!,
            ),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.bold(size: fontSize, color: textColor, height: 1),
            ),
          ),
        ],
      ),
    );
  }
}

/// Uppercase, letter-spaced section heading.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color = AppColors.muted});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(text.toUpperCase(), style: AppText.label(color: color)),
    );
  }
}
