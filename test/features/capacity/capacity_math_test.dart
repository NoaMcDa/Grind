import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/capacity/capacity_math.dart';

// Week of Sun Nov 1 to Sat Nov 7 2026, wall clock. Default working hours:
// Mon-Thu 9-18, Fri 9-14, minus lunch and the daily cushion: about 31 h free.
final _start = DateTime(2026, 11, 1);
final _end = DateTime(2026, 11, 8);
final _now = DateTime(2026, 11, 1, 8);
final _stamp = DateTime.utc(2026, 10, 1);

Task _task(
  String id, {
  int minutes = 60,
  DateTime? due,
  DateTime? at,
  DateTime? notBefore,
}) => Task(
  id: id,
  title: 'Task $id',
  estimatedMinutes: minutes,
  dueAt: due,
  scheduledStart: at,
  scheduledEnd: at?.add(Duration(minutes: minutes)),
  notBefore: notBefore,
  createdAt: _stamp,
  updatedAt: _stamp,
);

WeekReport _report(List<Task> tasks, {Set<String> topPinned = const {}}) =>
    buildWeekReport(
      weekStart: _start,
      weekEnd: _end,
      now: _now,
      prefs: const Preferences(),
      events: const [],
      tasks: tasks,
      topPinned: topPinned,
    );

/// 20 h due inside the week plus 13 h of undated, scheduled work.
List<Task> _overbookedWeek() => [
  _task('due-wed', minutes: 600, due: DateTime(2026, 11, 4, 17)),
  _task('due-thu', minutes: 600, due: DateTime(2026, 11, 5, 17)),
  _task('later-a', minutes: 360, at: DateTime(2026, 11, 3, 9)),
  _task('later-b', minutes: 240, at: DateTime(2026, 11, 4, 9)),
  _task('later-c', minutes: 180, at: DateTime(2026, 11, 5, 9)),
];

void main() {
  group('loadStateOf', () {
    test('calm, tight, overbooked', () {
      expect(loadStateOf(480, 0), LoadState.calm);
      expect(loadStateOf(480, 300), LoadState.calm);
      expect(loadStateOf(480, 420), LoadState.tight);
      expect(loadStateOf(480, 480), LoadState.tight);
      expect(loadStateOf(480, 481), LoadState.overbooked);
      expect(loadStateOf(0, 30), LoadState.overbooked);
    });
  });

  group('weekly report', () {
    test('a light week fits and suggests nothing', () {
      final r = _report([
        _task('a', minutes: 120, due: DateTime(2026, 11, 4, 17)),
        _task('b', minutes: 60, at: DateTime(2026, 11, 3, 10)),
      ]);
      expect(r.freeMinutes, greaterThan(25 * 60));
      expect(r.plannedMinutes, 180);
      expect(r.verdict, LoadState.calm);
      expect(r.overMinutes, 0);
      expect(r.deferrals, isEmpty);
      expect(r.days, hasLength(7));
    });

    test('a nearly full week is tight, not overbooked', () {
      final free = _report(const []).freeMinutes;
      final r = _report([
        _task('big', minutes: (free * 0.9).round(), due: DateTime(2026, 11, 5)),
      ]);
      expect(r.verdict, LoadState.tight);
      expect(r.deferrals, isEmpty);
    });

    test('an overbooked week says by how much and lists deferrals', () {
      final r = _report(_overbookedWeek());
      expect(r.capacity.overbooked, isTrue);
      expect(r.verdict, LoadState.overbooked);
      expect(r.overMinutes, r.plannedMinutes - r.freeMinutes);
      expect(r.overMinutes, greaterThan(0));
      expect(r.deferrals, isNotEmpty);
      final freed = r.deferrals.fold<int>(0, (s, d) => s + d.minutes);
      expect(freed, greaterThanOrEqualTo(r.overMinutes));
    });

    test('never suggests deferring something due inside the week', () {
      // The in-week deadline is the lowest-value work by every other
      // measure (no goal, lowest priority), and still stays.
      final tasks = [
        ..._overbookedWeek(),
        _task(
          'low-due',
          minutes: 30,
          due: DateTime(2026, 11, 7, 12),
        ).copyWith(priority: 3),
      ];
      final r = _report(tasks);
      final ids = r.deferrals.map((d) => d.task.id).toSet();
      expect(ids, isNotEmpty);
      expect(ids, isNot(contains('due-wed')));
      expect(ids, isNot(contains('due-thu')));
      expect(ids, isNot(contains('low-due')));
      for (final d in r.deferrals) {
        expect(d.task.dueAt == null || d.task.dueAt!.isAfter(_end), isTrue);
      }
    });

    test('top-pinned tasks are never suggested', () {
      final r = _report(
        _overbookedWeek(),
        topPinned: {'later-a', 'later-b', 'later-c'},
      );
      expect(r.deferrals, isEmpty);
    });

    test('deferral carries slack to the deadline', () {
      final r = _report([
        ..._overbookedWeek(),
        _task(
          'far',
          minutes: 120,
          due: DateTime(2026, 11, 12, 12),
          at: DateTime(2026, 11, 6, 9),
        ),
      ]);
      final far = r.deferrals.where((d) => d.task.id == 'far');
      if (far.isNotEmpty) expect(far.single.slackDays, 4);
      final undated = r.deferrals.where((d) => d.task.dueAt == null);
      for (final d in undated) {
        expect(d.slackDays, isNull);
      }
    });

    test('tasks held to next week (notBefore) do not count', () {
      final held = _task(
        'held',
        minutes: 600,
        due: DateTime(2026, 11, 6),
        notBefore: DateTime(2026, 11, 8),
      );
      final r = _report([held]);
      expect(r.plannedMinutes, 0);
    });

    test('done and deleted tasks do not count', () {
      final r = _report([
        _task(
          'x',
          minutes: 600,
          due: DateTime(2026, 11, 4),
        ).copyWith(status: TaskStatus.done),
        _task(
          'y',
          minutes: 600,
          due: DateTime(2026, 11, 4),
        ).copyWith(deletedAt: _stamp),
      ]);
      expect(r.plannedMinutes, 0);
    });
  });

  group('day bars', () {
    test('scheduled time lands on its day; a packed day is overbooked', () {
      final r = _report([
        _task('wed', minutes: 600, at: DateTime(2026, 11, 4, 8)),
        _task('mon', minutes: 60, at: DateTime(2026, 11, 2, 10)),
        _task('due-fri', minutes: 90, due: DateTime(2026, 11, 6, 12)),
      ]);
      final byDay = {for (final d in r.days) d.date.day: d};
      expect(byDay[4]!.plannedMinutes, 600);
      expect(byDay[4]!.state, LoadState.overbooked);
      expect(byDay[2]!.plannedMinutes, 60);
      expect(byDay[2]!.state, LoadState.calm);
      expect(byDay[6]!.plannedMinutes, 90);
      expect(byDay[1]!.freeMinutes, 0); // Sunday is not a working day
    });

    test('overdue unscheduled work sits on the first day', () {
      final r = _report([
        _task('late', minutes: 45, due: DateTime(2026, 10, 28)),
      ]);
      expect(r.days.first.plannedMinutes, 45);
    });
  });
}
