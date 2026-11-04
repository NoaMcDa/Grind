import 'widget_snapshot.dart';

/// Display copy for the "up next" row on the iOS home-screen widget (#23).
///
/// The widget reads a [WidgetSnapshot] through the App Group and draws one
/// reminder on its face. WidgetKit does its own text ellipsis, but letting
/// the OS pick the cut point gives the user "Work on the propo…" — a cut
/// in the middle of a word, inside a sentence that already has a gentle
/// if-then line the writer picked on purpose. This formatter trims to the
/// character budget each widget size allows, at a word boundary, with a
/// real ellipsis character ("…", not three dots) so the glyph stays one
/// character wide and does not steal a second line.
///
/// Pure data. The widget target (Swift) and the lock-screen cell (#12)
/// both read the same snapshot, so they both reach these strings. The
/// momentum meter copy and the medium-widget "plan" strip get their own
/// formatters in later slices.
///
/// Why pure Dart: the writer slice runs in the Flutter process and hands
/// the widget one JSON bundle. Formatting on the Dart side means the
/// Swift target renders the same characters on every OS version, and this
/// file unit-tests without the plugin or an iOS runtime.
class WidgetReminderCopy {
  const WidgetReminderCopy({required this.title, required this.line});

  /// Trimmed, ellipsised task title. Never empty for a non-null reminder —
  /// a reminder without a title would not have been scheduled.
  final String title;

  /// The if-then line (or the smart-snooze offer after two snoozes, #12),
  /// trimmed to the same size. Empty when the reminder carried no body:
  /// callers render just the title in that case rather than a dangling
  /// separator.
  final String line;

  /// True when there is nothing useful to show (both strings are empty).
  /// Lets the widget face fall back to the "momentum only" layout without
  /// looking at two fields.
  bool get isEmpty => title.isEmpty && line.isEmpty;

  /// Builds the copy for [reminder] at the given [size]. When [reminder]
  /// is null the result is [empty] — the widget shows "Nothing lined up"
  /// elsewhere. Nulls in, defaults out: the small widget is the default
  /// because it is the one iOS places by default on the home screen.
  static WidgetReminderCopy of(
    WidgetReminder? reminder, {
    WidgetReminderFace size = WidgetReminderFace.small,
  }) {
    if (reminder == null) return empty;
    return WidgetReminderCopy(
      title: _trim(reminder.title, size.titleChars),
      line: _trim(reminder.body, size.lineChars),
    );
  }

  /// A one-line "headline" for very compact surfaces: the lock-screen
  /// cell, the Siri confirmation card, the Dynamic Island. Combines
  /// [title] and [line] with " — " when both are non-empty; falls back to
  /// whichever one exists. Trimmed to the narrower of the two budgets so
  /// the compound string still fits one line.
  String headline() {
    if (title.isEmpty) return line;
    if (line.isEmpty) return title;
    return '$title — $line';
  }

  /// Shared "nothing to show" value. Const so the widget code can compare
  /// with [identical].
  static const empty = WidgetReminderCopy(title: '', line: '');

  /// Trims [raw] to at most [budget] characters. Cuts at the last space
  /// before the limit when one exists in the last quarter of the string,
  /// so the result ends on a word boundary. The ellipsis character
  /// counts against [budget]; a string already short enough is returned
  /// unchanged (no trailing ellipsis).
  static String _trim(String raw, int budget) {
    final text = raw.trim();
    if (text.isEmpty) return '';
    if (budget <= 0) return '';
    if (text.length <= budget) return text;
    // Leave room for the ellipsis itself.
    final cut = budget - 1;
    if (cut <= 0) return _ellipsis;
    // Prefer a word boundary in the last quarter so we don't lop off
    // most of the word we were about to render.
    final floor = (cut * 3) ~/ 4;
    final slice = text.substring(0, cut);
    final lastSpace = slice.lastIndexOf(' ');
    final at = lastSpace >= floor ? lastSpace : cut;
    // Strip trailing whitespace or punctuation that would sit next to the
    // ellipsis and look like a typo (". …", ", …").
    var head = text.substring(0, at).trimRight();
    while (head.isNotEmpty && _trailingPunct.contains(head[head.length - 1])) {
      head = head.substring(0, head.length - 1).trimRight();
    }
    if (head.isEmpty) return _ellipsis;
    return '$head$_ellipsis';
  }

  static const _ellipsis = '…';

  /// Punctuation we strip from the cut edge so the ellipsis reads cleanly.
  /// Covers Latin and Hebrew commas/periods — the app ships EN and HE.
  static const _trailingPunct = ',.;:!?،؛־–—-';

  @override
  bool operator ==(Object other) =>
      other is WidgetReminderCopy &&
      other.title == title &&
      other.line == line;

  @override
  int get hashCode => Object.hash(title, line);

  @override
  String toString() => 'WidgetReminderCopy(title: "$title", line: "$line")';
}

/// Which widget size the formatter is trimming for. Values match the two
/// iOS home-screen sizes the extension will register (#23); the
/// lock-screen rectangular and inline families reuse [small]'s budget,
/// since both show one truncated line.
///
/// The budgets are picked a touch lower than the pixel-perfect maximum so
/// a wider glyph (Hebrew ש, Latin m) does not force a mid-word wrap.
enum WidgetReminderFace {
  /// The small 2×2 widget. Title is rendered in a display font at ~28 pt,
  /// so ~16 characters per line (title gets ~1.5 lines); the body gets
  /// two lines at ~24 characters.
  small(titleChars: 28, lineChars: 48),

  /// The medium 4×2 widget. Twice the horizontal real estate, so roughly
  /// twice the characters per line; still capped because the body sits
  /// beside the momentum strip.
  medium(titleChars: 44, lineChars: 96);

  const WidgetReminderFace({required this.titleChars, required this.lineChars})
    : assert(titleChars > 0),
      assert(lineChars > 0);

  /// Maximum number of code units [WidgetReminderCopy] keeps for the
  /// task title on this face.
  final int titleChars;

  /// Maximum number of code units [WidgetReminderCopy] keeps for the
  /// if-then line on this face.
  final int lineChars;
}
