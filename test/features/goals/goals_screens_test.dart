import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/goals/goals.dart';
import 'package:grind/features/goals/presentation/goal_l10n.dart';
import 'package:grind/l10n/l10n.dart';
import 'package:grind/theme/app_theme.dart';

import '../../test_fonts.dart';

final _t0 = DateTime.utc(2026, 11, 3, 8);

GoalRecord _goal(
  String id,
  String title, {
  String? area,
  GoalHorizon horizon = GoalHorizon.month,
  GoalMetric? metric,
  GoalStatus status = GoalStatus.active,
  DateTime? targetDate,
}) => GoalRecord(
  id: id,
  title: title,
  area: area,
  horizon: horizon,
  metric: metric,
  status: status,
  targetDate: targetDate,
  createdAt: _t0,
  updatedAt: _t0,
);

final _seed = [
  _goal(
    'pm',
    'Finish the project management course',
    area: 'learning',
    metric: const FiniteMetric(target: 12, unit: 'lessons', current: 8),
    targetDate: DateTime.utc(2026, 12, 31, 21, 59),
  ),
  _goal(
    'read',
    'Read two investing books',
    area: 'investing',
    horizon: GoalHorizon.quarter,
    metric: const FiniteMetric(target: 10, unit: 'chapters', current: 9),
  ),
  _goal(
    'run',
    'Run a 10k',
    area: 'fitness',
    horizon: GoalHorizon.year,
    status: GoalStatus.done,
  ),
  _goal('week', 'Meal prep Sunday', area: 'Kitchen', horizon: GoalHorizon.week),
];

Task _task(String id, {String? goalId, bool done = false}) => Task(
  id: id,
  title: 'Task $id',
  goalId: goalId,
  status: done ? TaskStatus.done : TaskStatus.open,
  createdAt: _t0,
  updatedAt: _t0,
);

Future<ProviderContainer> _pump(
  WidgetTester tester,
  Widget child, {
  List<GoalRecord>? goals,
  List<Task> tasks = const [],
  Locale locale = const Locale('en'),
}) async {
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(FixedClock(_t0)),
      goalRepositoryProvider.overrideWithValue(
        InMemoryGoalRepository(seed: goals ?? _seed, clock: FixedClock(_t0)),
      ),
      taskRepositoryProvider.overrideWithValue(InMemoryTaskRepository(tasks)),
    ],
  );
  addTearDown(container.dispose);
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  // The scope sits above MaterialApp, as in the app, so sheets see it.
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

  group('GoalsScreen', () {
    for (final locale in const [Locale('en'), Locale('he')]) {
      testWidgets('sections, cards and status pills (${locale.languageCode})', (
        tester,
      ) async {
        final l = lookupAppLocalizations(locale);
        await _pump(tester, const GoalsScreen(), locale: locale);
        expect(
          Directionality.of(tester.element(find.byType(GoalsScreen))),
          locale.languageCode == 'he' ? TextDirection.rtl : TextDirection.ltr,
        );
        expect(find.text(l.goalsHorizonWeek.toUpperCase()), findsOneWidget);
        expect(find.text(l.goalsHorizonMonth.toUpperCase()), findsOneWidget);
        expect(
          find.text(
            l.goalsProgressLine(l.goalsOfTargetUnit(8, 12, 'lessons'), 67),
          ),
          findsOneWidget,
        );
        expect(find.text('Learning'), findsOneWidget);
        expect(find.text('Kitchen'), findsOneWidget);
        expect(
          find.text(l.goalByDate(DateTime.utc(2026, 12, 31, 21, 59))),
          findsOneWidget,
        );
        if (locale.languageCode == 'he') {
          expect(find.text(l.goalsTitle), findsWidgets);
          expect(find.text('Almost there'), findsNothing);
        }
        // 9 of 10 is close to done.
        expect(find.text(l.goalsCloseToDone), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Run a 10k'), 200);
        expect(find.text(l.goalsHorizonYear.toUpperCase()), findsOneWidget);
        expect(find.text(l.goalsCompleted), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('empty state invites a first goal', (tester) async {
      await _pump(tester, const GoalsScreen(), goals: const []);
      expect(find.text('No goals yet'), findsOneWidget);
      expect(find.text('Add a goal'), findsOneWidget);
    });

    testWidgets('tapping a card opens it', (tester) async {
      GoalRecord? opened;
      await _pump(tester, GoalsScreen(onOpenGoal: (_, g) => opened = g));
      await tester.tap(find.text('Finish the project management course'));
      expect(opened?.id, 'pm');
    });
  });

  group('GoalFormSheet', () {
    testWidgets('saves a new goal with area, horizon, importance, metric', (
      tester,
    ) async {
      final container = await _pump(
        tester,
        const GoalsScreen(),
        goals: const [],
      );
      await tester.tap(find.bySemanticsLabel('New goal'));
      await tester.pumpAndSettle();
      expect(find.text('New goal'), findsWidgets);

      // Empty title shows the gentle error.
      await tester.tap(find.bySemanticsLabel('Save'));
      await tester.pumpAndSettle();
      expect(
        find.text('Give it a short name and you are set.'),
        findsOneWidget,
      );

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Finish PM course');
      await tester.tap(find.bySemanticsLabel('Learning'));
      await tester.tap(find.bySemanticsLabel('Quarter'));
      await tester.tap(find.bySemanticsLabel('Importance 5'));
      await tester.pump();
      await tester.enterText(find.widgetWithText(TextField, 'Target'), '12');
      await tester.enterText(find.widgetWithText(TextField, 'Unit'), 'lessons');
      await tester.ensureVisible(find.bySemanticsLabel('Save'));
      await tester.tap(find.bySemanticsLabel('Save'));
      await tester.pumpAndSettle();

      final saved = await container.read(goalRepositoryProvider).getAll();
      expect(saved, hasLength(1));
      final g = saved.single;
      expect(g.title, 'Finish PM course');
      expect(g.area, 'learning');
      expect(g.horizon, GoalHorizon.quarter);
      expect(g.importance, 5);
      expect(
        g.metric,
        const FiniteMetric(target: 12, unit: 'lessons', current: 0),
      );
      expect(find.text('THIS QUARTER'), findsOneWidget);
      expect(find.text('0 of 12 lessons · 0%'), findsOneWidget);
    });

    testWidgets('rejects a zero target and saves a custom area', (
      tester,
    ) async {
      final container = await _pump(
        tester,
        const GoalsScreen(),
        goals: const [],
      );
      await tester.tap(find.bySemanticsLabel('New goal'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Learn guitar');
      await tester.tap(find.bySemanticsLabel('Your own'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Name your area'),
        'Music',
      );
      await tester.enterText(find.widgetWithText(TextField, 'Target'), '0');
      await tester.ensureVisible(find.bySemanticsLabel('Save'));
      await tester.tap(find.bySemanticsLabel('Save'));
      await tester.pumpAndSettle();
      expect(find.text('A whole number above 0 works.'), findsOneWidget);
      expect(await container.read(goalRepositoryProvider).getAll(), isEmpty);

      await tester.enterText(find.widgetWithText(TextField, 'Target'), '');
      await tester.ensureVisible(find.bySemanticsLabel('Save'));
      await tester.tap(find.bySemanticsLabel('Save'));
      await tester.pumpAndSettle();
      final g = (await container.read(goalRepositoryProvider).getAll()).single;
      expect(g.area, 'Music');
      expect(g.metric, isNull);
    });
  });

  group('GoalDetailScreen', () {
    for (final locale in const [Locale('en'), Locale('he')]) {
      testWidgets('ring, linked tasks, actions (${locale.languageCode})', (
        tester,
      ) async {
        final l = lookupAppLocalizations(locale);
        await _pump(
          tester,
          GoalDetailScreen(goalId: 'pm', onAddTask: (_, _) {}),
          locale: locale,
          tasks: [
            _task('a', goalId: 'pm', done: true),
            _task('b', goalId: 'pm'),
            _task('c'),
          ],
        );
        expect(
          find.text('Finish the project management course'),
          findsOneWidget,
        );
        expect(find.text('67%'), findsOneWidget);
        expect(find.text('8 / 12'), findsOneWidget);
        expect(find.text('Task a'), findsOneWidget);
        expect(find.text('Task b'), findsOneWidget);
        expect(find.text('Task c'), findsNothing);
        await tester.scrollUntilVisible(find.text(l.tasksNewTask), 200);
        expect(find.text(l.goalsLinkTask), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('+1 counts and cheers at 80 %; edit count sets it', (
      tester,
    ) async {
      final container = await _pump(
        tester,
        const GoalDetailScreen(goalId: 'pm'),
      );
      await tester.tap(find.text('+1'));
      await tester.pumpAndSettle();
      var g = await container.read(goalRepositoryProvider).getById('pm');
      expect(g!.finite!.current, 9);
      expect(g.lastProgressAt, _t0);
      expect(find.text('75%'), findsOneWidget);

      await tester.tap(find.text('+1'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Almost there on'), findsOneWidget);
      expect(find.text('83%'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Edit count'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '12');
      await tester.tap(find.bySemanticsLabel('Save'));
      await tester.pumpAndSettle();
      g = await container.read(goalRepositoryProvider).getById('pm');
      expect(g!.finite!.current, 12);
      expect(find.text('100%'), findsOneWidget);
      expect(find.textContaining('is complete'), findsOneWidget);
    });

    testWidgets('linked-tasks metric counts ticked tasks', (tester) async {
      final container = await _pump(
        tester,
        const GoalDetailScreen(goalId: 'g'),
        goals: [
          _goal(
            'g',
            'Ship thesis chapters',
            metric: const FiniteMetric(
              target: 2,
              unit: 'chapters',
              source: MetricSource.linkedTasks,
            ),
          ),
        ],
        tasks: [
          _task('a', goalId: 'g'),
          _task('b', goalId: 'g'),
          _task('c'),
        ],
      );
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('+1'), findsNothing);
      await tester.tap(find.bySemanticsLabel('Task a').last);
      await tester.pumpAndSettle();
      expect(find.text('50%'), findsOneWidget);
      final a = await container.read(taskRepositoryProvider).getById('a');
      expect(a!.isDone, isTrue);

      // Link c through the picker.
      await tester.scrollUntilVisible(find.text('Link a task'), 200);
      await tester.tap(find.text('Link a task'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Task c').last);
      await tester.pumpAndSettle();
      final c = await container.read(taskRepositoryProvider).getById('c');
      expect(c!.goalId, 'g');
    });

    testWidgets('missing goal shows a friendly state', (tester) async {
      await _pump(tester, const GoalDetailScreen(goalId: 'nope'));
      expect(find.text('This goal is not here anymore.'), findsOneWidget);
    });
  });

  test('goalsByHorizonProvider groups and orders', () async {
    final container = ProviderContainer(
      overrides: [
        goalRepositoryProvider.overrideWithValue(
          InMemoryGoalRepository(
            seed: [
              ..._seed,
              _goal('low', 'Low', horizon: GoalHorizon.month),
              _goal(
                'paused',
                'Paused',
                horizon: GoalHorizon.month,
                status: GoalStatus.paused,
              ),
            ].map((g) => g.id == 'low' ? g.copyWith(importance: 1) : g),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(goalsProvider, (_, _) {});
    await container.read(goalsProvider.future);
    final by = container.read(goalsByHorizonProvider);
    expect(by.keys, GoalHorizon.values);
    expect(by[GoalHorizon.month]!.map((g) => g.id), ['pm', 'low', 'paused']);
    expect(by[GoalHorizon.year]!.single.id, 'run');
  });
}
