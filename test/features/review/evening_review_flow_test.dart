import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/goals/domain/goal_metric.dart';
import 'package:grind/features/goals/domain/goal_record.dart';
import 'package:grind/features/goals/domain/goal_repository.dart';
import 'package:grind/features/goals/domain/metric_ticks.dart';
import 'package:grind/features/goals/goal_providers.dart';
import 'package:grind/features/review/review.dart';
import 'package:grind/l10n/l10n.dart';
import 'package:grind/theme/app_theme.dart';

import '../../test_fonts.dart';

Task _task(String id, DateTime remind, {DateTime? due}) {
  final t = DateTime(2026, 11, 3).toUtc();
  return Task(
    id: id,
    title: 'Task $id',
    remindAt: remind.toUtc(),
    dueAt: due?.toUtc(),
    createdAt: t,
    updatedAt: t,
  );
}

void main() {
  setUpAll(loadAppFonts);

  final now = DateTime(2026, 11, 3, 21);

  Future<({InMemoryTaskRepository tasks, InMemoryReviewRepository reviews})>
  pump(
    WidgetTester tester,
    List<Task> seed, {
    TextDirection dir = TextDirection.ltr,
    Locale locale = const Locale('en'),
    VoidCallback? onFinished,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final tasks = InMemoryTaskRepository(seed);
    final reviews = InMemoryReviewRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clockProvider.overrideWithValue(FixedClock(now)),
          taskRepositoryProvider.overrideWithValue(tasks),
          reviewRepositoryProvider.overrideWithValue(reviews),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          locale: locale,
          localizationsDelegates: localizationsDelegates,
          supportedLocales: supportedLocales,
          home: Directionality(
            textDirection: dir,
            child: EveningReviewFlow(onFinished: onFinished ?? () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (tasks: tasks, reviews: reviews);
  }

  Future<void> tap(WidgetTester tester, Key key) async {
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  Key primary(String label) => ValueKey('review-primary-$label');

  final seed = [
    _task('a', DateTime(2026, 11, 3, 9)),
    _task('b', DateTime(2026, 11, 3, 15)),
    _task('c', DateTime(2026, 11, 3, 18), due: DateTime(2026, 11, 3, 23, 59)),
  ];

  testWidgets('done, move, drop and win are saved', (tester) async {
    final env = await pump(tester, seed);
    await tap(tester, const ValueKey('review-done-a'));
    await tap(tester, primary('Continue'));
    // a is done; b moves tomorrow; c is due today so it offers keep/anyway.
    expect(find.text('Task a'), findsNothing);
    expect(find.byKey(const ValueKey('review-opt-b-laterThisWeek')), findsOne);
    expect(find.byKey(const ValueKey('review-opt-c-tomorrow')), findsNothing);
    await tap(tester, const ValueKey('review-opt-b-tomorrow'));
    await tap(tester, const ValueKey('review-opt-c-drop'));
    await tap(tester, const ValueKey('review-undo-c'));
    await tap(tester, const ValueKey('review-opt-c-drop'));
    await tap(tester, primary('Continue'));
    // check-in step: no goals seeded, so an empty state and Continue.
    await tap(tester, primary('Continue'));
    await tester.enterText(
      find.byKey(const ValueKey('review-win-field')),
      'Finished the draft',
    );
    await tap(tester, primary('Save and finish'));

    expect(find.byKey(const ValueKey('review-praise')), findsOneWidget);
    final all = await env.tasks.getAll();
    expect(all.map((t) => t.id), ['a', 'b']);
    expect(all.first.status, TaskStatus.done);
    expect(all.last.remindAt!.toLocal(), DateTime(2026, 11, 4, 15));
    final entries = await env.reviews.all();
    expect(entries.single.win, 'Finished the draft');
    expect(entries.single.doneCount, 1);
    expect(entries.single.movedCount, 2);
  });

  testWidgets('skipping every step records nothing and is handled', (
    tester,
  ) async {
    var finished = false;
    final env = await pump(tester, seed, onFinished: () => finished = true);
    for (var i = 0; i < 4; i++) {
      await tap(tester, const ValueKey('review-skip'));
    }
    expect(find.byKey(const ValueKey('review-praise')), findsOneWidget);
    await tap(tester, primary('Done'));
    expect(finished, isTrue);
    expect(await env.reviews.all(), isEmpty);
    expect(await env.reviews.isHandled('2026-11-03'), isTrue);
    final all = await env.tasks.getAll();
    expect(all.every((t) => t.status == TaskStatus.open), isTrue);
    expect(all.first.remindAt!.toLocal(), DateTime(2026, 11, 3, 9));
  });

  testWidgets('tomorrow anyway on a deadline task moves the deadline', (
    tester,
  ) async {
    final env = await pump(tester, seed);
    await tap(tester, primary('Continue'));
    await tap(tester, const ValueKey('review-opt-c-tomorrowAnyway'));
    await tap(tester, primary('Continue'));
    final c = await env.tasks.getById('c');
    expect(c!.dueAt!.toLocal(), DateTime(2026, 11, 4, 23, 59));
  });

  testWidgets('a recurring task completes its occurrence and stores the rule', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final occurrence = DateTime.utc(2026, 11, 3, 9);
    final t0 = DateTime.utc(2026, 11, 1);
    final tasks = InMemoryTaskRepository([
      Task(
        id: 'r',
        title: 'Stretch',
        remindAt: occurrence,
        createdAt: t0,
        updatedAt: t0,
      ),
    ]);
    final rules = InMemoryReminderRepository([
      ReminderRule(
        id: 'rule-r',
        taskId: 'r',
        rrule: 'FREQ=DAILY',
        createdAt: t0,
        updatedAt: t0,
      ),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clockProvider.overrideWithValue(
            FixedClock(DateTime.utc(2026, 11, 3, 21)),
          ),
          taskRepositoryProvider.overrideWithValue(tasks),
          reminderRepositoryProvider.overrideWithValue(rules),
          preferencesRepositoryProvider.overrideWithValue(
            InMemoryPreferencesRepository(
              const Preferences(timeZoneName: 'UTC'),
            ),
          ),
          reviewRepositoryProvider.overrideWithValue(
            InMemoryReviewRepository(),
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          localizationsDelegates: localizationsDelegates,
          supportedLocales: supportedLocales,
          home: EveningReviewFlow(onFinished: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tap(tester, const ValueKey('review-done-r'));
    await tap(tester, primary('Continue'));
    final rule = (await rules.getForTask('r'))!;
    expect(rule.lastCompletedAt, occurrence);
    final r = (await tasks.getById('r'))!;
    expect(r.status, TaskStatus.open);
    expect(r.remindAt, DateTime.utc(2026, 11, 4, 9));
  });

  testWidgets('checked-in recurring goals get a +1 tick', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final t0 = DateTime.utc(2026, 10, 1);
    final tasks = InMemoryTaskRepository();
    final reviews = InMemoryReviewRepository();
    final goals = InMemoryGoalRepository(
      clock: FixedClock(now),
      seed: [
        GoalRecord(
          id: 'g-workouts',
          title: 'Workouts',
          metric: const RecurringMetric(quota: 4, unit: 'workouts'),
          createdAt: t0,
          updatedAt: t0,
        ),
        // A paused goal — stays off the list.
        GoalRecord(
          id: 'g-paused',
          title: 'Paused',
          status: GoalStatus.paused,
          metric: const RecurringMetric(quota: 3, unit: 'runs'),
          createdAt: t0,
          updatedAt: t0,
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clockProvider.overrideWithValue(FixedClock(now)),
          taskRepositoryProvider.overrideWithValue(tasks),
          reviewRepositoryProvider.overrideWithValue(reviews),
          goalRepositoryProvider.overrideWithValue(goals),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          localizationsDelegates: localizationsDelegates,
          supportedLocales: supportedLocales,
          home: EveningReviewFlow(onFinished: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Skip through done + move to land on check-in.
    await tap(tester, primary('Continue'));
    await tap(tester, primary('Continue'));
    expect(find.text('Workouts'), findsOne);
    expect(find.text('Paused'), findsNothing);
    await tap(tester, const ValueKey('review-checkin-g-workouts'));
    await tap(tester, primary('Continue'));
    final ticks = (await tasks.getAll()).where(isMetricTick).toList();
    expect(ticks, hasLength(1));
    expect(ticks.single.goalId, 'g-workouts');
    expect(ticks.single.completedAt, isNotNull);
  });

  testWidgets(
    'Done on a deep-linked review entry falls back to /today (#212)',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      final router = GoRouter(
        initialLocation: '/review',
        routes: [
          GoRoute(
            path: '/today',
            builder: (_, _) => const Scaffold(body: Text('today-screen')),
          ),
          GoRoute(
            path: '/review',
            builder: (_, _) => const EveningReviewEntry(),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clockProvider.overrideWithValue(FixedClock(now)),
            taskRepositoryProvider.overrideWithValue(InMemoryTaskRepository()),
            reviewRepositoryProvider.overrideWithValue(
              InMemoryReviewRepository(),
            ),
          ],
          child: MaterialApp.router(
            theme: buildAppTheme(),
            localizationsDelegates: localizationsDelegates,
            supportedLocales: supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Skip through every step, then tap Done on the wrap page.
      for (var i = 0; i < 4; i++) {
        await tap(tester, const ValueKey('review-skip'));
      }
      expect(find.byKey(const ValueKey('review-praise')), findsOneWidget);
      await tap(tester, primary('Done'));
      expect(find.text('today-screen'), findsOneWidget);
      expect(router.routerDelegate.currentConfiguration.uri.path, '/today');
    },
  );

  testWidgets('lays out in RTL at 390x844', (tester) async {
    final he = lookupAppLocalizations(const Locale('he'));
    await pump(
      tester,
      seed,
      dir: TextDirection.rtl,
      locale: const Locale('he'),
    );
    expect(find.text(he.reviewDoneTitle), findsOneWidget);
    expect(find.text('What got done?'), findsNothing);
    expect(tester.takeException(), isNull);
    await tap(tester, primary(he.onboardingContinue));
    expect(tester.takeException(), isNull);
  });
}
