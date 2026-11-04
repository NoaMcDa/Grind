import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/goals/goals.dart';
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
  int importance = 3,
  DateTime? updatedAt,
}) => GoalRecord(
  id: id,
  title: title,
  area: area,
  horizon: horizon,
  metric: metric,
  status: status,
  importance: importance,
  createdAt: _t0,
  updatedAt: updatedAt ?? _t0,
);

Future<ProviderContainer> _pump(
  WidgetTester tester,
  Widget child, {
  List<GoalRecord> goals = const [],
  Locale locale = const Locale('en'),
}) async {
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(FixedClock(_t0)),
      goalRepositoryProvider.overrideWithValue(
        InMemoryGoalRepository(seed: goals, clock: FixedClock(_t0)),
      ),
      taskRepositoryProvider.overrideWithValue(
        InMemoryTaskRepository(const []),
      ),
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
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUpAll(loadAppFonts);

  group('GoalsLinkCard', () {
    testWidgets('shows the labelled "Goals" title in English and Hebrew', (
      tester,
    ) async {
      for (final locale in const [Locale('en'), Locale('he')]) {
        final l = lookupAppLocalizations(locale);
        await _pump(tester, const GoalsLinkCard(), locale: locale);
        expect(find.byKey(const Key('today-goals')), findsOneWidget);
        expect(find.text(l.goalsTitle), findsOneWidget);
      }
    });

    testWidgets('empty state: no goals shows the empty-state copy', (
      tester,
    ) async {
      await _pump(tester, const GoalsLinkCard());
      expect(find.text('Goals'), findsOneWidget);
      // The empty-state body line.
      expect(
        find.text(
          'Pick one thing you would love to move this month. Pip will cheer.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('one active goal shows its progress line', (tester) async {
      await _pump(
        tester,
        const GoalsLinkCard(),
        goals: [
          _goal(
            'pm',
            'Finish the PM course',
            area: 'learning',
            metric: const FiniteMetric(target: 12, unit: 'lessons', current: 8),
          ),
        ],
      );
      final l = lookupAppLocalizations(const Locale('en'));
      expect(
        find.text(
          l.goalsProgressLine(l.goalsOfTargetUnit(8, 12, 'lessons'), 67),
        ),
        findsOneWidget,
      );
    });

    testWidgets('picks the highest-importance active goal with a metric', (
      tester,
    ) async {
      await _pump(
        tester,
        const GoalsLinkCard(),
        goals: [
          _goal(
            'pm',
            'Project management',
            importance: 3,
            metric: const FiniteMetric(target: 10, unit: 'lessons', current: 1),
          ),
          _goal(
            'thesis',
            'Thesis',
            importance: 5,
            metric: const FiniteMetric(target: 10, unit: 'pages', current: 4),
          ),
          _goal('done', 'Already done', status: GoalStatus.done, importance: 5),
        ],
      );
      final l = lookupAppLocalizations(const Locale('en'));
      expect(
        find.text(l.goalsProgressLine(l.goalsOfTargetUnit(4, 10, 'pages'), 40)),
        findsOneWidget,
      );
    });

    testWidgets('tap: invokes the callback', (tester) async {
      var opened = false;
      await _pump(tester, GoalsLinkCard(onTap: () => opened = true));
      await tester.tap(find.byKey(const Key('today-goals')));
      expect(opened, isTrue);
    });

    testWidgets('the card is at least 44 px tall and spans the column width', (
      tester,
    ) async {
      await _pump(tester, const GoalsLinkCard());
      final size = tester.getSize(find.byKey(const Key('today-goals')));
      // Phone width is 390; the card is placed inside a Scaffold with no
      // padding here, so it should span the viewport edge to edge.
      expect(size.height, greaterThanOrEqualTo(44));
      expect(size.width, greaterThan(300));
    });
  });

  group('PipAllGoalsLink', () {
    testWidgets('renders the labelled "All goals" link', (tester) async {
      for (final locale in const [Locale('en'), Locale('he')]) {
        final l = lookupAppLocalizations(locale);
        await _pump(tester, const PipAllGoalsLink(), locale: locale);
        expect(find.byKey(const Key('pip-all-goals')), findsOneWidget);
        expect(find.text(l.goalsAllGoalsLink), findsOneWidget);
      }
    });

    testWidgets('tap: invokes the callback', (tester) async {
      var opened = false;
      await _pump(tester, PipAllGoalsLink(onTap: () => opened = true));
      await tester.tap(find.byKey(const Key('pip-all-goals')));
      expect(opened, isTrue);
    });
  });
}
