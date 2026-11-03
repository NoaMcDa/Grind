import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/tokens.dart';

/// Static (no shimmer, so no motion to turn off) loading placeholder.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.radius = AppRadii.cardSmall,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: Localizations.of<AppLocalizations>(
        context,
        AppLocalizations,
      )?.loading,
      excludeSemantics: true,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.lilac,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: AppColors.rule,
            width: AppStroke.borderThin,
          ),
        ),
      ),
    );
  }
}
