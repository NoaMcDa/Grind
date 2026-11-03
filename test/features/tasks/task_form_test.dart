import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/app/test_app.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/time_zones.dart';
import 'package:grind/features/goals/goals.dart';
import 'package:grind/features/tasks/task_form.dart';

import '../../test_fonts.dart';
import 'zone_test_support.dart';

final _t0 = DateTime.utc(2026, 10, 1);

GoalRecord _goal(String id, String title, {GoalStatus? status}) => GoalRecord(
  id: id,
  title: title,
  status: status ?? GoalStatus.active,
  createdAt: _t0,
  updatedAt: _t0,
);

Override get _goals => goalRepositoryProvider.overrideWithValue(
  InMemoryGoalRepository(
    seed: [
      _goal('thesis', 'Finish the thesis'),
      _goal('run', 'Run a 10k'),
      _goal('old', 'Paused one', status: GoalStatus.paused),
    ],
  ),
);

BuildContext _ctx(WidgetTester t) => t.element(find.byType(Scaffold).first);

Future<void> _save(WidgetTester t) async {
  await t.tap(find.bySemanticsLabel('Save'));
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    ensureTimeZones();
    await loadAppFonts();
  });

  testWidgets('the create sheet picks a repeat rule and saves it', (t) async {
    final c = await pumpGrindApp(t, overrides: [devicePrefsOverride()]);
    await t.tap(find.bySemanticsLabel('Add a task'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).first, 'Water plants');
    final chip = find.byKey(const Key('task-form-recurrence'));
    await t.ensureVisible(chip);
    await t.pumpAndSettle();
    expect(find.text('Does not repeat'), findsOneWidget);
    await t.tap(chip);
    await t.pumpAndSettle();
    await t.tap(find.text('Weekly'));
    await t.pumpAndSettle();
    await t.tap(find.text('Done').last);
    await t.pumpAndSettle();
    expect(find.text('Does not repeat'), findsNothing);
    await _save(t);

    final task = (await c.read(taskRepositoryProvider).getAll()).firstWhere(
      (x) => x.title == 'Water plants',
    );
    final rule = await c.read(reminderRepositoryProvider).getForTask(task.id);
    expect(rule, isNotNull);
    expect(rule!.rrule, startsWith('FREQ=WEEKLY'));
    // No time was picked: the series starts at 09:00 on the task's day.
    expect(task.remindAt, DateTime(2026, 10, 29, 9).toUtc());
    expect(find.text('Water plants'), findsOneWidget); // on Today
  });

  testWidgets('without a pick, no rule is written', (t) async {
    final c = await pumpGrindApp(t, overrides: [devicePrefsOverride()]);
    await t.tap(find.bySemanticsLabel('Add a task'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).first, 'Once only');
    await _save(t);
    final task = (await c.read(taskRepositoryProvider).getAll()).firstWhere(
      (x) => x.title == 'Once only',
    );
    expect(
      await c.read(reminderRepositoryProvider).getForTask(task.id),
      isNull,
    );
    expect(task.goalId, isNull);
  });

  testWidgets('editing a series can stop it', (t) async {
    final c = await pumpGrindApp(t, overrides: [devicePrefsOverride()]);
    final rules = c.read(reminderRepositoryProvider);
    await rules.upsert(
      ReminderRule(
        id: 'rule-gym',
        taskId: 'gym',
        rrule: 'FREQ=DAILY',
        createdAt: _t0,
        updatedAt: _t0,
      ),
    );
    final gym = (await c.read(taskRepositoryProvider).getById('gym'))!;
    showTaskSheet(_ctx(t), existing: gym);
    await t.pumpAndSettle();
    final chip = find.byKey(const Key('task-form-recurrence'));
    await t.ensureVisible(chip);
    await t.pumpAndSettle();
    expect(find.text('Every day'), findsWidgets);
    await t.tap(chip);
    await t.pumpAndSettle();
    await t.tap(find.text('Does not repeat').last);
    await t.pumpAndSettle();
    await t.tap(find.text('Done').last);
    await t.pumpAndSettle();
    await _save(t);
    expect(await rules.getForTask('gym'), isNull);
  });

  testWidgets('taskSheetForGoal presets the goal; the picker can change it', (
    t,
  ) async {
    final c = await pumpGrindApp(t, overrides: [devicePrefsOverride(), _goals]);
    taskSheetForGoal(_ctx(t), _goal('thesis', 'Finish the thesis'));
    await t.pumpAndSettle();
    final picker = find.byKey(const Key('task-form-goal'));
    await t.ensureVisible(picker);
    await t.pumpAndSettle();
    // Active goals only.
    expect(find.text('Run a 10k'), findsOneWidget);
    expect(find.text('Paused one'), findsNothing);
    final thesis = find.bySemanticsLabel('Finish the thesis');
    expect(t.getSemantics(thesis).flagsCollection.isSelected, isTrue);

    await t.enterText(find.byType(TextField).first, 'Draft chapter 3');
    await _save(t);
    var task = (await c.read(taskRepositoryProvider).getAll()).firstWhere(
      (x) => x.title == 'Draft chapter 3',
    );
    expect(task.goalId, 'thesis');

    // Edit: move it to another goal, then to none.
    showTaskSheet(_ctx(t), existing: task);
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Run a 10k'));
    await t.pumpAndSettle();
    await t.tap(find.text('Run a 10k'));
    await t.pumpAndSettle();
    await _save(t);
    task = (await c.read(taskRepositoryProvider).getById(task.id))!;
    expect(task.goalId, 'run');

    showTaskSheet(_ctx(t), existing: task);
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('No goal'));
    await t.pumpAndSettle();
    await t.tap(find.text('No goal'));
    await t.pumpAndSettle();
    await _save(t);
    task = (await c.read(taskRepositoryProvider).getById(task.id))!;
    expect(task.goalId, isNull);
  });

  testWidgets('no goals: no goal picker', (t) async {
    await pumpGrindApp(t, overrides: [devicePrefsOverride()]);
    await t.tap(find.bySemanticsLabel('Add a task'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('task-form-goal')), findsNothing);
  });
}
