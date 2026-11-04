import 'widget_snapshot.dart';

/// Why two snapshots differ enough to justify asking WidgetKit to reload
/// the home-screen widget (#23).
///
/// A write that contains the same `nextReminder` and the same momentum
/// bands as the previous one gives the user no new information — pushing
/// it still costs a WidgetKit reload and a disk write to the App Group.
/// This enum names the one change that made the write worth doing, so the
/// write path can log a breadcrumb and callers can skip when the result is
/// [none].
///
/// Ordering matches the writer's priority: `nextReminder` moves first (it
/// is what the user reads on the widget face), then momentum (band and
/// 7-day strip), then `writtenAt` on its own (the "a few minutes ago"
/// label going stale). [none] is the "nothing changed" answer.
enum WidgetSnapshotDelta {
  /// Same `nextReminder`, momentum and strip. Only `writtenAt` moved; the
  /// widget face would render identically. Callers skip the reload.
  none,

  /// The `nextReminder` was added, dropped, swapped for a different task,
  /// or had its title, body, fire time or action flags change.
  nextReminder,

  /// Momentum changed in a way the meter would show: the level band moved,
  /// the numeric value shifted by more than
  /// [WidgetSnapshotDeltaTolerances.momentumValueEpsilon], the "showed up"
  /// day count changed, or any day in the 7-day strip did.
  momentum,

  /// Neither `nextReminder` nor `momentum` changed, but the snapshot is
  /// much older than the new one — the widget's "a few minutes ago" label
  /// is now misleading. Threshold lives on
  /// [WidgetSnapshotDeltaTolerances.staleAfter].
  stale,
}

/// Tunables for [WidgetSnapshotDeltaCalculator]. Kept on one object so the
/// writer can override them in tests without passing five positional args.
class WidgetSnapshotDeltaTolerances {
  const WidgetSnapshotDeltaTolerances({
    this.momentumValueEpsilon = 0.5,
    this.staleAfter = const Duration(minutes: 15),
  });

  /// Smallest change in `momentum.value` (0..100) that counts as different.
  /// The meter rounds to one decimal, so a 0.5 move is one visible tick.
  final double momentumValueEpsilon;

  /// How old the previous snapshot must be before a bare `writtenAt` bump
  /// is reason enough to reload. 15 min matches the WidgetKit timeline
  /// granularity the extension requests for the "a few minutes ago" label.
  final Duration staleAfter;
}

/// Pure comparator for two [WidgetSnapshot]s.
///
/// Why pure: the writer runs on every task edit, focus change and resume
/// (gated by [WidgetRefreshPolicy]). Skipping no-op reloads saves the
/// WidgetKit reload budget without changing what the user sees. This
/// comparator has no I/O, so it unit-tests against a few hand-built pairs.
///
/// The comparator is deliberately strict about fields the widget face
/// renders (title, body, fire time, action flags, momentum band + strip)
/// and loose about fields it does not (schema version is a decode concern,
/// `writtenAt` only matters when the previous snapshot is stale).
abstract final class WidgetSnapshotDeltaCalculator {
  /// What changed between [previous] and [next]. When [previous] is null —
  /// first write of the process — the answer is [WidgetSnapshotDelta.none]
  /// if [next] is empty-ish (no reminder, zero momentum) and
  /// [WidgetSnapshotDelta.nextReminder] / [WidgetSnapshotDelta.momentum]
  /// otherwise. A null-to-non-empty transition always deserves the reload.
  static WidgetSnapshotDelta diff({
    required WidgetSnapshot? previous,
    required WidgetSnapshot next,
    WidgetSnapshotDeltaTolerances tolerances =
        const WidgetSnapshotDeltaTolerances(),
  }) {
    if (previous == null) {
      if (next.nextReminder != null) return WidgetSnapshotDelta.nextReminder;
      if (!_momentumIsEmpty(next.momentum)) {
        return WidgetSnapshotDelta.momentum;
      }
      return WidgetSnapshotDelta.none;
    }
    if (!_remindersMatch(previous.nextReminder, next.nextReminder)) {
      return WidgetSnapshotDelta.nextReminder;
    }
    if (!_momentumMatches(
      previous.momentum,
      next.momentum,
      tolerances.momentumValueEpsilon,
    )) {
      return WidgetSnapshotDelta.momentum;
    }
    final elapsed = next.writtenAt.difference(previous.writtenAt);
    if (!elapsed.isNegative && elapsed >= tolerances.staleAfter) {
      return WidgetSnapshotDelta.stale;
    }
    return WidgetSnapshotDelta.none;
  }

  /// Convenience for the write path: `if (shouldReload(prev, next)) ...`.
  /// Any non-[WidgetSnapshotDelta.none] result returns true.
  static bool shouldReload({
    required WidgetSnapshot? previous,
    required WidgetSnapshot next,
    WidgetSnapshotDeltaTolerances tolerances =
        const WidgetSnapshotDeltaTolerances(),
  }) =>
      diff(previous: previous, next: next, tolerances: tolerances) !=
      WidgetSnapshotDelta.none;

  static bool _remindersMatch(WidgetReminder? a, WidgetReminder? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    return a.taskId == b.taskId &&
        a.notificationId == b.notificationId &&
        a.fireAt.isAtSameMomentAs(b.fireAt) &&
        a.title == b.title &&
        a.body == b.body &&
        a.canComplete == b.canComplete &&
        a.canStartFocus == b.canStartFocus;
  }

  static bool _momentumMatches(
    WidgetMomentum a,
    WidgetMomentum b,
    double valueEpsilon,
  ) {
    if (a.level != b.level) return false;
    if (a.showedUpDays != b.showedUpDays) return false;
    if ((a.value - b.value).abs() >= valueEpsilon) return false;
    if (a.dayCounts.length != b.dayCounts.length) return false;
    for (var i = 0; i < a.dayCounts.length; i++) {
      if (a.dayCounts[i] != b.dayCounts[i]) return false;
    }
    return true;
  }

  static bool _momentumIsEmpty(WidgetMomentum m) =>
      m.value == 0 && m.showedUpDays == 0 && m.dayCounts.every((c) => c == 0);
}
