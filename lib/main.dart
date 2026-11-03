import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/backup_actions_adapter.dart';
import 'app/recent_sessions.dart';
import 'core/core.dart';
import 'core/data/data.dart';
import 'core/notifications/notifications.dart';
import 'features/calendar/apple/providers.dart';
import 'features/calendar/google/providers.dart';
import 'features/focus/providers.dart';
import 'features/goals/data/drift_goal_repository.dart';
import 'features/goals/goals.dart';
import 'features/recurrence/providers.dart';
import 'features/review/drift_review_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local storage is the permanent home of the data: open the database,
  // ask the browser not to evict it, and seed the demo day in debug builds.
  final db = AppDatabase(openConnection());
  await requestPersistentStorage();
  await seedDemoData(db, enabled: kDebugMode);

  runApp(
    GrindApp(
      overrides: [
        ...dataProvidersOverrides(db),
        focusRepositoryOverride(db),
        recentFocusSessionsOverride(),
        reviewRepositoryOverride(db),
        goalRepositoryProvider.overrideWith(
          (ref) => DriftGoalRepository(db, clock: ref.watch(clockProvider)),
        ),
        ...notificationOverrides(),
        // Recurring reminders feed their occurrences into the scheduler.
        notificationExtraProvider.overrideWith(
          (ref) => ref.watch(recurrenceExtraProvider),
        ),
        backupActionsOverride(),
        googleCalendarOverride(),
        appleCalendarOverride(),
      ],
    ),
  );
}
