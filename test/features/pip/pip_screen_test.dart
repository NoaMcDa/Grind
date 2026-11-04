import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/pip/pip_screen.dart';
import 'package:grind/l10n/l10n.dart';

import '../../test_fonts.dart';

final _now = DateTime(2026, 11, 3, 12);

Task _done(String id, DateTime at) => Task(
  id: id,
  title: 'Win $id',
  status: TaskStatus.done,
  completedAt: at,
  createdAt: at,
  updatedAt: at,
);

Future<void> _pump(
  WidgetTester tester,
  List<Task> tasks, {
  TextDirection dir = TextDirection.ltr,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(FixedClock(_now)),
        taskRepositoryProvider.overrideWithValue(InMemoryTaskRepository(tasks)),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: localizationsDelegates,
        supportedLocales: supportedLocales,
        home: Directionality(
          textDirection: dir,
          child: const Scaffold(body: PipScreen()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('real data: mood, showed-up line, wins, rest days', (
    tester,
  ) async {
    final tasks = [
      for (var i = 0; i < 6; i++) _done('a$i', _now),
      _done('b', DateTime(2026, 11, 1, 9)),
      _done('c', DateTime(2026, 10, 30, 9)),
    ];
    await _pump(tester, tasks);
    expect(find.text('Pip is glowing'), findsOneWidget);
    expect(
      find.textContaining('You showed up 3 of the last 7 days'),
      findsOneWidget,
    );
    expect(find.text('Strong'), findsOneWidget);
    expect(find.text('rest day'), findsNWidgets(4));
    expect(find.textContaining('Win '), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('no activity: gentle copy, no zeros, still all rest days', (
    tester,
  ) async {
    await _pump(tester, const []);
    expect(find.text('Pip is resting'), findsOneWidget);
    expect(find.text('Quiet'), findsOneWidget);
    expect(find.text('rest day'), findsNWidgets(7));
    expect(find.text('Your first win will land here.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping an unlock changes what Pip wears', (tester) async {
    await _pump(tester, [for (var i = 0; i < 25; i++) _done('t$i', _now)]);
    expect(find.text('wearing: Scarf'), findsOneWidget);
    await tester.ensureVisible(find.text('Party hat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Party hat'));
    await tester.pumpAndSettle();
    expect(find.text('wearing: Party hat'), findsOneWidget);
  });

  testWidgets('unlock states: worn, locked with hint, progress, unequip', (
    tester,
  ) async {
    final tasks = [for (var i = 0; i < 25; i++) _done('t$i', _now)];
    await _pump(tester, tasks);
    await tester.ensureVisible(find.text('Party hat'));
    await tester.pumpAndSettle();
    expect(find.text('Wearing'), findsOneWidget); // scarf
    expect(find.text('Tap to wear'), findsNWidgets(1)); // party hat
    expect(find.text('Finish a goal'), findsOneWidget); // crown locked
    expect(find.text('10 more sessions'), findsOneWidget); // no sessions: lock
    // Party hat is unlocked by 25 tasks and can be worn.
    await tester.tap(find.text('Party hat'));
    await tester.pumpAndSettle();
    expect(find.text('wearing: Party hat'), findsOneWidget);
    // Tapping the worn one takes it off.
    await tester.tap(find.text('Party hat'));
    await tester.pumpAndSettle();
    expect(find.text('no accessory'), findsOneWidget);
    // A locked one does nothing.
    await tester.tap(find.text('Crown'));
    await tester.pumpAndSettle();
    expect(find.text('no accessory'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNWidgets(1)); // boots
  });

  testWidgets('RTL at 390x844 has no overflow', (tester) async {
    await _pump(
      tester,
      [_done('a', _now)],
      dir: TextDirection.rtl,
      locale: const Locale('he'),
    );
    expect(find.text('קבוצת העידוד הפרטית שלך'), findsOneWidget);
    expect(find.text('Your cheering squad of one'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
