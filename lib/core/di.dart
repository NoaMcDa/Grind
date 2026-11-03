import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/domain.dart';
import 'repositories/repositories.dart';
import 'services/services.dart';

/// Dependency injection. Every interface has one provider here; the defaults
/// are the in-memory fakes so any screen runs with no platform code.
///
/// Real implementations override these in `main.dart` (integrator-owned) or in
/// tests via `ProviderScope(overrides: [...])`. Agents add providers for
/// their own feature in their own folder, not here.
final clockProvider = Provider<Clock>((_) => const SystemClock());

final taskRepositoryProvider = Provider<TaskRepository>(
  (_) => InMemoryTaskRepository(),
);

final reminderRepositoryProvider = Provider<ReminderRepository>(
  (_) => InMemoryReminderRepository(),
);

final calendarRepositoryProvider = Provider<CalendarRepository>(
  (_) => InMemoryCalendarRepository(),
);

final preferencesRepositoryProvider = Provider<PreferencesRepository>(
  (_) => InMemoryPreferencesRepository(),
);

final notificationServiceProvider = Provider<NotificationService>(
  (_) => FakeNotificationService(),
);

final googleCalendarProvider = Provider<CalendarProvider>(
  (_) => FakeCalendarProvider(CalendarSource.google),
);

final appleCalendarProvider = Provider<CalendarProvider>(
  (_) => FakeCalendarProvider(CalendarSource.apple),
);

/// Live preferences for widgets.
final preferencesProvider = StreamProvider<Preferences>(
  (ref) => ref.watch(preferencesRepositoryProvider).watch(),
);

/// Live task list for widgets.
final tasksProvider = StreamProvider<List<Task>>(
  (ref) => ref.watch(taskRepositoryProvider).watchAll(),
);
