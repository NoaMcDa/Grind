import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/goals/goals.dart';
import 'package:grind/features/goals/presentation/goal_l10n.dart';
import 'package:grind/features/review/review_providers.dart';
import 'package:grind/features/review/review_repository.dart';
import 'package:grind/l10n/l10n.dart';
import 'package:grind/theme/app_theme.dart';

import '../../test_fonts.dart';

// Tue 3 Nov 2026, 10:00 in Jerusalem (Sunday weeks: Nov 1 – Nov 7).
final _t0 = DateTime.utc(2026, 11, 3, 8);
final _old = DateTime.utc(2026, 9, 1);

GoalRecord _goal(
  String id,
  String title, {
  GoalHorizon horizon = GoalHorizon.month,
  GoalMetric? metric,
  GoalStatus status = GoalStatus.active,
  DateTime? lastProgressAt,
  DateTime? updatedAt,
}) => GoalRecord(
  id: id,
  title: title,
  horizon: horizon,
  metric: metric,
  status: status,
  lastProgressAt: lastProgressAt,
  createdAt: _old,
  updatedAt: updatedAt ?? _old,
);

Task _done(String id, DateTime at, {String? goalId, bool tick = false}) => Task(
  id: id,
  title: 'Task $id',
  goalId: goalId,
  category: tick ? metricTickCategory : null,
  status: TaskStatus.done,
  completedAt: at,
  createdAt: at,
  updatedAt: at,
);

final _goals = [
  _goal(
    'gym',
    'Work out four times a week',
    horizon: GoalHorizon.week,
    metric: const RecurringMetric(quota: 4, unit: 'workouts'),
  ),
  _goal(
    'pm',
    'Finish the project management course',
    metric: const FiniteMetric(target: 12, unit: 'lessons', current: 10),
    lastProgressAt: _t0.subtract(const Duration(days: 1)),
  ),
  _goal(
    'read',
    'Read two investing books',
    horizon: GoalHorizon.quarter,
    metric: const FiniteMetric(target: 10, unit: 'chapters', current: 3),
    lastProgressAt: _t0.subtract(const Duration(days: 30)),
  ),
  _goal(
    'run',
    'Run a 10k',
    horizon: GoalHorizon.year,
    status: GoalStatus.done,
    updatedAt: DateTime.utc(2026, 10, 28),
  ),
];

final _tasks = [
  // This week: three workouts (two +1s, one linked task).
  _done('w1', DateTime.utc(2026, 11, 1, 6), goalId: 'gym', tick: true),
  _done('w2', DateTime.utc(2026, 11, 2, 6), goalId: 'gym', tick: true),
  _done('w3', DateTime.utc(2026, 11, 3, 6), goalId: 'gym'),
  // Last week: four, the quota.
  for (var i = 0; i < 4; i++)
    _done('l$i', DateTime.utc(2026, 10, 26 + i, 6), goalId: 'gym', tick: true),
  // Two weeks ago: none. Three weeks ago: two.
  _done('o1', DateTime.utc(2026, 10, 13, 6), goalId: 'gym', tick: true),
  _done('o2', DateTime.utc(2026, 10, 14, 6), goalId: 'gym', tick: true),
  _done('real', DateTime.utc(2026, 10, 27, 9)),
];

class _Reviews extends InMemoryReviewRepository {
  _Reviews() {
    save(
      const ReviewEntry(
        date: '2026-10-27',
        win: 'Sent the thesis outline',
        doneCount: 3,
        movedCount: 2,
      ),
    );
    save(
      const ReviewEntry(
        date: '2026-10-29',
        win: 'Finished DL lab 3',
        doneCount: 2,
        movedCount: 0,
      ),
    );
  }
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  Widget child, {
  List<GoalRecord>? goals,
  List<Task>? tasks,
  Locale locale = const Locale('en'),
}) async {
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(FixedClock(_t0)),
      goalRepositoryProvider.overrideWithValue(
        InMemoryGoalRepository(seed: goals ?? _goals, clock: FixedClock(_t0)),
      ),
      taskRepositoryProvider.overrideWithValue(
        InMemoryTaskRepository(tasks ?? _tasks),
      ),
      reviewRepositoryProvider.overrideWithValue(_Reviews()),
    ],
  );
  addTearDown(container.dispose);
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildAppTheme(),
        locale: locale,
        supportedLocales: supportedLocales,
        localizationsDelegates: localizationsDelegates,
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUpAll(loadAppFonts);

  group('HighlightsScreen', () {
    for (final locale in const [Locale('en'), Locale('he')]) {
      testWidgets('recap and status groups (${locale.languageCode})', (
        tester,
      ) async {
        final l = lookupAppLocalizations(locale);
        String? shared;
        await _pump(
          tester,
          HighlightsScreen(onShare: (t) async => shared = t),
          locale: locale,
        );
        expect(
          Directionality.of(tester.element(find.byType(HighlightsScreen))),
          locale.languageCode == 'he' ? TextDirection.rtl : TextDirection.ltr,
        );
        expect(find.text(l.highlightsTitle), findsOneWidget);
        expect(find.text(l.recapTitleLastWeek), findsOneWidget);
        // Leads with the biggest win: the goal finished last week.
        expect(
          find.text(l.recapLeadGoalCompleted('Run a 10k')),
          findsOneWidget,
        );
        expect(find.text('Sent the thesis outline'), findsOneWidget);
        expect(find.text(l.recapRolledOverLine(2)), findsOneWidget);

        await tester.scrollUntilVisible(find.text(l.recapShare), 200);
        await tester.tap(find.text(l.recapShare));
        await tester.pump();
        expect(shared, contains(l.recapLeadGoalCompleted('Run a 10k')));
        expect(shared, contains('Work out four times a week 4/4'));

        for (final (group, title) in [
          (HighlightGroup.completed, 'Run a 10k'),
          (HighlightGroup.closeToDone, 'Finish the project management course'),
          (HighlightGroup.onTrack, 'Work out four times a week'),
          (HighlightGroup.stalled, 'Read two investing books'),
        ]) {
          final label = find.text(
            '${l.highlightGroup(group)} · 1'.toUpperCase(),
          );
          await tester.scrollUntilVisible(label, 200);
          expect(label, findsOneWidget);
          await tester.scrollUntilVisible(find.text(title), 200);
          expect(find.text(title), findsOneWidget);
        }
        expect(find.text(l.highlightsStalledNote(30)), findsOneWidget);
        expect(
          find.text(l.goalPeriodLine(3, 4, 'workouts', MetricPeriod.week)),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('no goals: a friendly empty state under the recap', (
      tester,
    ) async {
      await _pump(
        tester,
        const HighlightsScreen(),
        goals: const [],
        tasks: const [],
      );
      expect(find.text('Nothing to highlight yet'), findsOneWidget);
      expect(find.text('Last week with Pip'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('HighlightsLinkCard shows the recap headline', (tester) async {
      var opened = false;
      await _pump(
        tester,
        Scaffold(body: HighlightsLinkCard(onTap: () => opened = true)),
      );
      expect(find.text('Highlights'), findsOneWidget);
      await tester.tap(find.byType(HighlightsLinkCard));
      expect(opened, isTrue);
    });

    testWidgets('the Goals header links to Highlights', (tester) async {
      var opened = false;
      await _pump(tester, GoalsScreen(onOpenHighlights: (_) => opened = true));
      await tester.tap(find.bySemanticsLabel('Highlights'));
      expect(opened, isTrue);
      // The recurring goal reads per week on its card.
      expect(find.text('3 of 4 workouts this week'), findsOneWidget);
    });
  });

  group('recurring goal detail', () {
    for (final locale in const [Locale('en'), Locale('he')]) {
      testWidgets('this period, +1, trend (${locale.languageCode})', (
        tester,
      ) async {
        final l = lookupAppLocalizations(locale);
        final c = await _pump(
          tester,
          const GoalDetailScreen(goalId: 'gym'),
          locale: locale,
        );
        expect(
          find.text(l.goalPeriodLine(3, 4, 'workouts', MetricPeriod.week)),
          findsOneWidget,
        );
        expect(find.text('3/4'), findsOneWidget);
        expect(find.text(l.goalsTrendWeeks.toUpperCase()), findsOneWidget);
        // Tracked weeks since September: all 8; hit once (last week).
        expect(find.text(l.goalsTrendSummary(1, 8)), findsOneWidget);
        expect(find.byType(MetricTrend), findsOneWidget);
        // The linked task shows; the +1 ticks do not.
        expect(find.text('Task w3'), findsOneWidget);
        expect(find.text('Task w1'), findsNothing);

        await tester.tap(find.text('+1'));
        await tester.pumpAndSettle();
        expect(
          find.text(l.goalsMilestoneMetricHit('Work out four times a week')),
          findsOneWidget,
        );
        expect(find.text('4/4'), findsOneWidget);
        expect(find.text(l.goalsQuotaHitWeek), findsOneWidget);
        expect(find.text(l.goalsTrendSummary(2, 8)), findsOneWidget);

        await tester.tap(find.text(l.goalsUndoTick));
        await tester.pumpAndSettle();
        expect(find.text('3/4'), findsOneWidget);
        final ticks = (await c.read(taskRepositoryProvider).getAll())
            .where(isMetricTick)
            .length;
        expect(ticks, 8);
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('the form saves a weekly quota', (tester) async {
    final c = await _pump(tester, const GoalsScreen(), goals: const []);
    await tester.tap(find.bySemanticsLabel('New goal').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Nutrition plan');
    await tester.ensureVisible(find.bySemanticsLabel('Per week'));
    await tester.tap(find.bySemanticsLabel('Per week'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Starts fresh every week. Your +1 taps and linked tasks both count.',
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Linked tasks'), findsNothing);
    await tester.enterText(find.widgetWithText(TextField, 'How many'), '5');
    await tester.enterText(find.widgetWithText(TextField, 'Unit'), 'days');
    await tester.ensureVisible(find.bySemanticsLabel('Save'));
    await tester.tap(find.bySemanticsLabel('Save'));
    await tester.pumpAndSettle();
    final saved = await c.read(goalRepositoryProvider).getAll();
    expect(
      saved.single.metric,
      const RecurringMetric(quota: 5, unit: 'days', period: MetricPeriod.week),
    );
    expect(find.text('0 of 5 days this week'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
