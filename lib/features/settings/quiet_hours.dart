import '../../core/core.dart';
import '../onboarding/weekday_hours_editor.dart' show formatMinutes;

/// Quiet hours when the user first turns them on: overnight, 22:00–07:00.
/// The notification scheduler handles ranges that cross midnight.
const defaultQuietHours = TimeRange.wrapping(
  startMinutes: 22 * 60,
  endMinutes: 7 * 60,
);

/// [range] with a new start or end. Any order is allowed (an end before the
/// start crosses midnight); the same start and end would be empty, so that
/// returns null and the caller keeps the old range.
TimeRange? changeQuietHours(TimeRange range, {int? start, int? end}) {
  final s = start ?? range.startMinutes;
  final e = end ?? range.endMinutes;
  if (s < 0 || s >= 24 * 60 || e < 0 || e > 24 * 60) return null;
  if (s == e) return null;
  return TimeRange.wrapping(startMinutes: s, endMinutes: e);
}

/// "22:00 – 07:00".
String formatQuietHours(TimeRange range) =>
    '${formatMinutes(range.startMinutes)} – ${formatMinutes(range.endMinutes)}';
