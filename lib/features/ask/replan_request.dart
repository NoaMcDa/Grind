import 'dart:ui' show Locale;

/// A structured change a user asked for in free-text chat against today's
/// plan. Pre-tool-call: this layer only surfaces the user's intent, it
/// never invokes the scheduler or a [ToolCall] — the assistant executor
/// (see `lib/features/ask/tools/tool_call.dart`) takes a [ReplanRequest]
/// and turns it into the appropriate [MoveTaskCall] / [ReplanCall] after
/// matching [taskReference] to a real task.
///
/// Two shapes cover the common cases in epic #40's unchecked scope box
/// ("changes requested in chat are translated to tool calls"):
/// [MoveTaskDirection] — shift a named task earlier or later in the day —
/// and [DropTaskFromToday] — take a named task off today's plan. Picking
/// a specific clock time ("move gym to 09:00") is intentionally not
/// handled here: the free-text input never carries a dependable absolute
/// time, and the scheduler's slot logic already picks one from the
/// direction nudge.
sealed class ReplanRequest {
  const ReplanRequest();

  /// The unresolved phrase the user used to name a task. Already trimmed
  /// and lower-cased; the caller matches it against the day's tasks by
  /// title with its own heuristic (same contract as
  /// `AskIntentMatch.taskReference`).
  String get taskReference;
}

/// Which way to nudge a placed task along the day's timeline.
enum MoveDirection { earlier, later }

/// "Move {task} earlier" / "move {task} later" — the two deterministic
/// directional nudges. The executor translates this to a [MoveTaskCall]
/// using the scheduler's free slots (see `DayDraft.move`).
class MoveTaskDirection extends ReplanRequest {
  const MoveTaskDirection(this.taskReference, this.direction);

  @override
  final String taskReference;
  final MoveDirection direction;

  @override
  bool operator ==(Object other) =>
      other is MoveTaskDirection &&
      other.taskReference == taskReference &&
      other.direction == direction;

  @override
  int get hashCode => Object.hash(taskReference, direction);

  @override
  String toString() => 'MoveTaskDirection("$taskReference", $direction)';
}

/// "Drop {task} from today" / "take {task} off today" — ask the
/// scheduler to leave this task for another day. The executor turns
/// this into a re-plan with the task's row removed from the open set
/// for today.
class DropTaskFromToday extends ReplanRequest {
  const DropTaskFromToday(this.taskReference);

  @override
  final String taskReference;

  @override
  bool operator ==(Object other) =>
      other is DropTaskFromToday && other.taskReference == taskReference;

  @override
  int get hashCode => taskReference.hashCode;

  @override
  String toString() => 'DropTaskFromToday("$taskReference")';
}

/// Routes a free-text Ask Pip prompt to a [ReplanRequest]. Pure,
/// deterministic and offline; mirrors the style of
/// `classifyAskPrompt` so the two classifiers compose cleanly.
///
/// [locale] picks the phrase table. Only `he` is treated as Hebrew;
/// every other language uses the English table. Returns null when the
/// prompt matches no re-plan phrase — the caller can then try the
/// intent classifier or route to the model.
ReplanRequest? classifyReplanRequest(String prompt, {Locale? locale}) {
  final cleaned = _normalize(prompt);
  if (cleaned.isEmpty) return null;

  final lang = (locale?.languageCode ?? 'en') == 'he' ? 'he' : 'en';
  final rules = lang == 'he' ? _heRules : _enRules;
  for (final r in rules) {
    final m = r.pattern.firstMatch(cleaned);
    if (m == null) continue;
    final ref = _extractRef(m, lang);
    if (ref == null) continue;
    return r.build(ref);
  }
  return null;
}

String _normalize(String s) {
  // Collapse whitespace and strip trailing sentence punctuation so
  // "Move gym earlier!" and "move gym earlier" match the same rule.
  final lower = s.toLowerCase().trim();
  final squeezed = lower.replaceAll(RegExp(r'\s+'), ' ');
  return squeezed.replaceAll(RegExp(r'[?!.,:;]+$'), '').trim();
}

String? _extractRef(Match m, String lang) {
  if (m.groupCount < 1) return null;
  final raw = m.group(1);
  if (raw == null) return null;
  var trimmed = raw.trim();
  // Drop a leading article so "the gym" and "gym" normalize the same
  // way (matches the extractor in `ask_intent.dart`).
  final article = lang == 'he' ? RegExp(r'^(ה)') : RegExp(r'^(the|a|an|my) ');
  trimmed = trimmed.replaceFirst(article, '').trim();
  trimmed = trimmed.replaceAll(RegExp(r'[?!.,:;]+$'), '').trim();
  return trimmed.isEmpty ? null : trimmed;
}

class _Rule {
  const _Rule(this.pattern, this.build);
  final RegExp pattern;

  /// Builds the typed [ReplanRequest] from the already-extracted task
  /// reference.
  final ReplanRequest Function(String ref) build;
}

// English phrase table. Rules are tried in order; the first match wins,
// so more specific patterns go first. All grouping is non-capturing
// except for group 1, which is the task reference.
final List<_Rule> _enRules = [
  // Drop from today — before move so "take gym off today" never
  // tries the move patterns first.
  _Rule(
    RegExp(r'^(?:drop|remove) (.+?) from (?:today|the plan|my plan)$'),
    (ref) => DropTaskFromToday(ref),
  ),
  _Rule(
    RegExp(r'^take (.+?) off (?:today|the plan|my plan)$'),
    (ref) => DropTaskFromToday(ref),
  ),
  _Rule(RegExp(r"^i can'?t do (.+?) today$"), (ref) => DropTaskFromToday(ref)),
  _Rule(RegExp(r'^skip (.+?) today$'), (ref) => DropTaskFromToday(ref)),

  // Move earlier.
  _Rule(
    RegExp(r'^move (.+?) earlier$'),
    (ref) => MoveTaskDirection(ref, MoveDirection.earlier),
  ),
  _Rule(
    RegExp(r'^(?:push|bump|shift) (.+?) earlier$'),
    (ref) => MoveTaskDirection(ref, MoveDirection.earlier),
  ),
  _Rule(
    RegExp(r'^(?:do|start) (.+?) earlier$'),
    (ref) => MoveTaskDirection(ref, MoveDirection.earlier),
  ),
  _Rule(
    RegExp(r'^(.+?) (?:is )?too late$'),
    (ref) => MoveTaskDirection(ref, MoveDirection.earlier),
  ),

  // Move later.
  _Rule(
    RegExp(r'^move (.+?) later$'),
    (ref) => MoveTaskDirection(ref, MoveDirection.later),
  ),
  _Rule(
    RegExp(r'^(?:push|bump|shift) (.+?) later$'),
    (ref) => MoveTaskDirection(ref, MoveDirection.later),
  ),
  _Rule(
    RegExp(r'^(?:do|start) (.+?) later$'),
    (ref) => MoveTaskDirection(ref, MoveDirection.later),
  ),
  _Rule(
    RegExp(r'^(.+?) (?:is )?too early$'),
    (ref) => MoveTaskDirection(ref, MoveDirection.later),
  ),
];

// Hebrew phrase table. ASCII word boundary (`\b`) does not match
// Hebrew, so patterns end with `$` or `(?: |$)` instead; same
// convention as `ask_intent.dart`. The leading `ה` article is stripped
// by [_extractRef], so "הגים" and "גים" produce the same reference.
final List<_Rule> _heRules = [
  // Drop from today — before move patterns.
  _Rule(
    RegExp(r'^(?:הורד|תוריד|תורידי|הורידו) (.+?) מ(?:היום|התוכנית)$'),
    (ref) => DropTaskFromToday(ref),
  ),
  _Rule(
    RegExp(r'^(?:דלג|דלגי) על (.+?) היום$'),
    (ref) => DropTaskFromToday(ref),
  ),
  _Rule(
    RegExp(r'^(?:אני )?לא יכול(?:ה)? (.+?) היום$'),
    (ref) => DropTaskFromToday(ref),
  ),

  // Imperatives come first so "הזז גים מאוחר" (an "earlier"-colour
  // imperative with מאוחר as the direction word) does not trip the
  // bare "X מאוחר" rule below.
  _Rule(
    RegExp(r'^(?:הזז|תזיז|תזיזי|הזיזו) (.+?) (?:יותר )?מוקדם(?: יותר)?$'),
    (ref) => MoveTaskDirection(ref, MoveDirection.earlier),
  ),
  _Rule(
    RegExp(r'^(?:הזז|תזיז|תזיזי|הזיזו) (.+?) (?:יותר )?מאוחר(?: יותר)?$'),
    (ref) => MoveTaskDirection(ref, MoveDirection.later),
  ),

  // "X מאוחר" nudges earlier; "X מוקדם" nudges later.
  _Rule(
    RegExp(r'^(.+?) (?:כל כך )?מאוחר$'),
    (ref) => MoveTaskDirection(ref, MoveDirection.earlier),
  ),
  _Rule(
    RegExp(r'^(.+?) (?:כל כך )?מוקדם$'),
    (ref) => MoveTaskDirection(ref, MoveDirection.later),
  ),
];
