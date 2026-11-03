import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_text.dart';
import '../theme/tokens.dart';
import '../widgets/pill.dart';
import '../widgets/sticker_card.dart';

/// Stand-in for the task detail screen (`/task/:id`), so notifications and
/// widgets can already deep link. Replaced by the tasks feature.
class TaskPlaceholderPage extends StatelessWidget {
  const TaskPlaceholderPage({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StickerCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionLabel('Task'),
                        const SizedBox(height: 6),
                        Text(taskId, style: AppText.display(size: 22)),
                        const SizedBox(height: 6),
                        Text(
                          'Task details are coming soon.',
                          style: AppText.body(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  PillButton(
                    label: 'Back to Today',
                    onPressed: () => context.go('/today'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
