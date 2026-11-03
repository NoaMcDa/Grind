import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/core.dart';

/// Settings that `Preferences` has no field for yet. The integrator should
/// either add these fields to `Preferences` or back this with the database.
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

final settingsStoreProvider = Provider<SettingsStore>(
  (_) => InMemorySettingsStore(),
);
