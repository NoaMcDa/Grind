import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/core.dart';
import '../calendar/sync/calendar_sync_engine.dart';
import '../calendar/sync/providers.dart';

/// Everything that must happen besides wiping the database when the user
/// deletes all data or restores a backup: calendars are disconnected (which
/// clears Google's sync tokens and mirrored events), the mirrored events
/// and the stored calendar choice go, and the sync engines forget their
/// in-memory state so the next sync starts clean.
///
/// `BackupService.deleteAllData()` stays a database-only operation; the
/// backup adapter calls [resetCalendars] after it.
class DataResetService {
  DataResetService({
    required this.providers,
    required this.engines,
    required this.calendarRepository,
    required this.preferencesRepository,
  });

  final List<CalendarProvider> providers;
  final List<CalendarSyncEngine> engines;
  final CalendarRepository calendarRepository;
  final PreferencesRepository preferencesRepository;

  /// Never throws: a provider that cannot revoke (offline) must not leave the
  /// rest of the reset undone.
  Future<void> resetCalendars() async {
    for (final p in providers) {
      try {
        await p.disconnect();
      } catch (_) {
        // Best effort; the local state below is cleared regardless.
      }
      try {
        await calendarRepository.clearSource(p.source);
      } catch (_) {}
    }
    try {
      final prefs = await preferencesRepository.get();
      if (prefs.selectedCalendarIds.isNotEmpty) {
        await preferencesRepository.save(
          prefs.copyWith(selectedCalendarIds: const {}),
        );
      }
    } catch (_) {}
    for (final e in engines) {
      await e.reset();
    }
  }
}

final dataResetServiceProvider = Provider<DataResetService>(
  (ref) => DataResetService(
    providers: [
      ref.watch(googleCalendarProvider),
      ref.watch(appleCalendarProvider),
    ],
    engines: [
      ref.watch(calendarSyncEngineProvider),
      ref.watch(appleCalendarSyncEngineProvider),
    ],
    calendarRepository: ref.watch(calendarRepositoryProvider),
    preferencesRepository: ref.watch(preferencesRepositoryProvider),
  ),
);
