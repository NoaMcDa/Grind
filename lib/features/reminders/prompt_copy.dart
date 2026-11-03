import 'dart:ui' show Locale;

import 'package:grind/core/core.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../l10n/app_localizations.dart';
import '../goals/domain/metric_ticks.dart' show isMetricTick;

/// Title and body of one daily prompt.
typedef PromptText = ({String title, String body});

/// Pip's copy for the two daily prompts (#37), built outside any widget.
///
/// - Morning: an invitation, naming the day's first task when there is one
///   ("Want to plan the day together? First up: Thesis").
/// - Evening: leads with the win logged that day: the evening review's win
///   when one was saved, else what got done, else a plain invitation.
///
/// Never mentions what did not happen (`docs/tone-guide.md`).
abstract final class PromptCopy {
  /// Longest task title or win quoted in a prompt before it is shortened.
  static const maxQuote = 40;

  static PromptText morning({required String languageCode, String? firstTask}) {
    final l = _l10n(languageCode);
    final first = _quote(firstTask);
    return (
      title: l.promptMorningTitle,
      body: first == null
          ? l.promptMorningBody
          : l.promptMorningBodyFirst(first),
    );
  }

  /// [doneTitles]: titles of the tasks finished that day, latest first.
  static PromptText evening({
    required String languageCode,
    String? win,
    List<String> doneTitles = const [],
  }) {
    final l = _l10n(languageCode);
    final w = _quote(win);
    final latest = doneTitles.isEmpty ? null : _quote(doneTitles.first);
    final String body;
    if (w != null) {
      body = l.promptEveningBodyWin(w);
    } else if (latest != null && doneTitles.length == 1) {
      body = l.promptEveningBodyDone(latest);
    } else if (latest != null) {
      body = l.promptEveningBodyDoneMany(doneTitles.length, latest);
    } else {
      body = l.promptEveningBody;
    }
    return (title: l.promptEveningTitle, body: body);
  }

  /// The title of the first open task on the local day `[from, dayEnd)`:
  /// the earliest timed one (`scheduledStart`, else `remindAt`, else a due
  /// time) at or after [from], else a task due that day by date only.
  static String? firstTaskTitle(
    Iterable<Task> tasks,
    tz.TZDateTime from,
    tz.TZDateTime dayEnd,
  ) {
    final location = from.location;
    final dayStart = tz.TZDateTime(location, from.year, from.month, from.day);
    Task? timed;
    DateTime? timedAt;
    Task? dated;
    for (final t in tasks) {
      if (t.status != TaskStatus.open || t.deletedAt != null) continue;
      if (t.title.trim().isEmpty) continue;
      final at = t.scheduledStart ?? t.remindAt ?? _timedDue(t, location);
      if (at != null) {
        final u = at.toUtc();
        if (u.isBefore(from) || !u.isBefore(dayEnd)) continue;
        if (timedAt == null || u.isBefore(timedAt)) {
          timed = t;
          timedAt = u;
        }
        continue;
      }
      final due = t.dueAt?.toUtc();
      if (due == null || due.isBefore(dayStart) || !due.isBefore(dayEnd)) {
        continue;
      }
      if (dated == null || t.createdAt.isBefore(dated.createdAt)) dated = t;
    }
    return (timed ?? dated)?.title.trim();
  }

  /// Titles of the real tasks finished in `[dayStart, dayEnd)`, latest
  /// first (metric +1 ticks are not tasks).
  static List<String> doneTitles(
    Iterable<Task> tasks,
    DateTime dayStart,
    DateTime dayEnd,
  ) {
    final done = [
      for (final t in tasks)
        if (t.isDone &&
            t.deletedAt == null &&
            !isMetricTick(t) &&
            t.completedAt != null &&
            !t.completedAt!.isBefore(dayStart) &&
            t.completedAt!.isBefore(dayEnd) &&
            t.title.trim().isNotEmpty)
          t,
    ]..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
    return [for (final t in done) t.title.trim()];
  }

  /// A due time other than local midnight or 23:59 (those mean "by date").
  static DateTime? _timedDue(Task t, tz.Location location) {
    final due = t.dueAt;
    if (due == null) return null;
    final l = tz.TZDateTime.from(due.toUtc(), location);
    final m = l.hour * 60 + l.minute;
    return m == 0 || m >= 23 * 60 + 59 ? null : due;
  }

  static String? _quote(String? s) {
    final t = s?.trim().replaceAll(RegExp(r'[.!?\s]+$'), '');
    if (t == null || t.isEmpty) return null;
    if (t.length <= maxQuote) return t;
    return '${t.substring(0, maxQuote - 1).trimRight()}…';
  }

  static AppLocalizations _l10n(String code) {
    final c = code.toLowerCase();
    final he = c.startsWith('he') || c.startsWith('iw');
    return lookupAppLocalizations(Locale(he ? 'he' : 'en'));
  }
}
