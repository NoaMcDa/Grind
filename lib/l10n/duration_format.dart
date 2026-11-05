import 'app_localizations.dart';

/// Parses a user-typed duration into minutes. Accepts digit-only minutes
/// (`"90"`), hours (`"4h"`, `"4 h"`, `"4hr"`, `"4 hours"`), the HH:MM shape
/// (`"1:30"`), and mixed forms (`"1h30"`, `"1h 30m"`, `"1 hour 30 min"`).
/// Whitespace is ignored; Hebrew markers (`ש׳`/`שעה`/`שעות` and `דק׳`/`דקה`/`דקות`)
/// are accepted alongside the English ones. Returns null when the text has no
/// digits or the shape is unrecognised; otherwise returns a non-negative
/// minute count.
int? parseDuration(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;
  const maxMinutes = 24 * 60;
  // Normalise: strip whitespace, lower-case, replace Hebrew abbreviations.
  var s = trimmed.toLowerCase();
  // Map Hebrew tokens to h / m so the grammar below handles both locales.
  s = s
      .replaceAll('שעות', 'h')
      .replaceAll('שעה', 'h')
      .replaceAll('ש׳', 'h')
      .replaceAll("ש'", 'h')
      .replaceAll('דקות', 'm')
      .replaceAll('דקה', 'm')
      .replaceAll('דק׳', 'm')
      .replaceAll("דק'", 'm');
  // Normalise English synonyms into single letters.
  s = s
      .replaceAll('hours', 'h')
      .replaceAll('hour', 'h')
      .replaceAll('hrs', 'h')
      .replaceAll('hr', 'h')
      .replaceAll('minutes', 'm')
      .replaceAll('minute', 'm')
      .replaceAll('mins', 'm')
      .replaceAll('min', 'm');
  // Drop every remaining space.
  s = s.replaceAll(RegExp(r'\s+'), '');
  if (s.isEmpty) return null;

  // "1:30" shape.
  final colon = RegExp(r'^(\d+):(\d{1,2})$').firstMatch(s);
  if (colon != null) {
    final h = int.parse(colon.group(1)!);
    final m = int.parse(colon.group(2)!);
    if (m >= 60) return null;
    final total = h * 60 + m;
    if (total <= 0 || total > maxMinutes) return null;
    return total;
  }

  // "4h", "4h30", "4h30m", "30m", or bare "90".
  final hm = RegExp(r'^(?:(\d+)h)?(?:(\d+)m?)?$').firstMatch(s);
  if (hm != null && (hm.group(1) != null || hm.group(2) != null)) {
    final h = int.tryParse(hm.group(1) ?? '0') ?? 0;
    final m = int.tryParse(hm.group(2) ?? '0') ?? 0;
    final total = h * 60 + m;
    if (total <= 0 || total > maxMinutes) return null;
    return total;
  }
  return null;
}

/// Formats a minute count for the UI: minutes alone below an hour, hours
/// alone on a round hour, and `"1 h 30 min"` in between. Uses the locale's
/// own tokens (English `min`/`h`, Hebrew `דק׳`/`ש׳`). A negative or zero
/// value is shown as `"0 min"`.
String formatDuration(int minutes, AppLocalizations l) {
  if (minutes < 60) return l.commonMinutes(minutes < 0 ? 0 : minutes);
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (m == 0) return l.commonHours(h);
  return l.commonHoursMinutes(h, m);
}
