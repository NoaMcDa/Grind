/// Small summary of the user's recent task history for the "I'm stuck"
/// helper (epic #41).
///
/// Both paths of the helper need the same context in the same shape:
///
/// * The LLM path (#38) prefers structured counts in the system prompt over
///   a free-text journal — the model does better with "2 skipped, 1 done
///   today" than with four one-line events it has to tally itself.
/// * The offline fallback ([StaticUnstickSuggester]) can nudge its
///   defaults when it sees a streak of skipped tasks: lead with
///   `firstAction` instead of `split`, pick a gentler acknowledgement.
///
/// So this file lives beside [UnstickRequest.recentHistory] and exposes
/// one pure function the chat layer calls once per ask. No clock reads,
/// no Flutter, no gateway types — the summary is a value object in the
/// same spirit as the rest of the "I'm stuck" slice.
library;

import 'package:flutter/foundation.dart';

import 'unstick_request.dart';

/// Counts and a few shape hints derived from [UnstickRequest.recentHistory].
///
/// Everything here is a property of the input list alone — same events in
/// same order always give the same summary — so the chat layer can cache
/// one summary per request and pass it into every rendering path.
@immutable
class RecentHistorySummary {
  const RecentHistorySummary({
    required this.completed,
    required this.skipped,
    required this.missed,
    required this.started,
    required this.rescheduled,
    required this.trailingDropCount,
    required this.lastDropTitle,
  });

  /// How many events of each kind are in the window.
  final int completed;
  final int skipped;
  final int missed;
  final int started;
  final int rescheduled;

  /// Length of the tail streak where events are `skipped` or `missed`,
  /// measured from the last event backwards. Zero when the last event is
  /// anything else, or when the window is empty.
  ///
  /// Two or more in a row is the signal the chat layer uses to say "lead
  /// with the smallest possible first step": the user has already failed
  /// to start twice, so the next pill should not ask them to pick a time.
  final int trailingDropCount;

  /// Title of the most recent dropped (skipped or missed) task, if any.
  /// Used for the acknowledgement line — Pip can name what the user walked
  /// past instead of saying "you keep skipping stuff".
  final String? lastDropTitle;

  /// Total number of events in the window.
  int get total => completed + skipped + missed + started + rescheduled;

  bool get isEmpty => total == 0;

  /// At least one `completed` in the window. The offline fallback uses
  /// this to pick a gentler opener ("You have been moving today.") over
  /// the default acknowledgement.
  bool get hasAnyProgress => completed > 0;

  /// Two or more consecutive drops at the tail. See [trailingDropCount].
  bool get hasDropStreak => trailingDropCount >= 2;

  @override
  bool operator ==(Object other) =>
      other is RecentHistorySummary &&
      other.completed == completed &&
      other.skipped == skipped &&
      other.missed == missed &&
      other.started == started &&
      other.rescheduled == rescheduled &&
      other.trailingDropCount == trailingDropCount &&
      other.lastDropTitle == lastDropTitle;

  @override
  int get hashCode => Object.hash(
    completed,
    skipped,
    missed,
    started,
    rescheduled,
    trailingDropCount,
    lastDropTitle,
  );

  @override
  String toString() {
    final parts = <String>[
      'completed: $completed',
      'skipped: $skipped',
      'missed: $missed',
      'started: $started',
      'rescheduled: $rescheduled',
      'trailingDropCount: $trailingDropCount',
      if (lastDropTitle != null) 'lastDropTitle: "$lastDropTitle"',
    ];
    return 'RecentHistorySummary(${parts.join(', ')})';
  }
}

/// Summarise [events] for the "I'm stuck" helper.
///
/// [events] is the same list [UnstickRequest.recentHistory] carries:
/// oldest first, newest last. The summarizer walks it once and reads
/// only kind and title — timestamps are left to the scheduler.
///
/// Called with an empty list, returns a zero summary ([RecentHistorySummary.isEmpty]
/// is true). Callers do not need to guard on that: the fields are all
/// zero and [RecentHistorySummary.hasDropStreak] is false.
RecentHistorySummary summarizeRecentHistory(List<RecentEvent> events) {
  var completed = 0;
  var skipped = 0;
  var missed = 0;
  var started = 0;
  var rescheduled = 0;

  for (final e in events) {
    switch (e.kind) {
      case RecentEventKind.completed:
        completed++;
      case RecentEventKind.skipped:
        skipped++;
      case RecentEventKind.missed:
        missed++;
      case RecentEventKind.started:
        started++;
      case RecentEventKind.rescheduled:
        rescheduled++;
    }
  }

  // Walk the tail to measure the drop streak. A drop is skipped or missed;
  // `rescheduled` breaks the streak because the user did act on it.
  var trailingDrops = 0;
  String? lastDropTitle;
  for (var i = events.length - 1; i >= 0; i--) {
    final e = events[i];
    final isDrop =
        e.kind == RecentEventKind.skipped || e.kind == RecentEventKind.missed;
    if (!isDrop) break;
    trailingDrops++;
    lastDropTitle ??= e.taskTitle;
  }

  return RecentHistorySummary(
    completed: completed,
    skipped: skipped,
    missed: missed,
    started: started,
    rescheduled: rescheduled,
    trailingDropCount: trailingDrops,
    lastDropTitle: lastDropTitle,
  );
}

/// One-line headline for Pip to show or hand to the LLM.
///
/// Returns an empty string when [summary] is empty — the caller decides
/// whether to render a line at all, instead of showing "nothing yet"
/// which reads like judgement.
///
/// Kept English-plus-Hebrew to match the rest of the "I'm stuck" copy
/// constants ([UnstickTone]); any other [localeCode] falls back to
/// English, as in [StaticUnstickSuggester].
String recentHistoryHeadline(
  RecentHistorySummary summary, {
  String localeCode = 'en',
}) {
  if (summary.isEmpty) return '';
  final he = localeCode == 'he';

  // The two signals worth one short line: drop streak first because it
  // changes which pill Pip leads with; a plain progress line otherwise.
  if (summary.hasDropStreak) {
    final n = summary.trailingDropCount;
    return he ? '$n משימות ברצף לא התחילו.' : '$n tasks skipped in a row.';
  }

  if (summary.hasAnyProgress) {
    final c = summary.completed;
    return he ? '$c הושלמו היום.' : '$c done so far today.';
  }

  // Non-empty but no completions and no drop streak: at least one
  // started/rescheduled event. Report it plainly so Pip has something
  // to acknowledge.
  final moves = summary.started + summary.rescheduled;
  if (moves > 0) {
    return he ? '$moves צעדים עד עכשיו.' : '$moves moves so far today.';
  }

  // One or two drops but not a streak at the tail — still worth naming
  // the shape without labelling it.
  final drops = summary.skipped + summary.missed;
  return he ? '$drops משימות עברו היום.' : '$drops tasks slipped today.';
}
