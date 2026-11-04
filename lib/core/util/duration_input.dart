import '../../l10n/app_localizations.dart';

/// Helpers for duration input and display.
///
/// Stored durations are always whole minutes (this is the minute-granular
/// representation the rest of the app uses). These helpers only translate
/// between those minutes and the shapes a user types or reads.
///
/// `parseDuration` accepts:
///   * plain minutes: `"90"`, `"  90 "`
///   * hours: `"4h"`, `"4 h"`, `"4H"`
///   * hours + minutes: `"1h30"`, `"1 h 30"`, `"1h 30m"`
///   * colon form: `"1:30"`, `"0:45"`, `"02:05"`
/// Returns `null` for anything else (including empty, negative, or > 24 h).
///
/// `formatDuration` renders a minute count in the active locale, using
/// hours once it reaches 60 min ("4 h", "1 h 30 min"; Hebrew uses דק׳/שע׳).

/// Upper bound: a single estimate or focus block does not exceed one day.
const _maxMinutes = 24 * 60;

/// Parses a user-entered duration into whole minutes.
///
/// Whitespace is ignored. Returns `null` when [input] is empty, malformed,
/// or outside `(0, 1440]`.
int? parseDuration(String input) {
  final raw = input.trim();
  if (raw.isEmpty) return null;

  // Colon form: h:mm (or h:m). Accept any number of digits per piece but
  // keep the minute-piece at most two digits so "1:300" is invalid.
  final colon = RegExp(r'^(\d+):(\d{1,2})$').firstMatch(raw);
  if (colon != null) {
    final h = int.parse(colon.group(1)!);
    final m = int.parse(colon.group(2)!);
    if (m >= 60) return null;
    return _clamp(h * 60 + m);
  }

  // Strip spaces for the free-form shapes.
  final s = raw.replaceAll(RegExp(r'\s+'), '').toLowerCase();

  // Pure digits: already minutes.
  if (RegExp(r'^\d+$').hasMatch(s)) {
    return _clamp(int.parse(s));
  }

  // Hours (and optional minutes) with a trailing letter.
  // "4h", "4h30", "4h30m", "4hr", "4hrs", "4h 30min".
  final hm = RegExp(r'^(\d+)h(?:r|rs|our|ours)?(?:(\d+)m?i?n?s?)?$');
  final match = hm.firstMatch(s);
  if (match != null) {
    final h = int.parse(match.group(1)!);
    final m = match.group(2) == null ? 0 : int.parse(match.group(2)!);
    if (m >= 60) return null;
    return _clamp(h * 60 + m);
  }

  // Minutes with a unit suffix: "90m", "90min".
  final mOnly = RegExp(r'^(\d+)m(?:in|ins|inute|inutes)?$').firstMatch(s);
  if (mOnly != null) {
    return _clamp(int.parse(mOnly.group(1)!));
  }

  return null;
}

int? _clamp(int minutes) {
  if (minutes <= 0) return null;
  if (minutes > _maxMinutes) return null;
  return minutes;
}

/// Renders [minutes] for display. Under 60 minutes stays in minutes
/// ("45 min"); 60 and above switch to hours, with a leftover minute part
/// when it is non-zero ("1 h 30 min", "4 h").
String formatDuration(int minutes, AppLocalizations l10n) {
  final m = minutes < 0 ? 0 : minutes;
  if (m < 60) return l10n.commonMinutes(m);
  final h = m ~/ 60;
  final rem = m % 60;
  if (rem == 0) return l10n.commonHours(h);
  return l10n.commonHoursMinutes(h, rem);
}
