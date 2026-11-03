import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/notifications.dart';
import 'package:grind/features/goals/goals.dart';
import 'package:grind/features/reminders/weekly_recap_notification.dart';
import 'package:grind/features/review/review_repository.dart';

void main() {
  setUpAll(ensureTimeZones);

  // Tuesday 3 Nov 2026; with a Sunday week start the week ends Sat 7 Nov.
  final now = DateTime.utc(2026, 11, 3, 8);
  const prefs = Preferences(timeZoneName: 'UTC');

  GoalRecord goal(String id, {GoalStatus status = GoalStatus.active}) =>
      GoalRecord(
        id: id,
        title: id,
        horizon: GoalHorizon.month,
        status: status,
        importance: 3,
        createdAt: DateTime.utc(2026, 9, 1),
        updatedAt: DateTime.utc(2026, 11, 2, 12),
      );

  Task done(String id, DateTime at) => Task(
    id: id,
    title: id,
    status: TaskStatus.done,
    completedAt: at,
    createdAt: at,
    updatedAt: at,
  );

  Future<List<ScheduledNotification>> run({
    List<GoalRecord> goals = const [],
    List<Task> tasks = const [],
    List<ReviewEntry> reviews = const [],
    Preferences p = prefs,
    DateTime? at,
  }) async {
    final reviewRepo = InMemoryReviewRepository();
    for (final r in reviews) {
      await reviewRepo.save(r);
    }
    final hook = weeklyRecapNotifications(
      goals: InMemoryGoalRepository(seed: goals, clock: FixedClock(at ?? now)),
      reviews: reviewRepo,
      clock: FixedClock(at ?? now),
    );
    return hook(tasks, p);
  }

  test(
    'fires once on the last evening, leading with the biggest win',
    () async {
      final out = await run(
        goals: [goal('Run 5k', status: GoalStatus.done)],
        tasks: [done('t', DateTime.utc(2026, 11, 2, 10))],
      );
      final n = out.single;
      expect(n.id, 'recap:weekly:2026-11-07');
      expect(n.taskId, isEmpty);
      expect(n.actions, isEmpty);
      // An hour before the 20:30 evening prompt.
      expect(n.fireAt, DateTime.utc(2026, 11, 7, 19, 30));
      expect(n.title, 'Your week with Pip');
      expect(n.body, 'You finished "Run 5k". That\'s a big one.');
    },
  );

  test('a review win leads when no goal or quota did', () async {
    final out = await run(
      tasks: [done('t', DateTime.utc(2026, 11, 2, 10))],
      reviews: const [
        ReviewEntry(
          date: '2026-11-02',
          win: 'Sent the draft',
          doneCount: 1,
          movedCount: 0,
        ),
      ],
    );
    expect(out.single.body, 'Best moment: Sent the draft');
  });

  test('a quiet week sends nothing (no "you missed")', () async {
    expect(await run(), isEmpty);
  });

  test('follows weekStart, the zone and the language', () async {
    final out = await run(
      tasks: [done('t', DateTime.utc(2026, 11, 2, 10))],
      p: const Preferences(
        timeZoneName: 'Asia/Jerusalem',
        weekStart: DateTime.monday,
        localeCode: 'he',
        eveningPromptMinutes: 21 * 60,
      ),
    );
    final n = out.single;
    expect(n.id, 'recap:weekly:2026-11-08');
    // 20:00 in Jerusalem (UTC+2 in November).
    expect(n.fireAt, DateTime.utc(2026, 11, 8, 18));
    expect(n.title, 'השבוע שלך עם פיפ');
    expect(n.body, startsWith('דבר אחד הושלם'));
  });

  test('nothing once the recap time has passed', () async {
    final out = await run(
      tasks: [done('t', DateTime.utc(2026, 11, 2, 10))],
      at: DateTime.utc(2026, 11, 7, 21),
    );
    expect(out, isEmpty);
  });

  test('recap time without an evening prompt is 19:30', () {
    expect(
      recapMinutesFor(prefs.copyWith(eveningPromptMinutes: null)),
      19 * 60 + 30,
    );
    expect(recapMinutesFor(prefs.copyWith(eveningPromptMinutes: 30)), 0);
  });

  test('composes with other hooks and respects quiet hours', () async {
    final hook = combineExtras([
      (_, _) => throw StateError('broken feature'),
      weeklyRecapNotifications(
        goals: InMemoryGoalRepository(clock: FixedClock(now)),
        reviews: InMemoryReviewRepository(),
        clock: FixedClock(now),
      ),
    ]);
    final tasks = [done('t', DateTime.utc(2026, 11, 2, 10))];
    final quiet = prefs.copyWith(quietHours: TimeRange.hm(19, 0, 20, 0));
    final plan = NotificationScheduler.plan(
      tasks: tasks,
      prefs: quiet,
      clock: FixedClock(now),
      extra: await hook(tasks, quiet),
    );
    final recap = plan.singleWhere((n) => n.id.startsWith('recap:weekly:'));
    expect(recap.fireAt, DateTime.utc(2026, 11, 7, 20));
  });
}
