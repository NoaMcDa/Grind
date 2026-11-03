import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/tokens.dart';

/// Pill-shaped progress meter with an ink border.
///
/// [segments] colours the filled part left-to-right by weight, e.g. the
/// companion screen shows violet then pink. Fill never shows as "broken".
class MomentumMeter extends StatelessWidget {
  const MomentumMeter({
    super.key,
    required this.value,
    this.height = 18,
    this.segments = const [AppColors.pink],
    this.shadow = 0,
    this.semanticLabel,
  });

  /// 0..1
  final double value;
  final double height;
  final List<Color> segments;
  final double shadow;

  /// Announced name; the localized "Momentum" when null.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return Semantics(
      label:
          semanticLabel ??
          Localizations.of<AppLocalizations>(
            context,
            AppLocalizations,
          )?.momentumSemantic ??
          'Momentum',
      value: '${(v * 100).round()}%',
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: AppColors.ink, width: AppStroke.border),
          boxShadow: shadow > 0 ? AppShadows.hard(shadow) : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            // Zero is an empty track, not a sliver of ink (tone guide, rule 6).
            child: v == 0
                ? const SizedBox.shrink()
                : FractionallySizedBox(
                    widthFactor: v,
                    child: Container(
                      decoration: const BoxDecoration(
                        border: BorderDirectional(
                          end: BorderSide(
                            color: AppColors.ink,
                            width: AppStroke.border,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          for (var i = 0; i < segments.length; i++)
                            Expanded(
                              flex: i == 0 ? 5 : 3,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: segments[i],
                                  border: i < segments.length - 1
                                      ? const BorderDirectional(
                                          end: BorderSide(
                                            color: AppColors.ink,
                                            width: AppStroke.border,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
