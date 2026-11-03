import 'package:flutter/material.dart';

import '../../theme/app_text.dart';
import '../../theme/tokens.dart';
import '../../widgets/focus_tap.dart';

/// A row of mutually exclusive pill choices (44px targets).
class ChoicePills<T> extends StatelessWidget {
  const ChoicePills({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  /// Label per value, in display order.
  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final e in options.entries)
          Semantics(
            button: true,
            selected: e.key == selected,
            inMutuallyExclusiveGroup: true,
            label: e.value,
            excludeSemantics: true,
            child: FocusTap(
              onTap: () => onSelected(e.key),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44, minWidth: 56),
                // No `alignment`: it would stretch each chip to the Wrap's width.
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: e.key == selected ? AppColors.violet : AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppStroke.border,
                  ),
                ),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    e.value,
                    style: AppText.bold(
                      size: 14,
                      height: 1,
                      color: e.key == selected ? Colors.white : AppColors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
