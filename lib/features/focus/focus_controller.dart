import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/core.dart';
import 'providers.dart';

/// Interval lengths. Defaults are the classic 25/5 with a longer break after
/// every fourth session; RESEARCH.md Part 1C says users should be able to
/// adjust them. Held by the controller until a settings row exists.
class FocusSettings {
  const FocusSettings({
    this.focusMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.sessionsPerCycle = 4,
  });

  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int sessionsPerCycle;

  /// Bounds for the length picker on the idle screen.
  static const minFocusMinutes = 5;
  static const maxFocusMinutes = 120;

  /// What "+5 min" adds, and the step of the idle length picker.
  static const stepMinutes = 5;

  FocusSettings copyWith({
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? sessionsPerCycle,
  }) => FocusSettings(
    focusMinutes: focusMinutes ?? this.focusMinutes,
    shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
    longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
    sessionsPerCycle: sessionsPerCycle ?? this.sessionsPerCycle,
  );
}

enum FocusPhase { idle, focusing, paused, onBreak }

/// How a session ended; the screen shows the end-of-session sheet for it.
class FocusOutcome {
  const FocusOutcome({
    required this.sessionId,
    required this.taskId,
    required this.completed,
    required this.focusedMinutes,
  });

  final String sessionId;
  final String? taskId;

  /// True when the timer ran out, false when the user ended early.
  final bool completed;
  final int focusedMinutes;
}

/// What [FocusController.tick] noticed.
enum FocusTick { none, sessionOver, breakOver }

/// Immutable timer state. All times are wall-clock timestamps: the remaining
/// time is always `endsAt - now`, so backgrounding, a hidden tab or a missed
/// tick cannot make it drift.
class FocusState {
  const FocusState({
    this.phase = FocusPhase.idle,
    this.settings = const FocusSettings(),
    this.session,
    this.pausedTotal = Duration.zero,
    this.pausedAt,
    this.breakEndsAt,
    this.breakLength = Duration.zero,
    this.completedInCycle = 0,
    this.outcome,
  });

  final FocusPhase phase;
  final FocusSettings settings;

  /// The active session while focusing or paused.
  final FocusSession? session;

  /// Sum of finished pauses in [session].
  final Duration pausedTotal;

  /// Start of the current pause.
  final DateTime? pausedAt;

  final DateTime? breakEndsAt;
  final Duration breakLength;

  /// Completed sessions in the current cycle (0..sessionsPerCycle).
  final int completedInCycle;

  /// Set when a session ends, until the screen dismisses it.
  final FocusOutcome? outcome;

  bool get isRunning => phase == FocusPhase.focusing;
  bool get hasSession => session != null;

  Duration get planned =>
      Duration(minutes: session?.plannedMinutes ?? settings.focusMinutes);

  /// When the session's timer reaches zero (pauses push it later).
  DateTime? get endsAt => session?.startedAt.add(planned + pausedTotal);

  /// The full length of what the ring shows.
  Duration get total => phase == FocusPhase.onBreak ? breakLength : planned;

  Duration remaining(DateTime now) {
    final Duration left;
    switch (phase) {
      case FocusPhase.idle:
        return planned;
      case FocusPhase.focusing:
        left = endsAt!.difference(now);
      case FocusPhase.paused:
        left = endsAt!.difference(pausedAt!);
      case FocusPhase.onBreak:
        left = breakEndsAt!.difference(now);
    }
    return left.isNegative ? Duration.zero : left;
  }

  /// Share of [total] already used, 0..1.
  double progress(DateTime now) {
    final t = total.inMilliseconds;
    if (t <= 0) return 0;
    return (1 - remaining(now).inMilliseconds / t).clamp(0.0, 1.0);
  }

  /// Time actually focused in [session] up to [at], pauses excluded.
  Duration focused(DateTime at) {
    final s = session;
    if (s == null) return Duration.zero;
    final until = pausedAt ?? at;
    final d = until.difference(s.startedAt) - pausedTotal;
    if (d.isNegative) return Duration.zero;
    return d > planned ? planned : d;
  }

  /// 1-based number of the session in the cycle, for "Focus 2 of 4".
  int get currentNumber {
    final n = settings.sessionsPerCycle;
    if (phase == FocusPhase.focusing || phase == FocusPhase.paused) {
      return (completedInCycle + 1).clamp(1, n);
    }
    return completedInCycle >= n ? n : (completedInCycle + 1).clamp(1, n);
  }

  FocusState copyWith({
    FocusPhase? phase,
    FocusSettings? settings,
    Object? session = _unset,
    Duration? pausedTotal,
    Object? pausedAt = _unset,
    Object? breakEndsAt = _unset,
    Duration? breakLength,
    int? completedInCycle,
    Object? outcome = _unset,
  }) => FocusState(
    phase: phase ?? this.phase,
    settings: settings ?? this.settings,
    session: session == _unset ? this.session : session as FocusSession?,
    pausedTotal: pausedTotal ?? this.pausedTotal,
    pausedAt: pausedAt == _unset ? this.pausedAt : pausedAt as DateTime?,
    breakEndsAt: breakEndsAt == _unset
        ? this.breakEndsAt
        : breakEndsAt as DateTime?,
    breakLength: breakLength ?? this.breakLength,
    completedInCycle: completedInCycle ?? this.completedInCycle,
    outcome: outcome == _unset ? this.outcome : outcome as FocusOutcome?,
  );
}

const _unset = Object();

/// Drives the Focus tab: start, pause/resume, +5 min, end, breaks and the
/// 4-session cycle. Ticks only redraw; every number comes from timestamps
/// and [clockProvider]. On build it restores the active session from
/// [FocusSessionRepository.getActive], so a restart keeps the timer.
///
/// Pauses are persisted on the session: [pause] writes
/// [FocusSession.pausedAt], [resume] folds the pause into
/// [FocusSession.pausedMs]. A restart while paused comes back paused, and
/// paused time never counts as focused.
///
/// Breaks are not stored: only focus sessions (kind
/// [FocusSessionKind.focus]) are written. A break lives in memory, so a
/// restart during a break lands on the idle screen, which is harmless.
class FocusController extends AsyncNotifier<FocusState> {
  FocusSessionRepository get _repo => ref.read(focusSessionRepositoryProvider);
  TaskRepository get _tasks => ref.read(taskRepositoryProvider);
  DateTime _now() => ref.read(clockProvider).now().toUtc();

  @override
  Future<FocusState> build() async {
    final now = _now();
    const settings = FocusSettings();
    final local = ref.read(clockProvider).now().toLocal();
    final midnight = DateTime(local.year, local.month, local.day).toUtc();
    final today = await _repo.getBetween(
      midnight,
      midnight.add(const Duration(days: 1)),
    );
    final done = today
        .where((s) => s.kind == FocusSessionKind.focus && s.completed)
        .length;
    var s = FocusState(
      settings: settings,
      completedInCycle: done % settings.sessionsPerCycle,
    );
    final active = await _repo.getActive();
    if (active != null && active.kind == FocusSessionKind.focus) {
      s = s.copyWith(
        phase: active.isPaused ? FocusPhase.paused : FocusPhase.focusing,
        session: active,
        pausedTotal: active.paused,
        pausedAt: active.pausedAt,
      );
      s = (await _advance(s, now)).$1;
    }
    return s;
  }

  FocusState? get _s => state.valueOrNull;

  void _set(FocusState s) => state = AsyncData(s);

  /// Change the interval lengths (applies to the next session or break).
  void updateSettings(FocusSettings settings) {
    final s = _s;
    if (s == null) return;
    _set(s.copyWith(settings: settings));
  }

  /// Idle only: adjust the length of the next session by [deltaMinutes].
  void adjustNextLength(int deltaMinutes) {
    final s = _s;
    if (s == null || s.hasSession) return;
    final m = (s.settings.focusMinutes + deltaMinutes).clamp(
      FocusSettings.minFocusMinutes,
      FocusSettings.maxFocusMinutes,
    );
    _set(s.copyWith(settings: s.settings.copyWith(focusMinutes: m)));
  }

  /// Start a session on [taskId] (or a free session). Ends a running one
  /// first, and skips a break that is still going.
  Future<void> start({String? taskId, int? plannedMinutes}) async {
    var s = _s;
    if (s == null) return;
    if (s.hasSession) {
      await end();
      s = _s!;
    }
    final now = _now();
    final session = FocusSession(
      id: const Uuid().v4(),
      taskId: taskId,
      plannedMinutes: plannedMinutes ?? s.settings.focusMinutes,
      startedAt: now,
      createdAt: now,
      updatedAt: now,
    );
    await _repo.start(session);
    _set(
      s.copyWith(
        phase: FocusPhase.focusing,
        session: session,
        pausedTotal: Duration.zero,
        pausedAt: null,
        breakEndsAt: null,
        breakLength: Duration.zero,
        completedInCycle: s.completedInCycle >= s.settings.sessionsPerCycle
            ? 0
            : s.completedInCycle,
        outcome: null,
      ),
    );
  }

  /// Freeze the timer. The pause start is stored on the session, so a
  /// restart while paused restores the paused state.
  Future<void> pause() async {
    final s = _s;
    if (s == null || s.phase != FocusPhase.focusing) return;
    final now = _now();
    final session = s.session!.copyWith(pausedAt: now, updatedAt: now);
    _set(s.copyWith(phase: FocusPhase.paused, session: session, pausedAt: now));
    await _repo.update(session);
  }

  /// Continue; the finished pause is added to [FocusSession.pausedMs].
  Future<void> resume() async {
    final s = _s;
    if (s == null || s.phase != FocusPhase.paused) return;
    final now = _now();
    final total = s.pausedTotal + now.difference(s.pausedAt!);
    final session = s.session!.copyWith(
      pausedMs: total.inMilliseconds,
      pausedAt: null,
      updatedAt: now,
    );
    _set(
      s.copyWith(
        phase: FocusPhase.focusing,
        session: session,
        pausedTotal: total,
        pausedAt: null,
      ),
    );
    await _repo.update(session);
  }

  /// +5 min on the running session or break.
  Future<void> extend([int minutes = FocusSettings.stepMinutes]) async {
    final s = _s;
    if (s == null) return;
    if (s.phase == FocusPhase.onBreak) {
      final more = Duration(minutes: minutes);
      _set(
        s.copyWith(
          breakEndsAt: s.breakEndsAt!.add(more),
          breakLength: s.breakLength + more,
        ),
      );
      return;
    }
    final session = s.session;
    if (session == null) return;
    final updated = session.copyWith(
      plannedMinutes: session.plannedMinutes + minutes,
      updatedAt: _now(),
    );
    await _repo.update(updated);
    _set(s.copyWith(session: updated));
  }

  /// End the session now. [completed] marks it as a full session (counts
  /// toward the cycle and starts a break); the End button passes false.
  Future<void> end({bool completed = false}) async {
    final s = _s;
    if (s == null || !s.hasSession) return;
    _set(await _finish(s, _now(), completed: completed));
  }

  /// Call on every redraw tick and when the app returns to the foreground.
  /// Ends the session or the break if its end time has passed.
  Future<FocusTick> tick() async {
    final s = _s;
    if (s == null) return FocusTick.none;
    final (next, what) = await _advance(s, _now());
    if (!identical(next, s)) _set(next);
    return what;
  }

  /// Break over (or skipped): back to idle, ready for the next session.
  void skipBreak() {
    final s = _s;
    if (s == null || s.phase != FocusPhase.onBreak) return;
    _set(_toIdle(s));
  }

  /// Store the user's one-line note on what got done in the session the
  /// end-of-session sheet is about. Blank text clears it.
  Future<void> saveWin(String sessionId, String win) async {
    final ended = _lastEnded;
    if (ended == null || ended.id != sessionId) return;
    final text = win.trim();
    final updated = ended.copyWith(
      win: text.isEmpty ? null : text,
      updatedAt: _now(),
    );
    _lastEnded = updated;
    await _repo.update(updated);
  }

  /// The end-of-session sheet was handled.
  void dismissOutcome() {
    final s = _s;
    if (s == null || s.outcome == null) return;
    _set(s.copyWith(outcome: null));
  }

  // ------------------------------------------------------------ internals

  /// The session the current outcome is about, for [saveWin].
  FocusSession? _lastEnded;

  FocusState _toIdle(FocusState s) => s.copyWith(
    phase: FocusPhase.idle,
    session: null,
    pausedTotal: Duration.zero,
    pausedAt: null,
    breakEndsAt: null,
    breakLength: Duration.zero,
  );

  /// Applies every transition whose time has come, using the exact end
  /// timestamps (not [now]) so a session finished while backgrounded is
  /// logged with its true end.
  Future<(FocusState, FocusTick)> _advance(FocusState s, DateTime now) async {
    var what = FocusTick.none;
    if (s.phase == FocusPhase.focusing && !now.isBefore(s.endsAt!)) {
      s = await _finish(s, s.endsAt!, completed: true);
      what = FocusTick.sessionOver;
    }
    if (s.phase == FocusPhase.onBreak && !now.isBefore(s.breakEndsAt!)) {
      s = _toIdle(s);
      if (what == FocusTick.none) what = FocusTick.breakOver;
    }
    return (s, what);
  }

  Future<FocusState> _finish(
    FocusState s,
    DateTime at, {
    required bool completed,
  }) async {
    final session = s.session!;
    final focused = s.focused(at);
    final minutes = (focused.inSeconds / 60).round();
    // Ending while paused: the open pause counts as paused, up to [at].
    final open = s.pausedAt;
    final pausedTotal = open == null || !at.isAfter(open)
        ? s.pausedTotal
        : s.pausedTotal + at.difference(open);
    final ended = session.copyWith(
      endedAt: at,
      completed: completed,
      pausedMs: pausedTotal.inMilliseconds,
      pausedAt: null,
      updatedAt: _now(),
    );
    _lastEnded = ended;
    await _repo.update(ended);
    await _addActualMinutes(session.taskId, minutes);

    final outcome = FocusOutcome(
      sessionId: session.id,
      taskId: session.taskId,
      completed: completed,
      focusedMinutes: minutes,
    );
    final idle = _toIdle(s).copyWith(outcome: outcome);
    if (!completed) return idle;

    final count = s.completedInCycle + 1;
    final long = count >= s.settings.sessionsPerCycle;
    final breakLength = Duration(
      minutes: long
          ? s.settings.longBreakMinutes
          : s.settings.shortBreakMinutes,
    );
    return idle.copyWith(
      phase: FocusPhase.onBreak,
      completedInCycle: count,
      breakEndsAt: at.add(breakLength),
      breakLength: breakLength,
    );
  }

  /// Analytics seam: focused minutes accumulate on the task.
  Future<void> _addActualMinutes(String? taskId, int minutes) async {
    if (taskId == null || minutes <= 0) return;
    final task = await _tasks.getById(taskId);
    if (task == null) return;
    await _tasks.upsert(
      task.copyWith(
        actualMinutes: (task.actualMinutes ?? 0) + minutes,
        updatedAt: _now(),
      ),
    );
  }
}
