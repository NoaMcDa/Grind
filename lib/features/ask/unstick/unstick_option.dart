/// "I'm stuck" helper (epic #41).
///
/// A structured option Pip offers when the user says something like
/// *"I'm behind on my thesis, help"*. The assistant returns 1–3 of these
/// as pill buttons in the chat; choosing one later runs the matching tool
/// call (#42) against the scheduler or task layer.
///
/// This file is the shared data model and the tone-rule copy constants.
/// It has no dependency on the LLM gateway (#38) or the tool layer (#42),
/// and no Flutter widgets, so both the online and offline paths — plus
/// unit tests — can build an option the same way.
library;

import 'package:flutter/foundation.dart';

/// What an [UnstickOption] proposes.
enum UnstickKind {
  /// Break a long task into two shorter blocks on the same day.
  split,

  /// Keep one block, but make it shorter.
  shorten,

  /// Leave the length alone, move it to a different time.
  reschedule,

  /// Do a tiny first step right now (open the file, two minutes).
  firstAction,
}

/// One concrete, confirmable suggestion for an "I'm stuck" ask.
///
/// All fields are small and JSON-friendly so the same shape is cheap to
/// send over the wire (when the LLM path lands) and cheap to produce
/// offline. The scheduler, not the assistant, decides exact clock times;
/// [parameters] carries only the hints a tool call will need.
@immutable
class UnstickOption {
  const UnstickOption({
    required this.kind,
    required this.title,
    required this.humanRationale,
    this.parameters = const <String, Object?>{},
  });

  /// What this option would do.
  final UnstickKind kind;

  /// The short label for the pill button ("Two 25-min blocks").
  final String title;

  /// One sentence Pip says next to the pill ("Easier to start than one
  /// long block."). Tone rules: no praise, no judgement, no exclamation.
  final String humanRationale;

  /// Opaque hints the tool call layer (#42) will read:
  ///
  /// * `split`: `{ 'chunkMinutes': int, 'chunks': int }`
  /// * `shorten`: `{ 'minutes': int }`
  /// * `reschedule`: `{ 'when': 'later-today' | 'tomorrow' | 'evening' }`
  /// * `firstAction`: `{ 'minutes': int, 'label': String }`
  ///
  /// Kept as a plain map on purpose: this slice does not depend on the
  /// scheduler's task-draft types.
  final Map<String, Object?> parameters;

  /// Serialised shape used when the LLM path returns these over the wire.
  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'title': title,
    'humanRationale': humanRationale,
    if (parameters.isNotEmpty) 'parameters': parameters,
  };

  static UnstickOption? fromJson(Object? json) {
    if (json is! Map) return null;
    final j = json.cast<String, Object?>();
    final kind = UnstickKind.values.firstWhere(
      (k) => k.name == j['kind'],
      orElse: () => UnstickKind.firstAction,
    );
    final title = j['title'];
    final rationale = j['humanRationale'];
    if (title is! String || rationale is! String) return null;
    final params = j['parameters'];
    return UnstickOption(
      kind: kind,
      title: title,
      humanRationale: rationale,
      parameters: params is Map
          ? Map<String, Object?>.from(params.cast<String, Object?>())
          : const <String, Object?>{},
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UnstickOption &&
      other.kind == kind &&
      other.title == title &&
      other.humanRationale == humanRationale &&
      mapEquals(other.parameters, parameters);

  @override
  int get hashCode => Object.hash(
    kind,
    title,
    humanRationale,
    Object.hashAllUnordered(
      parameters.entries.map((e) => '${e.key}=${e.value}'),
    ),
  );

  @override
  String toString() => 'UnstickOption(${kind.name}, "$title")';
}

/// Praise-free, judgement-free copy used by the offline fallback and the
/// assistant prompt (epic #41 scope: *"no judgement, acknowledge, then one
/// small step"*). Kept as code constants, not ARB entries, so the slice
/// stays off the shared l10n file while sibling workers edit it.
///
/// Both locales ship the same options; the LLM path will replace these at
/// runtime with context-aware lines in the user's language.
class UnstickTone {
  const UnstickTone._();

  /// The one-line acknowledgement Pip opens with. Never starts with
  /// "Great" or "Nice" — only acknowledges what the user said.
  static const acknowledgeEn = "That's a lot. Let's make it smaller.";
  static const acknowledgeHe = 'זה הרבה. בוא נעשה את זה קטן יותר.';

  /// English pill labels and rationales, by kind.
  static const splitTitleEn = 'Two short blocks';
  static const splitRationaleEn = 'Easier to start than one long block.';

  static const shortenTitleEn = 'Just 15 minutes';
  static const shortenRationaleEn = 'A short start still counts.';

  static const rescheduleTitleEn = 'Move to tomorrow';
  static const rescheduleRationaleEn = 'Pick a fresh time, same length.';

  static const firstActionTitleEn = 'Open the file for 2 min';
  static const firstActionRationaleEn = 'Just the first step, nothing more.';

  /// Hebrew pill labels and rationales, by kind.
  static const splitTitleHe = 'שני בלוקים קצרים';
  static const splitRationaleHe = 'קל יותר להתחיל מבלוק אחד ארוך.';

  static const shortenTitleHe = 'רק 15 דקות';
  static const shortenRationaleHe = 'התחלה קצרה גם נחשבת.';

  static const rescheduleTitleHe = 'להעביר למחר';
  static const rescheduleRationaleHe = 'זמן חדש, אותו אורך.';

  static const firstActionTitleHe = 'לפתוח את הקובץ ל־2 דקות';
  static const firstActionRationaleHe = 'רק הצעד הראשון, לא יותר.';
}
