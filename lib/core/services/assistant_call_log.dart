/// Intent + latency logger for the assistant gateway (epic #38).
///
/// The epic calls for "logging of intents and latency (no content) for
/// tuning". This file is the pure-Dart piece of that: an immutable
/// [AssistantCallMetric] value object and an in-memory ring buffer
/// [AssistantCallLog] the gateway writes to on every call it finishes.
///
/// The invariant this slice holds the line on is **no content, ever**:
/// no prompt text, no response text, no user id, no task title. Only the
/// intent name, the model tier that served it, how long it took, and
/// whether it succeeded or which [AssistantErrorKind] it failed with.
/// A later PR under epic #38 wires a real sink for this (counters shipped
/// to our analytics backend, or a local developer overlay); keeping the
/// contract tight here means that sink can't accidentally widen the
/// payload.
///
/// Pure in-memory, pure Dart, no timers, no I/O. The gateway owns the
/// clock; this log just records what it is handed.
library;

import 'package:flutter/foundation.dart';

import 'assistant_gateway.dart';
import 'model_policy.dart';

/// Whether a logged call reached a usable response.
///
/// Kept deliberately small — two outcomes, plus the optional
/// [AssistantCallMetric.errorKind] for the failure reason — so a reader
/// doesn't have to learn a new taxonomy. Callers pivot on
/// [AssistantErrorKind] when they need detail.
enum AssistantCallOutcome { success, failed }

/// One row in the assistant's latency log.
///
/// Every field is a scalar: no maps, no lists, no free-form strings. The
/// [intent] mirrors [AssistantIntent.name] so the row joins cleanly with
/// [ModelPolicy] without taking a hard dependency on the enum. [tier] is
/// null for a call that never reached a model (e.g. the caller was opted
/// out, or the budget tracker refused the spend before the HTTP layer).
@immutable
class AssistantCallMetric {
  AssistantCallMetric({
    required this.intent,
    required this.latency,
    required this.outcome,
    required this.startedAt,
    this.tier,
    this.errorKind,
  }) {
    if (intent.isEmpty) {
      throw ArgumentError.value(intent, 'intent', 'must be non-empty');
    }
    if (latency.isNegative) {
      throw ArgumentError.value(latency, 'latency', 'must be non-negative');
    }
    if (!startedAt.isUtc) {
      throw ArgumentError.value(startedAt, 'startedAt', 'must be UTC');
    }
    if (outcome == AssistantCallOutcome.success && errorKind != null) {
      throw ArgumentError.value(
        errorKind,
        'errorKind',
        'must be null on a successful call',
      );
    }
    if (outcome == AssistantCallOutcome.failed && errorKind == null) {
      throw ArgumentError.value(
        errorKind,
        'errorKind',
        'must be set on a failed call',
      );
    }
  }

  /// The intent name, as [AssistantIntent.name]. A plain [String] so this
  /// value object does not depend on the gateway's enum at compile time.
  final String intent;

  /// The model class that served the call. Null when the call never
  /// reached a model (opted out, budget refused, request shaped wrong
  /// before the gateway looked at the policy).
  final ModelTier? tier;

  /// Wall-clock latency from gateway entry to the response landing (or
  /// the failure being raised). Always non-negative.
  final Duration latency;

  /// Did the call return a usable response, or did it raise?
  final AssistantCallOutcome outcome;

  /// Failure reason. Set exactly when [outcome] is
  /// [AssistantCallOutcome.failed]; null otherwise.
  final AssistantErrorKind? errorKind;

  /// When the call started, in UTC. UTC keeps the log a technical audit
  /// record rather than a user-facing timeline.
  final DateTime startedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssistantCallMetric &&
          intent == other.intent &&
          tier == other.tier &&
          latency == other.latency &&
          outcome == other.outcome &&
          errorKind == other.errorKind &&
          startedAt == other.startedAt;

  @override
  int get hashCode =>
      Object.hash(intent, tier, latency, outcome, errorKind, startedAt);

  @override
  String toString() =>
      'AssistantCallMetric(intent: $intent, tier: ${tier?.name}, '
      'latency: $latency, outcome: ${outcome.name}, '
      'errorKind: ${errorKind?.name}, startedAt: $startedAt)';
}

/// In-memory ring buffer of [AssistantCallMetric]s, newest first. Fires
/// listeners on every [record] and [clear] so a developer overlay can
/// rebuild without polling.
///
/// Deliberately storage-agnostic — no Drift, no SharedPreferences, no
/// network. This slice is the data model and the aggregate helpers; a
/// later sibling wires the sink that ships these counters off-device.
///
/// Aggregate helpers ([averageLatency], [countBy], [successRate]) are
/// cheap linear scans over the buffer. They are useful enough for a
/// developer overlay or a test and small enough that pre-indexing would
/// be premature.
class AssistantCallLog extends ChangeNotifier {
  /// [capacity] is the maximum number of entries kept at once; recording
  /// past it drops the oldest entry.
  AssistantCallLog({this.capacity = 100})
    : assert(capacity > 0, 'capacity must be positive');

  /// Maximum number of entries. Older entries are dropped on [record]
  /// once the log exceeds this count. 100 is enough for a developer
  /// overlay to show the last session's traffic without holding onto a
  /// full day's calls.
  final int capacity;

  final List<AssistantCallMetric> _entries = <AssistantCallMetric>[];

  /// All entries in the log, newest first. The returned list is an
  /// unmodifiable snapshot — mutate the log through [record] and [clear].
  List<AssistantCallMetric> get entries => List.unmodifiable(_entries);

  /// Current number of entries, 0 through [capacity].
  int get length => _entries.length;

  /// True when the log holds no entries.
  bool get isEmpty => _entries.isEmpty;

  /// True when the log has at least one entry.
  bool get isNotEmpty => _entries.isNotEmpty;

  /// Appends [metric] to the front of the log and notifies listeners.
  /// When the log exceeds [capacity] the oldest entry is dropped — the
  /// buffer is a tuning aid, not persistence.
  void record(AssistantCallMetric metric) {
    _entries.insert(0, metric);
    if (_entries.length > capacity) {
      _entries.removeLast();
    }
    notifyListeners();
  }

  /// Removes every entry. Listeners fire only when the log was not
  /// already empty, so a developer overlay's "clear" button is cheap
  /// to spam.
  void clear() {
    if (_entries.isEmpty) return;
    _entries.clear();
    notifyListeners();
  }

  /// Entries matching the given filters, newest first.
  ///
  /// Passing `null` for a filter leaves that axis unfiltered. The
  /// returned list is a fresh copy; mutating it does not touch the log.
  List<AssistantCallMetric> where({
    String? intent,
    ModelTier? tier,
    AssistantCallOutcome? outcome,
  }) => [
    for (final e in _entries)
      if ((intent == null || e.intent == intent) &&
          (tier == null || e.tier == tier) &&
          (outcome == null || e.outcome == outcome))
        e,
  ];

  /// Number of entries matching the given filters.
  int countBy({
    String? intent,
    ModelTier? tier,
    AssistantCallOutcome? outcome,
  }) {
    var n = 0;
    for (final e in _entries) {
      if (intent != null && e.intent != intent) continue;
      if (tier != null && e.tier != tier) continue;
      if (outcome != null && e.outcome != outcome) continue;
      n++;
    }
    return n;
  }

  /// Mean latency across entries matching the given filters, or null
  /// when no entry matches. Arithmetic in microseconds so a long tail
  /// of sub-millisecond calls doesn't round to zero.
  Duration? averageLatency({
    String? intent,
    ModelTier? tier,
    AssistantCallOutcome? outcome,
  }) {
    var total = 0;
    var n = 0;
    for (final e in _entries) {
      if (intent != null && e.intent != intent) continue;
      if (tier != null && e.tier != tier) continue;
      if (outcome != null && e.outcome != outcome) continue;
      total += e.latency.inMicroseconds;
      n++;
    }
    if (n == 0) return null;
    return Duration(microseconds: total ~/ n);
  }

  /// Fraction of calls matching the given intent / tier filter that
  /// succeeded, in `0.0..1.0`. Null when no matching entry exists — a
  /// zero-denominator success rate is a trap, not a number.
  double? successRate({String? intent, ModelTier? tier}) {
    var matched = 0;
    var ok = 0;
    for (final e in _entries) {
      if (intent != null && e.intent != intent) continue;
      if (tier != null && e.tier != tier) continue;
      matched++;
      if (e.outcome == AssistantCallOutcome.success) ok++;
    }
    if (matched == 0) return null;
    return ok / matched;
  }
}
