import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/analytics/analytics_screen.dart';
import 'package:grind/features/focus/providers.dart';
import 'package:grind/l10n/l10n.dart';

import '../../test_fonts.dart';

final _now = DateTime.utc(2026, 11, 3, 10);

Task _done(String id, String cat, int actual, int day) => Task(
  id: id,
  title: id,
  category: cat,
  estimatedMinutes: 30,
  actualMinutes: actual,
  status: TaskStatus.done,
  completedAt: DateTime.utc(2026, 11, day, 9),
  dueAt: DateTime.utc(2026, 11, day, 9),
  createdAt: _now,
  updatedAt: _now,
);

Future<void> _pump(
  WidgetTester tester,
  List<Task> tasks,
  List<FocusSession> sessions, {
  TextDirection dir = TextDirection.ltr,
  Locale? locale,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(FixedClock(_now)),
        taskRepositoryProvider.overrideWithValue(InMemoryTaskRepository(tasks)),
        focusSessionRepositoryProvider.overrideWithValue(
          InMemoryFocusSessionRepository(sessions),
        ),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: localizationsDelegates,
        supportedLocales: supportedLocales,
        home: Directionality(
          textDirection: dir,
          child: const AnalyticsScreen(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('empty state', (tester) async {
    await _pump(tester, const [], const []);
    expect(find.text('Your numbers'), findsOneWidget);
    expect(find.text('Nothing to chart yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cards with data, accuracy line in Pip tone', (tester) async {
    final tasks = [for (var i = 0; i < 5; i++) _done('t$i', 'study', 42, 2)];
    final session = FocusSession(
      id: 's',
      plannedMinutes: 25,
      startedAt: DateTime.utc(2026, 11, 3, 8),
      endedAt: DateTime.utc(2026, 11, 3, 8, 25),
      completed: true,
      createdAt: _now,
      updatedAt: _now,
    );
    await _pump(tester, tasks, [session]);
    expect(find.text('Focus minutes'), findsOneWidget);
    expect(find.text('Completion rate'), findsOneWidget);
    expect(find.text('study tasks usually run 1.4× longer'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.textContaining('Rest counts too'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('under the sample gate: waiting copy, no ratio', (tester) async {
    final tasks = [for (var i = 0; i < 3; i++) _done('t$i', 'study', 60, 2)];
    await _pump(tester, tasks, const []);
    expect(find.text('A few more tasks and Pip will know.'), findsOneWidget);
    expect(find.textContaining('usually'), findsNothing);
  });

  testWidgets('RTL at 390x844 has no overflow', (tester) async {
    final tasks = [for (var i = 0; i < 5; i++) _done('t$i', 'study', 42, 2)];
    final he = lookupAppLocalizations(const Locale('he'));
    await _pump(
      tester,
      tasks,
      const [],
      dir: TextDirection.rtl,
      locale: const Locale('he'),
    );
    expect(tester.takeException(), isNull);
    expect(find.text(he.analyticsTitle), findsOneWidget);
    expect(
      find.text(he.analyticsAccuracyLonger('study', '1.4')),
      findsOneWidget,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
