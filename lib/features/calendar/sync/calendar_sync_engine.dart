import 'dart:async';

import '../../../core/core.dart';
import 'calendar_sync_errors.dart';
import 'sync_status.dart';

/// Result of one [CalendarSyncEngine.pull].
class PullResult {
  const PullResult({
    this.upserted = const [],
    this.removed = const [],
    this.moved = const [],
    this.vanished = const [],
  });

  /// New or changed events written to the repository.
  final List<CalendarEvent> upserted;

  /// Events soft-deleted because they are gone from the provider's window.
  final List<CalendarEvent> removed;

  /// Write-backs (events with a `taskId`) whose time changed in the external
  /// calendar since Grind last saw them.
  final List<CalendarEvent> moved;

  /// Write-backs that disappeared from the external calendar.
  final List<CalendarEvent> vanished;

  static const empty = PullResult();
}

/// Provider-agnostic two-way sync between one [CalendarProvider] and the
/// local [CalendarRepository] / [TaskRepository].
///
/// * [pull] mirrors external events into the repository, keyed by
///   `(source, externalId)`.
/// * [pushTask] writes a scheduled task back as an event (when [writeBack]).
/// * [pullWriteBacks] applies external moves / deletes of written-back events
///   to their tasks.
///
/// Conflict policy (docs/adr/0005-google-calendar.md): the calendar wins for
/// time, the app wins for task fields (title, notes). A move is only taken
/// from the calendar when the event changed there since the last sync, so an
/// edit made in Grind is never undone by a stale calendar copy.
class CalendarSyncEngine {
  CalendarSyncEngine({
    required this.provider,
    required this.calendarRepository,
    required this.taskRepository,
    required this.preferencesRepository,
    required this.clock,
    this.writeBack = true,
    this.pastDays = 7,
    this.futureDays = 30,
  });

  final CalendarProvider provider;
  final CalendarRepository calendarRepository;
  final TaskRepository taskRepository;
  final PreferencesRepository preferencesRepository;
  final Clock clock;

  /// Whether scheduled tasks become events in this provider. Only one
  /// provider should write back, since [Task.calendarEventId] is one field.
  final bool writeBack;
  final int pastDays;
  final int futureDays;

  CalendarSource get source => provider.source;

  final _statusController = StreamController<SyncStatus>.broadcast();
  SyncStatus _status = const SyncStatus.idle();

  /// Write-backs changed externally, waiting for [pullWriteBacks].
  final List<CalendarEvent> _pendingMoves = [];
  final List<CalendarEvent> _pendingVanished = [];

  Future<void>? _inFlight;
  Future<void> _queue = Future.value();

  /// Runs [job] after every earlier queued job, so pushes never race a sync.
  Future<T> _serial<T>(Future<T> Function() job) {
    final result = _queue.then((_) => job());
    _queue = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  SyncStatus get status => _status;

  /// Current status first, then every change.
  Stream<SyncStatus> watchStatus() async* {
    yield _status;
    yield* _statusController.stream;
  }

  void _setStatus(SyncStatus s) {
    if (s == _status) return;
    _status = s;
    if (!_statusController.isClosed) _statusController.add(s);
  }

  DateTime _now() => clock.now().toUtc();

  /// Forget everything held in memory (pending moves, last status), after
  /// the provider was disconnected or all local data was replaced. Queued
  /// behind any sync in flight, so a running sync cannot repopulate it.
  Future<void> reset() => _serial(() async {
    _pendingMoves.clear();
    _pendingVanished.clear();
    _setStatus(const SyncStatus.idle());
  });

  /// The sync window: [pastDays] back to [futureDays] ahead, whole UTC days.
  ({DateTime from, DateTime to}) window() {
    final now = _now();
    final today = DateTime.utc(now.year, now.month, now.day);
    return (
      from: today.subtract(Duration(days: pastDays)),
      to: today.add(Duration(days: futureDays + 1)),
    );
  }

  /// One full cycle: pull, apply external write-back changes, push pending
  /// tasks. Concurrent calls share the run in flight.
  Future<void> sync() => _inFlight ??= _serial(_run).whenComplete(() {
    _inFlight = null;
  });

  /// Push task changes on their own (after an edit in Grind), queued behind
  /// any sync in flight. Errors land in [status].
  Future<void> pushSoon() => _serial(() async {
    try {
      await pushPending();
    } on CalendarSyncException catch (e) {
      _setStatus(SyncStatus.error(e.kind, lastSyncedAt: _status.lastSyncedAt));
    } catch (_) {
      _setStatus(
        SyncStatus.error(
          SyncErrorKind.generic,
          lastSyncedAt: _status.lastSyncedAt,
        ),
      );
    }
  });

  Future<void> _run() async {
    final last = _status.lastSyncedAt;
    _setStatus(SyncStatus.syncing(lastSyncedAt: last));
    try {
      if (!await provider.isConnected()) {
        await calendarRepository.clearSource(source);
        _pendingMoves.clear();
        _pendingVanished.clear();
        _setStatus(SyncStatus.idle(lastSyncedAt: last));
        return;
      }
      await pull();
      await pullWriteBacks();
      if (writeBack) await pushPending();
      _setStatus(SyncStatus.idle(lastSyncedAt: _now()));
    } on CalendarSyncException catch (e) {
      _setStatus(SyncStatus.error(e.kind, lastSyncedAt: last));
    } catch (_) {
      _setStatus(SyncStatus.error(SyncErrorKind.generic, lastSyncedAt: last));
    }
  }

  /// Calendars to read: the user's choice for this source, or the primary
  /// calendar when they never chose.
  Future<List<String>> selectedCalendarIds() async {
    final prefs = await preferencesRepository.get();
    final chosen = prefs.selectedCalendarIds[source];
    if (chosen != null) return chosen;
    final calendars = await provider.listCalendars();
    final primary = calendars.where((c) => c.isPrimary).toList();
    if (primary.isNotEmpty) return [primary.first.id];
    return calendars.isEmpty ? const [] : [calendars.first.id];
  }

  /// Calendar that receives write-backs: the primary one when writable,
  /// else the first writable selected calendar.
  Future<String?> writeCalendarId() async {
    final calendars = await provider.listCalendars();
    final writable = calendars.where((c) => c.canWrite).toList();
    final primary = writable.where((c) => c.isPrimary).firstOrNull;
    if (primary != null) return primary.id;
    final selected = await selectedCalendarIds();
    return writable.where((c) => selected.contains(c.id)).firstOrNull?.id ??
        writable.firstOrNull?.id;
  }

  /// Mirror external events in [from, to) (default: [window]) into the
  /// repository and soft-delete those that vanished.
  Future<PullResult> pull({DateTime? from, DateTime? to}) async {
    final w = window();
    final start = (from ?? w.from).toUtc();
    final end = (to ?? w.to).toUtc();
    if (!await provider.isConnected()) return PullResult.empty;

    final ids = await selectedCalendarIds();
    final incoming = ids.isEmpty
        ? const <CalendarEvent>[]
        : await provider.fetchEvents(calendarIds: ids, from: start, to: end);

    final now = _now();
    final seen = <String>{};
    final upserts = <CalendarEvent>[];
    final moved = <CalendarEvent>[];
    for (final e in incoming) {
      if (!seen.add(e.externalId)) continue;
      final prior = await calendarRepository.getByExternalId(
        source,
        e.externalId,
      );
      final merged = CalendarEvent(
        id:
            prior?.id ??
            (e.id.isEmpty ? '${source.name}:${e.externalId}' : e.id),
        source: source,
        externalId: e.externalId,
        calendarId: e.calendarId ?? prior?.calendarId,
        title: e.title,
        start: e.start.toUtc(),
        end: e.end.toUtc(),
        isAllDay: e.isAllDay,
        isBusy: e.isBusy,
        taskId: e.taskId ?? prior?.taskId,
        htmlLink: e.htmlLink,
        createdAt: prior?.createdAt ?? e.createdAt,
        updatedAt: prior == null ? e.updatedAt : now,
      );
      if (prior != null && _same(prior, merged)) continue;
      upserts.add(merged);
      if (prior != null &&
          merged.taskId != null &&
          (prior.start != merged.start || prior.end != merged.end)) {
        moved.add(merged);
      }
    }
    if (upserts.isNotEmpty) await calendarRepository.upsertAll(upserts);

    final existing = await calendarRepository.getBetween(start, end);
    final removed = <CalendarEvent>[];
    final vanished = <CalendarEvent>[];
    for (final e in existing) {
      if (e.source != source || seen.contains(e.externalId)) continue;
      // A write-back in a calendar we did not ask for (the user reads
      // "Work", Grind writes to the primary one) is absent from `incoming`
      // by construction, not because it was deleted.
      if (e.taskId != null &&
          e.calendarId != null &&
          !ids.contains(e.calendarId)) {
        continue;
      }
      await calendarRepository.delete(e.id);
      removed.add(e);
      if (e.taskId != null) vanished.add(e);
    }

    _pendingMoves.addAll(moved);
    _pendingVanished.addAll(vanished);
    return PullResult(
      upserted: upserts,
      removed: removed,
      moved: moved,
      vanished: vanished,
    );
  }

  /// Apply external changes to written-back events: a moved event moves its
  /// task (and pins it, since a person placed it), a deleted event
  /// unschedules its task. Returns the tasks that changed.
  Future<List<Task>> pullWriteBacks() async {
    final changed = <Task>[];
    final now = _now();
    final moves = List.of(_pendingMoves);
    final gone = List.of(_pendingVanished);
    _pendingMoves.clear();
    _pendingVanished.clear();

    for (final e in moves) {
      final task = await taskRepository.getById(e.taskId!);
      if (task == null || task.calendarEventId != e.externalId) continue;
      if (task.scheduledStart == e.start && task.scheduledEnd == e.end) {
        continue;
      }
      final next = task.copyWith(
        scheduledStart: e.start,
        scheduledEnd: e.end,
        lockedStart: true,
        updatedAt: now,
      );
      await taskRepository.upsert(next);
      changed.add(next);
    }
    for (final e in gone) {
      final task = await taskRepository.getById(e.taskId!);
      if (task == null || task.calendarEventId != e.externalId) continue;
      final next = task.copyWith(
        scheduledStart: null,
        scheduledEnd: null,
        lockedStart: false,
        calendarEventId: null,
        updatedAt: now,
      );
      await taskRepository.upsert(next);
      changed.add(next);
    }
    return changed;
  }

  /// Bring every task's write-back up to date: create events for newly
  /// scheduled open tasks in the window, update moved or renamed ones,
  /// delete events of unscheduled, skipped or deleted tasks.
  Future<void> pushPending() async {
    if (!writeBack || !await provider.isConnected()) return;
    final w = window();
    final tasks = await taskRepository.getAll();
    final byId = {for (final t in tasks) t.id: t};
    for (final t in tasks) {
      final inWindow =
          t.isScheduled &&
          t.scheduledStart!.isBefore(w.to) &&
          t.scheduledEnd!.isAfter(w.from);
      if (t.calendarEventId != null ||
          (inWindow && t.status == TaskStatus.open)) {
        await pushTask(t);
      }
    }
    // Write-backs whose task is gone (deleted in Grind).
    final events = await calendarRepository.getBetween(w.from, w.to);
    for (final e in events) {
      if (e.source != source || e.taskId == null) continue;
      if (byId.containsKey(e.taskId)) continue;
      await _deleteExternal(e.calendarId, e.externalId);
      await calendarRepository.delete(e.id);
    }
  }

  /// Create, update or delete the write-back event for [task]. Returns the
  /// task as stored afterwards (with `calendarEventId` set or cleared).
  Future<Task> pushTask(Task task) async {
    if (!writeBack || !await provider.isConnected()) return task;
    final ext = task.calendarEventId;
    final local = ext == null
        ? null
        : await calendarRepository.getByExternalId(source, ext);
    // Adopted from an imported event: the mirror existed before the task
    // (the event was pulled first, then turned into a task from the Plan).
    // Grind owns the task; the external calendar keeps its event, so the
    // engine never creates, updates or deletes a second event for it.
    if (local != null && local.createdAt.isBefore(task.createdAt)) {
      return task;
    }
    final wants =
        task.deletedAt == null &&
        task.isScheduled &&
        task.status != TaskStatus.skipped;

    if (wants) {
      if (ext == null) {
        if (task.status != TaskStatus.open) return task;
        return _create(task);
      }
      if (local != null && _matches(local, task)) return task;
      final calendarId = local?.calendarId ?? await writeCalendarId();
      if (calendarId == null) return task;
      try {
        await provider.updateEvent(
          calendarId: calendarId,
          externalId: ext,
          task: task,
        );
      } on ExternalEventMissingException {
        if (local != null) await calendarRepository.delete(local.id);
        return _create(task);
      }
      await calendarRepository.upsert(
        _eventFor(task, ext, calendarId, prior: local),
      );
      return task;
    }

    if (ext == null) return task;
    await _deleteExternal(local?.calendarId, ext);
    if (local != null) await calendarRepository.delete(local.id);
    final next = task.copyWith(calendarEventId: null, updatedAt: _now());
    await taskRepository.upsert(next);
    return next;
  }

  Future<Task> _create(Task task) async {
    final calendarId = await writeCalendarId();
    if (calendarId == null) return task;
    final ext = await provider.createEvent(calendarId: calendarId, task: task);
    await calendarRepository.upsert(_eventFor(task, ext, calendarId));
    final next = task.copyWith(calendarEventId: ext, updatedAt: _now());
    await taskRepository.upsert(next);
    return next;
  }

  Future<void> _deleteExternal(String? calendarId, String externalId) async {
    final id = calendarId ?? await writeCalendarId();
    if (id == null) return;
    try {
      await provider.deleteEvent(calendarId: id, externalId: externalId);
    } on ExternalEventMissingException {
      // Already gone; nothing to do.
    }
  }

  CalendarEvent _eventFor(
    Task task,
    String externalId,
    String calendarId, {
    CalendarEvent? prior,
  }) {
    final now = _now();
    return CalendarEvent(
      id: prior?.id ?? '${source.name}:$externalId',
      source: source,
      externalId: externalId,
      calendarId: calendarId,
      title: task.title,
      start: task.scheduledStart!.toUtc(),
      end: task.scheduledEnd!.toUtc(),
      isBusy: true,
      taskId: task.id,
      createdAt: prior?.createdAt ?? now,
      updatedAt: now,
    );
  }

  static bool _matches(CalendarEvent e, Task t) =>
      e.title == t.title &&
      e.start == t.scheduledStart?.toUtc() &&
      e.end == t.scheduledEnd?.toUtc();

  static bool _same(CalendarEvent a, CalendarEvent b) =>
      a.title == b.title &&
      a.start == b.start &&
      a.end == b.end &&
      a.isAllDay == b.isAllDay &&
      a.isBusy == b.isBusy &&
      a.taskId == b.taskId &&
      a.calendarId == b.calendarId &&
      a.htmlLink == b.htmlLink;

  Future<void> dispose() => _statusController.close();
}
