import '../domain/domain.dart';
import '../services/clock.dart';
import 'database.dart';
import 'mappers.dart';

/// Fills an empty database with the demo day the mock screens show
/// (`lib/features/today/today_screen.dart`, `lib/features/plan/plan_screen.dart`):
/// five tasks and two calendar events, placed on [clock]'s local today.
///
/// Does nothing unless [enabled] (pass e.g. `kDebugMode` or a
/// `--dart-define=GRIND_DEMO=true` flag) and the database has no tasks.
/// Returns true when it seeded.
Future<bool> seedDemoData(
  AppDatabase db, {
  required bool enabled,
  Clock clock = const SystemClock(),
}) async {
  if (!enabled) return false;
  return db.transaction(() async {
    final existing = await (db.select(db.tasks)..limit(1)).get();
    if (existing.isNotEmpty) return false;
    final now = clock.now();
    final created = now.toUtc();
    DateTime at(double hour) => DateTime(
      now.year,
      now.month,
      now.day,
      hour.floor(),
      ((hour - hour.floor()) * 60).round(),
    ).toUtc();

    Task task(
      String id,
      String title, {
      required double start,
      required double end,
      Energy energy = Energy.light,
      String? firstAction,
      bool remind = true,
      String? category,
    }) => Task(
      id: 'demo-$id',
      title: title,
      remindAt: remind ? at(start) : null,
      scheduledStart: at(start),
      scheduledEnd: at(end),
      estimatedMinutes: ((end - start) * 60).round(),
      energy: energy,
      firstAction: firstAction,
      category: category,
      createdAt: created,
      updatedAt: created,
    );

    CalendarEvent event(String id, String title, double start, double end) =>
        CalendarEvent(
          id: 'demo-$id',
          source: CalendarSource.local,
          externalId: 'demo-$id',
          title: title,
          start: at(start),
          end: at(end),
          createdAt: created,
          updatedAt: created,
        );

    final tasks = [
      task(
        'thesis',
        'Thesis: write related-work section',
        start: 8,
        end: 9.5,
        energy: Energy.deep,
        remind: false,
        category: 'study',
      ),
      task(
        'lab',
        'Deep learning lab 4',
        start: 12.5,
        end: 13.25,
        energy: Energy.deep,
        firstAction: 'If lunch is over, then open the notebook',
        category: 'study',
      ),
      task(
        'papers',
        'Read 2 papers',
        start: 16,
        end: 16.75,
        firstAction:
            'If you get to the library, then start with the shorter one',
        category: 'study',
      ),
      task(
        'gym',
        'Gym',
        start: 17.25,
        end: 18,
        firstAction: 'If it is 17:00, then pack your bag',
        category: 'workout',
      ),
      task(
        'mom',
        'Call mom',
        start: 19.5,
        end: 20,
        firstAction: 'If dinner is done, then call',
        category: 'personal',
      ),
    ];
    final events = [
      event('lecture', 'Lecture: Computer Vision', 10, 11.5),
      event('seminar', 'Seminar with supervisor', 14, 15.5),
    ];

    await db.batch((b) {
      b.insertAll(db.tasks, [for (final t in tasks) t.toCompanion()]);
      b.insertAll(db.calendarEvents, [for (final e in events) e.toCompanion()]);
    });
    return true;
  });
}
