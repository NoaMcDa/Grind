import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/core.dart';
import '../../core/data/database.dart';
import '../../core/data/mappers.dart';
import 'review_providers.dart';
import 'review_repository.dart';

/// [ReviewRepository] on the `review_entries` and `review_handled_days`
/// tables (schema v3). Saving a day again replaces its entry but keeps the
/// first `createdAt`.
class DriftReviewRepository implements ReviewRepository {
  DriftReviewRepository(this._db, {Clock clock = const SystemClock()})
    : _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  @override
  Future<void> save(ReviewEntry entry) => _db
      .into(_db.reviewEntries)
      .insert(
        ReviewEntriesCompanion.insert(
          date: entry.date,
          win: entry.win,
          doneCount: entry.doneCount,
          movedCount: entry.movedCount,
          createdAt: toMillis(_clock.now().toUtc()),
        ),
        onConflict: DoUpdate(
          (_) => ReviewEntriesCompanion(
            win: Value(entry.win),
            doneCount: Value(entry.doneCount),
            movedCount: Value(entry.movedCount),
          ),
        ),
      );

  @override
  Future<List<ReviewEntry>> all() async {
    final rows = await (_db.select(
      _db.reviewEntries,
    )..orderBy([(r) => OrderingTerm(expression: r.date)])).get();
    return [
      for (final r in rows)
        ReviewEntry(
          date: r.date,
          win: r.win,
          doneCount: r.doneCount,
          movedCount: r.movedCount,
        ),
    ];
  }

  @override
  Future<void> markHandled(String day) => _db
      .into(_db.reviewHandledDays)
      .insert(
        ReviewHandledDaysCompanion.insert(date: day),
        mode: InsertMode.insertOrIgnore,
      );

  @override
  Future<bool> isHandled(String day) async =>
      await (_db.select(
        _db.reviewHandledDays,
      )..where((r) => r.date.equals(day))).getSingleOrNull() !=
      null;
}

/// Add to the `ProviderScope` overrides in `main.dart`, next to
/// `dataProvidersOverrides(db)`:
///
/// ```dart
/// reviewRepositoryProvider.overrideWith(
///   (ref) => DriftReviewRepository(db, clock: ref.watch(clockProvider)),
/// ),
/// ```
///
/// or the shorthand `reviewRepositoryOverride(db)`.
Override reviewRepositoryOverride(AppDatabase db) =>
    reviewRepositoryProvider.overrideWith(
      (ref) => DriftReviewRepository(db, clock: ref.watch(clockProvider)),
    );
