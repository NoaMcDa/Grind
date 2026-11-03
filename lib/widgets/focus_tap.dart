import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A tap target that keyboard and switch users can reach: it takes focus
/// (Tab on the web), activates on Enter and Space, shows a focus ring and
/// the pointer cursor, and still taps like a [GestureDetector].
///
/// Disabled when [onTap] is null (not focusable, no cursor).
class FocusTap extends StatefulWidget {
  const FocusTap({
    super.key,
    required this.onTap,
    required this.child,
    this.radius = AppRadii.pill,
  });

  final VoidCallback? onTap;
  final Widget child;

  /// Corner radius of the focus ring (match the child's shape).
  final double radius;

  @override
  State<FocusTap> createState() => _FocusTapState();
}

class _FocusTapState extends State<FocusTap> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final onTap = widget.onTap;
    return FocusableActionDetector(
      enabled: onTap != null,
      mouseCursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            onTap?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            border: _focused
                ? Border.all(color: AppColors.violetDark, width: 3)
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
