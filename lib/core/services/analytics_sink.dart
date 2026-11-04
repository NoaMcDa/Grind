/// A pure-Dart analytics seam for epic #49 ("web deployment").
///
/// The epic's scope lists "basic analytics (privacy-respecting, e.g.
/// Plausible) and error reporting". This file does NOT ship any backend
/// yet. It only shapes the seam so that whoever wires Plausible (or any
/// other sink) later has a drop-in surface and the call sites don't have
/// to be rewritten.
///
/// Privacy stance (keep in sync with `docs/privacy.md`):
///
///   > Grind has no analytics, no advertising and no crash reporting
///   > service.
///
/// That remains true today because the default sink is [NoopAnalyticsSink]
/// and nothing in the app currently constructs anything else. Any PR that
/// wires a real backend MUST update `docs/privacy.md` in the same change.
///
/// Design notes:
///   * Fire-and-forget: [AnalyticsSink.record] returns `void`, never
///     throws, and never blocks the UI. A sink that talks to the network
///     buffers internally; a failing network must not surface here.
///   * Property values are constrained to JSON-ish scalars (string, int,
///     double, bool, null) so a backend can serialise them without
///     reflection. Anything else is a programming error: catch it at the
///     factory ([AnalyticsEvent.of]) rather than at send time.
///   * No PII by convention: event names are snake_case verbs ("task_done",
///     "plan_drafted"), properties describe the action ("source": "widget",
///     "has_deadline": true), never free-form user text. The seam does not
///     police this — reviewers do.
library;

/// JSON-ish scalar types an analytics property value may hold.
///
/// Enforced at construction time by [AnalyticsEvent.of] so the backend
/// side can assume the map is serialisable.
bool _isAllowedPropertyValue(Object? v) =>
    v == null || v is String || v is num || v is bool;

/// Raised when an [AnalyticsEvent] is built with a property whose value
/// is not a JSON-ish scalar. A typed exception, not an assert, so a bug
/// in release-mode code surfaces as a handleable error instead of being
/// silently dropped.
class InvalidAnalyticsPropertyException implements Exception {
  const InvalidAnalyticsPropertyException(this.key, this.value);

  final String key;
  final Object? value;

  @override
  String toString() =>
      'InvalidAnalyticsPropertyException: property "$key" has '
      'non-scalar value of type ${value.runtimeType}';
}

/// A single analytics event: a name plus optional scalar properties.
///
/// Value type. Two events with the same name and the same property map
/// are equal, which keeps test assertions simple
/// (`expect(sink.events, [AnalyticsEvent.of('task_done')])`).
class AnalyticsEvent {
  /// Preferred constructor. Validates and copies [properties] so the
  /// caller can't mutate it after construction. See
  /// [InvalidAnalyticsPropertyException] for the allowed value types.
  factory AnalyticsEvent.of(
    String name, {
    Map<String, Object?> properties = const {},
  }) {
    for (final entry in properties.entries) {
      if (!_isAllowedPropertyValue(entry.value)) {
        throw InvalidAnalyticsPropertyException(entry.key, entry.value);
      }
    }
    return AnalyticsEvent._(name, Map.unmodifiable(properties));
  }

  const AnalyticsEvent._(this.name, this.properties);

  /// The event name. Convention: snake_case verb phrase describing what
  /// happened ("task_done", "plan_drafted", "widget_tapped").
  final String name;

  /// Scalar properties describing the event. Never includes user-authored
  /// free text; see the privacy note at the top of this file.
  final Map<String, Object?> properties;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AnalyticsEvent) return false;
    if (name != other.name) return false;
    if (properties.length != other.properties.length) return false;
    for (final entry in properties.entries) {
      if (!other.properties.containsKey(entry.key)) return false;
      if (other.properties[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    name,
    Object.hashAllUnordered(
      properties.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );

  @override
  String toString() => properties.isEmpty
      ? 'AnalyticsEvent($name)'
      : 'AnalyticsEvent($name, $properties)';
}

/// Where analytics events go. The seam that decouples call sites from
/// any particular backend (Plausible, PostHog, a server endpoint, or
/// nothing at all).
///
/// Implementations MUST NOT throw. A sink that fails to deliver an event
/// should drop it silently; analytics are never load-bearing.
abstract interface class AnalyticsSink {
  /// Record [event]. Fire-and-forget. Returns immediately.
  void record(AnalyticsEvent event);
}

/// The default sink: drops every event. Keeps the privacy promise in
/// `docs/privacy.md` ("no analytics") true as long as no other sink is
/// constructed in app code.
///
/// Use this as the default wherever an [AnalyticsSink] is needed so
/// feature code can call `sink.record(...)` unconditionally without a
/// null check.
class NoopAnalyticsSink implements AnalyticsSink {
  const NoopAnalyticsSink();

  @override
  void record(AnalyticsEvent event) {
    // Deliberately empty. See class doc.
  }
}

/// An in-memory sink that keeps every event it receives, in order.
/// Intended for tests: a feature can pass one in and assert the events
/// it emitted without wiring a mock framework.
///
/// Not for production: the buffer grows without bound, and nothing reads
/// it. Prefer [NoopAnalyticsSink] in app code.
class BufferedAnalyticsSink implements AnalyticsSink {
  BufferedAnalyticsSink();

  final List<AnalyticsEvent> _events = [];

  /// Every event recorded on this sink, oldest first. Returned as an
  /// unmodifiable view so tests can `expect(sink.events, [...])` without
  /// accidentally mutating the buffer.
  List<AnalyticsEvent> get events => List.unmodifiable(_events);

  /// Drops every buffered event. Useful between phases of a test.
  void clear() => _events.clear();

  @override
  void record(AnalyticsEvent event) => _events.add(event);
}
