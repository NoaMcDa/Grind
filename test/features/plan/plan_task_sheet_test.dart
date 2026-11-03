import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/time_zones.dart';
import 'package:grind/features/plan/plan_task_sheet.dart';
import 'package:timezone/timezone.dart' as tz;

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
}
