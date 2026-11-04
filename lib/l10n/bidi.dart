import 'dart:ui' show TextDirection;

/// Bidi helpers for mixing Hebrew with embedded Latin text, numbers and
/// times.
///
/// Hebrew flows right-to-left while Latin words, ASCII digits and clock
/// times flow left-to-right. Without isolation the Unicode Bidi algorithm
/// (UAX #9) decides what to do on its own, and it often reorders digit
/// runs and neutral punctuation in surprising ways. Wrapping each LTR
/// run in a First-Strong Isolate (FSI U+2068 ... PDI U+2069) tells the
/// algorithm to resolve that span on its own, keeping the surrounding
/// Hebrew paragraph intact.
///
/// References:
///   https://www.unicode.org/reports/tr9/ (UAX #9)
///   https://www.w3.org/International/articles/inline-bidi-markup/
abstract final class Bidi {
  /// First-Strong Isolate - direction inferred from the first strong
  /// character inside the isolate. Pair with [pdi].
  static const fsi = '\u2068';

  /// Left-to-Right Isolate. Pair with [pdi].
  static const lri = '\u2066';

  /// Right-to-Left Isolate. Pair with [pdi].
  static const rli = '\u2067';

  /// Pop Directional Isolate - closes the nearest isolate.
  static const pdi = '\u2069';

  /// Left-to-Right Mark - zero-width strong LTR character.
  static const lrm = '\u200E';

  /// Right-to-Left Mark - zero-width strong RTL character.
  static const rlm = '\u200F';

  /// Wrap [text] in a bidi isolate so it is laid out in its own direction
  /// inside a surrounding paragraph. When [direction] is null the renderer
  /// picks the direction from the first strong character inside.
  ///
  /// An empty string is returned as-is: an isolate around nothing just
  /// wastes two code points.
  static String isolate(String text, {TextDirection? direction}) {
    if (text.isEmpty) return text;
    final open = switch (direction) {
      TextDirection.ltr => lri,
      TextDirection.rtl => rli,
      null => fsi,
    };
    return '$open$text$pdi';
  }

  /// True when [s] contains any character in the Hebrew block
  /// (U+0590 - U+05FF).
  static bool hasHebrew(String s) {
    for (final r in s.runes) {
      if (r >= 0x0590 && r <= 0x05FF) return true;
    }
    return false;
  }

  /// True when [s] contains any Basic Latin letter (A-Z, a-z).
  static bool hasLatin(String s) {
    for (final r in s.runes) {
      if (_isLatinLetter(r)) return true;
    }
    return false;
  }

  /// Direction guessed by the first strong character in [s], per the
  /// first-strong rule in UAX #9. Falls back to [TextDirection.ltr] when
  /// there is no strong character at all.
  static TextDirection firstStrong(String s) {
    for (final r in s.runes) {
      if (_isStrongRtl(r)) return TextDirection.rtl;
      if (_isStrongLtr(r)) return TextDirection.ltr;
    }
    return TextDirection.ltr;
  }

  /// Wrap every maximal Latin / digit run in [text] with FSI...PDI so each
  /// one renders in its own LTR span inside a Hebrew (or otherwise RTL)
  /// paragraph.
  ///
  /// A run starts at a Latin letter or ASCII digit and extends through
  /// consecutive Latin letters, ASCII digits and inner connectors
  /// (``.,:/'-_``). Trailing connectors are left outside the isolate so
  /// final punctuation stays on the paragraph level.
  ///
  /// Hebrew runs, whitespace and everything else pass through unchanged.
  /// If [text] contains no LTR runs it is returned as-is - no isolates,
  /// no allocation of a new string.
  static String wrapLatinRuns(String text) {
    if (text.isEmpty) return text;
    final runes = text.runes.toList(growable: false);
    // Find runs first; if none, skip the StringBuffer entirely.
    final runs = <_Run>[];
    var i = 0;
    while (i < runes.length) {
      if (_isLatinOrDigit(runes[i])) {
        final start = i;
        var end = i + 1;
        var lastStrong = i;
        while (end < runes.length) {
          final r = runes[end];
          if (_isLatinOrDigit(r)) {
            lastStrong = end;
            end++;
          } else if (_isConnector(r)) {
            end++;
          } else {
            break;
          }
        }
        runs.add(_Run(start, lastStrong + 1));
        i = lastStrong + 1;
      } else {
        i++;
      }
    }
    if (runs.isEmpty) return text;
    final out = StringBuffer();
    var cursor = 0;
    for (final run in runs) {
      for (var k = cursor; k < run.start; k++) {
        out.writeCharCode(runes[k]);
      }
      out.write(fsi);
      for (var k = run.start; k < run.end; k++) {
        out.writeCharCode(runes[k]);
      }
      out.write(pdi);
      cursor = run.end;
    }
    for (var k = cursor; k < runes.length; k++) {
      out.writeCharCode(runes[k]);
    }
    return out.toString();
  }
}

class _Run {
  const _Run(this.start, this.end);
  final int start;
  final int end;
}

bool _isLatinLetter(int r) =>
    (r >= 0x41 && r <= 0x5A) || (r >= 0x61 && r <= 0x7A);

bool _isAsciiDigit(int r) => r >= 0x30 && r <= 0x39;

bool _isLatinOrDigit(int r) => _isLatinLetter(r) || _isAsciiDigit(r);

// Inner connectors allowed between Latin/digit characters: . , : / ' - _
bool _isConnector(int r) =>
    r == 0x2E || // .
    r == 0x2C || // ,
    r == 0x3A || // :
    r == 0x2F || // /
    r == 0x27 || // '
    r == 0x2D || // -
    r == 0x5F; // _

// Strong LTR covers the Basic Latin and Latin-1 Supplement letter ranges,
// which is all we need for task names and the 'app' languages in Grind.
bool _isStrongLtr(int r) =>
    _isLatinLetter(r) ||
    (r >= 0x00C0 && r <= 0x00D6) ||
    (r >= 0x00D8 && r <= 0x00F6) ||
    (r >= 0x00F8 && r <= 0x02AF);

// Strong RTL covers Hebrew and Arabic (and their supplements). ASCII
// digits are treated as weak here on purpose - a Hebrew paragraph that
// opens with ASCII digits is still Hebrew-flavoured, not LTR.
bool _isStrongRtl(int r) =>
    (r >= 0x0590 && r <= 0x05FF) || // Hebrew
    (r >= 0x0600 && r <= 0x06FF) || // Arabic
    (r >= 0x0700 && r <= 0x074F) || // Syriac
    (r >= 0x0750 && r <= 0x077F) || // Arabic Supplement
    (r >= 0x08A0 && r <= 0x08FF) || // Arabic Extended-A
    (r >= 0xFB1D && r <= 0xFB4F) || // Hebrew Presentation Forms
    (r >= 0xFB50 && r <= 0xFDFF) || // Arabic Presentation Forms-A
    (r >= 0xFE70 && r <= 0xFEFF); // Arabic Presentation Forms-B
