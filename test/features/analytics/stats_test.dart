import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/analytics/stats.dart';
import 'package:grind/features/plan/scheduler/models.dart';

const _tz = 'Asia/Jerusalem';

FocusSession _s(String id, DateTime start, int minutes) => FocusSession(
  id: id,
  plannedMinutes: minutes,
  startedAt: start,
  endedAt: start.add(Duration(minutes: minutes)),
  completed: true,
  createdAt: start,
  updatedAt: start,
);

Task _t(
  String id, {
  String? category,
  int est = 30,
  int? actual,
  int day = 1,
  TaskStatus status = TaskStatus.done,
  DateTime? due,
  DateTime? scheduled,
  Energy energy = Energy.light,
}) {
  final at = DateTime.utc(2026, 10, day, 10);
  return Task(
    id: id,
    title: id,
    category: category,
    estimatedMinutes: est,
    actualMinutes: actual,
    status: status,
    completedAt: status == TaskStatus.done ? at : null,
    dueAt: due,
    scheduledStart: scheduled,
    energy: energy,
    createdAt: at,
    updatedAt: at,
  );
}

List<Task> _many(String cat, int n, int est, int actual) => [
  for (var i = 0; i < n; i++)
    _t('$cat$i', category: cat, est: est, actual: actual, day: i + 1),
];

void main() {
  group('focusMinutesPerDay', () {
    test('zero-fills days and sums sessions per local day', () {
      final from = DateTime.utc(2026, 11, 1, 22); // Nov 2 00:00 local
      final to = DateTime.utc(2026, 11, 4, 22); // Nov 5 00:00 local
      final out = focusMinutesPerDay(
        [
          _s('a', DateTime.utc(2026, 11, 2, 8), 25),
          _s('b', DateTime.utc(2026, 11, 2, 9), 30),
          _s('c', DateTime.utc(2026, 11, 4, 8), 50),
        ],
        from,
        to,
        _tz,
      );
      expect(out.map((d) => d.minutes), [55, 0, 50]);
      expect(out[1].isRest, isTrue);
      expect(out.first.day.day, 2);
    });

    test('assigns by local day, not UTC day (late evening)', () {
      final out = focusMinutesPerDay(
        [_s('a', DateTime.utc(2026, 11, 2, 22, 30), 20)], // Nov 3 00:30 local
        DateTime.utc(2026, 11, 1, 22),
        DateTime.utc(2026, 11, 3, 22),
        _tz,
      );
      expect(out.map((d) => d.minutes), [0, 20]);
    });

    test('DST end (25-hour day) keeps one bucket per calendar day', () {
      // Israel left DST on 2026-10-25 at 02:00 local.
      final from = DateTime.utc(2026, 10, 23, 21); // Oct 24 00:00 IDT
      final to = DateTime.utc(2026, 10, 26, 22); // Oct 27 00:00 IST
      final out = focusMinutesPerDay(
        [
          _s('a', DateTime.utc(2026, 10, 24, 21, 30), 10), // Oct 25 00:30 IDT
          _s('b', DateTime.utc(2026, 10, 25, 21, 30), 15), // Oct 25 23:30 IST
          _s('c', DateTime.utc(2026, 10, 25, 22, 30), 5), // Oct 26 00:30 IST
        ],
        from,
        to,
        _tz,
      );
      expect(out.length, 3);
      expect(out.map((d) => d.day.day), [24, 25, 26]);
      expect(out.map((d) => d.minutes), [0, 25, 5]);
    });

    test('DST start (23-hour day)', () {
      // Israel entered DST on 2026-03-27 at 02:00 local.
      final from = DateTime.utc(2026, 3, 26, 22); // Mar 27 00:00 IST
      final to = DateTime.utc(2026, 3, 28, 21); // Mar 29 00:00 IDT
      final out = focusMinutesPerDay(
        [_s('a', DateTime.utc(2026, 3, 27, 21, 30), 30)], // Mar 28 00:30 IDT
        from,
        to,
        _tz,
      );
      expect(out.map((d) => d.day.day), [27, 28]);
      expect(out.map((d) => d.minutes), [0, 30]);
    });

    test('ignores active sessions and sessions outside the range', () {
      final active = FocusSession(
        id: 'x',
        plannedMinutes: 25,
        startedAt: DateTime.utc(2026, 11, 2, 8),
        createdAt: DateTime.utc(2026, 11, 2),
        updatedAt: DateTime.utc(2026, 11, 2),
      );
      final out = focusMinutesPerDay(
        [active, _s('o', DateTime.utc(2026, 10, 1, 8), 25)],
        DateTime.utc(2026, 11, 1, 22),
        DateTime.utc(2026, 11, 2, 22),
        _tz,
      );
      expect(out.map((d) => d.minutes), [0]);
    });
  });

  group('completionRatePerWeek', () {
    test('weeks start on the preference and rate is null when empty', () {
      // Tue 2026-11-03; week starts Sunday -> this week begins Nov 1.
      final now = DateTime.utc(2026, 11, 3, 10);
      final out = completionRatePerWeek(
        [
          _t('a', due: DateTime.utc(2026, 11, 2, 10)),
          _t('b', due: DateTime.utc(2026, 11, 3, 10), status: TaskStatus.open),
          _t('c', due: DateTime.utc(2026, 10, 27, 10)), // previous week
          _t(
            'skip',
            due: DateTime.utc(2026, 11, 2, 10),
            status: TaskStatus.skipped,
          ),
        ],
        3,
        DateTime.sunday,
        _tz,
        now: now,
      );
      expect(out.length, 3);
      expect(out.last.weekStart.weekday, DateTime.sunday);
      expect(out.last.planned, 2);
      expect(out.last.rate, 0.5);
      expect(out[1].rate, 1.0);
      expect(out.first.rate, isNull);
    });
  });

  group('estimateAccuracy / userStatsFrom', () {
    List<Task> study(List<int> actuals, {int est = 30}) => [
      for (var i = 0; i < actuals.length; i++)
        _t(
          's$i',
          category: 'study',
          est: est,
          actual: actuals[i],
          day: i % 28 + 1,
        ),
    ];

    test('median of ratios, sample count, gate', () {
      final tasks = [
        ...study([36, 42, 45, 39, 60]), // 1.2 1.4 1.5 1.3 2.0 -> 1.4
        ..._many('admin', 3, 30, 15),
      ];
      final acc = estimateAccuracy(tasks);
      expect(acc.first.category, 'study');
      expect(acc.first.ratio, closeTo(1.4, 1e-9));
      expect(acc.first.n, 5);
      expect(acc.first.trusted, isTrue);
      final admin = acc.firstWhere((c) => c.category == 'admin');
      expect(admin.trusted, isFalse);
    });

    test('only the last 10 samples shape the median, n counts all', () {
      final tasks = study([...List.filled(5, 120), ...List.filled(10, 30)]);
      final c = estimateAccuracy(tasks).single;
      expect(c.n, 15);
      expect(c.ratio, 1.0);
    });

    test('ignores tasks missing a field or not done, or uncategorised', () {
      final tasks = [
        _t('a', category: 'x', actual: null),
        _t('b', actual: 30),
        _t('c', category: 'x', actual: 30, status: TaskStatus.open),
      ];
      expect(estimateAccuracy(tasks), isEmpty);
    });

    test('userStatsFrom gates below 5 and clamps to 0.5..3.0', () {
      final tasks = [
        ...study(List.filled(5, 120)), // ratio 4 -> 3.0
        ..._many('quick', 5, 60, 6), // 0.1 -> 0.5
        ..._many('few', 4, 30, 60), // under gate
      ];
      final stats = userStatsFrom(tasks, const []);
      expect(stats.durationRatioByCategory.keys.toSet(), {'study', 'quick'});
      expect(stats.durationRatioByCategory['study']!.median, 3.0);
      expect(stats.durationRatioByCategory['quick']!.median, 0.5);
      expect(stats.durationRatioByCategory['study']!.n, 5);
    });

    test('completion cells need 10 planned', () {
      final tasks = [
        for (var i = 0; i < 10; i++)
          _t(
            'm$i',
            scheduled: DateTime.utc(2026, 10, 5 + i, 7), // 09:00 local
            status: i < 7 ? TaskStatus.done : TaskStatus.open,
            energy: Energy.deep,
          ),
        for (var i = 0; i < 4; i++)
          _t('e$i', scheduled: DateTime.utc(2026, 10, 5 + i, 16)),
      ];
      final stats = userStatsFrom(tasks, const [], tzName: _tz);
      final cell =
          stats.completionRateByHourBand[HourBand.morning]![Energy.deep]!;
      expect(cell.planned, 10);
      expect(cell.completed, 7);
      expect(
        stats.completionRateByHourBand.containsKey(HourBand.evening),
        isFalse,
      );
    });

    test('empty input gives empty stats', () {
      final s = userStatsFrom(const [], const []);
      expect(s.durationRatioByCategory, isEmpty);
      expect(s.completionRateByHourBand, isEmpty);
    });
  });
}
