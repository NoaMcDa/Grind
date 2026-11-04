/// Per-user daily budget for assistant calls (epic #38).
///
/// The epic calls for a "budget per user per day" so one runaway client can't
/// drive up the bill. This file is the pure-Dart piece of that: a tracker
/// that counts calls and tokens against an [AssistantDailyBudget], rolls the
/// counters to a fresh day at local midnight, and refuses a spend that would
/// push either counter past its cap.
///
/// It is in-memory on purpose. A later PR under epic #38 wires it into the
/// server-side gateway (per-user persistence, enforcement before the LLM
/// call) and the Settings "daily budget" affordance; this slice defines the
/// contract and the arithmetic so those PRs have something to plug into.
///
/// The LLM never picks times. This file doesn't touch scheduling — it's
/// pure cost metering, deliberately orthogonal to [AssistantGateway] and
/// [ModelPolicy].
library;

import 'clock.dart';

/// A single user's spend against today's budget.
///
/// `date` is a floating local-calendar day (year/month/day only) so a trip
/// through a time-zone doesn't shift counters. The tracker rolls the usage
/// forward the first time the clock crosses local midnight; until then,
/// repeated reads return the same snapshot.
class AssistantDailyUsage {
  const AssistantDailyUsage({
    required this.date,
    required this.calls,
    required this.inputTokens,
    required this.outputTokens,
  }) : assert(calls >= 0),
       assert(inputTokens >= 0),
       assert(outputTokens >= 0);

  /// A zero-usage snapshot for [date].
  const AssistantDailyUsage.empty(this.date)
    : calls = 0,
      inputTokens = 0,
      outputTokens = 0;

  /// The floating local date these counters apply to; time component is
  /// always 00:00.
  final DateTime date;

  /// Completed calls on [date].
  final int calls;

  /// Input tokens sent on [date].
  final int inputTokens;

  /// Output tokens received on [date].
  final int outputTokens;

  /// Input + output. The budget cap is measured against this sum.
  int get totalTokens => inputTokens + outputTokens;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssistantDailyUsage &&
          date == other.date &&
          calls == other.calls &&
          inputTokens == other.inputTokens &&
          outputTokens == other.outputTokens;

  @override
  int get hashCode => Object.hash(date, calls, inputTokens, outputTokens);

  @override
  String toString() =>
      'AssistantDailyUsage(date: $date, calls: $calls, '
      'inputTokens: $inputTokens, outputTokens: $outputTokens)';
}

/// A per-user daily cap.
///
/// Either cap can be disabled by passing `null`; a null cap means that
/// axis is not metered. The defaults are generous — a brake, not a wall —
/// and tuned so a normal day's use never hits them. The server-side
/// policy will own the real numbers; this value lives here so tests and
/// the Settings screen can refer to the same shape.
class AssistantDailyBudget {
  const AssistantDailyBudget({this.maxCalls, this.maxTokens})
    : assert(maxCalls == null || maxCalls >= 0),
      assert(maxTokens == null || maxTokens >= 0);

  /// Maximum number of calls in a local day, or null for no cap.
  final int? maxCalls;

  /// Maximum combined input + output tokens in a local day, or null for
  /// no cap.
  final int? maxTokens;

  /// No limits. Used by callers that want the tracker's counters but
  /// don't want it to refuse a call.
  static const AssistantDailyBudget unlimited = AssistantDailyBudget();

  /// A safe default: 200 calls / 200k tokens per user per day. Picked to
  /// clear ordinary use with a wide margin; tune on the server once real
  /// traffic lands.
  static const AssistantDailyBudget defaults = AssistantDailyBudget(
    maxCalls: 200,
    maxTokens: 200000,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssistantDailyBudget &&
          maxCalls == other.maxCalls &&
          maxTokens == other.maxTokens;

  @override
  int get hashCode => Object.hash(maxCalls, maxTokens);

  @override
  String toString() =>
      'AssistantDailyBudget(maxCalls: $maxCalls, maxTokens: $maxTokens)';
}

/// Which cap a would-be spend ran into.
enum BudgetExceededReason { callLimit, tokenLimit }

/// Raised when a spend would push a user's usage past the budget.
///
/// The exception carries both axes so the caller can show a precise
/// message ("you've used 200 of 200 calls today") without re-querying.
class BudgetExceededException implements Exception {
  const BudgetExceededException({
    required this.reason,
    required this.userId,
    required this.usage,
    required this.budget,
  });

  final BudgetExceededReason reason;
  final String userId;
  final AssistantDailyUsage usage;
  final AssistantDailyBudget budget;

  @override
  String toString() {
    switch (reason) {
      case BudgetExceededReason.callLimit:
        return 'BudgetExceededException: user "$userId" hit '
            '${usage.calls}/${budget.maxCalls} calls for ${usage.date}';
      case BudgetExceededReason.tokenLimit:
        return 'BudgetExceededException: user "$userId" hit '
            '${usage.totalTokens}/${budget.maxTokens} tokens for ${usage.date}';
    }
  }
}

/// Per-user daily budget tracker for the assistant layer.
///
/// Counts calls and tokens against [budget] and refuses a spend that would
/// cross either cap. Counters roll to a fresh day on the first read or
/// write after local midnight (derived from the injected [Clock]), so a
/// device left running overnight doesn't carry yesterday's spend into
/// today.
///
/// Pure in-memory, pure Dart, no I/O, no timers. Everything that touches
/// wall time goes through [Clock], which is what the rest of the codebase
/// does.
class AssistantBudgetTracker {
  AssistantBudgetTracker({
    required this.clock,
    this.budget = AssistantDailyBudget.defaults,
  });

  final Clock clock;

  /// The current cap. Change it at runtime (e.g. after a Settings toggle)
  /// without reconstructing the tracker; already-recorded usage is kept.
  AssistantDailyBudget budget;

  final Map<String, AssistantDailyUsage> _byUser = {};

  /// This user's usage for today. Rolls to a fresh day if the clock has
  /// crossed local midnight since the last operation.
  AssistantDailyUsage usageFor(String userId) => _refresh(userId);

  /// True when a spend of [calls] calls and [tokens] tokens would still
  /// fit under both caps. Zero spends are always allowed (they're what
  /// the gateway asks before deciding whether to bother building a
  /// request).
  bool canSpend(String userId, {int tokens = 0, int calls = 1}) {
    assert(tokens >= 0);
    assert(calls >= 0);
    final usage = _refresh(userId);
    final maxCalls = budget.maxCalls;
    if (maxCalls != null && usage.calls + calls > maxCalls) return false;
    final maxTokens = budget.maxTokens;
    if (maxTokens != null && usage.totalTokens + tokens > maxTokens) {
      return false;
    }
    return true;
  }

  /// Like [canSpend] but throws [BudgetExceededException] when either cap
  /// would be crossed. The reason reports which cap tripped first; calls
  /// are checked before tokens so a client that is way over on calls
  /// doesn't get a token-limit message.
  void checkCanSpend(String userId, {int tokens = 0, int calls = 1}) {
    assert(tokens >= 0);
    assert(calls >= 0);
    final usage = _refresh(userId);
    final maxCalls = budget.maxCalls;
    if (maxCalls != null && usage.calls + calls > maxCalls) {
      throw BudgetExceededException(
        reason: BudgetExceededReason.callLimit,
        userId: userId,
        usage: usage,
        budget: budget,
      );
    }
    final maxTokens = budget.maxTokens;
    if (maxTokens != null && usage.totalTokens + tokens > maxTokens) {
      throw BudgetExceededException(
        reason: BudgetExceededReason.tokenLimit,
        userId: userId,
        usage: usage,
        budget: budget,
      );
    }
  }

  /// Record a completed call. Numbers are added to today's counters; the
  /// cap is not re-checked here, because a call that already ran must be
  /// accounted for even if (because the model returned more tokens than
  /// we asked for) it ends up over.
  ///
  /// Returns the usage after the record.
  AssistantDailyUsage record(
    String userId, {
    required int inputTokens,
    required int outputTokens,
    int calls = 1,
  }) {
    assert(inputTokens >= 0);
    assert(outputTokens >= 0);
    assert(calls >= 0);
    final current = _refresh(userId);
    final updated = AssistantDailyUsage(
      date: current.date,
      calls: current.calls + calls,
      inputTokens: current.inputTokens + inputTokens,
      outputTokens: current.outputTokens + outputTokens,
    );
    _byUser[userId] = updated;
    return updated;
  }

  /// Time left until the next local midnight on the current clock. Handy
  /// for a "resets in 4h" line in Settings.
  Duration untilReset() {
    final now = clock.now();
    final tomorrow = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    return tomorrow.difference(now);
  }

  /// Drop counters for one user. The next call will start from zero.
  void resetFor(String userId) => _byUser.remove(userId);

  /// Drop counters for every tracked user.
  void resetAll() => _byUser.clear();

  /// Refreshes the user's usage for the current local day, replacing it
  /// with an empty snapshot if the day has rolled over.
  AssistantDailyUsage _refresh(String userId) {
    final today = _dateOnly(clock.now());
    final current = _byUser[userId];
    if (current == null || current.date != today) {
      final fresh = AssistantDailyUsage.empty(today);
      _byUser[userId] = fresh;
      return fresh;
    }
    return current;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
