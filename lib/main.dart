import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/backup_actions_adapter.dart';
import 'core/data/data.dart';
import 'core/notifications/notifications.dart';
import 'features/calendar/apple/providers.dart';
import 'features/calendar/google/providers.dart';
import 'features/recurrence/providers.dart';

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
