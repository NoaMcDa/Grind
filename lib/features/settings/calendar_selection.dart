import '../../core/core.dart';

/// Which calendars of a connected provider Grind reads from.
class CalendarSelection {
  const CalendarSelection({required this.source, required this.ids});

  final CalendarSource source;
  final Set<String> ids;

  bool contains(String id) => ids.contains(id);

  CalendarSelection toggle(String id) {
    final next = Set<String>.of(ids);
    if (!next.remove(id)) next.add(id);
    return CalendarSelection(source: source, ids: next);
  }

  /// Default before the user chooses: the primary calendar(s) only.
  static CalendarSelection defaults(
    CalendarSource source,
    List<ExternalCalendar> calendars,
  ) => CalendarSelection(
    source: source,
    ids: {for (final c in calendars.where((c) => c.isPrimary)) c.id},
  );
}
