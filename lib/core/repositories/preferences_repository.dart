import 'dart:async';

import '../domain/domain.dart';

/// The single preferences row.
abstract interface class PreferencesRepository {
  Future<Preferences> get();
  Future<void> save(Preferences preferences);
  Stream<Preferences> watch();
}

class InMemoryPreferencesRepository implements PreferencesRepository {
  InMemoryPreferencesRepository([this._prefs = const Preferences()]);

  Preferences _prefs;
  final _changes = StreamController<Preferences>.broadcast();

  @override
  Future<Preferences> get() async => _prefs;

  @override
  Future<void> save(Preferences preferences) async {
    _prefs = preferences;
    _changes.add(_prefs);
  }

  @override
  Stream<Preferences> watch() async* {
    yield _prefs;
    yield* _changes.stream;
  }
}
