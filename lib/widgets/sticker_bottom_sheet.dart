import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/tokens.dart';

/// Shows a modal bottom sheet in the sticker style: white card, ink border,
/// 22 px top radius and a grab handle. Respects the keyboard inset.
Future<T?> showStickerSheet<T>(
  BuildContext context,
  WidgetBuilder builder, {
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (ctx) => StickerSheetFrame(child: builder(ctx)),
  );
}

/// The visual frame of the sheet; exposed for the gallery and tests.
class StickerSheetFrame extends StatelessWidget {
  const StickerSheetFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    const side = BorderSide(color: AppColors.ink, width: AppStroke.border);
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.card),
          ),
          border: Border(top: side, left: side, right: side),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 10, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Semantics(
                    label: Localizations.of<AppLocalizations>(
                      context,
                      AppLocalizations,
                    )?.dragHandle,
                    child: Container(
                      width: 44,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
