import 'dart:async';

import '../domain/domain.dart';

/// Persistence for focus sessions (#19). A session is *active* while its
/// `endedAt` is null; the focus controller ends the previous one before it
/// starts another, so at most one is active at a time. Sessions with a
/// `deletedAt` are hidden from every read.
///
/// Lives in `lib/core/data` rather than `lib/core/repositories` because
/// feature agents may only add files here; the integrator may move it next
/// to the other interfaces and export it from `repositories.dart`.
abstract interface class FocusSessionRepository {
  /// Insert a new session.
  Future<void> start(FocusSession session);

  /// Replace a stored session by id (+5 min, end). Unknown ids are ignored.
  Future<void> update(FocusSession session);

  /// The most recently started session that has not ended, if any.
  Future<FocusSession?> getActive();

  /// Sessions whose `startedAt` is in [from, to), oldest first.
  Future<List<FocusSession>> getBetween(DateTime from, DateTime to);

  /// Live view of [getActive]: current value first, then every change.
  Stream<FocusSession?> watchActive();

  /// Live view of [getBetween]: current value first, then every change.
  Stream<List<FocusSession>> watchBetween(DateTime from, DateTime to);
}

class InMemoryFocusSessionRepository implements FocusSessionRepository {
  InMemoryFocusSessionRepository([Iterable<FocusSession> seed = const []]) {
    for (final s in seed) {
      _sessions[s.id] = s;
    }
  }

  final Map<String, FocusSession> _sessions = {};
  final _changes = StreamController<void>.broadcast();

  /// Live (not soft-deleted) sessions, oldest first.
  List<FocusSession> get _sorted =>
      _sessions.values.where((s) => s.deletedAt == null).toList()
        ..sort((a, b) => a.startedAt.compareTo(b.startedAt));

  FocusSession? get _active =>
      _sorted.where((s) => s.endedAt == null).lastOrNull;

  List<FocusSession> _between(DateTime from, DateTime to) => _sorted
      .where((s) => !s.startedAt.isBefore(from) && s.startedAt.isBefore(to))
      .toList();

  @override
  Future<void> start(FocusSession session) async {
    _sessions[session.id] = session;
    _changes.add(null);
  }

  @override
  Future<void> update(FocusSession session) async {
    if (!_sessions.containsKey(session.id)) return;
    _sessions[session.id] = session;
    _changes.add(null);
  }

  @override
  Future<FocusSession?> getActive() async => _active;

  @override
  Future<List<FocusSession>> getBetween(DateTime from, DateTime to) async =>
      _between(from, to);

  @override
  Stream<FocusSession?> watchActive() async* {
    yield _active;
    yield* _changes.stream.map((_) => _active);
  }

  @override
  Stream<List<FocusSession>> watchBetween(DateTime from, DateTime to) async* {
    yield _between(from, to);
    yield* _changes.stream.map((_) => _between(from, to));
  }
}
