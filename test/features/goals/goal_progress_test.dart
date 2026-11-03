import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/goals/goals.dart';
import 'package:grind/theme/tokens.dart';

void main() {
  final t0 = DateTime.utc(2026, 11, 3, 8);

  GoalRecord goal({
    GoalMetric? metric,
    GoalStatus status = GoalStatus.active,
  }) => GoalRecord(
    id: 'g',
    title: 'PM course',
    metric: metric,
    status: status,
    createdAt: t0,
    updatedAt: t0,
  );

  Task task(String id, {String? goalId = 'g', bool done = false}) => Task(
    id: id,
    title: id,
    goalId: goalId,
    status: done ? TaskStatus.done : TaskStatus.open,
    createdAt: t0,
    updatedAt: t0,
  );

  group('GoalProgress', () {
    test('8 of 12 lessons is 67 %, in progress', () {
      final p = GoalProgress.of(
        goal(
          metric: const FiniteMetric(target: 12, unit: 'lessons', current: 8),
        ),
      );
      expect(p.current, 8);
      expect(p.target, 12);
      expect(p.percent, 67);
      expect(p.fraction, closeTo(0.667, 0.001));
      expect(p.status, GoalProgressStatus.inProgress);
      expect(GoalsStrings.progressLine(p), '8 of 12 lessons · 67%');
    });

    test('thresholds: 0, started, 80 % close to done, target completed', () {
      expect(GoalProgress.statusFor(0, 10), GoalProgressStatus.notStarted);
      expect(GoalProgress.statusFor(7, 10), GoalProgressStatus.inProgress);
      expect(GoalProgress.statusFor(8, 10), GoalProgressStatus.closeToDone);
      expect(GoalProgress.statusFor(9, 10), GoalProgressStatus.closeToDone);
      expect(GoalProgress.statusFor(10, 10), GoalProgressStatus.completed);
      expect(GoalProgress.statusFor(14, 10), GoalProgressStatus.completed);
      expect(
        GoalProgress.statusFor(1, 10, done: true),
        GoalProgressStatus.completed,
      );
    });

    test('over target clamps to 100 %, near target never shows 100', () {
      final over = GoalProgress.of(
        goal(metric: const FiniteMetric(target: 4, unit: 'x', current: 6)),
      );
      expect(over.fraction, 1);
      expect(over.percent, 100);
      final near = GoalProgress.of(
        goal(metric: const FiniteMetric(target: 200, unit: 'x', current: 199)),
      );
      expect(near.percent, 99);
      expect(near.isCompleted, isFalse);
    });

    test('linked-tasks metric counts done tasks linked to the goal', () {
      final g = goal(
        metric: const FiniteMetric(
          target: 4,
          unit: 'tasks',
          current: 99,
          source: MetricSource.linkedTasks,
        ),
      );
      final p = GoalProgress.of(
        g,
        linkedTasks: [
          task('a', done: true),
          task('b', done: true),
          task('c'),
          task('d', goalId: 'other', done: true),
        ],
      );
      expect(p.current, 2);
      expect(p.percent, 50);
    });

    test('no metric: only a done goal reads completed', () {
      expect(GoalProgress.of(goal()).hasMetric, isFalse);
      expect(GoalProgress.of(goal()).isCompleted, isFalse);
      expect(
        GoalProgress.of(goal(status: GoalStatus.done)).isCompleted,
        isTrue,
      );
    });

    test('milestones fire on the upward crossing only', () {
      GoalProgress at(int c) => GoalProgress(
        current: c,
        target: 10,
        unit: '',
        status: GoalProgress.statusFor(c, 10),
      );
      expect(
        GoalProgress.milestoneBetween(at(7), at(8)),
        GoalMilestone.closeToDone,
      );
      expect(GoalProgress.milestoneBetween(at(8), at(9)), isNull);
      expect(
        GoalProgress.milestoneBetween(at(9), at(10)),
        GoalMilestone.completed,
      );
      expect(
        GoalProgress.milestoneBetween(at(5), at(10)),
        GoalMilestone.completed,
      );
      expect(GoalProgress.milestoneBetween(at(10), at(7)), isNull);
    });
  });

  group('GoalRecord', () {
    test('importance 1–5 maps to the core 0..1 and back', () {
      for (var i = 1; i <= 5; i++) {
        expect(
          GoalRecord.importanceFromCore(GoalRecord.importanceToCore(i)),
          i,
        );
      }
      expect(GoalRecord.importanceFromCore(0.5), 3);
      expect(GoalRecord.importanceFromCore(0), 1);
    });

    test('toCore carries the manual fraction as progress', () {
      final core = goal(
        metric: const FiniteMetric(target: 4, unit: 'x', current: 1),
      ).toCore();
      expect(core.progress, 0.25);
      expect(goal(status: GoalStatus.done).toCore().progress, 1);
    });

    test('extras round-trip through JSON', () {
      final extras = GoalExtras(
        targetDate: DateTime.utc(2026, 12, 31, 21, 59),
        status: GoalStatus.paused,
        notes: 'Module 3 next',
        metric: const FiniteMetric(
          target: 12,
          unit: 'lessons',
          current: 8,
          source: MetricSource.linkedTasks,
        ),
      );
      final back = GoalExtras.fromJson(
        (jsonDecode(jsonEncode(extras.toJson())) as Map).cast(),
      );
      expect(back.targetDate, extras.targetDate);
      expect(back.status, GoalStatus.paused);
      expect(back.notes, 'Module 3 next');
      expect(back.metric, extras.metric);
    });
  });

  group('GoalArea', () {
    test('presets resolve by id; other strings are custom areas', () {
      expect(GoalArea.resolve('fitness'), GoalArea.fitness);
      expect(GoalArea.resolve(null), isNull);
      expect(GoalArea.resolve('  '), isNull);
      final custom = GoalArea.resolve('Music')!;
      expect(custom.isPreset, isFalse);
      expect(custom.label, 'Music');
      expect(GoalArea.customPalette, contains(custom.color));
      expect(GoalArea.resolve('Music')!.color, custom.color);
      expect(GoalArea.learning.color, AppColors.violet);
    });
  });
}
