import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/core.dart';

/// Prompt times and selected calendars. Backed by [Preferences] through
/// [PreferencesSettingsStore]; [InMemorySettingsStore] is for tests.
abstract interface class SettingsStore {
  /// Selected calendar ids per provider; null when the user never chose.
  Future<Set<String>?> selectedCalendarIds(CalendarSource source);
  Future<void> setSelectedCalendarIds(CalendarSource source, Set<String> ids);

  /// Minutes after midnight for the morning / evening prompts; null = off.
  Future<int?> morningPromptMinutes();
  Future<void> setMorningPromptMinutes(int? minutes);
  Future<int?> eveningPromptMinutes();
  Future<void> setEveningPromptMinutes(int? minutes);
}

class InMemorySettingsStore implements SettingsStore {
  final Map<CalendarSource, Set<String>> _selected = {};
  int? _morning = 8 * 60;
  int? _evening = 20 * 60;

  @override
  Future<Set<String>?> selectedCalendarIds(CalendarSource source) async =>
      _selected[source];

  @override
  Future<void> setSelectedCalendarIds(
    CalendarSource source,
    Set<String> ids,
  ) async => _selected[source] = Set.of(ids);

  @override
  Future<int?> morningPromptMinutes() async => _morning;

  @override
  Future<void> setMorningPromptMinutes(int? minutes) async =>
      _morning = minutes;

  @override
  Future<int?> eveningPromptMinutes() async => _evening;

  @override
  Future<void> setEveningPromptMinutes(int? minutes) async =>
      _evening = minutes;
}

/// Reads and writes the matching [Preferences] fields.
class PreferencesSettingsStore implements SettingsStore {
  PreferencesSettingsStore(this._prefs);

  final PreferencesRepository _prefs;

  Future<void> _update(Preferences Function(Preferences) change) async =>
      _prefs.save(change(await _prefs.get()));

  @override
  Future<Set<String>?> selectedCalendarIds(CalendarSource source) async {
    final ids = (await _prefs.get()).selectedCalendarIds[source];
    return ids == null ? null : Set.of(ids);
  }

  @override
  Future<void> setSelectedCalendarIds(CalendarSource source, Set<String> ids) =>
      _update(
        (p) => p.copyWith(
          selectedCalendarIds: {...p.selectedCalendarIds, source: ids.toList()},
        ),
      );

  @override
  Future<int?> morningPromptMinutes() async =>
      (await _prefs.get()).morningPromptMinutes;

  @override
  Future<void> setMorningPromptMinutes(int? minutes) =>
      _update((p) => p.copyWith(morningPromptMinutes: minutes));

  @override
  Future<int?> eveningPromptMinutes() async =>
      (await _prefs.get()).eveningPromptMinutes;

  @override
  Future<void> setEveningPromptMinutes(int? minutes) =>
      _update((p) => p.copyWith(eveningPromptMinutes: minutes));
}

final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => PreferencesSettingsStore(ref.watch(preferencesRepositoryProvider)),
);
