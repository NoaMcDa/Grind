import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import '../theme/tokens.dart';
import 'pill.dart';
import 'pip_avatar.dart';

/// Pip + title + body + optional action. Encouraging, never guilt.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.pipSize = 96,
  });

  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double pipSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 24,
          vertical: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PipAvatar(size: pipSize),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppText.display(size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: AppText.body(color: AppColors.muted),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              PillButton(
                label: actionLabel!,
                onPressed: onAction,
                color: AppColors.violet,
                textColor: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
