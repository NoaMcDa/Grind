import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/app/test_app.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/time_zones.dart';

import '../../test_fonts.dart';
import '../tasks/zone_test_support.dart';

final _c = DateTime.utc(2026, 10, 1);

/// Every Tuesday at 07:00 in Jerusalem, anchored a week before the test day
/// (Tue Nov 3 2026, 12:00 UTC = 14:00 there).
Task _weekly() => Task(
  id: 'w',
  title: 'Weekly review',
  remindAt: DateTime.utc(2026, 10, 27, 5),
  createdAt: _c,
  updatedAt: _c,
);

Future<ProviderContainer> _pumpWeekly(WidgetTester tester) => pumpGrindApp(
  tester,
  clock: FixedClock(DateTime.utc(2026, 11, 3, 12)),
  overrides: [
    taskRepositoryProvider.overrideWithValue(
      InMemoryTaskRepository([_weekly()]),
    ),
    reminderRepositoryProvider.overrideWithValue(
      InMemoryReminderRepository([
        ReminderRule(
          id: 'rule-w',
          taskId: 'w',
          rrule: 'FREQ=WEEKLY;BYDAY=TU',
          createdAt: _c,
          updatedAt: _c,
        ),
      ]),
    ),
    preferencesRepositoryProvider.overrideWithValue(
      InMemoryPreferencesRepository(
        const Preferences(onboardingDone: true, timeZoneName: 'Asia/Jerusalem'),
      ),
    ),
  ],
);

void main() {
  setUpAll(() async {
    ensureTimeZones();
    await loadAppFonts();
  });

  testWidgets('a weekly task shows on its day at the occurrence time; the '
      'checkbox completes this occurrence only', (tester) async {
    final c = await _pumpWeekly(tester);
    final repo = c.read(taskRepositoryProvider);
    expect(find.text('Weekly review'), findsOneWidget);
    expect(find.text('07:00'), findsOneWidget); // 07:00 Jerusalem, not UTC
    expect(find.text('0 of 1 today'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Complete Weekly review'));
    await tester.pumpAndSettle();
    final after = (await repo.getById('w'))!;
    expect(after.isDone, isFalse);
    expect(after.remindAt, DateTime.utc(2026, 11, 10, 5));
    final rule = await c.read(reminderRepositoryProvider).getForTask('w');
    expect(rule!.lastCompletedAt, DateTime.utc(2026, 11, 3, 5));
    expect(find.text('Nicely done. The next one is lined up.'), findsOneWidget);
    // The occurrence stays on Today as a done row and counts.
    expect(find.text('Weekly review'), findsOneWidget);
    expect(find.text('1 of 1 today'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect((await repo.getById('w'))!.remindAt, DateTime.utc(2026, 10, 27, 5));
    final restored = await c.read(reminderRepositoryProvider).getForTask('w');
    expect(restored!.lastCompletedAt, isNull);
    expect(find.text('Weekly review'), findsOneWidget);
    expect(find.text('0 of 1 today'), findsOneWidget);
  });

  testWidgets('swipe right on a weekly task completes this occurrence only', (
    tester,
  ) async {
    final c = await _pumpWeekly(tester);
    await tester.drag(find.text('Weekly review'), const Offset(300, 0));
    await tester.pumpAndSettle();
    final after = (await c.read(taskRepositoryProvider).getById('w'))!;
    expect(after.isDone, isFalse);
    expect(after.remindAt, DateTime.utc(2026, 11, 10, 5));
  });

  testWidgets(
    'deleting a weekly task takes its rule along; undo restores both',
    (tester) async {
      final c = await _pumpWeekly(tester);
      final rules = c.read(reminderRepositoryProvider);
      await tester.drag(find.text('Weekly review'), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(await rules.getForTask('w'), isNull);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(await rules.getForTask('w'), isNotNull);
      expect(find.text('Weekly review'), findsOneWidget);
    },
  );

  testWidgets('Up next shows today, done items sink, momentum is real', (
    tester,
  ) async {
    await pumpGrindApp(tester, overrides: [devicePrefsOverride()]);
    expect(find.text('UP NEXT'), findsOneWidget);
    expect(find.text('1 of 4 today'), findsOneWidget);
    // Open tasks first by reminder time, the done one last.
    final lab = tester.getTopLeft(find.text('Deep learning lab 4')).dy;
    final gym = tester.getTopLeft(find.text('Gym')).dy;
    final mom = tester.getTopLeft(find.text('Call mom')).dy;
    expect(lab < gym, isTrue);
    expect(gym < mom, isTrue);
  });

  testWidgets('empty state renders when nothing is due', (tester) async {
    final container = await pumpGrindApp(
      tester,
      overrides: [devicePrefsOverride()],
    );
    final repo = container.read(taskRepositoryProvider);
    for (final t in await repo.getAll()) {
      await repo.delete(t.id);
    }
    await tester.pumpAndSettle();
    expect(find.text('Nothing due today'), findsOneWidget);
    expect(find.text('0 of 0 today'), findsOneWidget);
  });

  testWidgets('swipe right completes, swipe left deletes and undo restores', (
    tester,
  ) async {
    final container = await pumpGrindApp(
      tester,
      overrides: [devicePrefsOverride()],
    );
    final repo = container.read(taskRepositoryProvider);

    await tester.drag(find.text('Gym'), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect((await repo.getById('gym'))!.status, TaskStatus.done);
    expect(find.text('2 of 4 today'), findsOneWidget);

    await tester.drag(find.text('Deep learning lab 4'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(await repo.getById('lab'), isNull);
    expect(find.text('Deep learning lab 4'), findsNothing);
    expect(find.text('Task deleted'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(await repo.getById('lab'), isNotNull);
    expect(find.text('Deep learning lab 4'), findsOneWidget);
  });

  testWidgets('checkbox toggles done and undo reopens', (tester) async {
    final container = await pumpGrindApp(
      tester,
      overrides: [devicePrefsOverride()],
    );
    final repo = container.read(taskRepositoryProvider);
    await tester.tap(find.bySemanticsLabel('Complete Gym'));
    await tester.pumpAndSettle();
    expect((await repo.getById('gym'))!.isDone, isTrue);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect((await repo.getById('gym'))!.isDone, isFalse);
  });

  testWidgets('RTL at 390x844 has no overflow', (tester) async {
    await pumpGrindApp(
      tester,
      overrides: [
        preferencesRepositoryProvider.overrideWithValue(
          InMemoryPreferencesRepository(
            const Preferences(onboardingDone: true, localeCode: 'he'),
          ),
        ),
      ],
    );
    expect(tester.takeException(), isNull);
    expect(
      Directionality.of(tester.element(find.byType(Scaffold).first)),
      TextDirection.rtl,
    );
    expect(find.text('מומנטום'), findsOneWidget);
    expect(find.text('הבא בתור'), findsOneWidget);
    expect(find.text('Up next'), findsNothing);
    expect(find.textContaining('מתוך'), findsWidgets);
  });
}
