/// Hebrew date-expression normalizer.
///
/// Turns a short Hebrew date phrase ("מחר ב-7", "מחרתיים בשעה 20:30",
/// "בעוד שעתיים") into a resolved [DateTime] against the caller's [now].
///
/// This is the pure-function counterpart of the full capture parser in
/// `features/assistant/task_draft_parser.dart`: it covers only the subset
/// of Hebrew date phrases that callers like reminder forms, tool-call
/// parameter checks and voice transcripts need, and it returns `null`
/// rather than throwing on anything it does not understand. The task
/// parser still owns the harder paths — weekdays, recurrence, English
/// prose and the title/duration/energy extraction around them (#39).
///
/// Nothing here touches time zones: [now] carries the user's local wall
/// clock and the resolved value keeps that same offset, so the caller
/// stays in charge of UTC conversion (same contract as the task parser).
library;

/// The result of a successful [parseHebrewDateExpression] call.
class HebrewDateExpression {
  const HebrewDateExpression({
    required this.resolved,
    this.dayKeyword,
    this.time,
    this.deltaMinutes,
  });

  /// The absolute wall-clock [DateTime] the phrase refers to. Carries the
  /// same local offset as the `now` passed in.
  final DateTime resolved;

  /// The matched day keyword ("היום", "מחר", "מחרתיים", "הערב",
  /// "הלילה"), or `null` when the phrase was a relative "בעוד N …" form.
  final String? dayKeyword;

  /// The explicit time of day found in the phrase ("ב-7", "בשעה 20:30"),
  /// or `null` when none was given. Defaults supplied by "הערב" / "הלילה"
  /// / "בבוקר" / "בצהריים" are reported here too, so callers can tell
  /// "resolved at midnight" apart from "resolved at the keyword's hint".
  final HebrewTimeOfDay? time;

  /// The duration added to [now] for a "בעוד N …" phrase, in minutes,
  /// or `null` for a day-keyword phrase.
  final int? deltaMinutes;

  @override
  bool operator ==(Object other) =>
      other is HebrewDateExpression &&
      other.resolved == resolved &&
      other.dayKeyword == dayKeyword &&
      other.time == time &&
      other.deltaMinutes == deltaMinutes;

  @override
  int get hashCode =>
      Object.hash(resolved, dayKeyword, time, deltaMinutes);

  @override
  String toString() =>
      'HebrewDateExpression(resolved: $resolved, dayKeyword: $dayKeyword, '
      'time: $time, deltaMinutes: $deltaMinutes)';
}

/// A 24-hour wall-clock time, 00:00 ..= 23:59. Value object so callers can
/// compare parsed times without reaching back for the full [DateTime].
class HebrewTimeOfDay {
  const HebrewTimeOfDay(this.hour, this.minute)
    : assert(hour >= 0 && hour <= 23, 'hour must be 0..23'),
      assert(minute >= 0 && minute <= 59, 'minute must be 0..59');

  final int hour;
  final int minute;

  @override
  bool operator ==(Object other) =>
      other is HebrewTimeOfDay && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() =>
      'HebrewTimeOfDay(${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')})';
}

/// Parse [input] as a Hebrew date phrase and resolve it against [now].
///
/// Returns `null` when nothing recognisable is found so callers can fall
/// back cleanly (the task parser, an "I didn't catch that" nudge, …).
/// Recognised shapes:
///
///   * `היום` / `מחר` / `מחרתיים` — day keyword, optional time suffix
///     like `ב-7`, `ב-7:30` or `בשעה 20:30`. Without a time the resolved
///     value sits at 00:00 of the target day.
///   * `הערב` / `הלילה` / `בבוקר` / `בצהריים` — "today" plus an implied
///     time (20:00 / 21:00 / 09:00 / 12:00). An explicit time in the
///     phrase wins over the implied one.
///   * `בעוד N דקות` / `בעוד N שעות` / `בעוד N ימים` — plain relative
///     deltas, plus the common dual forms `שעתיים` / `יומיים`, the
///     fractions `חצי שעה` and `רבע שעה`, and the bare singulars
///     `בעוד דקה` / `בעוד שעה` / `בעוד יום`.
///
/// Case-insensitivity is not a concept in Hebrew; ASCII around a phrase
/// (leading / trailing whitespace, a trailing full stop) is ignored.
HebrewDateExpression? parseHebrewDateExpression(
  String input, {
  required DateTime now,
}) {
  final cleaned = _squish(input);
  if (cleaned.isEmpty) return null;

  // Shape 1: "בעוד …" relative delta.
  final delta = _parseRelativeDelta(cleaned);
  if (delta != null) {
    return HebrewDateExpression(
      resolved: now.add(Duration(minutes: delta)),
      deltaMinutes: delta,
    );
  }

  // Shape 2: day keyword with optional time.
  return _parseDayKeyword(cleaned, now);
}

// ---------------------------------------------------------------------------
// Day-keyword shape
// ---------------------------------------------------------------------------

// Keyword -> (day offset, implied time or null).
const Map<String, _KeywordSpec> _dayKeywords = {
  'היום': _KeywordSpec(0, null),
  'מחר': _KeywordSpec(1, null),
  'מחרתיים': _KeywordSpec(2, null),
  'הערב': _KeywordSpec(0, HebrewTimeOfDay(20, 0)),
  'הלילה': _KeywordSpec(0, HebrewTimeOfDay(21, 0)),
  'בבוקר': _KeywordSpec(0, HebrewTimeOfDay(9, 0)),
  'בצהריים': _KeywordSpec(0, HebrewTimeOfDay(12, 0)),
};

HebrewDateExpression? _parseDayKeyword(String text, DateTime now) {
  String? matchedKeyword;
  _KeywordSpec? matchedSpec;
  var remainder = text;
  // Longest-match wins so "מחרתיים" is not swallowed by "מחר".
  final sorted = _dayKeywords.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final keyword in sorted) {
    final re = RegExp('(?:^|\\s)${RegExp.escape(keyword)}(?:\\s|\$)');
    final m = re.firstMatch(text);
    if (m != null) {
      matchedKeyword = keyword;
      matchedSpec = _dayKeywords[keyword];
      remainder = text.replaceRange(m.start, m.end, ' ');
      break;
    }
  }
  if (matchedKeyword == null || matchedSpec == null) return null;

  final explicitTime = _parseTime(remainder);
  final time = explicitTime ?? matchedSpec.impliedTime;

  final day = DateTime(now.year, now.month, now.day)
      .add(Duration(days: matchedSpec.dayOffset));
  final resolved = time == null
      ? day
      : DateTime(day.year, day.month, day.day, time.hour, time.minute);

  return HebrewDateExpression(
    resolved: resolved,
    dayKeyword: matchedKeyword,
    time: time,
  );
}

class _KeywordSpec {
  const _KeywordSpec(this.dayOffset, this.impliedTime);
  final int dayOffset;
  final HebrewTimeOfDay? impliedTime;
}

// Matches "ב-7", "ב-7:30", "בשעה 20", "בשעה 20:30". The task parser's
// regex is the reference; this one is the same shape, kept here so the
// normalizer stays a standalone unit.
final RegExp _timeRe = RegExp(
  r'ב[-\s]?(?:שעה\s*)?(\d{1,2})(?::([0-5]\d))?(?:\s|$)',
);

HebrewTimeOfDay? _parseTime(String text) {
  final m = _timeRe.firstMatch(text);
  if (m == null) return null;
  final h = int.parse(m.group(1)!);
  final min = m.group(2) == null ? 0 : int.parse(m.group(2)!);
  if (h < 0 || h > 23) return null;
  return HebrewTimeOfDay(h, min);
}

// ---------------------------------------------------------------------------
// "בעוד …" relative shape
// ---------------------------------------------------------------------------

// Unit tables: each entry is (regex pattern body, unit minutes). The
// pattern body is anchored to "בעוד …" and anything trailing is ignored.
const Map<String, int> _numberWords = {
  'דקה': 1,
  'שתי דקות': 2,
  'שתיים דקות': 2,
  'שלוש דקות': 3,
  'ארבע דקות': 4,
  'חמש דקות': 5,
  'עשר דקות': 10,
};

int? _parseRelativeDelta(String text) {
  // "בעוד" must stand alone at the start of its clause.
  final head = RegExp(r'(?:^|\s)בעוד\s+');
  final m = head.firstMatch(text);
  if (m == null) return null;
  final tail = text.substring(m.end).trim();
  if (tail.isEmpty) return null;

  // Compound fractions and dual forms first — so "שעתיים" is not read
  // as a digit-less "שעה".
  if (tail.startsWith('חצי שעה')) return 30;
  if (tail.startsWith('רבע שעה')) return 15;
  if (tail.startsWith('שעה וחצי')) return 90;
  if (tail.startsWith('שעתיים')) return 120;
  if (tail.startsWith('יומיים')) return 2 * 24 * 60;
  if (tail.startsWith('שבועיים')) return 14 * 24 * 60;

  // "בעוד <N> <unit>" — ASCII digits only (Hebrew numeric words outside
  // of the dual forms are vanishingly rare in capture text).
  final numRe = RegExp(r'^(\d+)\s+(\S+)');
  final numMatch = numRe.firstMatch(tail);
  if (numMatch != null) {
    final n = int.parse(numMatch.group(1)!);
    final unit = numMatch.group(2)!;
    final unitMinutes = _unitMinutes(unit);
    if (unitMinutes != null) return n * unitMinutes;
  }

  // Small spelled-out numbers ("עשר דקות").
  for (final entry in _numberWords.entries) {
    if (tail.startsWith(entry.key)) return entry.value;
  }

  // Bare singulars: "בעוד דקה", "בעוד שעה", "בעוד יום", "בעוד שבוע".
  final bareRe = RegExp(r'^(\S+)');
  final bareMatch = bareRe.firstMatch(tail);
  if (bareMatch != null) {
    switch (bareMatch.group(1)) {
      case 'דקה':
        return 1;
      case 'שעה':
        return 60;
      case 'יום':
        return 24 * 60;
      case 'שבוע':
        return 7 * 24 * 60;
    }
  }

  return null;
}

int? _unitMinutes(String unit) {
  switch (unit) {
    case 'דקה':
    case 'דקות':
      return 1;
    case 'שעה':
    case 'שעות':
      return 60;
    case 'יום':
    case 'ימים':
      return 24 * 60;
    case 'שבוע':
    case 'שבועות':
      return 7 * 24 * 60;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

String _squish(String s) {
  // Collapse runs of ASCII whitespace to single spaces and strip a
  // trailing full stop or Hebrew-safe punctuation. Leading / trailing
  // spaces are returned without surrounding whitespace.
  var out = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  while (out.isNotEmpty) {
    final last = out.codeUnitAt(out.length - 1);
    if (last == 0x2E || last == 0x2C || last == 0x21 || last == 0x3F) {
      // . , ! ?
      out = out.substring(0, out.length - 1).trimRight();
    } else {
      break;
    }
  }
  return out;
}
