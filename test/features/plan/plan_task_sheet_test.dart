import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/app/test_app.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/time_zones.dart';
import 'package:grind/features/calendar/sync/calendar_sync_engine.dart'
    show importedCalendarEventIdFor;
import 'package:grind/features/plan/plan_task_sheet.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../test_fonts.dart';
import '../tasks/zone_test_support.dart';

void main() {
  final t = DateTime.utc(2026, 11, 3, 22, 30);
  CalendarEvent event(CalendarSource source, {String? link}) => CalendarEvent(
    id: 'e',
    source: source,
    externalId: 'e',
    title: 'Sync',
    start: t,
    end: t.add(const Duration(hours: 1)),
    htmlLink: link,
    createdAt: t,
    updatedAt: t,
  );

  group('calendarDayUrl', () {
    late tz.Location jerusalem;
    setUpAll(() => jerusalem = locationFor('Asia/Jerusalem'));

    test('opens the event itself when the provider gave a link', () {
      final url = calendarDayUrl(
        event(
          CalendarSource.google,
          link: 'https://www.google.com/calendar/event?eid=abc',
        ),
        jerusalem,
      );
      expect(url.toString(), 'https://www.google.com/calendar/event?eid=abc');
    });

    test('falls back to the day view in the user zone', () {
      // 22:30 UTC is already 4 Nov (00:30) in Jerusalem.
      expect(
        calendarDayUrl(event(CalendarSource.google), jerusalem).toString(),
        'https://calendar.google.com/calendar/r/day/2026/11/4',
      );
    });

    test('ignores a non-https link', () {
      expect(
        calendarDayUrl(
          event(CalendarSource.google, link: 'javascript:alert(1)'),
          jerusalem,
        ).toString(),
        startsWith('https://calendar.google.com/calendar/r/day/'),
      );
      expect(
        calendarDayUrl(event(CalendarSource.apple, link: 'ftp://x'), jerusalem),
        isNull,
      );
    });

    test('Apple events without a link have no URL', () {
      expect(calendarDayUrl(event(CalendarSource.apple), jerusalem), isNull);
    });
  });

  group('Add as task', () {
    setUpAll(() async {
      ensureTimeZones();
      await loadAppFonts();
    });

    // 2026-10-29 10:00 → 11:30 local, the demo day (see testNow / demoSeed).
    final eventStart = DateTime(2026, 10, 29, 10).toUtc();
    final eventEnd = DateTime(2026, 10, 29, 11, 30).toUtc();
    final seminar = CalendarEvent(
      id: 'seminar',
      source: CalendarSource.google,
      externalId: 'seminar-ext',
      title: 'Seminar with supervisor',
      start: eventStart,
      end: eventEnd,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

    Future<ProviderContainer> pump(WidgetTester tester) => pumpGrindApp(
      tester,
      overrides: [
        devicePrefsOverride(),
        calendarRepositoryProvider.overrideWithValue(
          InMemoryCalendarRepository([seminar]),
        ),
        taskRepositoryProvider.overrideWithValue(InMemoryTaskRepository()),
      ],
    );

    BuildContext ctx(WidgetTester t) => t.element(find.byType(Scaffold).first);

    testWidgets(
      'the event sheet exposes Add as task and creates a linked task',
      (tester) async {
        final container = await pump(tester);
        showPlanEventSheet(ctx(tester), seminar);
        await tester.pumpAndSettle();

        final addAsTask = find.byKey(const Key('plan-add-as-task'));
        expect(addAsTask, findsOneWidget);
        expect(find.text('Add as task'), findsOneWidget);

        await tester.tap(addAsTask);
        await tester.pumpAndSettle();

        // The task sheet opens with the event's title prefilled.
        expect(find.text('New task'), findsOneWidget);
        final titleField = tester.widget<TextField>(
          find.byType(TextField).first,
        );
        expect(titleField.controller?.text, 'Seminar with supervisor');
        await tester.tap(find.bySemanticsLabel('Save'));
        await tester.pumpAndSettle();

        final tasks = await container.read(taskRepositoryProvider).getAll();
        final saved = tasks.singleWhere(
          (t) => t.title == 'Seminar with supervisor',
        );
        expect(saved.scheduledStart, eventStart);
        expect(saved.scheduledEnd, eventEnd);
        expect(saved.estimatedMinutes, 90);
        expect(
          saved.calendarEventId,
          importedCalendarEventIdFor('seminar-ext'),
        );
      },
    );

    testWidgets('tapping Add as task again reopens the existing task', (
      tester,
    ) async {
      final existing = Task(
        id: 'from-seminar',
        title: 'Seminar prep',
        scheduledStart: eventStart,
        scheduledEnd: eventEnd,
        calendarEventId: importedCalendarEventIdFor('seminar-ext'),
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      final container = await pumpGrindApp(
        tester,
        overrides: [
          devicePrefsOverride(),
          calendarRepositoryProvider.overrideWithValue(
            InMemoryCalendarRepository([seminar]),
          ),
          taskRepositoryProvider.overrideWithValue(
            InMemoryTaskRepository([existing]),
          ),
        ],
      );

      showPlanEventSheet(ctx(tester), seminar);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('plan-add-as-task')));
      await tester.pumpAndSettle();

      // The edit sheet shows the existing task's title, no duplicate is made.
      expect(find.text('Edit task'), findsOneWidget);
      final titleField = tester.widget<TextField>(find.byType(TextField).first);
      expect(titleField.controller?.text, 'Seminar prep');
      final all = await container.read(taskRepositoryProvider).getAll();
      expect(all.map((t) => t.id).toSet(), {'from-seminar'});
    });
  });
}
