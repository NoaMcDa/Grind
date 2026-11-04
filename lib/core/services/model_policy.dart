/// Which Claude model class an assistant intent runs on (epic #38).
///
/// The gateway built in PR #104 keeps intents behind a typed enum; this file
/// defines the orthogonal question of which model class — Haiku for the
/// cheap, latency-sensitive calls, Sonnet for the few that need more
/// reasoning — serves each one. Keeping the two concerns apart means a
/// future intent can be added without touching the model side, and a model
/// swap (Haiku 4 → Haiku 5, Sonnet 4.5 → whatever is next) touches one
/// table only.
///
/// Why strings and not PR #104's `AssistantIntent`: this slice has to land
/// on top of plain `main`, so the policy keys off the intent's name as a
/// stable string identifier. The strings ARE the enum's `.name` values, so
/// once PR #104 merges the gateway does `policy.tierFor(intent.name)` and
/// that is the whole adapter.
///
/// The LLM never picks times. Model choice is cost / quality only.
library;

/// A Claude model class. The policy answers in tiers, not exact model IDs,
/// so swapping `claude-haiku-4` for `claude-haiku-5` (or whatever ships) is
/// a one-line change on the server and a no-op on the client.
enum ModelTier {
  /// Cheap, fast, good enough for short structured outputs:
  /// capture parses and praise copy.
  haiku,

  /// Slower and dearer, for calls that have to read the day's context and
  /// explain it back: plan explanations and anything that would embarrass
  /// us in Haiku.
  sonnet,
}

/// Raised when an intent key doesn't have a tier mapped. Kept as a typed
/// exception rather than an assert so a stray server rename surfaces as a
/// handleable error instead of a release-mode silent fallback.
class UnknownIntentException implements Exception {
  const UnknownIntentException(this.intent);

  final String intent;

  @override
  String toString() => 'UnknownIntentException: no tier for intent "$intent"';
}

/// Maps an intent name to the [ModelTier] that should serve it.
///
/// Pure, no dependencies. The default instance
/// carries the epic's policy — Haiku for `capture` and `praise`, Sonnet for
/// `planExplanation`. Tests and future intents can pass a custom map.
///
/// The policy is a value type: two instances built from the same map are
/// equal, so tests can compare whole policies without poking at internals.
class ModelPolicy {
  /// Builds a policy from an explicit mapping. The map is copied so the
  /// caller can't mutate it after construction.
  ModelPolicy(Map<String, ModelTier> mapping)
    : _mapping = Map.unmodifiable(mapping);

  /// The policy the epic specifies:
  /// * `capture` and `praise` → Haiku (cheap, high-volume, short output)
  /// * `planExplanation` → Sonnet (a paragraph that has to read context)
  ///
  /// Intent keys mirror PR #104's `AssistantIntent.name` values so the
  /// gateway can pass `intent.name` straight through.
  static const Map<String, ModelTier> defaultMapping = {
    'capture': ModelTier.haiku,
    'praise': ModelTier.haiku,
    'planExplanation': ModelTier.sonnet,
  };

  /// The policy wired into the assistant by default.
  static final ModelPolicy defaults = ModelPolicy(defaultMapping);

  final Map<String, ModelTier> _mapping;

  /// Every intent the policy knows about, in insertion order. Handy for
  /// the Settings "what runs on which model" copy and for tests that want
  /// to assert the policy covers exactly the intents the gateway speaks.
  Iterable<String> get intents => _mapping.keys;

  /// Returns the tier for [intent], or throws [UnknownIntentException]
  /// when there is no mapping. Callers that want a soft fallback can use
  /// [tierForOr].
  ModelTier tierFor(String intent) {
    final tier = _mapping[intent];
    if (tier == null) throw UnknownIntentException(intent);
    return tier;
  }

  /// Like [tierFor] but returns [fallback] instead of throwing. Intended
  /// for telemetry or cost estimation paths that should never blow up on
  /// an unrecognised intent.
  ModelTier tierForOr(String intent, {required ModelTier fallback}) =>
      _mapping[intent] ?? fallback;

  /// True when [intent] is in the policy. Prefer this over catching the
  /// exception from [tierFor] when the caller is already planning the
  /// recovery path.
  bool knows(String intent) => _mapping.containsKey(intent);

  /// A new policy with [intent] mapped to [tier]. Existing entries are
  /// preserved; [intent] is overwritten if already present. The receiver
  /// is unchanged.
  ModelPolicy withOverride(String intent, ModelTier tier) =>
      ModelPolicy({..._mapping, intent: tier});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ModelPolicy) return false;
    if (_mapping.length != other._mapping.length) return false;
    for (final entry in _mapping.entries) {
      if (other._mapping[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAllUnordered(
    _mapping.entries.map((e) => Object.hash(e.key, e.value)),
  );

  @override
  String toString() => 'ModelPolicy($_mapping)';
}
