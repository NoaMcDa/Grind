import 'package:drift/drift.dart';

import '../../domain/domain.dart';
import '../../repositories/preferences_repository.dart';
import '../../services/clock.dart';
import '../database.dart';
import '../mappers.dart';

/// [PreferencesRepository] on the single preferences row. Before the first
/// [save] it reads as the [Preferences] defaults.
class DriftPreferencesRepository implements PreferencesRepository {
  DriftPreferencesRepository(this._db, {Clock clock = const SystemClock()})
    : _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  SimpleSelectStatement<$PreferencesTableTable, PreferencesRow> _row() =>
      _db.select(_db.preferencesTable)
        ..where((p) => p.id.equals(PreferencesRows.singletonId));

  @override
  Future<Preferences> get() async =>
      (await _row().getSingleOrNull())?.toDomain() ?? const Preferences();

  @override
  Future<void> save(Preferences preferences) => _db.transaction(() async {
    final now = _clock.now().toUtc();
    final existing = await _row().getSingleOrNull();
    final createdAt = existing == null ? now : fromMillis(existing.createdAt);
    await _db
        .into(_db.preferencesTable)
        .insertOnConflictUpdate(
          preferences.toCompanion(createdAt: createdAt, updatedAt: now),
        );
  });

  @override
  Stream<Preferences> watch() => _row().watchSingleOrNull().map(
    (row) => row?.toDomain() ?? const Preferences(),
  );
}
