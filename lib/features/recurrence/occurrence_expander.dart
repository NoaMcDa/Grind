import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/time_zones.dart';
import 'package:rrule/rrule.dart';
import 'package:timezone/timezone.dart' as tz;

/// Loads the IANA database once. Safe to call often.
void ensureTimeZonesInitialized() => ensureTimeZones();

/// Parsed form of [ReminderRule.rrule].
///
/// The field holds the RRULE body on its first line (`FREQ=WEEKLY;BYDAY=MO`)
/// and optionally more lines, as floating wall-clock times in the task's
/// zone:
/// - `DTSTART:<yyyyMMddTHHmmss>`: the series' first occurrence. `Task.remindAt`
///   moves on to the next pending occurrence as occurrences are completed;
///   DTSTART keeps the start so `COUNT` and `until` are counted from it
///   (written by [pinSeriesStart] on the first completion or edit).
/// - `EXDATE:<yyyyMMddTHHmmss>,...`: skipped occurrences.
///
/// The `rrule` package models neither, so this layer owns them.
class RruleText {
  const RruleText(this.body, [this.exdates = const [], this.dtstart]);

  /// RRULE body, no `RRULE:` prefix.
  final String body;

  /// Excluded occurrences as wall-clock fields stored in UTC-flagged dates.
  final List<DateTime> exdates;

  /// The series start as wall-clock fields in a UTC-flagged date, or null
  /// when the series starts at the task's `remindAt`.
  final DateTime? dtstart;

  static const _prefix = 'EXDATE:';
  static const _startPrefix = 'DTSTART:';

  factory RruleText.parse(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return const RruleText('');
    var body = lines.first;
    if (body.startsWith('RRULE:')) body = body.substring(6);
    final ex = <DateTime>[];
    DateTime? start;
    for (final l in lines.skip(1)) {
      if (l.startsWith(_startPrefix)) {
        start = _parseWall(l.substring(_startPrefix.length).trim()) ?? start;
        continue;
      }
      if (!l.startsWith(_prefix)) continue;
      for (final v in l.substring(_prefix.length).split(',')) {
        final d = _parseWall(v.trim());
        if (d != null) ex.add(d);
      }
    }
    return RruleText(body, ex, start);
  }

  /// Same text with [occurrence] (a wall-clock moment in the task zone)
  /// excluded.
  RruleText withExdate(DateTime occurrence) {
    final w = wallClock(occurrence);
    if (exdates.contains(w)) return this;
    return RruleText(body, [...exdates, w]..sort(), dtstart);
  }

  /// Same text with the body replaced and the exclusions and start kept.
  RruleText withBody(String newBody) => RruleText(newBody, exdates, dtstart);

  /// Same text starting at [start] (a wall-clock moment in the task zone),
  /// or at the task's `remindAt` when null.
  RruleText withDtstart(DateTime? start) =>
      RruleText(body, exdates, start == null ? null : wallClock(start));

  @override
  String toString() => [
    body,
    if (dtstart != null) '$_startPrefix${_formatWall(dtstart!)}',
    if (exdates.isNotEmpty) '$_prefix${exdates.map(_formatWall).join(',')}',
  ].join('\n');

  static String _two(int v) => v.toString().padLeft(2, '0');

  static String _formatWall(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}${_two(d.month)}${_two(d.day)}'
      'T${_two(d.hour)}${_two(d.minute)}${_two(d.second)}';

  static DateTime? _parseWall(String v) {
    final m = RegExp(r'^(\d{4})(\d\d)(\d\d)T(\d\d)(\d\d)(\d\d)$').firstMatch(v);
    if (m == null) return null;
    final p = [for (var i = 1; i <= 6; i++) int.parse(m.group(i)!)];
    return DateTime.utc(p[0], p[1], p[2], p[3], p[4], p[5]);
  }
}

/// A moment's wall-clock fields as a UTC-flagged [DateTime]: the form the
/// `rrule` package iterates in, so recurrence math never meets a DST jump.
DateTime wallClock(DateTime t) =>
    DateTime.utc(t.year, t.month, t.day, t.hour, t.minute, t.second);

/// Fire times of [rule] inside `[from, to)`, as local wall-clock
/// [tz.TZDateTime]s in [timeZoneName].
///
/// Occurrences are computed in the task's wall-clock time, so a 07:00 series
/// stays 07:00 across DST changes. The series starts at the rule's DTSTART
/// (see [RruleText]) when it has one, else at [anchor] (`Task.remindAt`), so
/// `COUNT` and `until` are counted from the start, not from the next pending
/// occurrence. Each occurrence fires `rule.leadMinutes` earlier;
/// [from]/[to] bound the fire times. Occurrences after `rule.until`, after an
/// RRULE `UNTIL` or past `COUNT`, and excluded dates, are skipped. A time that
/// does not exist on a spring-forward day shifts forward by the DST gap.
/// A monthly rule on the 31st skips months without a 31st (RFC 5545).
///
/// Pure: no I/O besides the (idempotent) time zone database load.
List<tz.TZDateTime> expandOccurrences({
  required ReminderRule rule,
  required DateTime anchor,
  required DateTime from,
  required DateTime to,
  required String timeZoneName,
  int maxResults = 400,
}) {
  final location = locationFor(timeZoneName);
  final text = RruleText.parse(rule.rrule);
  if (text.body.isEmpty) return const [];
  final RecurrenceRule parsed;
  try {
    parsed = RecurrenceRule.fromString('RRULE:${text.body}');
  } on Object {
    return const [];
  }

  final lead = Duration(minutes: rule.leadMinutes);
  final anchorWall =
      text.dtstart ?? wallClock(tz.TZDateTime.from(anchor, location));
  final fromUtc = from.toUtc();
  final toUtc = to.toUtc();
  if (!toUtc.isAfter(fromUtc)) return const [];

  // Occurrence instants that can fire inside the window, padded a day each
  // side in wall-clock terms to absorb the zone offset, then filtered exactly.
  final after = wallClock(
    tz.TZDateTime.from(fromUtc.add(lead), location),
  ).subtract(const Duration(days: 1));
  final before = wallClock(
    tz.TZDateTime.from(toUtc.add(lead), location),
  ).add(const Duration(days: 1));
  // The series starts after the window (the `rrule` package asserts
  // `before >= start`).
  if (before.isBefore(anchorWall)) return const [];

  final untilUtc = rule.until?.toUtc();
  final out = <tz.TZDateTime>[];
  for (final wall in parsed.getInstances(
    start: anchorWall,
    after: after.isBefore(anchorWall) ? null : after,
    includeAfter: true,
    before: before,
    includeBefore: true,
  )) {
    if (text.exdates.contains(wall)) continue;
    final occurrence = tz.TZDateTime(
      location,
      wall.year,
      wall.month,
      wall.day,
      wall.hour,
      wall.minute,
      wall.second,
    );
    if (untilUtc != null && occurrence.toUtc().isAfter(untilUtc)) break;
    final fire = tz.TZDateTime.from(occurrence.subtract(lead), location);
    final fireUtc = fire.toUtc();
    if (fireUtc.isBefore(fromUtc)) continue;
    if (!fireUtc.isBefore(toUtc)) break;
    out.add(fire);
    if (out.length >= maxResults) break;
  }
  return out;
}

/// The instant the series starts (UTC): the rule's DTSTART in
/// [timeZoneName], else [anchor].
DateTime seriesStart(ReminderRule rule, DateTime anchor, String timeZoneName) {
  final start = RruleText.parse(rule.rrule).dtstart;
  if (start == null) return anchor.toUtc();
  return tz.TZDateTime(
    locationFor(timeZoneName),
    start.year,
    start.month,
    start.day,
    start.hour,
    start.minute,
    start.second,
  ).toUtc();
}

/// [rule] with its start written down as DTSTART ([anchor], the task's
/// current `remindAt`, in [timeZoneName]) unless it already has one. Call it
/// before `remindAt` moves on, so the series keeps counting from its start.
ReminderRule pinSeriesStart(
  ReminderRule rule,
  DateTime anchor,
  String timeZoneName,
) {
  final text = RruleText.parse(rule.rrule);
  if (text.dtstart != null || text.body.isEmpty) return rule;
  final wall = tz.TZDateTime.from(anchor.toUtc(), locationFor(timeZoneName));
  return rule.copyWith(rrule: text.withDtstart(wall).toString());
}
