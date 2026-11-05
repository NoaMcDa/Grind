/// Output value object for the "I'm stuck" helper (epic #41).
///
/// Pairs with [UnstickRequest]: the suggester (offline) and the LLM path
/// (#38) both return an [UnstickResponse] so the chat UI builds the pill
/// row from one shape regardless of which backend answered.
///
/// It bundles the praise-free acknowledgement Pip opens with, the 1-3
/// structured [UnstickOption]s to render as pills, and a [source] tag the
/// UI and logs can use to tell offline fallbacks apart from LLM answers.
/// It has no Flutter, no gateway types and no clock reads, so unit tests
/// and both paths produce it the same way.
library;

import 'package:flutter/foundation.dart';

import 'unstick_option.dart';

/// Where an [UnstickResponse] was produced.
enum UnstickSource {
  /// Built on-device by the static suggester — no network, no LLM.
  offline,

  /// Returned by the cloud assistant (#38).
  llm,
}

/// The reply to an "I'm stuck" ask: an acknowledgement plus 1-3 options.
///
/// Instances are immutable value objects: same inputs compare equal, which
/// lets the chat layer de-duplicate a repeated ask without re-rendering
/// the pills.
@immutable
class UnstickResponse {
  UnstickResponse({
    required this.acknowledgement,
    required List<UnstickOption> options,
    this.source = UnstickSource.offline,
  }) : options = List<UnstickOption>.unmodifiable(options),
       assert(acknowledgement != '', 'acknowledgement must not be empty'),
       assert(options.isNotEmpty, 'options must not be empty'),
       assert(options.length <= 3, 'options must be at most 3');

  /// The one-line, praise-free opener Pip says above the pill row.
  /// Tone rules (#117): acknowledges what the user said, no judgement.
  final String acknowledgement;

  /// 1-3 pill-ready [UnstickOption]s. The order is the render order; the
  /// static suggester places `firstAction` last as the safety net, and the
  /// LLM path is expected to do the same.
  final List<UnstickOption> options;

  /// Where this response came from. The UI uses it to annotate logs and
  /// to decide whether to disclose "offline suggestions" in the pill row.
  final UnstickSource source;

  /// Serialised shape the LLM path returns over the wire.
  Map<String, Object?> toJson() => {
    'acknowledgement': acknowledgement,
    'options': options.map((o) => o.toJson()).toList(),
    'source': source.name,
  };

  /// Parses a JSON map the gateway or a persisted log returns. Returns
  /// null on any structural problem — callers decide whether to surface
  /// an error or fall back to the static suggester.
  static UnstickResponse? fromJson(Object? json) {
    if (json is! Map) return null;
    final j = json.cast<String, Object?>();
    final ack = j['acknowledgement'];
    if (ack is! String || ack.isEmpty) return null;

    final rawOptions = j['options'];
    if (rawOptions is! List || rawOptions.isEmpty) return null;
    final parsed = <UnstickOption>[];
    for (final entry in rawOptions) {
      final option = UnstickOption.fromJson(entry);
      if (option != null) parsed.add(option);
    }
    if (parsed.isEmpty || parsed.length > 3) return null;

    final sourceName = j['source'];
    final source = UnstickSource.values.firstWhere(
      (s) => s.name == sourceName,
      orElse: () => UnstickSource.offline,
    );

    return UnstickResponse(
      acknowledgement: ack,
      options: parsed,
      source: source,
    );
  }

  /// Returns a copy with one or more fields replaced.
  UnstickResponse copyWith({
    String? acknowledgement,
    List<UnstickOption>? options,
    UnstickSource? source,
  }) => UnstickResponse(
    acknowledgement: acknowledgement ?? this.acknowledgement,
    options: options ?? this.options,
    source: source ?? this.source,
  );

  @override
  bool operator ==(Object other) =>
      other is UnstickResponse &&
      other.acknowledgement == acknowledgement &&
      other.source == source &&
      listEquals(other.options, options);

  @override
  int get hashCode =>
      Object.hash(acknowledgement, source, Object.hashAll(options));

  @override
  String toString() =>
      'UnstickResponse(${source.name}, ack: "$acknowledgement", '
      'options: ${options.length})';
}
