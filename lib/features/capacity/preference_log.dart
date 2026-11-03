import 'dart:convert';

import 'json_doc_store.dart';

/// One manual override, as a pairwise preference: the user put task A above
/// task B. Both feature vectors are kept (the scheduler's score terms plus
/// size and due distance) so a future learned ranker (research §6, v3) can
/// train on them without replaying history.
class PairwisePreference {
  const PairwisePreference({
    required this.winnerId,
    required this.loserId,
    required this.winnerFeatures,
    required this.loserFeatures,
    required this.at,
    this.source = 'drag',
  });

  /// The task the user ranked higher.
  final String winnerId;
  final String loserId;
  final Map<String, double> winnerFeatures;
  final Map<String, double> loserFeatures;
  final DateTime at;

  /// `'drag'` (reordered) or `'pin'` (pin changed).
  final String source;

  Map<String, Object?> toJson() => {
    'winner': winnerId,
    'loser': loserId,
    'winnerFeatures': winnerFeatures,
    'loserFeatures': loserFeatures,
    'at': at.toUtc().toIso8601String(),
    'source': source,
  };

  factory PairwisePreference.fromJson(Map<String, Object?> j) {
    Map<String, double> f(Object? v) => {
      for (final e in (v as Map).entries)
        e.key as String: (e.value as num).toDouble(),
    };
    return PairwisePreference(
      winnerId: j['winner'] as String,
      loserId: j['loser'] as String,
      winnerFeatures: f(j['winnerFeatures']),
      loserFeatures: f(j['loserFeatures']),
      at: DateTime.parse(j['at'] as String).toUtc(),
      source: (j['source'] as String?) ?? 'drag',
    );
  }
}

/// Append-only log of manual overrides.
abstract interface class PreferenceLog {
  Future<void> record(PairwisePreference preference);
  Future<List<PairwisePreference>> all();
}

class InMemoryPreferenceLog implements PreferenceLog {
  final List<PairwisePreference> entries = [];

  @override
  Future<void> record(PairwisePreference preference) async =>
      entries.add(preference);

  @override
  Future<List<PairwisePreference>> all() async => List.unmodifiable(entries);
}

/// The log as one JSON document in a [JsonDocStore], newest last, capped at
/// [maxEntries] (oldest dropped).
class JsonPreferenceLog implements PreferenceLog {
  JsonPreferenceLog(this._store, {this.maxEntries = 2000});

  static const docName = 'preference_log';

  final JsonDocStore _store;
  final int maxEntries;
  List<PairwisePreference>? _cache;

  @override
  Future<List<PairwisePreference>> all() async {
    final cached = _cache;
    if (cached != null) return List.unmodifiable(cached);
    final raw = await _store.read(docName);
    var list = <PairwisePreference>[];
    if (raw != null) {
      try {
        list = [
          for (final e in jsonDecode(raw) as List)
            PairwisePreference.fromJson((e as Map).cast<String, Object?>()),
        ];
      } catch (_) {
        list = [];
      }
    }
    return List.unmodifiable(_cache = list);
  }

  @override
  Future<void> record(PairwisePreference preference) async {
    final list = [...await all(), preference];
    final kept = list.length > maxEntries
        ? list.sublist(list.length - maxEntries)
        : list;
    _cache = kept;
    await _store.write(docName, jsonEncode([for (final p in kept) p.toJson()]));
  }
}
