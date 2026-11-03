// End-to-end MVP flows through the whole app (router, tabs, sheets) on the
// in-memory fakes with a FixedClock. Each test is one user journey.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/app/demo_seed.dart';
import 'package:grind/app/tab_bar.dart';
import 'package:grind/app/test_app.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/time_zones.dart';
import 'package:grind/features/plan/plan_l10n.dart';
import 'package:grind/l10n/l10n.dart';

import '../features/tasks/zone_test_support.dart';
import '../test_fonts.dart';

final _day = DateTime(2026, 10, 29);

Task _unscheduled(String id, String title, {int minutes = 45}) => Task(
  id: id,
  title: title,
  estimatedMinutes: minutes,
  dueAt: DateTime(2026, 10, 30, 23, 59).toUtc(),
  createdAt: DateTime.utc(2026, 10, 1),
  updatedAt: DateTime.utc(2026, 10, 1),
);

Future<void> _tab(WidgetTester t, String label) async {
  await t.tap(
    find.descendant(
      of: find.byType(GrindShellTabBar),
      matching: find.text(label),
    ),
  );
  await t.pumpAndSettle();
}

/// Lets a toast run out so it does not cover the next tap.
Future<void> _clearToasts(WidgetTester t) async {
  await t.pump(const Duration(seconds: 5));
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    ensureTimeZones();
    await loadAppFonts();
  });

  testWidgets(
    'capture on Today, schedule it for me, see it on Plan, done updates momentum',
    (t) async {
      final c = await pumpGrindApp(t, overrides: [devicePrefsOverride()]);
      final repo = c.read(taskRepositoryProvider);
      expect(find.text('1 of 4 today'), findsOneWidget);

      // Capture.
      await t.tap(find.bySemanticsLabel('Add a task'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).first, 'Write abstract');
      await t.tap(find.bySemanticsLabel('Save'));
      await t.pumpAndSettle();
      expect(find.text('Write abstract'), findsOneWidget);
      expect(find.text('1 of 5 today'), findsOneWidget);
      final id = (await repo.getAll())
          .firstWhere((x) => x.title == 'Write abstract')
          .id;

      // Schedule it for me, from the task detail.
      await t.tap(find.text('Write abstract'));
      await t.pumpAndSettle();
      expect(find.text('Not placed yet'), findsOneWidget);
      await t.tap(find.byKey(const Key('task-schedule-for-me')));
      await t.pumpAndSettle();
      final placed = (await repo.getById(id))!;
      expect(placed.isScheduled, isTrue);
      expect(placed.lockedStart, isFalse);
      final start = placed.scheduledStart!.toLocal();
      final slot = formatPlanSlot(
        lookupAppLocalizations(const Locale('en')),
        start,
        placed.scheduledEnd!.toLocal(),
      );
      // 09:00 is free (the lecture starts at 10:00), so that is the spot.
      expect(start, DateTime(2026, 10, 29, 9));
      expect(find.text(slot), findsOneWidget); // "On the plan" field
      expect(find.textContaining('$slot · '), findsOneWidget); // the toast
      await _clearToasts(t);

      await t.tap(find.bySemanticsLabel('Back'));
      await t.pumpAndSettle();

      // It is on Plan at that time.
      await _tab(t, 'Plan');
      final block = find.byKey(Key('plan-task-$id'));
      expect(block, findsOneWidget);
      expect(
        find.descendant(of: block, matching: find.text('Write abstract')),
        findsOneWidget,
      );

      // Done from the Today row moves momentum.
      await _tab(t, 'Today');
      await t.tap(find.bySemanticsLabel('Complete Write abstract'));
      await t.pumpAndSettle();
      expect(find.text('2 of 5 today'), findsOneWidget);
      expect((await repo.getById(id))!.isDone, isTrue);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('reminder card: open, snoozed, then done', (t) async {
    // 12:35: the lab reminder (12:30) has just fired.
    final c = await pumpGrindApp(
      t,
      clock: FixedClock(DateTime(2026, 10, 29, 12, 35)),
      overrides: [devicePrefsOverride()],
    );
    final repo = c.read(taskRepositoryProvider);
    expect(find.text('REMINDER · NOW'), findsOneWidget);
    expect(find.text('Snooze 15'), findsOneWidget);
    expect(find.text('1 of 4 today'), findsOneWidget);

    await t.tap(find.text('Snooze 15'));
    await t.pumpAndSettle();
    expect(find.textContaining('See you at'), findsOneWidget);
    expect((await repo.getById('lab'))!.snoozeCount, 1);
    await _clearToasts(t);

    // Back to open (undo), then Done.
    await t.tap(find.text('Undo').first);
    await t.pumpAndSettle();
    await _clearToasts(t);
    expect(find.text('Done'), findsOneWidget);
    await t.tap(find.text('Done'));
    await t.pumpAndSettle();
    expect(find.text('Nice start!'), findsOneWidget);
    expect(find.text('2 of 4 today'), findsOneWidget);
    expect((await repo.getById('lab'))!.isDone, isTrue);
  });

  testWidgets(
    'Re-plan with Pip lists placements with reasons; Apply schedules them; '
    'a dragged task stays put on the next re-plan',
    (t) async {
      final c = await pumpGrindApp(
        t,
        initialLocation: '/plan',
        overrides: [
          devicePrefsOverride(),
          taskRepositoryProvider.overrideWithValue(
            InMemoryTaskRepository([
              ...demoTasks(_day),
              _unscheduled('abstract', 'Write abstract'),
              _unscheduled('huge', 'Rewrite the whole thesis', minutes: 900),
            ]),
          ),
        ],
      );
      final repo = c.read(taskRepositoryProvider);
      expect(find.byKey(const Key('plan-capacity')), findsOneWidget);
      expect(find.textContaining('free · '), findsOneWidget);

      await t.tap(find.byKey(const Key('plan-replan')));
      await t.pumpAndSettle();
      expect(find.text("Pip's draft for the week"), findsOneWidget);
      final row = find.byKey(const Key('replan-placed-abstract'));
      expect(row, findsOneWidget);
      // Each placement shows its reasons.
      expect(
        find.descendant(of: row, matching: find.textContaining('Thu')),
        findsOneWidget,
      );
      final unplaced = find.byKey(const Key('replan-unplaced-huge'));
      expect(unplaced, findsOneWidget);
      expect(
        find.descendant(
          of: unplaced,
          matching: find.text('Rewrite the whole thesis'),
        ),
        findsOneWidget,
      );

      await t.tap(find.byKey(const Key('replan-apply')));
      await t.pumpAndSettle();
      expect(find.text("Pip's draft for the week"), findsNothing);
      final abstract = (await repo.getById('abstract'))!;
      expect(abstract.isScheduled, isTrue);
      expect(abstract.scheduledStart!.isUtc, isTrue);
      expect((await repo.getById('huge'))!.isScheduled, isFalse);
      expect(find.textContaining('have a spot now'), findsOneWidget);
      await _clearToasts(t);

      // The placed task is on today's timeline; drag it by 15 minutes.
      final local = abstract.scheduledStart!.toLocal();
      expect(DateTime(local.year, local.month, local.day), _day);
      final block = find.byKey(const Key('plan-task-abstract'));
      await t.ensureVisible(block);
      await t.pumpAndSettle();
      final g = await t.startGesture(t.getCenter(block));
      await t.pump(const Duration(milliseconds: 700));
      await g.moveBy(const Offset(0, 10));
      await t.pump();
      await g.up();
      await t.pumpAndSettle();
      final dragged = (await repo.getById('abstract'))!;
      expect(dragged.lockedStart, isTrue);
      expect(
        dragged.scheduledStart!.toLocal(),
        local.add(const Duration(minutes: 15)),
      );

      // Re-plan again: the dragged task is kept, not offered as a change.
      await t.tap(find.byKey(const Key('plan-replan')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('replan-placed-abstract')), findsNothing);
      expect(
        find.text('One thing you placed yourself stays put.'),
        findsOneWidget,
      );
      await t.tap(find.text('Not now'));
      await t.pumpAndSettle();
      expect(
        (await repo.getById('abstract'))!.scheduledStart,
        dragged.scheduledStart,
      );
    },
  );

  testWidgets(
    'a weekly task: on Today now and next week; completing this week keeps '
    'next week',
    (t) async {
      final clock = FixedClock(testNow);
      final c = await pumpGrindApp(
        t,
        clock: clock,
        overrides: [devicePrefsOverride()],
      );
      final repo = c.read(taskRepositoryProvider);
      final row = find.text('Team retro');

      Future<void> setDay(DateTime now) async {
        clock.set(now);
        await t.pump(const Duration(minutes: 1)); // Today re-reads the clock
        await t.pumpAndSettle();
      }

      // Create it with "Repeats: Weekly" from the quick-add sheet.
      await t.tap(find.bySemanticsLabel('Add a task'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).first, 'Team retro');
      final chip = find.byKey(const Key('task-form-recurrence'));
      await t.ensureVisible(chip);
      await t.pumpAndSettle();
      await t.tap(chip);
      await t.pumpAndSettle();
      await t.tap(find.text('Weekly'));
      await t.pumpAndSettle();
      await t.tap(find.text('Done').last);
      await t.pumpAndSettle();
      await t.tap(find.bySemanticsLabel('Save'));
      await t.pumpAndSettle();
      final id = (await repo.getAll())
          .firstWhere((x) => x.title == 'Team retro')
          .id;
      final rule = await c.read(reminderRepositoryProvider).getForTask(id);
      expect(rule!.rrule, startsWith('FREQ=WEEKLY'));

      // Today, at the series' 09:00.
      expect(row, findsOneWidget);
      expect(find.text('1 of 5 today'), findsOneWidget);
      final nextWeek = testNow.add(const Duration(days: 7));

      // Next week it is there too (and the demo day's tasks are not).
      await setDay(nextWeek);
      expect(row, findsOneWidget);
      expect(find.text('0 of 1 today'), findsOneWidget);
      await setDay(testNow);
      expect(row, findsOneWidget);

      // Complete today's occurrence: the series continues.
      await t.tap(find.bySemanticsLabel('Complete Team retro'));
      await t.pumpAndSettle();
      expect(
        find.text('Nicely done. The next one is lined up.'),
        findsOneWidget,
      );
      await _clearToasts(t);
      final after = (await repo.getById(id))!;
      expect(after.isDone, isFalse);
      // The same wall-clock time a week on.
      expect(
        after.remindAt!.difference(DateTime(2026, 10, 29, 9).toUtc()),
        const Duration(days: 7),
      );
      expect(row, findsNothing);

      await setDay(nextWeek);
      expect(row, findsOneWidget);
      expect(find.text('09:00'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('settings are reachable from the Today header', (t) async {
    await pumpGrindApp(t, overrides: [devicePrefsOverride()]);
    await t.tap(find.byKey(const Key('today-settings')));
    await t.pumpAndSettle();
    expect(find.text('Good morning!'), findsNothing);
    expect(find.text('Settings'), findsWidgets);
    await t.tap(find.byTooltip('Back'));
    await t.pumpAndSettle();
    expect(find.text('Good morning!'), findsOneWidget);
  });

  testWidgets(
    'onboarding gate: a new user finishes onboarding, lands on Today',
    (t) async {
      await pumpGrindApp(
        t,
        overrides: [
          preferencesRepositoryProvider.overrideWithValue(
            InMemoryPreferencesRepository(devicePrefs()),
          ),
        ],
      );
      expect(find.text('Good morning!'), findsNothing);
      // One Skip per optional step.
      final skip = find.text('Skip').hitTestable();
      for (var i = 0; i < 6 && skip.evaluate().isNotEmpty; i++) {
        await t.tap(skip);
        await t.pumpAndSettle();
      }
      await t.tap(find.text('Take me to Today'));
      await t.pumpAndSettle();
      expect(find.text('Good morning!'), findsOneWidget);
    },
  );
}
