import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:grind/core/core.dart';
import 'package:grind/features/calendar/google/google_event_mapper.dart';
import 'package:grind/l10n/l10n.dart';

void main() {
  final he = lookupAppLocalizations(const Locale('he'));
  final en = lookupAppLocalizations(const Locale('en'));
  final now = DateTime.utc(2026, 11, 3, 8);

  gcal.Event untitled() => gcal.Event(
    id: 'e1',
    summary: '  ',
    start: gcal.EventDateTime(dateTime: DateTime.utc(2026, 11, 3, 9)),
    end: gcal.EventDateTime(dateTime: DateTime.utc(2026, 11, 3, 10)),
  );

  test('an untitled event gets the localized placeholder title', () {
    expect(
      GoogleEventMapper.toDomain(
        untitled(),
        calendarId: 'c',
        now: now,
        l10n: he,
      )!.title,
      he.calendarUntitledEvent,
    );
    expect(
      GoogleEventMapper.toDomain(untitled(), calendarId: 'c', now: now)!.title,
      en.calendarUntitledEvent,
    );
  });

  test('the written-back event footer follows the language', () {
    final task = Task(
      id: 't',
      title: 'Write',
      scheduledStart: DateTime.utc(2026, 11, 3, 9),
      scheduledEnd: DateTime.utc(2026, 11, 3, 10),
      createdAt: now,
      updatedAt: now,
    );
    expect(
      GoogleEventMapper.fromTask(task, l10n: he).description,
      he.calendarWrittenByGrind,
    );
    expect(
      GoogleEventMapper.fromTask(task).description,
      en.calendarWrittenByGrind,
    );
  });
}
