import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/capacity/capacity.dart';
import 'package:grind/l10n/l10n.dart';
import 'package:grind/theme/app_theme.dart';
import 'package:grind/widgets/widgets.dart';

import '../../test_fonts.dart';

// Tue Nov 3 2026, 09:00 in Asia/Jerusalem (UTC+2) -> week Sun Nov 1 to Sat Nov 7.
final _now = DateTime.utc(2026, 11, 3, 7);
final _stamp = DateTime.utc(2026, 10, 1);

Task _task(
  String id,
  String title, {
  int minutes = 60,
  DateTime? due,
  DateTime? at,
}) => Task(
  id: id,
  title: title,
  estimatedMinutes: minutes,
  dueAt: due,
  scheduledStart: at,
  scheduledEnd: at?.add(Duration(minutes: minutes)),
  createdAt: _stamp,
  updatedAt: _stamp,
);

final _overbooked = [
  _task(
    'wed',
    'Finish the report',
    minutes: 600,
    due: DateTime.utc(2026, 11, 4, 15),
  ),
  _task(
    'thu',
    'Prepare the talk',
    minutes: 600,
    due: DateTime.utc(2026, 11, 5, 15),
  ),
  _task(
    'a',
    'Reorganise the shelves',
    minutes: 360,
    at: DateTime.utc(2026, 11, 3, 7),
  ),
  _task(
    'b',
    'Read the long article',
    minutes: 240,
    at: DateTime.utc(2026, 11, 4, 7),
  ),
  _task('c', 'Tidy the inbox', minutes: 180, at: DateTime.utc(2026, 11, 5, 7)),
];

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required Locale locale,
  List<Task> tasks = const [],
  int tab = 0,
}) async {
  final repo = InMemoryTaskRepository(tasks);
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(FixedClock(_now)),
      taskRepositoryProvider.overrideWithValue(repo),
      jsonDocStoreProvider.overrideWithValue(InMemoryJsonDocStore()),
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
        home: WeekCapacityScreen(initialTab: tab),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUpAll(loadAppFonts);

  for (final locale in const [Locale('en'), Locale('he')]) {
    final l = lookupAppLocalizations(locale);
    final rtl = locale.languageCode == 'he';

    group('WeekCapacityScreen (${locale.languageCode})', () {
      testWidgets('overbooked week: verdict, bars, moves, no overflow', (
        tester,
      ) async {
        await _pump(tester, locale: locale, tasks: _overbooked);
        expect(tester.takeException(), isNull);
        expect(
          Directionality.of(tester.element(find.byType(WeekCapacityScreen))),
          rtl ? TextDirection.rtl : TextDirection.ltr,
        );
        expect(find.text(l.capacityTitle), findsOneWidget);
        expect(find.text(l.capacityStateOver), findsOneWidget);
        expect(find.byType(WeekBars), findsOneWidget);
        expect(find.text(l.capacityMoveTitle.toUpperCase()), findsOneWidget);
        expect(find.text(l.capacityMoveAll), findsOneWidget);
        // In-week deadlines are never offered.
        expect(find.text('Finish the report'), findsNothing);
        expect(find.text('Prepare the talk'), findsNothing);
      });

      testWidgets('"Move all suggested" unschedules and holds to next week', (
        tester,
      ) async {
        final container = await _pump(
          tester,
          locale: locale,
          tasks: _overbooked,
        );
        final before = container.read(weekReportProvider).deferrals;
        expect(before, isNotEmpty);
        await tester.ensureVisible(find.text(l.capacityMoveAll));
        await tester.tap(find.text(l.capacityMoveAll));
        await tester.pumpAndSettle();
        final repo = container.read(taskRepositoryProvider);
        for (final d in before) {
          final t = (await repo.getById(d.task.id))!;
          expect(t.isScheduled, isFalse);
          expect(t.notBefore, isNotNull);
        }
        expect(container.read(weekReportProvider).deferrals, isEmpty);
        expect(tester.takeException(), isNull);
      });

      testWidgets('a light week fits and offers nothing to move', (
        tester,
      ) async {
        await _pump(
          tester,
          locale: locale,
          tasks: [_task('x', 'Quick call', due: DateTime.utc(2026, 11, 4, 12))],
        );
        expect(tester.takeException(), isNull);
        expect(find.text(l.capacityVerdictFits), findsOneWidget);
        expect(find.text(l.capacityNothingToMove), findsOneWidget);
        expect(find.text(l.capacityMoveAll), findsNothing);
      });

      testWidgets('priorities tab: ranked rows, weights, no overflow', (
        tester,
      ) async {
        await _pump(tester, locale: locale, tasks: _overbooked, tab: 1);
        expect(tester.takeException(), isNull);
        expect(find.byType(PriorityList), findsOneWidget);
        expect(find.text(l.capacityRank(1)), findsOneWidget);
        expect(find.text(l.capacityWeightsTitle), findsOneWidget);
        expect(find.byIcon(Icons.drag_handle_rounded), findsWidgets);

        await tester.tap(find.text(l.capacityTabWeek));
        await tester.pumpAndSettle();
        expect(find.byType(WeekBars), findsOneWidget);
      });

      testWidgets('weight sliders are named for screen readers', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _pump(tester, locale: locale, tasks: _overbooked, tab: 1);
        await tester.ensureVisible(find.text(l.capacityWeightsTitle));
        await tester.tap(find.text(l.capacityWeightsTitle));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(l.capacityWeightsReset));
        await tester.pumpAndSettle();
        for (final name in [
          l.capacityWeightUrgency,
          l.capacityWeightImportance,
          l.capacityWeightPriority,
          l.capacityWeightQuickWin,
        ]) {
          final node = tester.getSemantics(
            find
                .byWidgetPredicate(
                  (w) => w is Slider && w.semanticFormatterCallback != null,
                )
                .at(
                  [
                    l.capacityWeightUrgency,
                    l.capacityWeightImportance,
                    l.capacityWeightPriority,
                    l.capacityWeightQuickWin,
                  ].indexOf(name),
                ),
          );
          expect(node.value, startsWith(name));
          expect(node.flagsCollection.isSlider, isTrue);
        }
        handle.dispose();
      });

      testWidgets('deep-link entry shows Back that falls back to /plan', (
        tester,
      ) async {
        final container = ProviderContainer(
          overrides: [
            clockProvider.overrideWithValue(FixedClock(_now)),
            taskRepositoryProvider.overrideWithValue(
              InMemoryTaskRepository(const []),
            ),
            jsonDocStoreProvider.overrideWithValue(InMemoryJsonDocStore()),
          ],
        );
        addTearDown(container.dispose);
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final router = GoRouter(
          initialLocation: '/week',
          routes: [
            GoRoute(
              path: '/week',
              builder: (_, _) => const WeekCapacityScreen(),
            ),
            GoRoute(
              path: '/plan',
              builder: (_, _) => const Scaffold(body: Text('PLAN_MARKER')),
            ),
          ],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              theme: buildAppTheme(),
              locale: locale,
              supportedLocales: supportedLocales,
              localizationsDelegates: localizationsDelegates,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Back control must be present even when the navigator cannot pop.
        final back = find.byTooltip(l.capacityBack);
        expect(back, findsOneWidget);
        await tester.tap(back);
        await tester.pumpAndSettle();

        expect(find.text('PLAN_MARKER'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('pin sheet sets a priority', (tester) async {
        final container = await _pump(
          tester,
          locale: locale,
          tasks: _overbooked,
          tab: 1,
        );
        final first = container.read(priorityRankProvider).first;
        await tester.tap(
          find
              .descendant(
                of: find.byType(PriorityList),
                matching: find.byType(Pill),
              )
              .first,
        );
        await tester.pumpAndSettle();
        expect(find.text(l.capacityPinTitle), findsOneWidget);
        await tester.tap(find.text(l.capacityPinLow).last);
        await tester.pumpAndSettle();
        final t = await container
            .read(taskRepositoryProvider)
            .getById(first.task.id);
        expect(t!.priority, 3);
        expect(tester.takeException(), isNull);
      });
    });
  }
}
