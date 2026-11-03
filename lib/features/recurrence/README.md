# Recurrence

A recurring task is one `Task` plus one `ReminderRule`. This folder expands
the rule into occurrences (`occurrence_expander.dart`), completes them
(`occurrence_completion.dart`), schedules their notifications
(`recurrence_notifications.dart`) and edits a series (`series_edit.dart`).

## Where the state lives

| Field | Meaning |
|---|---|
| `ReminderRule.rrule` line 1 | RRULE body (`FREQ=WEEKLY;BYDAY=MO`) |
| `DTSTART:` line | The series' first occurrence, wall clock in the user's zone. Written by `pinSeriesStart` before `remindAt` first moves; absent means "starts at `Task.remindAt`" |
| `EXDATE:` line | Skipped occurrences ("this one" edits) |
| `ReminderRule.lastCompletedAt` | The most recently completed occurrence (UTC). Every occurrence at or before it counts as done |
| `Task.remindAt` | The next pending occurrence, for the core notification scheduler and the reminder card |
| `Task.status` | `done` only when the series has no occurrence left |

`COUNT` and `until` are counted from the series start (DTSTART, else
`remindAt`), so moving `remindAt` on never restarts them.

## Completing

- `completeSeriesOccurrence` sets `lastCompletedAt` to the occurrence (it never
  moves backwards), pins DTSTART, and moves `remindAt` to the next occurrence
  after it, or marks the task done when none is left. Store both the task and
  the rule. `completeOccurrence` is its task half, for callers that cannot
  write the rule yet.
- `uncompleteSeriesOccurrence` sets `lastCompletedAt` back to the occurrence
  before the one being un-checked (null for the first), reopens the task and
  sets `remindAt` to the first occurrence after the new `lastCompletedAt`.
- Notifications: occurrences at or before `lastCompletedAt` are not pending.
- Today (`itemsOnDay` in `lib/features/tasks`): occurrences at or before
  `lastCompletedAt` are done rows when `lastCompletedAt` is on that day, and
  left out on other days (not due, and not known to be done). Later
  occurrences are open rows.

## Editing a series

- "This one" (`editThisOccurrence`): the occurrence becomes an EXDATE and a
  one-off copy. The copy is done when the occurrence was done. The series
  keeps its DTSTART and `lastCompletedAt` (EXDATEs still count toward
  `COUNT`, as in RFC 5545).
- "All future" (`editAllFuture`) at an occurrence after the series start:
  - the old rule ends one minute before it (`until`) and keeps DTSTART and
    `lastCompletedAt`; when `remindAt` is at or after the split nothing is
    pending in the old part and its task is done;
  - the new series starts at the occurrence with the `COUNT` that is left and
    the EXDATEs from then on (or the new RRULE as given);
  - a `lastCompletedAt` at or after the split moves to the new series, which
    then pins its start and sets `remindAt` to its next pending occurrence.
- "All future" at or before the series start edits in place: DTSTART is
  dropped (the series starts at the new `remindAt`), `lastCompletedAt` stays.
- Changing the reminder time in the task form drops DTSTART the same way;
  changing the repeat rule replaces the whole `rrule` text.
