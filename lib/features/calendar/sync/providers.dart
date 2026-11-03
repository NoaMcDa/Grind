import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import 'calendar_sync_engine.dart';
import 'sync_scheduler.dart';
import 'sync_status.dart';

/// Two-way sync with Google Calendar (the reference provider). Scheduled
/// tasks are written back here.
final calendarSyncEngineProvider = Provider<CalendarSyncEngine>((ref) {
  final engine = CalendarSyncEngine(
    provider: ref.watch(googleCalendarProvider),
    calendarRepository: ref.watch(calendarRepositoryProvider),
    taskRepository: ref.watch(taskRepositoryProvider),
    preferencesRepository: ref.watch(preferencesRepositoryProvider),
    clock: ref.watch(clockProvider),
  );
  ref.onDispose(engine.dispose);
  return engine;
});

/// Read-only sync of Apple Calendar through the same engine. Write-back is
/// off: a task keeps one `calendarEventId`, and Google owns it for now.
final appleCalendarSyncEngineProvider = Provider<CalendarSyncEngine>((ref) {
  final engine = CalendarSyncEngine(
    provider: ref.watch(appleCalendarProvider),
    calendarRepository: ref.watch(calendarRepositoryProvider),
    taskRepository: ref.watch(taskRepositoryProvider),
    preferencesRepository: ref.watch(preferencesRepositoryProvider),
    clock: ref.watch(clockProvider),
    writeBack: false,
  );
  ref.onDispose(engine.dispose);
  return engine;
});

/// Live Google sync status for a small status line or a Settings row.
final syncStatusProvider = StreamProvider<SyncStatus>(
  (ref) => ref.watch(calendarSyncEngineProvider).watchStatus(),
);

/// Live Apple Calendar sync status.
final appleSyncStatusProvider = StreamProvider<SyncStatus>(
  (ref) => ref.watch(appleCalendarSyncEngineProvider).watchStatus(),
);

/// Runs both engines on start, on foreground and every 15 minutes.
final calendarSyncSchedulerProvider = Provider<SyncScheduler>((ref) {
  final scheduler = SyncScheduler([
    ref.watch(calendarSyncEngineProvider),
    ref.watch(appleCalendarSyncEngineProvider),
  ], tasks: ref.watch(taskRepositoryProvider));
  ref.onDispose(scheduler.stop);
  return scheduler;
});

/// Call once from `GrindApp` when `startServices` is true:
///
/// ```dart
/// if (widget.startServices) startCalendarSync(ref);
/// ```
SyncScheduler startCalendarSync(WidgetRef ref) {
  final scheduler = ref.read(calendarSyncSchedulerProvider);
  unawaited(scheduler.start());
  return scheduler;
}
