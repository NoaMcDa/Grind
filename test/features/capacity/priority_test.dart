import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/capacity/capacity.dart';
import 'package:grind/features/plan/scheduler/scheduler.dart' as sched;

final _now = DateTime.utc(2026, 11, 3, 9);

Task _t(
  String id, {
  int priority = 2,
  DateTime? due,
  int minutes = 60,
  String? goalId,
  TaskStatus status = TaskStatus.open,
}) => Task(
  id: id,
  title: 'Task $id',
  priority: priority,
  dueAt: due,
  estimatedMinutes: minutes,
  goalId: goalId,
  status: status,
  createdAt: _now,
  updatedAt: _now,
);

List<RankedTask> _rank(
  List<Task> tasks, {
  Map<String, Goal> goals = const {},
  Set<String> top = const {},
  sched.SchedulerWeights weights = const sched.SchedulerWeights(),
}) => rankTasks(
  tasks: tasks,
  goals: goals,
  now: _now,
  stats: const sched.UserStats(),
  weights: weights,
  avgFreeHoursPerDay: 6,
  topPinned: top,
);

Goal _goal(String id, double importance, {DateTime? lastProgressAt}) => Goal(
  id: id,
  title: 'Goal $id',
  importance: importance,
  progress: 0.4,
  lastProgressAt: lastProgressAt,
  createdAt: _now,
  updatedAt: _now,
);

void main() {
  group('rankTasks', () {
    test('orders by score, with 1-based ranks and the scheduler score', () {
      final tasks = [
        _t('someday', priority: 3),
        _t('tomorrow', due: _now.add(const Duration(days: 1))),
        _t('overdue', due: _now.subtract(const Duration(days: 1))),
      ];
      final r = _rank(tasks);
      expect(r.map((e) => e.task.id), ['overdue', 'tomorrow', 'someday']);
      expect(r.map((e) => e.rank), [1, 2, 3]);
      final expected = sched.score(
        tasks[2],
        null,
        _now,
        const sched.UserStats(),
        const sched.SchedulerWeights(),
        6,
      );
      expect(r.first.score, closeTo(expected, 1e-9));
    });

    test('skips done and deleted tasks', () {
      final r = _rank([
        _t('open'),
        _t('done', status: TaskStatus.done),
        _t('gone').copyWith(deletedAt: _now),
      ]);
      expect(r.map((e) => e.task.id), ['open']);
    });

    test('top pins rank above every score', () {
      final r = _rank(
        [
          _t('urgent', due: _now.add(const Duration(hours: 5)), priority: 1),
          _t('chill', priority: 3),
        ],
        top: {'chill'},
      );
      expect(r.map((e) => e.task.id), ['chill', 'urgent']);
      expect(r.first.pin, PriorityPin.top);
      expect(r.first.topReason, PriorityReason.pinnedTop);
    });

    test('weights change the order', () {
      final tasks = [
        _t('dated', due: _now.add(const Duration(days: 1))),
        _t('goal', goalId: 'g'),
      ];
      final goals = {'g': _goal('g', 1)};
      expect(
        _rank(
          tasks,
          goals: goals,
          weights: const sched.SchedulerWeights(
            urgency: 0.9,
            importance: 0,
            priority: 0,
            quickWin: 0,
          ),
        ).first.task.id,
        'dated',
      );
      expect(
        _rank(
          tasks,
          goals: goals,
          weights: const sched.SchedulerWeights(
            urgency: 0,
            importance: 0.9,
            priority: 0,
            quickWin: 0,
          ),
        ).first.task.id,
        'goal',
      );
    });
  });

  group('reasons', () {
    test('overdue, due soon, high, goal, stalled, quick win, steady', () {
      final goals = {
        'big': _goal(
          'big',
          0.9,
          lastProgressAt: _now.subtract(const Duration(days: 20)),
        ),
      };
      final r = {
        for (final e in _rank([
          _t(
            'overdue',
            due: _now.subtract(const Duration(days: 2)),
            minutes: 120,
          ),
          _t('soon', due: _now.add(const Duration(days: 1)), minutes: 120),
          _t('high', priority: 1, minutes: 120),
          _t('goal', goalId: 'big', minutes: 120),
          _t('quick', minutes: 10),
          _t('plain', minutes: 120),
        ], goals: goals))
          e.task.id: e,
      };
      expect(r['overdue']!.topReason, PriorityReason.overdue);
      expect(r['soon']!.topReason, PriorityReason.dueSoon);
      expect(r['high']!.reasons, contains(PriorityReason.markedHigh));
      expect(r['goal']!.reasons, contains(PriorityReason.goalMatters));
      expect(r['goal']!.reasons, contains(PriorityReason.goalStalled));
      expect(r['goal']!.reasons, contains(PriorityReason.goalMoving));
      expect(r['quick']!.reasons, contains(PriorityReason.quickWin));
      expect(r['plain']!.reasons, [PriorityReason.steady]);
      for (final e in r.values) {
        expect(e.reasons.length, lessThanOrEqualTo(3));
        expect(e.reasons, isNotEmpty);
      }
    });

    test('the breakdown rides along and sums to the score', () {
      final r = _rank([_t('a', due: _now.add(const Duration(days: 2)))]).single;
      expect(r.breakdown.total, r.score);
      expect(r.breakdown.urgency, greaterThan(0));
    });
  });

  group('pins', () {
    test('map to Task.priority 1-3', () {
      expect(PriorityPin.top.taskPriority, 1);
      expect(PriorityPin.high.taskPriority, 1);
      expect(PriorityPin.normal.taskPriority, 2);
      expect(PriorityPin.low.taskPriority, 3);
      expect(PriorityPin.of(_t('a', priority: 3), {}), PriorityPin.low);
      expect(PriorityPin.of(_t('a', priority: 1), {'a'}), PriorityPin.top);
    });
  });

  group('actions', () {
    late ProviderContainer container;
    late InMemoryTaskRepository repo;
    late InMemoryPreferenceLog log;
    late InMemoryCapacitySettings settings;

    setUp(() async {
      repo = InMemoryTaskRepository([
        _t('a', due: _now.add(const Duration(days: 1)), priority: 1),
        _t('b', due: _now.add(const Duration(days: 3))),
        _t('c', priority: 3),
      ]);
      log = InMemoryPreferenceLog();
      settings = InMemoryCapacitySettings();
      container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(FixedClock(_now)),
          taskRepositoryProvider.overrideWithValue(repo),
          preferenceLogProvider.overrideWithValue(log),
          capacitySettingsProvider.overrideWithValue(settings),
        ],
      );
      addTearDown(container.dispose);
      container.listen(priorityRankProvider, (_, _) {});
      await container.read(tasksProvider.future);
      await Future<void>.delayed(Duration.zero);
    });

    List<String> ids() =>
        container.read(priorityRankProvider).map((r) => r.task.id).toList();

    test('starting order', () => expect(ids(), ['a', 'b', 'c']));

    test('dragging up logs the dragged task over the one it jumped', () async {
      final ranked = container.read(priorityRankProvider);
      await container.read(capacityActionsProvider).reorder(ranked, 2, 1);
      expect(log.entries, hasLength(1));
      final e = log.entries.single;
      expect(e.winnerId, 'c');
      expect(e.loserId, 'b');
      expect(e.source, 'drag');
      expect(
        e.winnerFeatures.keys,
        containsAll(['urgency', 'importance', 'score', 'adjustedMinutes']),
      );
      expect(e.loserFeatures['urgency'], isNotNull);
      // The nudge: c is now "high".
      expect((await repo.getById('c'))!.priority, 1);
    });

    test('dragging to the top pins it top', () async {
      final ranked = container.read(priorityRankProvider);
      await container.read(capacityActionsProvider).reorder(ranked, 2, 0);
      await Future<void>.delayed(Duration.zero);
      expect(ids().first, 'c');
      expect(container.read(capacityConfigProvider).topPinned, {'c'});
      expect(settings.config.topPinned, {'c'});
      expect(log.entries.single.winnerId, 'c');
      expect(log.entries.single.loserId, 'a');
    });

    test('dragging down logs the one now above as the winner', () async {
      final ranked = container.read(priorityRankProvider);
      // Flutter reports newIndex 2 for "after b" when moving index 0.
      await container.read(capacityActionsProvider).reorder(ranked, 0, 2);
      final e = log.entries.single;
      expect(e.winnerId, 'b');
      expect(e.loserId, 'a');
    });

    test('a no-op drag logs nothing', () async {
      final ranked = container.read(priorityRankProvider);
      await container.read(capacityActionsProvider).reorder(ranked, 1, 1);
      await container.read(capacityActionsProvider).reorder(ranked, 1, 2);
      expect(log.entries, isEmpty);
    });

    test('pinning writes Task.priority and top goes to the config', () async {
      final actions = container.read(capacityActionsProvider);
      final c = (await repo.getById('c'))!;
      await actions.setPin(c, PriorityPin.top);
      expect((await repo.getById('c'))!.priority, 1);
      expect(container.read(capacityConfigProvider).topPinned, {'c'});
      expect(log.entries.single.source, 'pin');
      expect(log.entries.single.winnerId, 'c');
      await actions.setPin((await repo.getById('c'))!, PriorityPin.low);
      expect((await repo.getById('c'))!.priority, 3);
      expect(container.read(capacityConfigProvider).topPinned, isEmpty);
    });

    test('moving to next week unschedules and holds until Sunday', () async {
      await repo.upsert(
        (await repo.getById('b'))!.copyWith(
          scheduledStart: DateTime.utc(2026, 11, 4, 8),
          scheduledEnd: DateTime.utc(2026, 11, 4, 9),
        ),
      );
      final n = await container.read(capacityActionsProvider).deferToNextWeek([
        'b',
        'nope',
      ]);
      expect(n, 1);
      final b = (await repo.getById('b'))!;
      expect(b.scheduledStart, isNull);
      expect(b.scheduledEnd, isNull);
      expect(b.lockedStart, isFalse);
      // Next week starts Sun Nov 8, Asia/Jerusalem (UTC+2 in November).
      expect(b.notBefore, DateTime.utc(2026, 11, 7, 22));
    });

    test('weights persist and reset', () async {
      final n = container.read(capacityConfigProvider.notifier);
      await n.setWeights(const sched.SchedulerWeights(urgency: 0.7));
      expect(settings.config.weights.urgency, 0.7);
      await n.resetWeights();
      expect(
        settings.config.weights.urgency,
        const sched.SchedulerWeights().urgency,
      );
    });
  });

  group('JSON stores', () {
    test('preference log round-trips through a doc store', () async {
      final store = InMemoryJsonDocStore();
      final log = JsonPreferenceLog(store);
      await log.record(
        PairwisePreference(
          winnerId: 'a',
          loserId: 'b',
          winnerFeatures: const {'urgency': 0.5},
          loserFeatures: const {'urgency': 0.1},
          at: _now,
        ),
      );
      final again = await JsonPreferenceLog(store).all();
      expect(again, hasLength(1));
      expect(again.single.winnerId, 'a');
      expect(again.single.winnerFeatures['urgency'], 0.5);
      expect(again.single.at, _now);
    });

    test('the log is capped', () async {
      final log = JsonPreferenceLog(InMemoryJsonDocStore(), maxEntries: 2);
      for (final id in ['1', '2', '3']) {
        await log.record(
          PairwisePreference(
            winnerId: id,
            loserId: 'x',
            winnerFeatures: const {},
            loserFeatures: const {},
            at: _now,
          ),
        );
      }
      expect((await log.all()).map((e) => e.winnerId), ['2', '3']);
    });

    test('settings round-trip and survive garbage', () async {
      final store = InMemoryJsonDocStore();
      final s = JsonCapacitySettings(store);
      await s.save(
        const CapacityConfig(
          weights: sched.SchedulerWeights(quickWin: 0.3),
          topPinned: {'t'},
        ),
      );
      final back = await JsonCapacitySettings(store).load();
      expect(back.weights.quickWin, 0.3);
      expect(back.topPinned, {'t'});
      store.docs[JsonCapacitySettings.docName] = 'not json';
      expect(
        (await s.load()).weights.urgency,
        const sched.SchedulerWeights().urgency,
      );
    });
  });
}
