// Regression test for #219: a deleted task must disappear from a goal's
// "Linked tasks", counts, and "Next scheduled task", same as on Today.
//
// Exercises the two acceptance scenarios: a plain task with `goalId`, and a
// task with a weekly `ReminderRule`. Both go through
// `TaskActions.deleteWithUndo`, the same entry the Today swipe and the detail
// screen Delete button call into.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/goals/goals.dart';
import 'package:grind/features/tasks/task_actions.dart';
import 'package:grind/l10n/l10n.dart';

final _t0 = DateTime.utc(2026, 11, 3, 8);

GoalRecord _goal() => GoalRecord(
  id: 'g',
  title: 'Move more',
  metric: const RecurringMetric(quota: 2, unit: 'workouts'),
  createdAt: _t0,
  updatedAt: _t0,
);

Task _pilates({String id = 'pilates', DateTime? remindAt}) => Task(
  id: id,
  title: 'pilates',
  goalId: 'g',
  remindAt: remindAt,
  createdAt: _t0,
  updatedAt: _t0,
);

ReminderRule _weekly() => ReminderRule(
  id: 'rule-pilates',
  taskId: 'pilates',
  rrule: 'FREQ=WEEKLY',
  createdAt: _t0,
  updatedAt: _t0,
);

/// Pumps a scaffold that exposes a BuildContext (through [grab]) so tests can
/// call context-aware actions such as [TaskActions.deleteWithUndo].
Future<ProviderContainer> _pump(
  WidgetTester tester,
  InMemoryTaskRepository tasks,
  InMemoryReminderRepository rules, {
  required void Function(BuildContext) grab,
}) async {
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(FixedClock(_t0)),
      goalRepositoryProvider.overrideWithValue(
        InMemoryGoalRepository(seed: [_goal()], clock: FixedClock(_t0)),
      ),
      taskRepositoryProvider.overrideWithValue(tasks),
      reminderRepositoryProvider.overrideWithValue(rules),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        supportedLocales: supportedLocales,
        localizationsDelegates: localizationsDelegates,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              grab(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets(
    'deleteWithUndo removes a plain linked task from goalLinkedTasksProvider',
    (tester) async {
      final tasks = InMemoryTaskRepository([_pilates()]);
      final rules = InMemoryReminderRepository();
      late BuildContext ctx;
      final container = await _pump(
        tester,
        tasks,
        rules,
        grab: (c) => ctx = c,
      );

      // Baseline: the task is linked to the goal.
      final sub = container.listen(goalLinkedTasksProvider('g'), (_, _) {});
      addTearDown(sub.close);
      await container.read(tasksProvider.future);
      await tester.pumpAndSettle();
      expect(
        container.read(goalLinkedTasksProvider('g')).map((t) => t.id),
        ['pilates'],
      );

      await container
          .read(taskActionsProvider)
          .deleteWithUndo(ctx, (await tasks.getById('pilates'))!);
      await tester.pump();

      expect(container.read(goalLinkedTasksProvider('g')), isEmpty);
      expect(container.read(goalTasksProvider('g')), isEmpty);
      expect(
        (await tasks.getAll()).where((t) => t.id == 'pilates'),
        isEmpty,
        reason: 'the task is soft-deleted so watchAll filters it out',
      );
      // Let the snackbar's auto-dismiss timer fire so no timer leaks out.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'deleteWithUndo removes a recurring linked task (weekly rule) too',
    (tester) async {
      final tasks = InMemoryTaskRepository([
        _pilates(remindAt: DateTime.utc(2026, 11, 3, 16)),
      ]);
      final rules = InMemoryReminderRepository([_weekly()]);
      late BuildContext ctx;
      final container = await _pump(
        tester,
        tasks,
        rules,
        grab: (c) => ctx = c,
      );

      final sub = container.listen(goalLinkedTasksProvider('g'), (_, _) {});
      addTearDown(sub.close);
      await container.read(tasksProvider.future);
      await tester.pumpAndSettle();
      expect(
        container.read(goalLinkedTasksProvider('g')).map((t) => t.id),
        ['pilates'],
      );
      expect(await rules.getForTask('pilates'), isNotNull);

      await container
          .read(taskActionsProvider)
          .deleteWithUndo(ctx, (await tasks.getById('pilates'))!);
      await tester.pump();

      // The series task is fully gone from the goal's list — not left behind
      // as a "skip this occurrence only" artefact.
      expect(container.read(goalLinkedTasksProvider('g')), isEmpty);
      expect(container.read(goalTasksProvider('g')), isEmpty);
      expect(
        await rules.getForTask('pilates'),
        isNull,
        reason: 'the rule is soft-deleted with the task',
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );
}
