import 'package:flutter/material.dart';

import '../app/tab_bar.dart';
import '../theme/app_text.dart';
import '../theme/tokens.dart';
import 'pip_avatar.dart';

/// A sticker-style snackbar with a small Pip. Announced as a live region.
///
/// Auto-dismisses after [duration], even with an action (and with a
/// horizontal dismiss direction so a swipe closes it on devices that
/// otherwise keep action snackbars alive under `accessibleNavigation`).
/// Its bottom margin clears the shell's tab bar ([GrindTabBar.visualHeight])
/// so the toast never covers the bar. Any current or queued toasts are
/// cleared first so praise toasts never pile up.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showPipToast(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 4),
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.of(context);
  // Drop any queued (and the current) praise toasts so new ones never pile
  // up and keep the tab bar covered longer.
  messenger.clearSnackBars();
  return messenger.showSnackBar(
    SnackBar(
      duration: duration,
      backgroundColor: AppColors.card,
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.horizontal,
      elevation: 0,
      // Lift the toast above the shell's tab bar; Flutter's floating
      // snackbar already offsets by the bottom safe area, so add only the
      // tab bar's own visible height here.
      margin: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + GrindTabBar.visualHeight,
      ),
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
