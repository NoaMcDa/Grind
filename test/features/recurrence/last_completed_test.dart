import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/recurrence/occurrence_completion.dart';
import 'package:grind/features/recurrence/occurrence_expander.dart';
import 'package:grind/features/recurrence/recurrence_notifications.dart';
import 'package:grind/features/recurrence/series_edit.dart';
import 'package:grind/features/tasks/day_bounds.dart';
import 'package:grind/features/tasks/task_actions.dart';
import 'package:grind/features/tasks/task_providers.dart';
import 'package:timezone/timezone.dart' as tz;

const zone = 'Asia/Jerusalem';

ReminderRule rule(
  String rrule, {
  String taskId = 't1',
  DateTime? lastCompletedAt,
}) => ReminderRule(
  id: 'r-$taskId',
  taskId: taskId,
  rrule: rrule,
  lastCompletedAt: lastCompletedAt,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

Task task(String id, DateTime remindAt) => Task(
  id: id,
  title: 'Take meds',
  remindAt: remindAt,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  ensureTimeZonesInitialized();
  final loc = tz.getLocation(zone);
  // Plain UTC values, as stored.
  DateTime at(int y, int m, int d, [int h = 7, int mi = 0]) =>
      DateTime.fromMillisecondsSinceEpoch(
        tz.TZDateTime(loc, y, m, d, h, mi).millisecondsSinceEpoch,
        isUtc: true,
      );
  final now = DateTime.utc(2026, 3, 22);

  group('completion is stored on the rule', () {
    test('lastCompletedAt is the occurrence; remindAt is the next one', () {
      final p = completeSeriesOccurrence(
        task: task('t1', at(2026, 3, 23)),
        rule: rule('FREQ=DAILY'),
        occurrenceAt: at(2026, 3, 23),
        timeZoneName: zone,
        now: now,
      );
      expect(p.rule.lastCompletedAt, at(2026, 3, 23));
      expect(p.rule.lastCompletedAt!.isUtc, isTrue);
      expect(p.task.remindAt, at(2026, 3, 24));
      expect(p.task.isDone, isFalse);
      // The start is pinned, so the series still begins on the 23rd.
      expect(seriesStart(p.rule, p.task.remindAt!, zone), at(2026, 3, 23));
    });

    test('COUNT counts from the series start, not the moved remindAt', () {
      var t = task('t1', at(2026, 3, 23));
      var r = rule('FREQ=DAILY;COUNT=3');
      for (final d in [23, 24]) {
        final p = completeSeriesOccurrence(
          task: t,
          rule: r,
          occurrenceAt: at(2026, 3, d),
          timeZoneName: zone,
          now: now,
        );
        t = p.task;
        r = p.rule;
      }
      expect(t.isDone, isFalse);
      expect(t.remindAt, at(2026, 3, 25));
      // The third (last) occurrence finishes the series.
      final last = completeOccurrence(
        task: t,
        rule: r,
        occurrenceAt: at(2026, 3, 25),
        timeZoneName: zone,
        now: now,
      );
      expect(last.isDone, isTrue);
      // And nothing is expanded after the third.
      final fires = expandOccurrences(
        rule: r,
        anchor: t.remindAt!,
        from: at(2026, 3, 20, 0),
        to: at(2026, 4, 1, 0),
        timeZoneName: zone,
      );
      expect(fires, hasLength(3));
    });

    test('until is counted from the series start too', () {
      final r = rule('FREQ=DAILY;COUNT=2');
      final p = completeSeriesOccurrence(
        task: task('t1', at(2026, 3, 23)),
        rule: r,
        occurrenceAt: at(2026, 3, 23),
        timeZoneName: zone,
        now: now,
      );
      final fires = expandOccurrences(
        rule: p.rule,
        anchor: p.task.remindAt!,
        from: at(2026, 3, 23, 0),
        to: at(2026, 4, 1, 0),
        timeZoneName: zone,
      );
      expect(fires.map((f) => f.toUtc()), [at(2026, 3, 23), at(2026, 3, 24)]);
    });

    test('un-completing reverts to the previous occurrence, or null', () {
      var t = task('t1', at(2026, 3, 23));
      var r = rule('FREQ=DAILY');
      for (final d in [23, 24]) {
        final p = completeSeriesOccurrence(
          task: t,
          rule: r,
          occurrenceAt: at(2026, 3, d),
          timeZoneName: zone,
          now: now,
        );
        t = p.task;
        r = p.rule;
      }
      var p = uncompleteSeriesOccurrence(
        task: t,
        rule: r,
        occurrenceAt: at(2026, 3, 24),
        timeZoneName: zone,
        now: now,
      );
      expect(p.rule.lastCompletedAt, at(2026, 3, 23));
      expect(p.task.remindAt, at(2026, 3, 24));
      p = uncompleteSeriesOccurrence(
        task: p.task,
        rule: p.rule,
        occurrenceAt: at(2026, 3, 23),
        timeZoneName: zone,
        now: now,
      );
      expect(p.rule.lastCompletedAt, isNull);
      expect(p.task.remindAt, at(2026, 3, 23));
      expect(p.task.isDone, isFalse);
    });
  });

  group('done occurrences are not pending', () {
    test('no notification at or before lastCompletedAt', () async {
      final t = task('t1', at(2026, 3, 23));
      final out = await recurrenceExtraNotifications(
        InMemoryReminderRepository([
          rule('FREQ=DAILY', lastCompletedAt: at(2026, 3, 24)),
        ]),
        horizonDays: 4,
        clock: FixedClock(at(2026, 3, 22, 12)),
      )([t], const Preferences(timeZoneName: zone));
      expect(out.map((n) => n.fireAt), [at(2026, 3, 25), at(2026, 3, 26)]);
    });
  });

  group('Today rows', () {
    final day = localDayBounds(at(2026, 3, 24, 9), zone);

    test('a completed occurrence stays as a done row on its day', () {
      // Twice a day; 07:00 done, 19:00 open; remindAt is the 19:00 one.
      final r = rule(
        'FREQ=DAILY;BYHOUR=7,19;BYMINUTE=0',
        lastCompletedAt: at(2026, 3, 24),
      );
      final items = itemsOnDay(
        tasks: [task('t1', at(2026, 3, 24, 19))],
        rules: {'t1': pinSeriesStart(r, at(2026, 3, 23), zone)},
        day: day,
      );
      expect(items.map((i) => (i.at, i.isDone)), [
        (at(2026, 3, 24, 19), false),
        (at(2026, 3, 24), true),
      ]);
      expect(items.where((i) => i.isDone), hasLength(1));
    });

    test('done occurrences of an earlier day are not due today', () {
      final r = pinSeriesStart(
        rule('FREQ=DAILY', lastCompletedAt: at(2026, 3, 23)),
        at(2026, 3, 22),
        zone,
      );
      final next = localDayBounds(at(2026, 3, 23, 9), zone);
      expect(
        itemsOnDay(
          tasks: [task('t1', at(2026, 3, 24))],
          rules: {'t1': r},
          day: next,
        ).single.isDone,
        isTrue,
      );
      final earlier = localDayBounds(at(2026, 3, 22, 9), zone);
      expect(
        itemsOnDay(
          tasks: [task('t1', at(2026, 3, 24))],
          rules: {'t1': r},
          day: earlier,
        ),
        isEmpty,
      );
    });

    test('the last occurrence done: the finished series shows it done', () {
      final r = pinSeriesStart(
        rule('FREQ=DAILY;COUNT=2', lastCompletedAt: at(2026, 3, 24)),
        at(2026, 3, 23),
        zone,
      );
      final finished = task(
        't1',
        at(2026, 3, 24),
      ).copyWith(status: TaskStatus.done, completedAt: at(2026, 3, 24));
      final items = itemsOnDay(tasks: [finished], rules: {'t1': r}, day: day);
      expect(items.single.isDone, isTrue);
      expect(items.single.occurrence, isTrue);
    });
  });

  group('TaskActions', () {
    late ProviderContainer c;
    late InMemoryTaskRepository tasks;
    late InMemoryReminderRepository rules;

    setUp(() {
      tasks = InMemoryTaskRepository([task('t1', at(2026, 3, 23))]);
      rules = InMemoryReminderRepository([rule('FREQ=DAILY')]);
      c = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(FixedClock(at(2026, 3, 23, 8))),
          taskRepositoryProvider.overrideWithValue(tasks),
          reminderRepositoryProvider.overrideWithValue(rules),
          preferencesRepositoryProvider.overrideWithValue(
            InMemoryPreferencesRepository(
              const Preferences(timeZoneName: zone),
            ),
          ),
        ],
      );
      addTearDown(c.dispose);
    });

    test('completeRecurring stores lastCompletedAt (UTC)', () async {
      final next = await c
          .read(taskActionsProvider)
          .completeRecurring(
            (await tasks.getById('t1'))!,
            occurrenceAt: at(2026, 3, 23),
          );
      expect(next!.remindAt, at(2026, 3, 24));
      final stored = (await rules.getForTask('t1'))!;
      expect(stored.lastCompletedAt, at(2026, 3, 23));
      expect(stored.lastCompletedAt!.isUtc, isTrue);
    });

    test('uncompleteRecurring goes back to nothing completed', () async {
      final actions = c.read(taskActionsProvider);
      await actions.completeRecurring(
        (await tasks.getById('t1'))!,
        occurrenceAt: at(2026, 3, 23),
      );
      final back = await actions.uncompleteRecurring(
        (await tasks.getById('t1'))!,
        occurrenceAt: at(2026, 3, 23),
      );
      expect(back!.remindAt, at(2026, 3, 23));
      expect((await rules.getForTask('t1'))!.lastCompletedAt, isNull);
    });
  });

  group('series edits keep lastCompletedAt', () {
    test('"this one" on a done occurrence: the copy is done', () async {
      final tasks = InMemoryTaskRepository();
      final rules = InMemoryReminderRepository();
      final t = task('t1', at(2026, 3, 24));
      final r = rule('FREQ=DAILY', lastCompletedAt: at(2026, 3, 23));
      await tasks.upsert(t);
      await rules.upsert(r);
      final one = await editThisOccurrence(
        tasks: tasks,
        rules: rules,
        task: t,
        rule: r,
        occurrenceAt: at(2026, 3, 23),
        timeZoneName: zone,
        now: now,
      );
      expect(one.isDone, isTrue);
      final stored = (await rules.getForTask('t1'))!;
      expect(stored.lastCompletedAt, at(2026, 3, 23));
    });

    test('"all future" after completions splits at the series start, '
        'with the COUNT that is left', () async {
      final tasks = InMemoryTaskRepository();
      final rules = InMemoryReminderRepository();
      var t = task('t1', at(2026, 3, 23));
      var r = rule('FREQ=DAILY;COUNT=5');
      for (final d in [23, 24]) {
        final p = completeSeriesOccurrence(
          task: t,
          rule: r,
          occurrenceAt: at(2026, 3, d),
          timeZoneName: zone,
          now: now,
        );
        t = p.task;
        r = p.rule;
      }
      await tasks.upsert(t);
      await rules.upsert(r);
      // remindAt is the 25th now; the series still started on the 23rd, so
      // this is a split, not an in-place edit.
      final future = await editAllFuture(
        tasks: tasks,
        rules: rules,
        task: t,
        rule: r,
        occurrenceAt: at(2026, 3, 25),
        timeZoneName: zone,
        now: now,
      );
      expect(future.id, isNot('t1'));
      final newRule = (await rules.getForTask(future.id))!;
      expect(newRule.rrule, 'FREQ=DAILY;COUNT=3');
      expect(newRule.lastCompletedAt, isNull);
      final old = (await rules.getForTask('t1'))!;
      expect(old.lastCompletedAt, at(2026, 3, 24));
      // Nothing is pending before the split: the old part is done.
      expect((await tasks.getById('t1'))!.isDone, isTrue);
    });

    test('"all future" at a done occurrence carries the completion', () async {
      final tasks = InMemoryTaskRepository();
      final rules = InMemoryReminderRepository();
      final t = task('t1', at(2026, 3, 26));
      final r = pinSeriesStart(
        rule('FREQ=DAILY', lastCompletedAt: at(2026, 3, 25)),
        at(2026, 3, 23),
        zone,
      );
      await tasks.upsert(t);
      await rules.upsert(r);
      final future = await editAllFuture(
        tasks: tasks,
        rules: rules,
        task: t,
        rule: r,
        occurrenceAt: at(2026, 3, 25),
        timeZoneName: zone,
        now: now,
      );
      final newRule = (await rules.getForTask(future.id))!;
      expect(newRule.lastCompletedAt, at(2026, 3, 25));
      expect(future.remindAt, at(2026, 3, 26));
    });
  });
}
