import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/goals/goals.dart';
import 'package:grind/features/goals/presentation/goal_l10n.dart';
import 'package:grind/l10n/l10n.dart';
import 'package:grind/theme/app_theme.dart';

import '../../test_fonts.dart';

// Tuesday 3 Nov 2026, 10:00 in Jerusalem (the default zone, UTC+2).
final _t0 = DateTime.utc(2026, 11, 3, 8);
DateTime _endOf(int m, int d) => DateTime.utc(2026, m, d, 21, 59);

final _goal = GoalRecord(
  id: 'pm',
  title: 'Finish the project management course',
  area: 'learning',
  horizon: GoalHorizon.year,
  createdAt: _t0,
  updatedAt: _t0,
);

Milestone _ms(
  String id,
  String title, {
  DateTime? due,
  int order = 0,
  MilestoneStatus status = MilestoneStatus.open,
}) => Milestone(
  id: id,
  goalId: 'pm',
  title: title,
  dueAt: due,
  sortOrder: order,
  status: status,
  createdAt: _t0,
  updatedAt: _t0,
);

final _seed = [
  _ms('m1', 'Modules 1-2', order: 0, status: MilestoneStatus.done),
  _ms('m2', 'Module 3', order: 1, due: _endOf(11, 2)),
  _ms('m3', 'Final project', order: 2, due: _endOf(12, 20)),
];

final _tasks = [
  Task(
    id: 't1',
    title: 'Watch lesson 7',
    goalId: 'pm',
    scheduledStart: DateTime.utc(2026, 11, 4, 7),
    scheduledEnd: DateTime.utc(2026, 11, 4, 8),
    createdAt: _t0,
    updatedAt: _t0,
  ),
];

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  List<Milestone>? milestones,
  List<MilestoneTaskLink>? links,
  Locale locale = const Locale('en'),
}) async {
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(FixedClock(_t0)),
      goalRepositoryProvider.overrideWithValue(
        InMemoryGoalRepository(seed: [_goal], clock: FixedClock(_t0)),
      ),
      taskRepositoryProvider.overrideWithValue(InMemoryTaskRepository(_tasks)),
      milestoneRepositoryProvider.overrideWithValue(
        InMemoryMilestoneRepository(
          seed: milestones ?? _seed,
          links:
              links ??
              [
                MilestoneTaskLink(
                  taskId: 't1',
                  milestoneId: 'm2',
                  createdAt: _t0,
                ),
              ],
          clock: FixedClock(_t0),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildAppTheme(),
        locale: locale,
        supportedLocales: supportedLocales,
        localizationsDelegates: localizationsDelegates,
        home: const GoalDetailScreen(goalId: 'pm'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Scrolls the goal screen until [f] is fully on screen.
Future<void> _scrollTo(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(
    f.first,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(f.last);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  for (final locale in const [Locale('en'), Locale('he')]) {
    testWidgets('progress, next, moved, next task (${locale.languageCode})', (
      tester,
    ) async {
      final l = lookupAppLocalizations(locale);
      final c = await _pump(tester, locale: locale);
      final nov9 = l.goalDay(DateTime(2026, 11, 9));

      await _scrollTo(tester, find.text(l.goalsMilestonesProgress(1, 3)));
      expect(find.text(l.goalsMilestones.toUpperCase()), findsOneWidget);
      // The next milestone reads with its new date, not the old one.
      expect(find.text(l.goalsMilestoneNextLine('Module 3', nov9)), findsOne);
      // The next scheduled task: Wed 4 Nov, 09:00 Jerusalem.
      expect(find.text(l.goalsNextTask.toUpperCase()), findsOneWidget);
      expect(find.text('Watch lesson 7'), findsWidgets);

      // Moved, never missed: a gentle line and a one-tap new date.
      await _scrollTo(tester, find.text(l.goalsMilestoneMoveAccept(nov9)));
      await tester.ensureVisible(find.text(l.goalsMilestoneMoveAccept(nov9)));
      await tester.pumpAndSettle();
      expect(find.text(l.goalsMilestoneMovedBody(nov9)), findsOneWidget);
      expect(find.textContaining(l.goalsMilestoneMoved), findsWidgets);
      expect(find.textContaining('missed'), findsNothing);
      expect(find.textContaining('failed'), findsNothing);
      await tester.tap(find.text(l.goalsMilestoneMoveAccept(nov9)));
      await tester.pumpAndSettle();
      expect(find.text(l.goalsMilestoneMovedToast(nov9)), findsOneWidget);
      final m2 = await c.read(milestoneRepositoryProvider).getById('m2');
      expect(m2!.dueAt, _endOf(11, 9));
      expect(find.text(l.goalsMilestoneMovedBody(nov9)), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the milestone task shows once, under its milestone', (
    tester,
  ) async {
    await _pump(tester);
    await _scrollTo(tester, find.text('Final project'));
    // Once in "next scheduled task", once under Module 3, not in the
    // linked-tasks list.
    expect(find.text('Watch lesson 7'), findsNWidgets(2));
    expect(find.text('1 of 3 reached'), findsOneWidget);
  });

  testWidgets('empty: an invitation, then add a milestone with the sheet', (
    tester,
  ) async {
    final c = await _pump(tester, milestones: const [], links: const []);
    await _scrollTo(tester, find.text('Add a milestone'));
    expect(
      find.text(
        'Break a long goal into a few steps. '
        'Each step gets its own weekly tasks.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Add a milestone'));
    await tester.pumpAndSettle();
    expect(find.text('New milestone'), findsOneWidget);

    // An empty name gets a gentle hint.
    await tester.tap(find.bySemanticsLabel('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Give it a short name'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Module 3');
    await tester.tap(find.bySemanticsLabel('Save'));
    await tester.pumpAndSettle();
    final all = await c.read(milestoneRepositoryProvider).getAll();
    expect(all.map((m) => (m.title, m.goalId, m.dueAt)), [
      ('Module 3', 'pm', null),
    ]);
    expect(find.text('0 of 1 reached'), findsOneWidget);
  });

  testWidgets('complete, reorder, edit and delete a milestone', (tester) async {
    final c = await _pump(tester);
    final repo = c.read(milestoneRepositoryProvider);
    await _scrollTo(tester, find.text('Add a milestone'));

    // Complete with the check dot.
    await tester.tap(find.bySemanticsLabel('Final project'));
    await tester.pumpAndSettle();
    expect((await repo.getById('m3'))!.isDone, isTrue);
    expect(find.text('Milestone reached: Final project'), findsOneWidget);

    // Move "Final project" up above "Module 3".
    await tester.tap(find.bySemanticsLabel('Move up: Final project'));
    await tester.pumpAndSettle();
    expect((await repo.getAll()).map((m) => m.id), ['m1', 'm3', 'm2']);

    // Edit: rename through the sheet.
    await tester.tap(find.bySemanticsLabel('Milestone options: Module 3'));
    await tester.pumpAndSettle();
    expect(find.text('Edit milestone'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Module 3 + quiz');
    await tester.tap(find.bySemanticsLabel('Save'));
    await tester.pumpAndSettle();
    expect((await repo.getById('m2'))!.title, 'Module 3 + quiz');

    // Delete asks first, then keeps the tasks.
    await tester.tap(
      find.bySemanticsLabel('Milestone options: Module 3 + quiz'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Delete').last);
    await tester.pumpAndSettle();
    expect(find.text('Delete this milestone?'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Delete').last);
    await tester.pumpAndSettle();
    expect(await repo.getById('m2'), isNull);
    expect(find.text('Milestone deleted'), findsOneWidget);
    expect((await c.read(taskRepositoryProvider).getById('t1'))!.goalId, 'pm');
  });

  for (final locale in const [Locale('en'), Locale('he')]) {
    testWidgets('add a weekly task for a milestone (${locale.languageCode})', (
      tester,
    ) async {
      final l = lookupAppLocalizations(locale);
      final c = await _pump(tester, locale: locale);
      await _scrollTo(tester, find.text(l.goalsMilestoneAddTask));
      await tester.tap(find.text(l.goalsMilestoneAddTask).last);
      await tester.pumpAndSettle();
      expect(
        find.text(l.goalsMilestoneTaskSheetTitle('Final project')),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField), 'Outline the report');
      await tester.tap(find.text(l.goalsMilestoneNextWeek));
      await tester.tap(find.text(l.commonHours(1)));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel(l.commonSave));
      await tester.pumpAndSettle();
      expect(find.text(l.goalsMilestoneTaskAdded), findsOneWidget);

      final all = await c.read(taskRepositoryProvider).getAll();
      final added = all.firstWhere((t) => t.title == 'Outline the report');
      expect((added.goalId, added.estimatedMinutes), ('pm', 60));
      expect(added.dueAt, _endOf(11, 14));
      final links = await c
          .read(milestoneRepositoryProvider)
          .watchLinks()
          .first;
      expect(links.firstWhere((x) => x.taskId == added.id).milestoneId, 'm3');
      expect(tester.takeException(), isNull);
    });
  }
}
