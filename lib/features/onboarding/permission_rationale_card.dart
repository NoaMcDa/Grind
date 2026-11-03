import 'package:flutter/material.dart';

import '../../theme/app_text.dart';
import '../../theme/tokens.dart';
import '../../widgets/sticker_card.dart';

/// A sticker card that explains why a permission is asked for, honestly,
/// before the system prompt appears.
class PermissionRationaleCard extends StatelessWidget {
  const PermissionRationaleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.color = AppColors.card,
    this.child,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;

  /// Optional extra content under the text (status, buttons).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return StickerCard(
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.lilac,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppStroke.borderThin,
                  ),
                ),
                child: Icon(icon, size: 22, color: AppColors.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppText.display(size: 18, height: 1.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: AppText.body(
              size: 14,
              weight: FontWeight.w500,
              height: 1.4,
              color: AppColors.muted,
            ),
          ),
          if (child != null) ...[const SizedBox(height: 12), child!],
        ],
      ),
    );
  }
}
