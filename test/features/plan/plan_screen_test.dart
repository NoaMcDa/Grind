import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/app/demo_seed.dart';
import 'package:grind/app/test_app.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/calendar/sync/calendar_sync_engine.dart';
import 'package:grind/features/plan/plan_screen.dart';

import '../../test_fonts.dart';
import '../tasks/zone_test_support.dart';

final _day = DateTime(2026, 10, 29);

CalendarEvent _event(
  String id,
  String title,
  DateTime s,
  DateTime e, {
  bool allDay = false,
}) => CalendarEvent(
  id: id,
  source: CalendarSource.google,
  externalId: id,
  title: title,
  start: s.toUtc(),
  end: e.toUtc(),
  isAllDay: allDay,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  List<CalendarEvent> extraEvents = const [],
  List<Task> extraTasks = const [],
}) {
  return pumpGrindApp(
    tester,
    initialLocation: '/plan',
    overrides: [
      devicePrefsOverride(),
      calendarRepositoryProvider.overrideWithValue(
        InMemoryCalendarRepository([...demoEvents(_day), ...extraEvents]),
      ),
      taskRepositoryProvider.overrideWithValue(
        InMemoryTaskRepository([...demoTasks(_day), ...extraTasks]),
      ),
    ],
  );
}

Task _tomorrowTask() {
  final c = DateTime.utc(2026);
  return Task(
    id: 'tomorrow',
    title: 'Tomorrow thing',
    scheduledStart: DateTime(2026, 10, 30, 10).toUtc(),
    scheduledEnd: DateTime(2026, 10, 30, 11).toUtc(),
    createdAt: c,
    updatedAt: c,
  );
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('today shows exactly the seeded events and tasks', (t) async {
    await _pump(t);
    for (final title in [
      'Lecture: Computer Vision',
      'Seminar with supervisor',
      'Thesis: write related-work section',
      'Lunch break',
      'Deep learning lab 4',
      'Read 2 papers',
      'Gym',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    expect(find.text('Call mom'), findsNothing); // not scheduled
    expect(find.byType(PlanScreen), findsOneWidget);
    expect(find.text('2 of 5 done'), findsOneWidget);
    expect(find.byKey(const Key('plan-now-line')), findsOneWidget);
    expect(find.text('Re-plan with Pip'), findsOneWidget);
    expect(find.text('Add task'), findsOneWidget);
  });

  testWidgets('tomorrow is empty and shows the empty state', (t) async {
    await _pump(t);
    await t.tap(find.byKey(const Key('plan-next-day')));
    await t.pumpAndSettle();
    expect(find.text('Lecture: Computer Vision'), findsNothing);
    expect(find.text('Gym'), findsNothing);
    expect(find.text('Nothing planned yet'), findsOneWidget);
    expect(find.text('Fri, Oct 30'), findsOneWidget);
  });

  testWidgets('week strip selects a day; now line is today only', (t) async {
    await _pump(t, extraTasks: [_tomorrowTask()]);
    await t.tap(find.byKey(const Key('plan-day-2026-10-30')));
    await t.pumpAndSettle();
    expect(find.text('Tomorrow thing'), findsOneWidget);
    expect(find.text('Gym'), findsNothing);
    expect(find.byKey(const Key('plan-now-line')), findsNothing);
    await t.tap(find.byKey(const Key('plan-day-2026-10-29')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('plan-now-line')), findsOneWidget);
  });

  testWidgets('swiping the timeline changes the day', (t) async {
    await _pump(t, extraTasks: [_tomorrowTask()]);
    await t.fling(
      find.text('Lecture: Computer Vision'),
      const Offset(-300, 0),
      1000,
    );
    await t.pumpAndSettle();
    expect(find.text('Tomorrow thing'), findsOneWidget);
  });

  testWidgets('dragging a task snaps to 15 minutes and locks it', (t) async {
    final c = await _pump(t);
    final repo = c.read(taskRepositoryProvider);
    final before = (await repo.getById('lab'))!;
    final g = await t.startGesture(
      t.getCenter(find.byKey(const Key('plan-task-lab'))),
    );
    await t.pump(const Duration(milliseconds: 700));
    await g.moveBy(const Offset(0, 10));
    await t.pump();
    expect(find.byKey(const Key('plan-drag-ghost')), findsOneWidget);
    await g.up();
    await t.pumpAndSettle();
    final after = (await repo.getById('lab'))!;
    // 12:30 + 12.5 min -> 12:45
    expect(after.scheduledStart!.toLocal(), DateTime(2026, 10, 29, 12, 45));
    expect(
      after.scheduledEnd!.difference(after.scheduledStart!),
      before.scheduledEnd!.difference(before.scheduledStart!),
    );
    expect(after.lockedStart, isTrue);
    expect(find.byKey(const Key('plan-drag-ghost')), findsNothing);
  });

  testWidgets('a task cannot be dropped onto a busy event', (t) async {
    final c = await _pump(t);
    final repo = c.read(taskRepositoryProvider);
    final g = await t.startGesture(
      t.getCenter(find.byKey(const Key('plan-task-lab'))),
    );
    await t.pump(const Duration(milliseconds: 700));
    await g.moveBy(const Offset(0, 72)); // +1.5h -> 14:00, the seminar
    await t.pump();
    await g.up();
    await t.pumpAndSettle();
    final after = (await repo.getById('lab'))!;
    expect(after.scheduledStart!.toLocal(), DateTime(2026, 10, 29, 12, 30));
    expect(after.lockedStart, isFalse);
  });

  testWidgets('all-day events render above the timeline', (t) async {
    await _pump(
      t,
      extraEvents: [
        _event(
          'hol',
          'Public holiday',
          DateTime(2026, 10, 29),
          DateTime(2026, 10, 30),
          allDay: true,
        ),
      ],
    );
    expect(find.text('Public holiday'), findsOneWidget);
    expect(find.text('All day'), findsOneWidget);
  });

  testWidgets('overlapping events sit side by side', (t) async {
    await _pump(
      t,
      extraEvents: [
        _event(
          'ov',
          'Overlap meeting',
          DateTime(2026, 10, 29, 10, 30),
          DateTime(2026, 10, 29, 12),
        ),
      ],
    );
    final a = t.getRect(find.byKey(const Key('plan-event-lecture-cv')));
    final b = t.getRect(find.byKey(const Key('plan-event-ov')));
    expect(a.right, lessThanOrEqualTo(b.left + 0.5));
    expect(a.width, closeTo(b.width, 0.5));
    expect(a.width, lessThan(200));
  });

  testWidgets('event in another zone shows at its local time', (t) async {
    final tokyo = DateTime(
      2026,
      10,
      29,
      19,
    ).toUtc().add(const Duration(hours: 9));
    final iso = tokyo.toIso8601String().replaceAll('Z', '');
    final s = DateTime.parse('$iso+09:00');
    await _pump(
      t,
      extraEvents: [
        _event('tk', 'Tokyo call', s, s.add(const Duration(hours: 2))),
      ],
    );
    expect(find.text('Tokyo call'), findsOneWidget);
    expect(find.text('19:00–21:00'), findsOneWidget);
  });

  testWidgets('a task written back to the calendar shows once', (t) async {
    final c = DateTime.utc(2026);
    final task = Task(
      id: 'pushed',
      title: 'Pushed to Google',
      scheduledStart: DateTime(2026, 10, 29, 8).toUtc(),
      scheduledEnd: DateTime(2026, 10, 29, 9).toUtc(),
      calendarEventId: 'ext-pushed',
      createdAt: c,
      updatedAt: c,
    );
    final mirror = CalendarEvent(
      id: 'google:ext-pushed',
      source: CalendarSource.google,
      externalId: 'ext-pushed',
      title: 'Pushed to Google',
      start: task.scheduledStart!,
      end: task.scheduledEnd!,
      taskId: 'pushed',
      createdAt: c,
      updatedAt: c,
    );
    await _pump(t, extraTasks: [task], extraEvents: [mirror]);
    expect(find.text('Pushed to Google'), findsOneWidget);
    expect(find.byKey(const Key('plan-task-pushed')), findsOneWidget);
    expect(find.byKey(const Key('plan-event-google:ext-pushed')), findsNothing);
  });

  testWidgets('an event added as a task shows only as the task', (t) async {
    final c = DateTime.utc(2026);
    final event = _event(
      'lesson',
      'Krav lesson',
      DateTime(2026, 10, 29, 8),
      DateTime(2026, 10, 29, 9),
    );
    final task = Task(
      id: 'lesson-task',
      title: 'Krav lesson',
      scheduledStart: event.start,
      scheduledEnd: event.end,
      calendarEventId: importedCalendarEventIdFor('lesson'),
      createdAt: c,
      updatedAt: c,
    );
    await _pump(t, extraTasks: [task], extraEvents: [event]);
    expect(find.text('Krav lesson'), findsOneWidget);
    expect(find.byKey(const Key('plan-task-lesson-task')), findsOneWidget);
    expect(find.byKey(const Key('plan-event-lesson')), findsNothing);
  });

  testWidgets(
    'an event linked to an imported task is hidden (no duplicate card)',
    (t) async {
      // Reuses the seeded Google "seminar" event; a task carrying the
      // imported sentinel for its externalId should replace the dashed card.
      final linkedTask = Task(
        id: 'from-seminar',
        title: 'Imported seminar task',
        scheduledStart: DateTime(2026, 10, 29, 14).toUtc(),
        scheduledEnd: DateTime(2026, 10, 29, 15, 30).toUtc(),
        calendarEventId: importedCalendarEventIdFor('seminar'),
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      await _pump(t, extraTasks: [linkedTask]);
      // The task card appears; the original dashed event card is gone.
      expect(find.text('Imported seminar task'), findsOneWidget);
      expect(find.text('Seminar with supervisor'), findsNothing);
      expect(find.byKey(const Key('plan-event-seminar')), findsNothing);
    },
  );

  testWidgets('tapping an event opens the read-only sheet', (t) async {
    await _pump(t);
    await t.tap(find.byKey(const Key('plan-event-seminar')));
    await t.pumpAndSettle();
    expect(find.text('Open in calendar'), findsOneWidget);
    expect(find.text('14:00–15:30'), findsWidgets);
  });

  testWidgets('tapping a task opens the detail and can unschedule', (t) async {
    final c = await _pump(t);
    await t.tap(find.byKey(const Key('plan-task-lab')));
    await t.pumpAndSettle();
    expect(find.text('Mark done'), findsOneWidget);
    await t.tap(find.text('Unschedule'));
    await t.pumpAndSettle();
    final lab = (await c.read(taskRepositoryProvider).getById('lab'))!;
    expect(lab.isScheduled, isFalse);
    expect(find.text('Deep learning lab 4'), findsNothing);
  });

  testWidgets('Hebrew RTL at 390x844: copy, no overflow, replan sheet', (
    t,
  ) async {
    await pumpGrindApp(
      t,
      initialLocation: '/plan',
      overrides: [
        preferencesRepositoryProvider.overrideWithValue(
          InMemoryPreferencesRepository(
            devicePrefs(
              const Preferences(onboardingDone: true, localeCode: 'he'),
            ),
          ),
        ),
        calendarRepositoryProvider.overrideWithValue(
          InMemoryCalendarRepository(demoEvents(_day)),
        ),
        taskRepositoryProvider.overrideWithValue(
          InMemoryTaskRepository(demoTasks(_day)),
        ),
      ],
    );
    expect(
      Directionality.of(t.element(find.byType(PlanScreen))),
      TextDirection.rtl,
    );
    expect(t.takeException(), isNull);
    expect(find.text('היום שלך, בטיוטה'), findsOneWidget);
    expect(find.text('תכנון מחדש עם פיפ'), findsOneWidget);
    expect(find.text('2 מתוך 5 הושלמו'), findsOneWidget);
    expect(find.text('Re-plan with Pip'), findsNothing);
    await t.tap(find.byKey(const Key('plan-replan')));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(find.text('הטיוטה של פיפ לשבוע'), findsOneWidget);
    await t.tap(find.text('לא עכשיו'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('plan-next-day')));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(find.text('עוד לא תוכנן כלום'), findsOneWidget);
  });
}
