import 'widget_snapshot.dart';

/// How trustworthy a [WidgetSnapshot] looks when the iOS home-screen widget
/// reads it through the App Group (#23).
///
/// Why a grade and not just a boolean: the writer-side
/// `WidgetSnapshotDeltaCalculator.staleAfter` decides when a new write is
/// worth a WidgetKit reload. The reader side has the opposite job — a
/// snapshot was already read, and the widget has to pick what to show for
/// it. "A few minutes ago" works for a snapshot from five minutes back; a
/// snapshot from an hour ago probably should not claim to know the next
/// reminder at all. Three bands plus an [expired] trailer let the widget
/// render differently in each case without the UI code reinventing the
/// thresholds.
///
/// Ordering follows real time: [fresh] is the newest state, [expired] the
/// oldest. [index] ordering is stable so callers can compare grades with
/// `a.index >= b.index` ("at least this stale") without a lookup table.
enum WidgetSnapshotFreshness {
  /// Just written. The widget shows the snapshot as-is with an exact
  /// timestamp ("Next at 09:00"); the reader can trust every field.
  fresh,

  /// Minutes have passed. Still show the reminder and momentum, but
  /// prefer the relative label ("a few minutes ago") over a precise
  /// timestamp — the writer may have missed a tick and the data could
  /// already be a nudge behind.
  aging,

  /// Many minutes have passed. The widget shows the data with a visible
  /// "refreshing…" hint; a scheduler replan is probably in flight and
  /// the fresh snapshot will land on the next timeline tick.
  stale,

  /// Too old to trust. The widget drops the reminder row and renders the
  /// "Open Grind" fallback — the user tapping it is cheaper than showing
  /// a reminder that already fired.
  expired,
}

/// Thresholds for [WidgetSnapshotFreshnessCalculator]. Kept on one object
/// so the reader can override them in tests without passing three
/// positional arguments. Defaults align with WidgetKit's timeline
/// granularity (reloads every ~15 min) and the writer-side staleness
/// window.
///
/// Invariant: `agingAfter < staleAfter < expiredAfter` and every
/// threshold is non-negative. An asserts-in-debug check catches a
/// misordered policy that would make the grade un-monotonic in time
/// (a snapshot could register as [WidgetSnapshotFreshness.stale] before
/// it was [WidgetSnapshotFreshness.aging]). Release builds trust the
/// defaults because the only callers that construct this type are
/// tests.
class WidgetSnapshotFreshnessThresholds {
  const WidgetSnapshotFreshnessThresholds({
    this.agingAfter = const Duration(minutes: 2),
    this.staleAfter = const Duration(minutes: 15),
    this.expiredAfter = const Duration(hours: 1),
  }) : assert(
         agingAfter >= Duration.zero &&
             staleAfter >= Duration.zero &&
             expiredAfter >= Duration.zero,
         'WidgetSnapshotFreshnessThresholds durations must be non-negative',
       ),
       assert(
         agingAfter < staleAfter && staleAfter < expiredAfter,
         'WidgetSnapshotFreshnessThresholds must satisfy '
         'agingAfter < staleAfter < expiredAfter',
       );

  /// Oldest age that still counts as [WidgetSnapshotFreshness.fresh].
  /// 2 min covers the writer-side debounce plus one scheduler tick.
  final Duration agingAfter;

  /// Oldest age that still counts as [WidgetSnapshotFreshness.aging].
  /// 15 min matches `WidgetSnapshotDeltaTolerances.staleAfter` so the
  /// reader's "stale" band starts the moment the writer thinks a bare
  /// `writtenAt` bump is reason enough to reload.
  final Duration staleAfter;

  /// Oldest age that still counts as [WidgetSnapshotFreshness.stale].
  /// Past this, the snapshot is [WidgetSnapshotFreshness.expired] and
  /// the widget shows the "Open Grind" fallback. 1 h is deliberately
  /// generous — a user's phone can sit in Low Power Mode for a while
  /// before iOS wakes an extension again.
  final Duration expiredAfter;
}

/// Pure grader for a [WidgetSnapshot]'s age at read time (#23).
///
/// Why pure: the widget extension reads a snapshot and decides what to
/// render on every timeline refresh. Keeping this a stateless function
/// of `(snapshot.writtenAt, now, thresholds)` lets both the Flutter app
/// (for debug surfaces and the resume-time self-check) and the native
/// widget target (over the method channel, eventually) share one answer
/// without passing a live clock around.
///
/// A null snapshot always grades as [WidgetSnapshotFreshness.expired]
/// so the widget's "nothing to show" path and its "too old to show"
/// path hit the same code.
abstract final class WidgetSnapshotFreshnessCalculator {
  /// Grades [snapshot] against [now]. A null [snapshot] (nothing in the
  /// App Group yet, or a payload that failed to decode) grades as
  /// [WidgetSnapshotFreshness.expired]: the widget has no reminder to
  /// show, and the fallback surface is the right answer.
  ///
  /// Clock skew (e.g. a time-zone change between the writer and the
  /// reader) can make [now] earlier than `snapshot.writtenAt`. A
  /// future-dated snapshot is treated as [WidgetSnapshotFreshness.fresh],
  /// not as an exception: the widget would otherwise flicker to the
  /// fallback the first time the user crosses a time zone.
  static WidgetSnapshotFreshness grade({
    required WidgetSnapshot? snapshot,
    required DateTime now,
    WidgetSnapshotFreshnessThresholds thresholds =
        const WidgetSnapshotFreshnessThresholds(),
  }) {
    if (snapshot == null) return WidgetSnapshotFreshness.expired;
    final elapsed = now.toUtc().difference(snapshot.writtenAt.toUtc());
    if (elapsed.isNegative) return WidgetSnapshotFreshness.fresh;
    if (elapsed < thresholds.agingAfter) return WidgetSnapshotFreshness.fresh;
    if (elapsed < thresholds.staleAfter) return WidgetSnapshotFreshness.aging;
    if (elapsed < thresholds.expiredAfter) {
      return WidgetSnapshotFreshness.stale;
    }
    return WidgetSnapshotFreshness.expired;
  }

  /// Convenience predicate for the widget UI: `if (shouldShowReminder(...))`.
  /// True for every grade but [WidgetSnapshotFreshness.expired], so the
  /// caller can hide the row without matching the enum.
  static bool shouldShowReminder({
    required WidgetSnapshot? snapshot,
    required DateTime now,
    WidgetSnapshotFreshnessThresholds thresholds =
        const WidgetSnapshotFreshnessThresholds(),
  }) =>
      grade(snapshot: snapshot, now: now, thresholds: thresholds) !=
      WidgetSnapshotFreshness.expired;
}
