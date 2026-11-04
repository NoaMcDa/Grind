/// Retry / backoff policy for the assistant gateway (epic #38).
///
/// The real gateway (PR #104 shipped the client-side abstraction) will post
/// `{intent, input, context}` to a server-side function. Networks and edge
/// functions being what they are, some calls will fail transiently: a TCP
/// reset, a cold-start timeout, a 429 from the upstream model. The policy
/// in this file answers the two questions every caller has at that point:
///
///   1. Is this failure worth retrying at all, or is it the user's fault
///      (opted out, bad request) and no amount of retrying will help?
///   2. If it is retryable, how long should we wait before trying again?
///
/// Keeping the answer in a pure value object rather than inline in the
/// gateway means:
///
///   * The gateway stays a thin HTTP layer; the "how to recover" rules are
///     a one-line adapter (`policy.delayFor(attempt)`) around it.
///   * A test can freeze the clock and assert the exact delay sequence a
///     given error produces, without spinning a real `Future.delayed`.
///   * A Settings "back off aggressively on mobile data" toggle is a swap
///     of policy instances, not a fork of the gateway.
///
/// Scope: no timers, no `Future.delayed`, no `Random`. The policy returns
/// an immutable schedule; the caller owns the waiting. Deterministic by
/// default so the same attempt count on the same policy always produces
/// the same delay — handy for golden tests and for a user-facing "trying
/// again in 2s" countdown that mustn't lie.
library;

import 'assistant_gateway.dart';

/// A retry schedule for the assistant gateway.
///
/// Immutable value type. Two policies built from the same parameters are
/// equal, so tests can compare whole policies without poking at internals.
///
/// The default [AssistantRetryPolicy.defaults] gives three tries over
/// roughly one second of total wait — short enough that a user tapping
/// "Ask" won't notice a single transient flap, long enough to clear a
/// cold-start lambda or a one-off rate limit.
class AssistantRetryPolicy {
  /// Builds a policy from explicit parameters. Prefer
  /// [AssistantRetryPolicy.defaults] unless a specific call site needs to
  /// tune the shape.
  ///
  /// Parameters:
  ///
  ///   * [maxAttempts] — total tries, including the first. 1 disables
  ///     retries. Must be at least 1.
  ///   * [initialDelay] — the wait before the second attempt. Must be
  ///     non-negative.
  ///   * [maxDelay] — cap on any individual wait, so an aggressive
  ///     multiplier can't drive the user into a minute-long stall.
  ///   * [multiplier] — factor each successive delay is multiplied by.
  ///     Must be at least 1 (a flat schedule is a valid policy); typical
  ///     values are 2 (exponential) or 1 (constant).
  ///   * [retryableKinds] — the set of [AssistantErrorKind] values the
  ///     policy considers worth retrying. Defaults to the ones the gateway
  ///     surfaces as transient: `network`, `timeout`, `rateLimited`.
  AssistantRetryPolicy({
    required this.maxAttempts,
    required this.initialDelay,
    required this.maxDelay,
    required this.multiplier,
    Set<AssistantErrorKind> retryableKinds = _defaultRetryableKinds,
  }) : assert(maxAttempts >= 1, 'maxAttempts must be at least 1'),
       assert(!initialDelay.isNegative, 'initialDelay must be non-negative'),
       assert(!maxDelay.isNegative, 'maxDelay must be non-negative'),
       assert(
         maxDelay >= initialDelay,
         'maxDelay must be at least initialDelay',
       ),
       assert(multiplier >= 1, 'multiplier must be at least 1'),
       retryableKinds = Set.unmodifiable(retryableKinds);

  /// The total number of attempts the caller may make, including the
  /// first. `maxAttempts == 1` means no retries at all.
  final int maxAttempts;

  /// The delay before attempt 2. Successive delays are
  /// `initialDelay * multiplier^(n-1)`, capped at [maxDelay].
  final Duration initialDelay;

  /// Cap on any single delay. Protects the user from a long stall when
  /// the multiplier compounds through many attempts.
  final Duration maxDelay;

  /// Factor each successive delay is multiplied by.
  final num multiplier;

  /// The [AssistantErrorKind] values this policy treats as transient.
  /// Everything else is terminal and should surface to the caller after
  /// the first failure.
  final Set<AssistantErrorKind> retryableKinds;

  static const Set<AssistantErrorKind> _defaultRetryableKinds = {
    AssistantErrorKind.network,
    AssistantErrorKind.timeout,
    AssistantErrorKind.rateLimited,
  };

  /// The policy wired into the assistant by default: three tries,
  /// 250 ms → 500 ms → 1 s cap, doubling. Short enough that a single
  /// transient flap is invisible to the user, long enough to clear a
  /// cold-start lambda or a one-off rate limit.
  static final AssistantRetryPolicy defaults = AssistantRetryPolicy(
    maxAttempts: 3,
    initialDelay: const Duration(milliseconds: 250),
    maxDelay: const Duration(seconds: 2),
    multiplier: 2,
  );

  /// A policy that never retries. Handy for tests that want the first
  /// failure to surface, and for a "no retries on mobile data" toggle
  /// later. [shouldRetry] returns false for every kind, so a caller that
  /// only consults [shouldRetry] (without also checking [maxAttempts])
  /// still gets the no-retry behaviour.
  static final AssistantRetryPolicy noRetry = AssistantRetryPolicy(
    maxAttempts: 1,
    initialDelay: Duration.zero,
    maxDelay: Duration.zero,
    multiplier: 1,
    retryableKinds: const <AssistantErrorKind>{},
  );

  /// True when [kind] is in [retryableKinds].
  ///
  /// `optedOut`, `invalidResponse` and `other` are terminal by default:
  /// retrying an opted-out call is a privacy foot-gun, a schema mismatch
  /// won't fix itself on another round trip, and `other` is a catch-all
  /// we'd rather surface than loop on.
  bool shouldRetry(AssistantErrorKind kind) => retryableKinds.contains(kind);

  /// Convenience: `shouldRetry(e.kind)`. Lets a caller write
  /// `if (policy.shouldRetryException(e) && attempt + 1 < policy.maxAttempts)`
  /// without poking at `.kind`.
  bool shouldRetryException(AssistantException e) => shouldRetry(e.kind);

  /// Delay before the [attempt]-th try, 1-indexed.
  ///
  /// `delayFor(1)` is always zero — the first try happens immediately.
  /// `delayFor(2)` is [initialDelay]. From there each delay is the
  /// previous one multiplied by [multiplier], capped at [maxDelay].
  ///
  /// Throws [ArgumentError] when [attempt] is less than 1 or greater
  /// than [maxAttempts]: a caller asking for a delay beyond the policy's
  /// budget has a bug.
  Duration delayFor(int attempt) {
    if (attempt < 1) {
      throw ArgumentError.value(attempt, 'attempt', 'must be at least 1');
    }
    if (attempt > maxAttempts) {
      throw ArgumentError.value(
        attempt,
        'attempt',
        'must be at most maxAttempts ($maxAttempts)',
      );
    }
    if (attempt == 1) return Duration.zero;
    // Arithmetic in microseconds to keep sub-millisecond multipliers honest
    // and to avoid floating-point drift on long schedules.
    var micros = initialDelay.inMicroseconds;
    for (var i = 2; i < attempt; i++) {
      micros = (micros * multiplier).round();
      if (micros >= maxDelay.inMicroseconds) {
        return maxDelay;
      }
    }
    final capped = micros >= maxDelay.inMicroseconds
        ? maxDelay.inMicroseconds
        : micros;
    return Duration(microseconds: capped);
  }

  /// The full delay sequence, from attempt 1 through [maxAttempts].
  /// Convenience for tests and for a Settings "retry schedule" preview.
  List<Duration> get schedule => [
    for (var i = 1; i <= maxAttempts; i++) delayFor(i),
  ];

  /// A new policy that keeps every field but swaps the ones named.
  /// Mirrors [ModelPolicy.withOverride]'s copy-on-change shape.
  AssistantRetryPolicy copyWith({
    int? maxAttempts,
    Duration? initialDelay,
    Duration? maxDelay,
    num? multiplier,
    Set<AssistantErrorKind>? retryableKinds,
  }) => AssistantRetryPolicy(
    maxAttempts: maxAttempts ?? this.maxAttempts,
    initialDelay: initialDelay ?? this.initialDelay,
    maxDelay: maxDelay ?? this.maxDelay,
    multiplier: multiplier ?? this.multiplier,
    retryableKinds: retryableKinds ?? this.retryableKinds,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AssistantRetryPolicy) return false;
    if (maxAttempts != other.maxAttempts) return false;
    if (initialDelay != other.initialDelay) return false;
    if (maxDelay != other.maxDelay) return false;
    if (multiplier != other.multiplier) return false;
    if (retryableKinds.length != other.retryableKinds.length) return false;
    for (final k in retryableKinds) {
      if (!other.retryableKinds.contains(k)) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    maxAttempts,
    initialDelay,
    maxDelay,
    multiplier,
    Object.hashAllUnordered(retryableKinds),
  );

  @override
  String toString() =>
      'AssistantRetryPolicy(maxAttempts: $maxAttempts, '
      'initialDelay: $initialDelay, maxDelay: $maxDelay, '
      'multiplier: $multiplier, retryableKinds: $retryableKinds)';
}
