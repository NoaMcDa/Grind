import 'package:googleapis/calendar/v3.dart' as gcal;

import '../../../core/core.dart';
import '../sync/calendar_sync_strings.dart';

/// Google Calendar `Event` <-> Grind domain.
///
/// Times: timed events keep their instant and become UTC. All-day events
/// (Google sends a date with no zone) start at local midnight of that date on
/// this device, stored as UTC, and end at local midnight of the (exclusive)
/// end date, so they cover exactly the day(s) shown in Google.
abstract final class GoogleEventMapper {
  /// Private extended property carrying the Grind task id of a write-back.
  static const taskIdKey = 'grindTaskId';

  /// Domain id for a Google event (stable across syncs).
  static String domainId(String eventId) => 'google:$eventId';

  /// Null for cancelled events and events without usable times.
  static CalendarEvent? toDomain(
    gcal.Event e, {
    required String calendarId,
    required DateTime now,
  }) {
    final id = e.id;
    if (id == null || e.status == 'cancelled') return null;
    final start = e.start;
    final end = e.end;
    if (start == null) return null;

    final DateTime from;
    final DateTime to;
    final allDay = start.date != null && start.dateTime == null;
    if (allDay) {
      from = _localMidnight(start.date!);
      to = end?.date != null
          ? _localMidnight(end!.date!)
          : _localMidnight(start.date!.add(const Duration(days: 1)));
    } else {
      final s = start.dateTime;
      if (s == null) return null;
      from = s.toUtc();
      to = (end?.dateTime ?? s.add(const Duration(minutes: 30))).toUtc();
    }

    final selfDeclined = (e.attendees ?? const <gcal.EventAttendee>[]).any(
      (a) => a.self == true && a.responseStatus == 'declined',
    );
    final title = (e.summary ?? '').trim();
    return CalendarEvent(
      id: domainId(id),
      source: CalendarSource.google,
      externalId: id,
      calendarId: calendarId,
      title: title.isEmpty ? CalendarSyncStrings.untitledEvent : title,
      start: from,
      end: to.isAfter(from) ? to : from.add(const Duration(minutes: 1)),
      isAllDay: allDay,
      isBusy: e.transparency != 'transparent' && !selfDeclined,
      taskId: e.extendedProperties?.private?[taskIdKey],
      htmlLink: _link(e.htmlLink),
      createdAt: (e.created ?? now).toUtc(),
      updatedAt: (e.updated ?? now).toUtc(),
    );
  }

  /// The event body Grind writes for a scheduled [task]. Times are sent as
  /// UTC instants; Google shows them in each viewer's zone. Default reminders
  /// are off because Grind sends its own.
  static gcal.Event fromTask(Task task) {
    final notes = task.notes?.trim();
    return gcal.Event(
      summary: task.title,
      description: [
        if (notes != null && notes.isNotEmpty) notes,
        CalendarSyncStrings.writtenByGrind,
      ].join('\n\n'),
      start: gcal.EventDateTime(dateTime: task.scheduledStart!.toUtc()),
      end: gcal.EventDateTime(dateTime: task.scheduledEnd!.toUtc()),
      transparency: 'opaque',
      reminders: gcal.EventReminders(useDefault: false),
      extendedProperties: gcal.EventExtendedProperties(
        private: {taskIdKey: task.id},
      ),
    );
  }

  /// Google's `htmlLink`, kept only when it is an https URL.
  static String? _link(String? raw) {
    final uri = raw == null ? null : Uri.tryParse(raw.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    return uri.toString();
  }

  static DateTime _localMidnight(DateTime date) =>
      DateTime(date.year, date.month, date.day).toUtc();

  /// JSON for the persisted mirror (see `GoogleSyncState`).
  static Map<String, Object?> toJson(CalendarEvent e) => {
    'id': e.id,
    'ext': e.externalId,
    'cal': e.calendarId,
    'title': e.title,
    'start': e.start.toUtc().toIso8601String(),
    'end': e.end.toUtc().toIso8601String(),
    'allDay': e.isAllDay,
    'busy': e.isBusy,
    'task': e.taskId,
    'link': e.htmlLink,
    'created': e.createdAt.toUtc().toIso8601String(),
    'updated': e.updatedAt.toUtc().toIso8601String(),
  };

  static CalendarEvent fromJson(Map<String, Object?> j) => CalendarEvent(
    id: j['id']! as String,
    source: CalendarSource.google,
    externalId: j['ext']! as String,
    calendarId: j['cal'] as String?,
    title: j['title']! as String,
    start: DateTime.parse(j['start']! as String),
    end: DateTime.parse(j['end']! as String),
    isAllDay: j['allDay'] as bool? ?? false,
    isBusy: j['busy'] as bool? ?? true,
    taskId: j['task'] as String?,
    htmlLink: j['link'] as String?,
    createdAt: DateTime.parse(j['created']! as String),
    updatedAt: DateTime.parse(j['updated']! as String),
  );
}
