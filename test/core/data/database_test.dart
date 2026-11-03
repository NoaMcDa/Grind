import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/data/connection/memory.dart';
import 'package:grind/core/data/data.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openInMemoryDatabase());
  tearDown(() => db.close());

  test('schema version is 3', () async {
    // Changing the schema means bumping this and writing a migration step
    // (see AppDatabase.migration and docs/adr/0001-local-database.md).
    expect(AppDatabase.currentSchemaVersion, 3);
    expect(db.schemaVersion, 3);
    final v = await db.customSelect('PRAGMA user_version').getSingle();
    expect(v.read<int>('user_version'), 3);
  });

  test('tables', () {
    expect(db.allTables.map((t) => t.actualTableName).toSet(), {
      'tasks',
      'reminder_rules',
      'calendar_events',
      'focus_sessions',
      'goals',
      'preferences',
      'review_entries',
      'review_handled_days',
    });
    // Review tables are keyed by day, not by id (see database.dart).
    final keyedByDay = {'review_entries', 'review_handled_days'};
    for (final t in db.allTables) {
      if (keyedByDay.contains(t.actualTableName)) continue;
      final cols = t.$columns.map((c) => c.name).toSet();
      expect(
        cols,
        containsAll(['id', 'created_at', 'updated_at', 'deleted_at']),
        reason: t.actualTableName,
      );
    }
  });

  test('foreign keys are enforced', () async {
    final fk = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(fk.read<int>('foreign_keys'), 1);
  });

  group('seedDemoData', () {
    final clock = FixedClock(DateTime(2026, 11, 3, 7));

    test('does nothing when disabled', () async {
      expect(await seedDemoData(db, enabled: false, clock: clock), isFalse);
      expect(await DriftTaskRepository(db).getAll(), isEmpty);
    });

    test('seeds the demo day once', () async {
      expect(await seedDemoData(db, enabled: true, clock: clock), isTrue);
      expect(await seedDemoData(db, enabled: true, clock: clock), isFalse);

      final tasks = await DriftTaskRepository(db).getAll();
      expect(tasks.map((t) => t.title).toSet(), {
        'Thesis: write related-work section',
        'Deep learning lab 4',
        'Read 2 papers',
        'Gym',
        'Call mom',
      });
      final lab = tasks.firstWhere((t) => t.id == 'demo-lab');
      expect(lab.scheduledStart!.toLocal(), DateTime(2026, 11, 3, 12, 30));
      expect(lab.scheduledEnd!.toLocal(), DateTime(2026, 11, 3, 13, 15));
      expect(lab.firstAction, 'If lunch is over, then open the notebook');
      expect(lab.energy, Energy.deep);

      final day = DateTime(2026, 11, 3);
      final due = await DriftTaskRepository(
        db,
      ).getDueBetween(day.toUtc(), day.add(const Duration(days: 1)).toUtc());
      expect(due.length, 4);

      final events = await DriftCalendarRepository(
        db,
      ).getBetween(day.toUtc(), day.add(const Duration(days: 1)).toUtc());
      expect(events.map((e) => e.title), [
        'Lecture: Computer Vision',
        'Seminar with supervisor',
      ]);
    });
  });

  test('dataProvidersOverrides swaps the interface providers', () async {
    final container = ProviderContainer(overrides: dataProvidersOverrides(db));
    addTearDown(container.dispose);
    expect(container.read(taskRepositoryProvider), isA<DriftTaskRepository>());
    expect(
      container.read(reminderRepositoryProvider),
      isA<DriftReminderRepository>(),
    );
    expect(
      container.read(calendarRepositoryProvider),
      isA<DriftCalendarRepository>(),
    );
    expect(
      container.read(preferencesRepositoryProvider),
      isA<DriftPreferencesRepository>(),
    );
    expect(container.read(appDatabaseProvider), same(db));
    expect(container.read(backupServiceProvider), isA<BackupService>());

    await container
        .read(taskRepositoryProvider)
        .upsert(
          Task(
            id: 'x',
            title: 'via provider',
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
        );
    expect((await DriftTaskRepository(db).getById('x'))!.title, 'via provider');
  });

  test('web persistence is a no-op off the web', () async {
    expect(await requestPersistentStorage(), isTrue);
    expect(await isStoragePersisted(), isTrue);
  });
}
