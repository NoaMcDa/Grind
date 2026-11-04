import '../../core/domain/energy.dart';
import '../recurrence/recurrence.dart';
import 'task_draft.dart';

/// Offline / opted-out natural-language → [TaskDraft] parser.
///
/// Handles the common capture phrases in EN and HE with regex and a small
/// date arithmetic pass, so the Ask screen (#39) never breaks when the
/// cloud assistant (#38) is off, has no network or hits rate limits.
///
/// The LLM path is strictly better at ambiguous phrases; this parser is
/// the floor the product sits on. Anything it cannot resolve becomes
/// `null` on the draft (the task card then prompts the user).
class TaskDraftParser {
  /// [weekStart] follows [DateTime.monday] … [DateTime.sunday] and matches
  /// `Preferences.weekStart`. It only affects how "next week" is anchored
  /// when used without a weekday.
  const TaskDraftParser({this.weekStart = DateTime.sunday});

  final int weekStart;

  /// Parse [input] in the user's local wall-clock time [now], using
  /// [locale] to pick EN or HE keyword tables. Everything else (title,
  /// durations, 24-hour times, day numbers) is locale-agnostic.
  ///
  /// [now] carries the local date and hour; its time zone is ignored by
  /// the parser — the caller converts the resulting `date`+`time` back to
  /// UTC with its own `tz.Location`.
  TaskDraft parse(String input, {required DateTime now, String locale = 'en'}) {
    final normalised = _normalise(input);
    if (normalised.isEmpty) {
      throw const FormatException('empty input');
    }

    final isHebrew = locale.toLowerCase().startsWith('he');
    final lexicon = isHebrew ? _he : _en;

    var remaining = normalised;

    // "If X, then Y" first — so a time, duration or recurrence inside the
    // clause is not mistaken for the task's own schedule.
    final firstActionResult = _extractFirstAction(remaining, lexicon);
    final firstAction = firstActionResult.firstAction;
    remaining = firstActionResult.remaining;

    final durResult = _extractDuration(remaining, lexicon);
    final duration = durResult.minutes;
    remaining = durResult.remaining;

    final energyResult = _extractEnergy(remaining, lexicon);
    final energy = energyResult.energy;
    remaining = energyResult.remaining;

    final timeResult = _extractTime(remaining, lexicon);
    final timeOfDay = timeResult.time;
    remaining = timeResult.remaining;

    // Recurrence first, so "every Monday" is not eaten as a one-off date.
    final recurrenceResult = _extractRecurrence(remaining, lexicon);
    final rrule = recurrenceResult.rrule;
    remaining = recurrenceResult.remaining;

    final dateResult = _extractDate(remaining, lexicon, now, timeOfDay);
    final date = dateResult.date;
    remaining = dateResult.remaining;

    final title = _titleCase(_cleanTitle(remaining, lexicon));
    if (title.isEmpty) {
      throw const FormatException('could not extract a title');
    }

    return TaskDraft(
      title: title,
      date: date == null ? null : _fmtDate(date),
      time: timeOfDay == null ? null : _fmtTime(timeOfDay),
      durationMinutes: duration,
      energy: energy,
      firstAction: firstAction,
      recurrenceRrule: rrule,
    );
  }

  // ------------------------------- duration ------------------------------ //

  _DurationResult _extractDuration(String s, _Lexicon lex) {
    var total = 0;
    var any = false;
    var out = s;

    // Word durations first ("half an hour", "שעה וחצי").
    for (final w in lex.durationWords.entries) {
      final re = _word(w.key);
      if (re.hasMatch(out)) {
        total += w.value;
        any = true;
        out = out.replaceAll(re, ' ');
      }
    }

    // Compound hours+mins: "1 hour 30 min", "1h 30m", "1h30".
    final compound = _bodyRe(
      r'(\d+)\s*(?:h|hr|hrs|hour|hours|שעות|שעה)\s*(?:and\s*|ו)?(\d+)\s*(?:m|min|mins|minute|minutes|דקות|דקה)?',
    );
    out = out.replaceAllMapped(compound, (m) {
      total += int.parse(m[1]!) * 60 + int.parse(m[2]!);
      any = true;
      return ' ';
    });

    // Bare hours: "1 hour", "2h", "שעה".
    final hours = _bodyRe(
      r'(\d+(?:\.\d+)?)\s*(?:h|hr|hrs|hour|hours|שעות|שעה)',
    );
    out = out.replaceAllMapped(hours, (m) {
      final v = double.parse(m[1]!);
      total += (v * 60).round();
      any = true;
      return ' ';
    });

    // Bare minutes: "45 min", "30 minutes", "45 דקות".
    final mins = _bodyRe(r'(\d+)\s*(?:m|min|mins|minute|minutes|דקות|דקה)');
    out = out.replaceAllMapped(mins, (m) {
      total += int.parse(m[1]!);
      any = true;
      return ' ';
    });

    if (!any || total < 5 || total > 1440) return _DurationResult(null, s);
    return _DurationResult(total, _squish(out));
  }

  // --------------------------------- time -------------------------------- //

  _TimeResult _extractTime(String s, _Lexicon lex) {
    var out = s;

    // 24h: 07:30, 19:00 (reject 12h times with am/pm trailing).
    final twentyFour = RegExp(
      r'(?<![0-9A-Za-z])([01]?\d|2[0-3]):([0-5]\d)(?![0-9]|\s*(?:am|pm|a\.m|p\.m))',
      caseSensitive: false,
    );
    final twentyFourMatch = twentyFour.firstMatch(out);
    if (twentyFourMatch != null) {
      final h = int.parse(twentyFourMatch[1]!);
      final m = int.parse(twentyFourMatch[2]!);
      out = out.replaceFirst(twentyFour, ' ');
      return _TimeResult(_Time(h, m), _squish(out));
    }

    // 12h: 7am, 7:30 pm, 7 am, 7pm.
    final twelve = RegExp(
      r'(?<!\d)(\d{1,2})(?::([0-5]\d))?\s*(am|pm|a\.m\.?|p\.m\.?)\b',
      caseSensitive: false,
    );
    final twelveMatch = twelve.firstMatch(out);
    if (twelveMatch != null) {
      var h = int.parse(twelveMatch[1]!);
      final m = twelveMatch[2] == null ? 0 : int.parse(twelveMatch[2]!);
      final pm = twelveMatch[3]!.toLowerCase().startsWith('p');
      if (h == 12) {
        h = pm ? 12 : 0;
      } else if (pm) {
        h += 12;
      }
      if (h >= 0 && h <= 23) {
        out = out.replaceFirst(twelve, ' ');
        return _TimeResult(_Time(h, m), _squish(out));
      }
    }

    // HE "ב-7", "ב-7:30", "בשעה 7".
    final heTime = RegExp(r'ב[-\s]?(?:שעה\s*)?(\d{1,2})(?::([0-5]\d))?\b');
    final heMatch = heTime.firstMatch(out);
    if (heMatch != null) {
      var h = int.parse(heMatch[1]!);
      final m = heMatch[2] == null ? 0 : int.parse(heMatch[2]!);
      if (h >= 1 && h <= 7 && lex.eveningHints.any(out.contains)) h += 12;
      if (h >= 0 && h <= 23) {
        out = out.replaceFirst(heTime, ' ');
        return _TimeResult(_Time(h, m), _squish(out));
      }
    }

    // "at 7", "at 7:30"
    final atTime = RegExp(r'\bat\s+(\d{1,2})(?::([0-5]\d))?\b');
    final atMatch = atTime.firstMatch(out);
    if (atMatch != null) {
      var h = int.parse(atMatch[1]!);
      final m = atMatch[2] == null ? 0 : int.parse(atMatch[2]!);
      if (h >= 1 && h <= 7 && lex.eveningHints.any(out.contains)) h += 12;
      if (h >= 0 && h <= 23) {
        out = out.replaceFirst(atTime, ' ');
        return _TimeResult(_Time(h, m), _squish(out));
      }
    }

    // Phrase words: "noon", "midnight", "tonight", "morning"…
    for (final w in lex.timeWords.entries) {
      final re = _word(w.key);
      if (re.hasMatch(out)) {
        out = out.replaceAll(re, ' ');
        return _TimeResult(w.value, _squish(out));
      }
    }

    return _TimeResult(null, s);
  }

  // --------------------------------- date -------------------------------- //

  _DateResult _extractDate(String s, _Lexicon lex, DateTime now, _Time? time) {
    var out = s;
    final today = DateTime(now.year, now.month, now.day);

    // Keywords: today, tomorrow, tonight, מחר, היום…
    for (final w in lex.dayKeywords.entries) {
      final re = _word(w.key);
      if (re.hasMatch(out)) {
        out = out.replaceAll(re, ' ');
        return _DateResult(today.add(Duration(days: w.value)), _squish(out));
      }
    }

    // Weekday with optional "next"/"this" (or HE "ביום" / "הבא" after the day).
    for (final e in lex.weekdays.entries) {
      // "next <day>" / "<day> הבא" (adds a week)
      final nextRe = _bodyRe(_nextPatternFor(e.key, lex.nextMarkers));
      if (nextRe.hasMatch(out)) {
        out = out.replaceAll(nextRe, ' ');
        return _DateResult(
          _nextWeekday(today, e.value, nextWeek: true),
          _squish(out),
        );
      }
      // "this <day>" / bare "<day>" / "ביום <day>"  (next occurrence)
      final thisRe = _bodyRe(_thisPatternFor(e.key, lex.thisMarkers));
      if (thisRe.hasMatch(out)) {
        out = out.replaceAll(thisRe, ' ');
        return _DateResult(_nextWeekday(today, e.value), _squish(out));
      }
    }

    // "in N days", "בעוד N ימים"
    final inDays = _bodyRe(r'(?:in|בעוד)\s+(\d+)\s+(?:days?|ימים|יום)');
    final inMatch = inDays.firstMatch(out);
    if (inMatch != null) {
      final n = int.parse(inMatch[1]!);
      out = out.replaceFirst(inDays, ' ');
      return _DateResult(today.add(Duration(days: n)), _squish(out));
    }

    // "next week", "בשבוע הבא"
    final nextWeek = _bodyRe(r'(?:next\s+week|בשבוע\s+הבא)');
    if (nextWeek.hasMatch(out)) {
      out = out.replaceAll(nextWeek, ' ');
      return _DateResult(
        today.add(Duration(days: _daysToNextWeek(today))),
        _squish(out),
      );
    }

    // No date found: if there's a time already in the past today, bump
    // tomorrow.
    if (time != null) {
      final nowMins = now.hour * 60 + now.minute;
      final tMins = time.hour * 60 + time.minute;
      if (tMins <= nowMins) return _DateResult(today.add(_oneDay), out);
      return _DateResult(today, out);
    }
    return _DateResult(null, out);
  }

  DateTime _nextWeekday(DateTime today, int weekday, {bool nextWeek = false}) {
    var delta = (weekday - today.weekday) % 7;
    if (delta < 0) delta += 7;
    if (nextWeek && delta < 7) delta += 7;
    return today.add(Duration(days: delta));
  }

  int _daysToNextWeek(DateTime today) {
    var delta = (weekStart - today.weekday) % 7;
    if (delta <= 0) delta += 7;
    return delta;
  }

  // ------------------------------- energy -------------------------------- //

  _EnergyResult _extractEnergy(String s, _Lexicon lex) {
    for (final w in lex.deepHints) {
      if (_word(w).hasMatch(s)) return _EnergyResult(Energy.deep, s);
    }
    for (final w in lex.lightHints) {
      if (_word(w).hasMatch(s)) return _EnergyResult(Energy.light, s);
    }
    return _EnergyResult(null, s);
  }

  // ------------------------------ first action -------------------------- //

  /// Pulls an `if <condition> (then|,) <action>` clause out of [s] and
  /// returns the formatted if-then string plus the text with the clause
  /// removed.
  ///
  /// The clause is extracted BEFORE date/time/duration/recurrence so a
  /// time ("if it's 17:00") or duration ("if you have 30 min") inside
  /// the condition is not mistaken for the task's own schedule.
  _FirstActionResult _extractFirstAction(String s, _Lexicon lex) {
    final body =
        '${RegExp.escape(lex.ifMarker)}\\s+(.+?)\\s*,?\\s+'
        '${RegExp.escape(lex.thenMarker)}\\s+(.+?)\$';
    final re = RegExp(_lb + body + _rb, caseSensitive: false);
    final m = re.firstMatch(s);
    if (m == null) return _FirstActionResult(null, s);

    final cond = m[1]!.trim();
    final action = m[2]!.trim();
    if (cond.isEmpty || action.isEmpty) return _FirstActionResult(null, s);

    final before = s.substring(0, m.start).trim();
    // The clause is often written as "..., if X then Y": strip the
    // trailing comma left behind so the title cleanup never inherits
    // stray punctuation.
    final beforeClean = before.endsWith(',')
        ? before.substring(0, before.length - 1).trim()
        : before;

    final formatted =
        '${lex.ifMarkerCanonical} $cond, ${lex.thenMarker} '
        '$action';
    return _FirstActionResult(formatted, _squish(beforeClean));
  }

  // ------------------------------- recurrence ---------------------------- //

  _RecurrenceResult _extractRecurrence(String s, _Lexicon lex) {
    var out = s;
    // "every day", "כל יום"
    final daily = _bodyRe(r'(?:every\s+day|daily|כל\s+יום)');
    if (daily.hasMatch(out)) {
      out = out.replaceAll(daily, ' ');
      return _RecurrenceResult(
        const Recurrence.daily().toRRule(),
        _squish(out),
      );
    }
    // "every weekday", "weekdays", "ימי חול"
    final weekdays = _bodyRe(r'(?:every\s+weekday|weekdays|ימי\s+חול)');
    if (weekdays.hasMatch(out)) {
      out = out.replaceAll(weekdays, ' ');
      return _RecurrenceResult(
        const Recurrence.weekdays().toRRule(),
        _squish(out),
      );
    }
    // "every Monday" / "כל יום שני"
    for (final e in lex.weekdays.entries) {
      final re = _bodyRe(r'(?:every|כל\s+יום)\s+' + RegExp.escape(e.key));
      if (re.hasMatch(out)) {
        out = out.replaceAll(re, ' ');
        return _RecurrenceResult(
          Recurrence.weekly({e.value}).toRRule(),
          _squish(out),
        );
      }
    }
    if (_word('weekly').hasMatch(out)) {
      out = out.replaceAll(_word('weekly'), ' ');
      return _RecurrenceResult(
        const Recurrence.weekly({}).toRRule(),
        _squish(out),
      );
    }
    if (_word('monthly').hasMatch(out)) {
      out = out.replaceAll(_word('monthly'), ' ');
      return _RecurrenceResult(
        const Recurrence.monthly(null).toRRule(),
        _squish(out),
      );
    }
    return _RecurrenceResult(null, s);
  }

  // ------------------------------ title cleanup -------------------------- //

  String _cleanTitle(String s, _Lexicon lex) {
    var out = s;
    for (final w in lex.fillerWords) {
      out = out.replaceAll(_word(w, caseSensitive: false), ' ');
    }
    out = out.replaceAll(RegExp(r'[,،]+'), ' ');
    out = out.replaceAll(RegExp(r'\s+-\s+'), ' ');
    return _squish(out);
  }

  String _titleCase(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();
}

// ----------------------------- shared helpers --------------------------- //

const _lb = r'(?<![A-Za-z0-9֐-׿])';
const _rb = r'(?![A-Za-z0-9֐-׿])';

/// A regex matching [word] with Unicode-aware word boundaries that
/// recognise Hebrew letters as "word" characters too. Dart's `\b` is
/// ASCII-only; a Hebrew keyword at the end of a string would never
/// match otherwise.
RegExp _word(String word, {bool caseSensitive = true}) =>
    RegExp(_lb + RegExp.escape(word) + _rb, caseSensitive: caseSensitive);

/// A regex that wraps an already-escaped pattern [body] with the custom
/// EN+HE boundaries.
RegExp _bodyRe(String body, {bool caseSensitive = false}) =>
    RegExp('$_lb(?:$body)$_rb', caseSensitive: caseSensitive);

String _nextPatternFor(String day, List<String> nextMarkers) {
  final markers = nextMarkers.map(RegExp.escape).join('|');
  final esc = RegExp.escape(day);
  // "next <day>" (EN) or "<day> הבא/הקרוב" (HE).
  return '(?:(?:$markers)\\s+$esc|$esc\\s+(?:$markers))';
}

String _thisPatternFor(String day, List<String> thisMarkers) {
  final markers = thisMarkers.map(RegExp.escape).join('|');
  final esc = RegExp.escape(day);
  return '(?:(?:(?:$markers)\\s+)?$esc)';
}

String _normalise(String s) => s.replaceAll(' ', ' ').trim();

String _squish(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

String _fmtDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

String _fmtTime(_Time t) =>
    '${t.hour.toString().padLeft(2, '0')}:'
    '${t.minute.toString().padLeft(2, '0')}';

const _oneDay = Duration(days: 1);

class _Time {
  const _Time(this.hour, this.minute);
  final int hour;
  final int minute;
}

class _DurationResult {
  const _DurationResult(this.minutes, this.remaining);
  final int? minutes;
  final String remaining;
}

class _TimeResult {
  const _TimeResult(this.time, this.remaining);
  final _Time? time;
  final String remaining;
}

class _DateResult {
  const _DateResult(this.date, this.remaining);
  final DateTime? date;
  final String remaining;
}

class _EnergyResult {
  const _EnergyResult(this.energy, this.remaining);
  final Energy? energy;
  final String remaining;
}

class _RecurrenceResult {
  const _RecurrenceResult(this.rrule, this.remaining);
  final String? rrule;
  final String remaining;
}

class _FirstActionResult {
  const _FirstActionResult(this.firstAction, this.remaining);
  final String? firstAction;
  final String remaining;
}

class _Lexicon {
  const _Lexicon({
    required this.weekdays,
    required this.dayKeywords,
    required this.timeWords,
    required this.durationWords,
    required this.deepHints,
    required this.lightHints,
    required this.eveningHints,
    required this.nextMarkers,
    required this.thisMarkers,
    required this.fillerWords,
    required this.ifMarker,
    required this.ifMarkerCanonical,
    required this.thenMarker,
  });

  /// Lowercase weekday → [DateTime.weekday].
  final Map<String, int> weekdays;

  /// Keyword → day offset from today (0 = today, 1 = tomorrow).
  final Map<String, int> dayKeywords;

  /// Phrase words → time of day.
  final Map<String, _Time> timeWords;

  /// Phrase words → minutes.
  final Map<String, int> durationWords;

  /// Words that nudge energy toward deep focus.
  final List<String> deepHints;

  /// Words that nudge energy toward light.
  final List<String> lightHints;

  /// Any of these in the input nudges a bare hour (1-7) to PM.
  final List<String> eveningHints;

  /// "next" markers used both before and after the weekday.
  final List<String> nextMarkers;

  /// "this" markers to strip ahead of a weekday.
  final List<String> thisMarkers;

  /// Noise words that linger after extraction and should not end up in
  /// the title.
  final List<String> fillerWords;

  /// The "if" marker used in the `if … then …` extractor, matched
  /// case-insensitively.
  final String ifMarker;

  /// How the "if" marker is spelled in the formatted output (EN
  /// capitalises it to match the demo seed style; HE has no case).
  final String ifMarkerCanonical;

  /// The "then" marker used in the extractor (also the output spelling).
  final String thenMarker;
}

const _Lexicon _en = _Lexicon(
  weekdays: {
    'monday': DateTime.monday,
    'tuesday': DateTime.tuesday,
    'wednesday': DateTime.wednesday,
    'thursday': DateTime.thursday,
    'friday': DateTime.friday,
    'saturday': DateTime.saturday,
    'sunday': DateTime.sunday,
    'mon': DateTime.monday,
    'tue': DateTime.tuesday,
    'tues': DateTime.tuesday,
    'wed': DateTime.wednesday,
    'thu': DateTime.thursday,
    'thur': DateTime.thursday,
    'thurs': DateTime.thursday,
    'fri': DateTime.friday,
    'sat': DateTime.saturday,
    'sun': DateTime.sunday,
  },
  dayKeywords: {'today': 0, 'tonight': 0, 'tomorrow': 1, 'tmrw': 1, 'tmr': 1},
  timeWords: {
    'noon': _Time(12, 0),
    'midnight': _Time(0, 0),
    'tonight': _Time(20, 0),
    'morning': _Time(9, 0),
    'afternoon': _Time(14, 0),
    'evening': _Time(19, 0),
    'night': _Time(21, 0),
  },
  durationWords: {
    'half an hour': 30,
    'half hour': 30,
    'half-hour': 30,
    'an hour': 60,
    'quarter of an hour': 15,
  },
  deepHints: ['deep', 'focus', 'focused', 'study', 'write', 'writing', 'code'],
  lightHints: [
    'gym',
    'walk',
    'run',
    'errands',
    'laundry',
    'groceries',
    'shopping',
    'call',
  ],
  eveningHints: ['evening', 'tonight', 'night', 'dinner', 'pm', 'after work'],
  nextMarkers: ['next', 'coming'],
  thisMarkers: ['this', 'on'],
  fillerWords: ['at', 'on', 'for', 'about', 'around', 'the', 'a'],
  ifMarker: 'if',
  ifMarkerCanonical: 'If',
  thenMarker: 'then',
);

const _Lexicon _he = _Lexicon(
  weekdays: {
    'ראשון': DateTime.sunday,
    'שני': DateTime.monday,
    'שלישי': DateTime.tuesday,
    'רביעי': DateTime.wednesday,
    'חמישי': DateTime.thursday,
    'שישי': DateTime.friday,
    'שבת': DateTime.saturday,
  },
  dayKeywords: {'היום': 0, 'הערב': 0, 'הלילה': 0, 'מחר': 1, 'מחרתיים': 2},
  timeWords: {
    'צהריים': _Time(12, 0),
    'חצות': _Time(0, 0),
    'הערב': _Time(20, 0),
    'הלילה': _Time(21, 0),
    'בוקר': _Time(9, 0),
    'בבוקר': _Time(9, 0),
    'אחהצ': _Time(14, 0),
    'אחה״צ': _Time(14, 0),
    'ערב': _Time(19, 0),
    'בערב': _Time(19, 0),
  },
  durationWords: {'חצי שעה': 30, 'שעה וחצי': 90, 'שעתיים': 120, 'רבע שעה': 15},
  deepHints: ['עבודה', 'מיקוד', 'לימודים', 'תזה', 'כתיבה', 'קוד'],
  lightHints: ['חדר כושר', 'הליכה', 'ריצה', 'קניות', 'כביסה', 'שיחה'],
  eveningHints: ['ערב', 'בערב', 'הערב', 'לילה', 'בלילה', 'ארוחת ערב'],
  nextMarkers: ['הבא', 'הקרוב'],
  thisMarkers: ['ביום'],
  fillerWords: ['של', 'ל'],
  ifMarker: 'אם',
  ifMarkerCanonical: 'אם',
  thenMarker: 'אז',
);
