import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/app/test_app.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/time_zones.dart';
import 'package:grind/features/tasks/day_bounds.dart';
import 'package:grind/features/today/today_providers.dart';

import '../../test_fonts.dart';
import '../tasks/zone_test_support.dart';

final _c = DateTime.utc(2026, 11, 1);

Task _t(String id, {int minutes = 30}) => Task(
  id: id,
  title: id,
  estimatedMinutes: minutes,
  createdAt: _c,
  updatedAt: _c,
);

void main() {
  setUpAll(() async {
    ensureTimeZones();
    await loadAppFonts();
  });

  group('planMyDayInvitation', () {
    final loc = locationFor('UTC');
    // Monday 9 Nov 2026; default working hours 09:00–18:00.
    final day = dayBoundsOf(DateTime(2026, 11, 9), loc);
    const prefs = Preferences(timeZoneName: 'UTC');
    bool show(
      DateTime nowUtc, {
      List<Task>? tasks,
      Preferences p = prefs,
      DayBounds? on,
    }) => planMyDayInvitation(
      tasks: tasks ?? [_t('a')],
      prefs: p,
      nowUtc: nowUtc,
      day: on ?? day,
    );

    test('mornings with open work and an empty schedule', () {
      expect(show(DateTime.utc(2026, 11, 9, 8)), isTrue);
      expect(show(DateTime.utc(2026, 11, 9, 11, 59)), isTrue);
    });

    test('not before 05:00, not from noon', () {
      expect(show(DateTime.utc(2026, 11, 9, 4, 30)), isFalse);
      expect(show(DateTime.utc(2026, 11, 9, 12)), isFalse);
    });

    test('a late morning prompt keeps it up three hours after', () {
      final late = prefs.copyWith(morningPromptMinutes: 11 * 60);
      expect(show(DateTime.utc(2026, 11, 9, 13, 30), p: late), isTrue);
      expect(show(DateTime.utc(2026, 11, 9, 14), p: late), isFalse);
    });

    test('hidden once anything is scheduled today', () {
      final placed = _t('b').copyWith(
        scheduledStart: DateTime.utc(2026, 11, 9, 15),
        scheduledEnd: DateTime.utc(2026, 11, 9, 16),
      );
      expect(
        show(DateTime.utc(2026, 11, 9, 8), tasks: [_t('a'), placed]),
        isFalse,
      );
      // Something done earlier today counts too.
      final done = placed.copyWith(status: TaskStatus.done);
      expect(
        show(DateTime.utc(2026, 11, 9, 8), tasks: [_t('a'), done]),
        isFalse,
      );
    });

    test('hidden without open work or working hours', () {
      expect(show(DateTime.utc(2026, 11, 9, 8), tasks: const []), isFalse);
      final done = _t('a').copyWith(status: TaskStatus.done);
      expect(show(DateTime.utc(2026, 11, 9, 8), tasks: [done]), isFalse);
      // Saturday: no working hours.
      final sat = dayBoundsOf(DateTime(2026, 11, 14), loc);
      expect(show(DateTime.utc(2026, 11, 14, 8), on: sat), isFalse);
    });
  });

  group('Today card', () {
    // Monday 08:30 on the device clock.
    final clock = FixedClock(DateTime(2026, 11, 9, 8, 30));

    Future<ProviderContainer> pump(
      WidgetTester tester, {
      String locale = 'en',
    }) => pumpGrindApp(
      tester,
      clock: clock,
      overrides: [
        taskRepositoryProvider.overrideWithValue(
          InMemoryTaskRepository([
            _t('Write intro', minutes: 45),
            _t('Email Dana', minutes: 15),
          ]),
        ),
        calendarRepositoryProvider.overrideWithValue(
          InMemoryCalendarRepository(),
        ),
        devicePrefsOverride(
          Preferences(onboardingDone: true, localeCode: locale),
        ),
      ],
    );

    testWidgets('opens the draft; accepting schedules the day and the '
        'card steps aside', (tester) async {
      final c = await pump(tester);
      expect(find.text('Plan my day with Pip'), findsOneWidget);
      expect(
        find.text(
          'Pip can sketch today around your calendar. Ready when you are.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('today-plan-my-day-go')));
      await tester.pumpAndSettle();
      expect(find.text('Your day, drafted'), findsOneWidget);
      expect(find.byKey(const Key('draft-item-Write intro')), findsOneWidget);
      expect(find.byKey(const Key('draft-item-Email Dana')), findsOneWidget);

      await tester.tap(find.byKey(const Key('draft-accept')));
      await tester.pumpAndSettle();
      final tasks = await c.read(taskRepositoryProvider).getAll();
      for (final t in tasks) {
        expect(t.isScheduled, isTrue, reason: t.id);
        expect(t.lockedStart, isFalse);
        expect(t.scheduledStart!.toLocal().day, 9);
      }
      expect(find.text('Done. 2 things have a spot now.'), findsOneWidget);
      expect(find.byKey(const Key('today-plan-my-day')), findsNothing);
    });

    testWidgets('Not now keeps everything as it was', (tester) async {
      final c = await pump(tester);
      await tester.tap(find.byKey(const Key('today-plan-my-day-go')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      final tasks = await c.read(taskRepositoryProvider).getAll();
      expect(tasks.any((t) => t.isScheduled), isFalse);
      expect(find.byKey(const Key('today-plan-my-day')), findsOneWidget);
    });

    testWidgets('the close button hides it for today', (tester) async {
      await pump(tester);
      await tester.tap(find.bySemanticsLabel('Hide for today'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('today-plan-my-day')), findsNothing);
    });

    testWidgets('Hebrew: copy and no overflow', (tester) async {
      await pump(tester, locale: 'he');
      expect(find.text('לתכנן את היום עם פיפ'), findsOneWidget);
      expect(find.text('טיוטה ליום שלי'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a day that already has a plan shows no card', (tester) async {
      await pumpGrindApp(tester, overrides: [devicePrefsOverride()]);
      expect(find.byKey(const Key('today-plan-my-day')), findsNothing);
    });
  });
}
