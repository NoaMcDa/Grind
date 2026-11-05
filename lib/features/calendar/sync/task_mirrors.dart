import '../../../core/core.dart';
import 'calendar_sync_engine.dart'
    show externalIdFromTaskCalendarEventId, isImportedCalendarEventId;

/// Which calendar events are the calendar copy of a Grind task, so a screen
/// that draws tasks does not draw the same block twice.
///
/// Two kinds of event mirror a task:
///
/// * a write-back: Grind created the event for a scheduled task, so the
///   event carries `taskId` (`extendedProperties.private.grindTaskId` on
///   Google, the local row's `taskId` otherwise);
/// * an import: the user tapped "Add as task" on the event, so a task holds
///   the event's external id behind the `imported:` sentinel in
///   `Task.calendarEventId`.
///
/// Either way the task is the thing to show, edit and count; the event stays
/// in the repository (the sync engine still follows moves of the external
/// copy) but is hidden from the Plan timeline, the load bars and the
/// capacity report.
///
/// External ids of events that a live task was created from.
Set<String> importedExternalIds(Iterable<Task> tasks) => {
  for (final t in tasks)
    if (t.deletedAt == null && isImportedCalendarEventId(t.calendarEventId))
      externalIdFromTaskCalendarEventId(t.calendarEventId)!,
};

/// True when [e] is the calendar copy of a task: a write-back, or an event
/// whose external id is in [imported] (see [importedExternalIds]).
bool isTaskMirror(CalendarEvent e, Set<String> imported) =>
    e.taskId != null || imported.contains(e.externalId);

/// [events] without the ones that mirror a task in [tasks].
List<CalendarEvent> withoutTaskMirrors(
  Iterable<CalendarEvent> events,
  Iterable<Task> tasks,
) {
  final imported = importedExternalIds(tasks);
  return [
    for (final e in events)
      if (!isTaskMirror(e, imported)) e,
  ];
}
