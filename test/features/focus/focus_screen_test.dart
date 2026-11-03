import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/app/test_app.dart';
import 'package:grind/core/core.dart';
import 'package:grind/l10n/app_localizations.dart';
import 'package:grind/features/focus/providers.dart';

import '../../test_fonts.dart';

final en = lookupAppLocalizations(const Locale('en'));

void main() {
  setUpAll(loadAppFonts);

  String remaining(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('focus-remaining'))).data!;

  testWidgets('deep link shows the task; start, pause, resume, +5', (
    tester,
  ) async {
    final clock = FixedClock(testNow);
    await pumpGrindApp(
      tester,
      initialLocation: '/focus?taskId=lab',
      clock: clock,
    );
    expect(find.text('Deep learning lab 4'), findsWidgets);
    expect(find.text('FOCUS 1 OF 4'), findsOneWidget);
    expect(remaining(tester), '25:00');

    await tester.tap(find.bySemanticsLabel('Start focus'));
    await tester.pump();
    expect(find.bySemanticsLabel('Pause'), findsOneWidget);

    clock.advance(const Duration(minutes: 10));
    await tester.pump(const Duration(seconds: 1));
    expect(remaining(tester), '15:00');

    await tester.tap(find.bySemanticsLabel('Pause'));
    await tester.pump();
    expect(find.text('PAUSED'), findsWidgets);
    clock.advance(const Duration(minutes: 3));
    await tester.pump(const Duration(seconds: 1));
    expect(remaining(tester), '15:00');

    await tester.tap(find.bySemanticsLabel('Resume'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('+5 min'));
    await tester.pump();
    expect(remaining(tester), '20:00');
  });

  testWidgets('End opens the sheet; Mark task done completes the task', (
    tester,
  ) async {
    final clock = FixedClock(testNow);
    final container = await pumpGrindApp(
      tester,
      initialLocation: '/focus?taskId=lab',
      clock: clock,
    );
    await tester.tap(find.bySemanticsLabel('Start focus'));
    await tester.pump();
    clock.advance(const Duration(minutes: 12));
    await tester.tap(find.bySemanticsLabel('End'));
    await tester.pumpAndSettle();

    expect(find.text(en.focusEarlyTitle), findsOneWidget);
    expect(
      find.text(en.focusFocusedForTask(12, 'Deep learning lab 4')),
      findsOneWidget,
    );
    await tester.tap(find.bySemanticsLabel(en.focusMarkDone));
    await tester.pumpAndSettle();

    final task = (await container.read(taskRepositoryProvider).getById('lab'))!;
    expect(task.isDone, isTrue);
    expect(task.actualMinutes, 12);
    expect(find.text(en.focusTaskDone), findsOneWidget);
    expect(find.bySemanticsLabel('Start focus'), findsOneWidget);
  });

  testWidgets('time up shows the sheet, then the break with one dot', (
    tester,
  ) async {
    final clock = FixedClock(testNow);
    await pumpGrindApp(tester, initialLocation: '/focus', clock: clock);
    expect(find.text(en.focusFree), findsWidgets);
    await tester.tap(find.bySemanticsLabel('Start focus'));
    await tester.pump();

    clock.advance(const Duration(minutes: 26));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text(en.focusDoneTitle), findsOneWidget);
    expect(find.bySemanticsLabel(en.focusMarkDone), findsNothing);

    await tester.tap(find.bySemanticsLabel(en.focusKeepGoing));
    await tester.pumpAndSettle();
    expect(find.text(en.focusBreak.toUpperCase()), findsOneWidget);
    expect(find.bySemanticsLabel('1 of 4 sessions done'), findsOneWidget);
    expect(remaining(tester), '04:00');

    clock.advance(const Duration(minutes: 4));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text(en.focusBreakOverToast), findsOneWidget);
    expect(find.text('FOCUS 2 OF 4'), findsOneWidget);
  });

  testWidgets('Log a win shows a toast', (tester) async {
    final clock = FixedClock(testNow);
    await pumpGrindApp(tester, initialLocation: '/focus', clock: clock);
    await tester.tap(find.bySemanticsLabel('Start focus'));
    await tester.pump();
    clock.advance(const Duration(minutes: 5));
    await tester.tap(find.bySemanticsLabel('End'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(en.focusLogWin));
    await tester.pumpAndSettle();
    expect(find.text(en.focusWinLogged), findsOneWidget);
  });

  testWidgets('a running session is picked up when the screen opens', (
    tester,
  ) async {
    final clock = FixedClock(testNow);
    final start = clock.now().toUtc().subtract(const Duration(minutes: 5));
    await pumpGrindApp(
      tester,
      initialLocation: '/focus',
      clock: clock,
      overrides: [
        focusSessionRepositoryProvider.overrideWithValue(
          InMemoryFocusSessionRepository([
            FocusSession(
              id: 'running',
              taskId: 'papers',
              plannedMinutes: 25,
              startedAt: start,
              createdAt: start,
              updatedAt: start,
            ),
          ]),
        ),
      ],
    );
    expect(find.text('Read 2 papers'), findsWidgets);
    expect(remaining(tester), '20:00');
    expect(find.bySemanticsLabel('Pause'), findsOneWidget);
  });

  testWidgets('RTL at 390x844 has no overflow while focusing', (tester) async {
    final clock = FixedClock(testNow);
    final container = await pumpGrindApp(
      tester,
      initialLocation: '/focus?taskId=lab',
      clock: clock,
      overrides: [
        preferencesRepositoryProvider.overrideWithValue(
          InMemoryPreferencesRepository(
            const Preferences(onboardingDone: true, localeCode: 'he'),
          ),
        ),
      ],
    );
    expect(
      Directionality.of(tester.element(find.byType(Scaffold).first)),
      TextDirection.rtl,
    );
    final ctrl = container.read(focusControllerProvider.notifier);
    await ctrl.start(taskId: 'lab');
    await tester.pump();
    clock.advance(const Duration(minutes: 25));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // Hebrew copy is on screen: the end-of-session sheet title.
    expect(find.text('הסבב הסתיים. עבודה יפה.'), findsOneWidget);
  });
}
