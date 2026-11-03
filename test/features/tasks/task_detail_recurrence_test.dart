import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/app/test_app.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/time_zones.dart';

import '../../test_fonts.dart';

final _c = DateTime.utc(2026, 10, 1);
// 16:00 on the test day (Oct 29) in the device zone.
final _remind = DateTime(2026, 10, 29, 16).toUtc();

Task _papers() => Task(
  id: 'p',
  title: 'Read 2 papers',
  remindAt: _remind,
  scheduledStart: _remind,
  scheduledEnd: _remind.add(const Duration(minutes: 30)),
  createdAt: _c,
  updatedAt: _c,
);

ReminderRule _daily() => ReminderRule(
  id: 'rule-p',
  taskId: 'p',
  rrule: 'FREQ=DAILY',
  createdAt: _c,
  updatedAt: _c,
);

void main() {
  setUpAll(() async {
    ensureTimeZones();
    await loadAppFonts();
  });

  testWidgets('Complete on a recurring task completes one occurrence', (
    t,
  ) async {
    final c = await pumpGrindApp(
      t,
      initialLocation: '/task/p',
      overrides: [
        taskRepositoryProvider.overrideWithValue(
          InMemoryTaskRepository([_papers()]),
        ),
        reminderRepositoryProvider.overrideWithValue(
          InMemoryReminderRepository([_daily()]),
        ),
      ],
    );
    expect(find.text('Every day'), findsOneWidget);
    await t.tap(find.text('Complete'));
    await t.pumpAndSettle();

    final task = (await c.read(taskRepositoryProvider).getById('p'))!;
    expect(task.isDone, isFalse);
    expect(task.remindAt!.isAfter(_remind), isTrue);
    expect(
      task.remindAt!.difference(_remind).inHours,
      inInclusiveRange(23, 25),
    );
    expect(task.isScheduled, isFalse, reason: 'the next one gets a new slot');
    expect(find.textContaining('next one is lined up'), findsOneWidget);
  });

  testWidgets('the recurrence chip writes and deletes the rule', (t) async {
    final c = await pumpGrindApp(
      t,
      initialLocation: '/task/p',
      overrides: [
        taskRepositoryProvider.overrideWithValue(
          InMemoryTaskRepository([_papers()]),
        ),
      ],
    );
    final rules = c.read(reminderRepositoryProvider);
    expect(find.text('Does not repeat'), findsOneWidget);

    await t.tap(find.byKey(const Key('task-recurrence')));
    await t.pumpAndSettle();
    await t.tap(find.text('Daily'));
    await t.pumpAndSettle();
    await t.tap(find.text('Done').last);
    await t.pumpAndSettle();
    final rule = await rules.getForTask('p');
    expect(rule, isNotNull);
    expect(rule!.rrule, 'FREQ=DAILY');
    expect(find.text('Every day'), findsOneWidget);

    await t.tap(find.byKey(const Key('task-recurrence')));
    await t.pumpAndSettle();
    await t.tap(find.text('Does not repeat').last);
    await t.pumpAndSettle();
    await t.tap(find.text('Done').last);
    await t.pumpAndSettle();
    expect(await rules.getForTask('p'), isNull);
    expect(find.text('Does not repeat'), findsOneWidget);
  });
}
