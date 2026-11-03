import 'dart:async';

import '../services/clock.dart';

/// Whether a milestone is still ahead or reached. There is no "missed":
/// a milestone whose date passed while open is simply *moved* (#25).
enum MilestoneStatus { open, done }

/// One step of a long goal (#25): "Finish module 3 by Dec 1". Ordered by
/// [sortOrder] under its goal. Tasks are linked to a milestone through
/// [MilestoneTaskLink] rows (the `milestone_tasks` table), so `Task` itself
/// needs no new field.
///
/// Not to be confused with the goals feature's `GoalMilestone` enum, which
/// names progress *events* (close to done, completed, quota hit).
class Milestone {
  const Milestone({
    required this.id,
    required this.goalId,
    required this.title,
    this.dueAt,
    this.sortOrder = 0,
    this.status = MilestoneStatus.open,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String goalId;
  final String title;

  /// UTC; the end of the local day the user picked. Null: no date.
  final DateTime? dueAt;

  /// Position under the goal, ascending (ties: oldest first).
  final int sortOrder;
  final MilestoneStatus status;
  final DateTime? completedAt;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDone => status == MilestoneStatus.done;

  Milestone copyWith({
    String? title,
    Object? dueAt = _unset,
    int? sortOrder,
    MilestoneStatus? status,
    Object? completedAt = _unset,
    DateTime? updatedAt,
    Object? deletedAt = _unset,
  }) => Milestone(
    id: id,
    goalId: goalId,
    title: title ?? this.title,
    dueAt: dueAt == _unset ? this.dueAt : dueAt as DateTime?,
    sortOrder: sortOrder ?? this.sortOrder,
    status: status ?? this.status,
    completedAt: completedAt == _unset
        ? this.completedAt
        : completedAt as DateTime?,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt == _unset ? this.deletedAt : deletedAt as DateTime?,
  );

  @override
  bool operator ==(Object other) =>
      other is Milestone &&
      other.id == id &&
      other.goalId == goalId &&
      other.title == title &&
      other.dueAt == dueAt &&
      other.sortOrder == sortOrder &&
      other.status == status &&
      other.completedAt == completedAt &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.deletedAt == deletedAt;

  @override
  int get hashCode => Object.hash(
    id,
    goalId,
    title,
    dueAt,
    sortOrder,
    status,
    completedAt,
    createdAt,
    updatedAt,
    deletedAt,
  );

  @override
  String toString() => 'Milestone($id, $title, $status, due $dueAt)';
}

/// A task that is one of a milestone's weekly steps. A task belongs to at
/// most one milestone; the task's own `goalId` is set to the milestone's
/// goal as well, so goal counts and lists keep working.
class MilestoneTaskLink {
  const MilestoneTaskLink({
    required this.taskId,
    required this.milestoneId,
    required this.createdAt,
  });

  final String taskId;
  final String milestoneId;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      other is MilestoneTaskLink &&
      other.taskId == taskId &&
      other.milestoneId == milestoneId &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(taskId, milestoneId, createdAt);
}

/// Persistence for milestones and their task links. Same shape as the core
/// repositories: soft delete for milestones, live views emit the current
/// value first.
abstract interface class MilestoneRepository {
  /// Non-deleted milestones of every goal, by goal then [Milestone.sortOrder].
  Future<List<Milestone>> getAll();

  Future<Milestone?> getById(String id);

  /// Insert or replace by id.
  Future<void> upsert(Milestone milestone);

  Future<void> upsertAll(Iterable<Milestone> milestones);

  /// Soft delete (sets deletedAt) and drops the milestone's task links;
  /// the tasks themselves stay.
  Future<void> delete(String id);

  Stream<List<Milestone>> watchAll();

  /// Links [taskId] to [milestoneId], replacing any earlier link.
  Future<void> linkTask(String taskId, String milestoneId);

  Future<void> unlinkTask(String taskId);

  /// Every task link, oldest first.
  Stream<List<MilestoneTaskLink>> watchLinks();
}

class InMemoryMilestoneRepository implements MilestoneRepository {
  InMemoryMilestoneRepository({
    Iterable<Milestone> seed = const [],
    Iterable<MilestoneTaskLink> links = const [],
    Clock clock = const SystemClock(),
  }) : _clock = clock {
    for (final m in seed) {
      _items[m.id] = m;
    }
    for (final l in links) {
      _links[l.taskId] = l;
    }
  }

  final Clock _clock;
  final Map<String, Milestone> _items = {};
  final Map<String, MilestoneTaskLink> _links = {};
  final _changes = StreamController<void>.broadcast();

  List<Milestone> get _live =>
      _items.values.where((m) => m.deletedAt == null).toList()
        ..sort(compareMilestones);

  List<MilestoneTaskLink> get _linkList =>
      _links.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  void _notify() => _changes.add(null);

  @override
  Future<List<Milestone>> getAll() async => _live;

  @override
  Future<Milestone?> getById(String id) async {
    final m = _items[id];
    return m == null || m.deletedAt != null ? null : m;
  }

  @override
  Future<void> upsert(Milestone milestone) => upsertAll([milestone]);

  @override
  Future<void> upsertAll(Iterable<Milestone> milestones) async {
    for (final m in milestones) {
      _items[m.id] = m;
    }
    _notify();
  }

  @override
  Future<void> delete(String id) async {
    final m = _items[id];
    if (m == null) return;
    final now = _clock.now().toUtc();
    _items[id] = m.copyWith(deletedAt: now, updatedAt: now);
    _links.removeWhere((_, l) => l.milestoneId == id);
    _notify();
  }

  @override
  Stream<List<Milestone>> watchAll() async* {
    yield _live;
    yield* _changes.stream.map((_) => _live);
  }

  @override
  Future<void> linkTask(String taskId, String milestoneId) async {
    _links[taskId] = MilestoneTaskLink(
      taskId: taskId,
      milestoneId: milestoneId,
      createdAt: _clock.now().toUtc(),
    );
    _notify();
  }

  @override
  Future<void> unlinkTask(String taskId) async {
    if (_links.remove(taskId) != null) _notify();
  }

  @override
  Stream<List<MilestoneTaskLink>> watchLinks() async* {
    yield _linkList;
    yield* _changes.stream.map((_) => _linkList);
  }
}

/// Goal, then [Milestone.sortOrder], then oldest first, then id.
int compareMilestones(Milestone a, Milestone b) {
  final g = a.goalId.compareTo(b.goalId);
  if (g != 0) return g;
  final s = a.sortOrder.compareTo(b.sortOrder);
  if (s != 0) return s;
  final c = a.createdAt.compareTo(b.createdAt);
  return c != 0 ? c : a.id.compareTo(b.id);
}

const _unset = Object();
