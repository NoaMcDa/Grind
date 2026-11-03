import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import '../theme/tokens.dart';
import 'pip_avatar.dart';

/// A sticker-style snackbar with a small Pip. Announced as a live region.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showPipToast(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 4),
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  return messenger.showSnackBar(
    SnackBar(
      duration: duration,
      backgroundColor: AppColors.card,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 14, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.row),
        side: const BorderSide(color: AppColors.ink, width: AppStroke.border),
      ),
      action: actionLabel == null
          ? null
          : SnackBarAction(
              label: actionLabel,
              textColor: AppColors.violetDark,
              onPressed: onAction ?? () {},
            ),
      content: Semantics(
        liveRegion: true,
        container: true,
        child: Row(
          children: [
            const ExcludeSemantics(child: PipAvatar(size: 32)),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: AppText.bold())),
          ],
        ),
      ),
    ),
  );
}
