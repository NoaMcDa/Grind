import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/app/test_app.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/goals/goals.dart';

import '../../test_fonts.dart';
import '../tasks/zone_test_support.dart';

final _c = DateTime.utc(2026, 10, 29);

GoalRecord _goal(String id, String title, {String area = 'learning'}) =>
    GoalRecord(id: id, title: title, area: area, createdAt: _c, updatedAt: _c);

Task _task(
  String id, {
  required String title,
  String? goalId,
  DateTime? remindAt,
}) => Task(
  id: id,
  title: title,
  goalId: goalId,
  remindAt: remindAt,
  createdAt: _c,
  updatedAt: _c,
);

void main() {
  setUpAll(loadAppFonts);

  testWidgets(
    'a Today task row with a goalId shows the goal area chip and opens '
    '/goals/:id on tap',
    (tester) async {
      final tasks = [
        _task(
          'reading',
          title: 'Read 10 pages',
          goalId: 'pm',
          remindAt: DateTime(2026, 10, 29, 10).toUtc(),
        ),
        _task(
          'standalone',
          title: 'Standalone task',
          remindAt: DateTime(2026, 10, 29, 11).toUtc(),
        ),
      ];
      final c = await pumpGrindApp(
        tester,
        overrides: [
          devicePrefsOverride(),
          taskRepositoryProvider.overrideWithValue(
            InMemoryTaskRepository(tasks),
          ),
          goalRepositoryProvider.overrideWithValue(
            InMemoryGoalRepository(
              seed: [_goal('pm', 'Finish the PM course')],
              clock: const SystemClock(),
            ),
          ),
        ],
      );
      // The chip appears on the task with the goal, and labels it with the
      // goal area ("Learning" is the preset id for 'learning').
      expect(find.byKey(const Key('task-goal-reading')), findsOneWidget);
      expect(find.byKey(const Key('task-goal-standalone')), findsNothing);

      // Tap: router pushes /goals/pm — the detail screen opens.
      await tester.tap(find.byKey(const Key('task-goal-reading')));
      await tester.pumpAndSettle();
      expect(find.text('Finish the PM course'), findsWidgets);
      c.dispose();
    },
  );

  testWidgets('a task without a goal shows no area chip', (tester) async {
    await pumpGrindApp(
      tester,
      overrides: [
        devicePrefsOverride(),
        taskRepositoryProvider.overrideWithValue(
          InMemoryTaskRepository([
            _task(
              'bare',
              title: 'Bare task',
              remindAt: DateTime(2026, 10, 29, 10).toUtc(),
            ),
          ]),
        ),
      ],
    );
    expect(find.byKey(const Key('task-goal-bare')), findsNothing);
  });
}
