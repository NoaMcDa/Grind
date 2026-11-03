import 'dart:async';

import '../domain/domain.dart';

/// Recurrence rules attached to tasks (one-time reminders have none).
abstract interface class ReminderRepository {
  Future<List<ReminderRule>> getAll();
  Future<ReminderRule?> getForTask(String taskId);
  Future<void> upsert(ReminderRule rule);
  Future<void> delete(String id);
  Stream<List<ReminderRule>> watchAll();
}

class InMemoryReminderRepository implements ReminderRepository {
  InMemoryReminderRepository([Iterable<ReminderRule> seed = const []]) {
    for (final r in seed) {
      _rules[r.id] = r;
    }
  }

  final Map<String, ReminderRule> _rules = {};
  final _changes = StreamController<List<ReminderRule>>.broadcast();

  List<ReminderRule> get _live =>
      _rules.values.where((r) => r.deletedAt == null).toList();

  @override
  Future<List<ReminderRule>> getAll() async => _live;

  @override
  Future<ReminderRule?> getForTask(String taskId) async =>
      _live.where((r) => r.taskId == taskId).firstOrNull;

  @override
  Future<void> upsert(ReminderRule rule) async {
    _rules[rule.id] = rule;
    _changes.add(_live);
  }

  @override
  Future<void> delete(String id) async {
    final r = _rules[id];
    if (r == null) return;
    final now = DateTime.now().toUtc();
    _rules[id] = r.copyWith(deletedAt: now, updatedAt: now);
    _changes.add(_live);
  }

  @override
  Stream<List<ReminderRule>> watchAll() async* {
    yield _live;
    yield* _changes.stream;
  }
}
