import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/time_zones.dart';
import 'package:grind/features/recurrence/providers.dart';
import 'package:grind/features/tasks/day_bounds.dart';
import 'package:grind/features/tasks/task_providers.dart';

const _jlm = 'Asia/Jerusalem';
final _c = DateTime.utc(2026, 10, 1);

Task _task(String id, {DateTime? remindAt, DateTime? dueAt}) => Task(
  id: id,
  title: id,
  remindAt: remindAt,
  dueAt: dueAt,
  createdAt: _c,
  updatedAt: _c,
);

ReminderRule _rule(String taskId, String rrule) => ReminderRule(
  id: 'rule-$taskId',
  taskId: taskId,
  rrule: rrule,
  createdAt: _c,
  updatedAt: _c,
);

void main() {
  setUpAll(ensureTimeZones);

  group('localDayBounds', () {
    test('22:30 UTC on Nov 3 is already Nov 4 in Jerusalem (UTC+2)', () {
      final b = localDayBounds(DateTime.utc(2026, 11, 3, 22, 30), _jlm);
      expect(b.date, DateTime(2026, 11, 4));
      expect(b.start.toUtc(), DateTime.utc(2026, 11, 3, 22));
      expect(b.end.toUtc(), DateTime.utc(2026, 11, 4, 22));
      expect(b.contains(DateTime.utc(2026, 11, 3, 21, 59)), isFalse);
      expect(b.contains(DateTime.utc(2026, 11, 3, 22)), isTrue);
      expect(b.contains(DateTime.utc(2026, 11, 4, 21, 59)), isTrue);
      expect(b.contains(DateTime.utc(2026, 11, 4, 22)), isFalse);
    });

    test('21:59 UTC is still Nov 3 there; UTC itself says Nov 3', () {
      expect(
        localDayBounds(DateTime.utc(2026, 11, 3, 21, 59), _jlm).date,
        DateTime(2026, 11, 3),
      );
      expect(
        localDayBounds(DateTime.utc(2026, 11, 3, 22, 30), 'UTC').date,
        DateTime(2026, 11, 3),
      );
    });

    test('a DST day is 25 hours (Jerusalem, Oct 25 2026)', () {
      final b = localDayBounds(DateTime.utc(2026, 10, 25, 12), _jlm);
      expect(b.end.difference(b.start), const Duration(hours: 25));
      expect(b.shift(1).date, DateTime(2026, 10, 26));
    });

    test('zoneWall and fromZoneWall round-trip and return plain UTC', () {
      final loc = locationFor(_jlm);
      final t = DateTime.utc(2026, 11, 3, 22, 15);
      final wall = zoneWall(t, loc);
      expect(
        [wall.year, wall.month, wall.day, wall.hour, wall.minute],
        [2026, 11, 4, 0, 15],
      );
      final back = fromZoneWall(wall, loc);
      expect(back, t);
      expect(back.runtimeType, DateTime);
    });
  });

  group('todayTasksProvider', () {
    ProviderContainer container(
      DateTime nowUtc,
      List<Task> tasks, [
      List<ReminderRule> rules = const [],
    ]) {
      final c = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(FixedClock(nowUtc)),
          taskRepositoryProvider.overrideWithValue(
            InMemoryTaskRepository(tasks),
          ),
          reminderRepositoryProvider.overrideWithValue(
            InMemoryReminderRepository(rules),
          ),
          preferencesRepositoryProvider.overrideWithValue(
            InMemoryPreferencesRepository(
              const Preferences(timeZoneName: _jlm),
            ),
          ),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    Future<List<String>> ids(ProviderContainer c) async {
      final sub = c.listen(todayTasksProvider, (_, _) {});
      addTearDown(sub.close);
      await c.read(tasksProvider.future);
      await c.read(reminderRulesProvider.future);
      await c.read(preferencesProvider.future);
      await Future<void>.delayed(Duration.zero);
      return [for (final i in c.read(todayTasksProvider)) i.key];
    }

    test(
      'uses the preference zone, not the device clock, around midnight',
      () async {
        // 22:30 UTC = 00:30 on Nov 4 in Jerusalem.
        final c = container(DateTime.utc(2026, 11, 3, 22, 30), [
          // 23:00 on Nov 3 in Jerusalem: yesterday there, "today" in UTC.
          _task('yesterday', remindAt: DateTime.utc(2026, 11, 3, 21)),
          // 10:00 on Nov 4 in Jerusalem: today there, "tomorrow" in UTC.
          _task('today', remindAt: DateTime.utc(2026, 11, 4, 8)),
          // Due 23:59 on Nov 4 in Jerusalem.
          _task('due', dueAt: DateTime.utc(2026, 11, 4, 21, 59)),
        ]);
        expect(await ids(c), ['today', 'due']);
      },
    );

    test(
      'a weekly series shows on each of its days, at the occurrence',
      () async {
        // Anchored Tue Oct 27 07:00 Jerusalem (05:00 UTC), every Tuesday.
        final anchor = DateTime.utc(2026, 10, 27, 5);
        final tasks = [_task('w', remindAt: anchor)];
        final rules = [_rule('w', 'FREQ=WEEKLY;BYDAY=TU')];

        // Tue Nov 3, 12:00 UTC: one row, at 07:00 Jerusalem that day.
        final tue = container(DateTime.utc(2026, 11, 3, 12), tasks, rules);
        final rows = await ids(tue);
        expect(rows, hasLength(1));
        final item = tue.read(todayTasksProvider).single;
        expect(item.occurrence, isTrue);
        expect(item.at, DateTime.utc(2026, 11, 3, 5));
        expect(item.at.runtimeType, DateTime);

        // Wed Nov 4: nothing.
        final wed = container(DateTime.utc(2026, 11, 4, 12), tasks, rules);
        expect(await ids(wed), isEmpty);
      },
    );

    test('a series with an unreadable rule is listed as a one-off', () async {
      final c = container(
        DateTime.utc(2026, 11, 3, 12),
        [_task('x', remindAt: DateTime.utc(2026, 11, 3, 9))],
        [_rule('x', 'NOT A RULE')],
      );
      expect(await ids(c), ['x']);
    });
  });
}
