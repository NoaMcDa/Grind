/// Which event asked for a widget reload. Order matters: the policy treats
/// [schedulerReplan] as authoritative (never rate-limited) and the rest as
/// best-effort hints that can coalesce into the next scheduler run.
enum WidgetRefreshTrigger {
  /// The notification scheduler finished a replan. The pending set, and
  /// therefore the snapshot's `nextReminder`, may have changed. The
  /// scheduler's own debounce (see `NotificationSync.debounce`) already
  /// smooths bursts, so we let every replan through.
  schedulerReplan,

  /// A task was added, completed, deleted or edited. The scheduler will
  /// replan soon (within its debounce); meanwhile the momentum meter and
  /// the "next reminder" may already be stale, so we try to refresh and
  /// let the rate limit decide.
  taskChanged,

  /// A focus session started or ended. Momentum counts each focus event, so
  /// the meter animates sooner than the next scheduler run.
  focusStateChanged,

  /// The app returned to the foreground. A defensive refresh: the widget
  /// may have been visible with an old snapshot while the app was gone.
  appResumed,

  /// Explicit (debug, a settings screen, a test). Always honored.
  manual,
}

/// Why a refresh was skipped. Callers log it as a counter / breadcrumb;
/// the user never sees it.
enum WidgetRefreshSkipReason {
  /// Too soon after the last refresh — see [WidgetRefreshPolicy.minInterval].
  tooSoon,
}

/// The policy's answer. Either [WidgetRefreshDecision.refresh] with the
/// triggering event, or [WidgetRefreshDecision.skip] with why. Uses a
/// sealed-style pair of named constructors so callers can switch on it.
class WidgetRefreshDecision {
  const WidgetRefreshDecision.refresh(WidgetRefreshTrigger this.trigger)
    : skipReason = null;

  const WidgetRefreshDecision.skip(WidgetRefreshSkipReason this.skipReason)
    : trigger = null;

  /// Set when the decision is a refresh, null otherwise.
  final WidgetRefreshTrigger? trigger;

  /// Set when the decision is a skip, null otherwise.
  final WidgetRefreshSkipReason? skipReason;

  /// True on a refresh decision. Lets callers write
  /// `if (decision.shouldRefresh) ...` without looking at both fields.
  bool get shouldRefresh => trigger != null;
}

/// Decides whether the Flutter app should call `HomeWidget.saveWidgetData`
/// plus `updateWidget` for a given event (#23).
///
/// Why it exists: WidgetKit rate-limits timeline reloads server-side, so
/// pounding `updateWidget` on every task edit wastes budget without
/// changing what the user sees. This policy is pure Dart — it takes an
/// event, the time, and the last refresh — so it unit-tests without
/// touching the plugin or an iOS target.
///
/// The authoritative refresh is a scheduler replan: it is the only moment
/// the "next reminder" can change, and it already runs behind a debounce
/// in `NotificationSync`. Everything else (task edits, focus changes,
/// resume) is best-effort, rate-limited to one call per [minInterval]; the
/// scheduler run that follows catches whatever was coalesced.
///
/// Stateless: the caller owns the `lastRefreshAt` timestamp. That keeps
/// the policy trivial to test and makes it safe to share across isolates.
class WidgetRefreshPolicy {
  const WidgetRefreshPolicy({this.minInterval = const Duration(seconds: 30)});

  /// Shortest gap between two best-effort refreshes. Scheduler replans and
  /// manual requests ignore this. 30 s matches the WidgetKit reload budget
  /// guidance in Apple's documentation (several reloads per hour, bursts
  /// allowed).
  final Duration minInterval;

  /// Whether to refresh now. [lastRefreshAt] is when the caller last wrote
  /// a snapshot; null means no refresh has happened yet in this process.
  WidgetRefreshDecision decide({
    required WidgetRefreshTrigger trigger,
    required DateTime now,
    DateTime? lastRefreshAt,
  }) {
    // Authoritative triggers always refresh: the scheduler is the source of
    // truth for `nextReminder`, and `manual` is the escape hatch.
    if (trigger == WidgetRefreshTrigger.schedulerReplan ||
        trigger == WidgetRefreshTrigger.manual) {
      return WidgetRefreshDecision.refresh(trigger);
    }
    if (lastRefreshAt == null) {
      return WidgetRefreshDecision.refresh(trigger);
    }
    // Clock skew (e.g. a time-zone change between calls) can make `now`
    // earlier than `lastRefreshAt`. Treat that as "plenty of time passed",
    // not as a reason to block the refresh forever.
    final elapsed = now.difference(lastRefreshAt);
    if (!elapsed.isNegative && elapsed < minInterval) {
      return const WidgetRefreshDecision.skip(
        WidgetRefreshSkipReason.tooSoon,
      );
    }
    return WidgetRefreshDecision.refresh(trigger);
  }
}
