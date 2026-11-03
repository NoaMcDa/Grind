import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/companion/effort_score.dart';
import 'package:grind/features/companion/mood.dart';

final _now = DateTime(2026, 11, 3, 12);

Task _done(String id, DateTime at) => Task(
  id: id,
  title: id,
  status: TaskStatus.done,
  completedAt: at,
  createdAt: at,
  updatedAt: at,
);

FocusSession _session(String id, DateTime at) => FocusSession(
  id: id,
  plannedMinutes: 25,
  startedAt: at.subtract(const Duration(minutes: 25)),
  endedAt: at,
  completed: true,
  createdAt: at,
  updatedAt: at,
);

DateTime _ago(int days, [int hours = 0]) =>
    _now.subtract(Duration(days: days, hours: hours));

void main() {
  test('no events: quiet, zero, nothing negative', () {
    final s = EffortScore.compute(tasks: const [], now: _now);
    expect(s.value, 0);
    expect(s.level, MomentumLevel.quiet);
    expect(s.showedUpDays, 0);
    expect(s.dayCounts, everyElement(0));
    final copy = MoodCopy.line(moodFor(s.level), s.showedUpDays);
    expect(copy, contains('whenever you are'));
    expect(copy.toLowerCase(), isNot(contains('0 of')));
  });

  test('weights: session 1.5, task 1.0, started 0.25 (fresh events)', () {
    double v(List<Task> t, [List<FocusSession> s = const []]) =>
        EffortScore.compute(tasks: t, sessions: s, now: _now).value;
    final task = v([_done('a', _now)]);
    final session = v(const [], [_session('s', _now)]);
    final started = v([
      Task(
        id: 'x',
        title: 'x',
        scheduledStart: _now,
        scheduledEnd: _now.add(const Duration(hours: 1)),
        createdAt: _now,
        updatedAt: _now,
      ),
    ]);
    expect(task, closeTo(12.5, 0.01));
    expect(session / task, closeTo(1.5, 0.01));
    expect(started / task, closeTo(0.25, 0.01));
  });

  test('half-life of three days and clamp to 100', () {
    final fresh = EffortScore.compute(tasks: [_done('a', _now)], now: _now);
    final old = EffortScore.compute(tasks: [_done('a', _ago(3))], now: _now);
    expect(old.value, closeTo(fresh.value / 2, 0.05));
    final many = [for (var i = 0; i < 40; i++) _done('t$i', _now)];
    expect(EffortScore.compute(tasks: many, now: _now).value, 100);
  });

  test('events older than 7 days do not count', () {
    final s = EffortScore.compute(tasks: [_done('a', _ago(8))], now: _now);
    expect(s.value, 0);
  });

  test('decay is monotonic as time passes with no new events', () {
    final tasks = [for (var i = 0; i < 6; i++) _done('t$i', _ago(i ~/ 2))];
    var prev = double.infinity;
    for (var h = 0; h <= 24 * 8; h += 6) {
      final v = EffortScore.compute(
        tasks: tasks,
        now: _now.add(Duration(hours: h)),
      ).value;
      expect(v, lessThanOrEqualTo(prev + 1e-9));
      prev = v;
    }
    expect(prev, 0);
  });

  test('one quiet day never drops a level', () {
    // Steady daily work, then a day with nothing.
    final tasks = [
      for (var d = 1; d <= 6; d++) ...[
        _done('a$d', _ago(d, 1)),
        _done('b$d', _ago(d, 2)),
      ],
    ];
    for (final start in [0, 6, 12, 18]) {
      final before = EffortScore.compute(
        tasks: tasks,
        now: _now.add(Duration(hours: start)),
      );
      // The same moment a day later, still without a new event.
      final after = EffortScore.compute(
        tasks: tasks,
        now: _now.add(Duration(hours: start + 24)),
      );
      expect(after.level.index, greaterThanOrEqualTo(before.level.index));
    }
  });

  test('showed-up days and week bars count finished work per local day', () {
    final tasks = [
      _done('a', _now),
      _done('b', _now),
      _done('c', DateTime(2026, 11, 1, 9)),
      _done('d', DateTime(2026, 10, 28, 9)),
    ];
    final s = EffortScore.compute(
      tasks: tasks,
      sessions: [_session('s', DateTime(2026, 10, 31, 10))],
      now: _now,
    );
    expect(s.showedUpDays, 4);
    expect(s.dayCounts, [1, 0, 0, 1, 1, 0, 2]);
  });

  test('levels and moods map thresholds', () {
    expect(EffortScore.levelFor(0), MomentumLevel.quiet);
    expect(EffortScore.levelFor(20), MomentumLevel.steady);
    expect(EffortScore.levelFor(55), MomentumLevel.strong);
    expect(moodFor(MomentumLevel.strong), PipMood.glowing);
    expect(moodFor(MomentumLevel.quiet), PipMood.quiet);
  });

  test('recent + carry equals value', () {
    final s = EffortScore.compute(
      tasks: [_done('a', _now), _done('b', _ago(5))],
      now: _now,
    );
    expect(s.recent + s.carry, closeTo(s.value, 1e-9));
    expect(s.recent, greaterThan(0));
    expect(s.carry, greaterThan(0));
  });

  test('all mood copy is free of negative words', () {
    for (final m in PipMood.values) {
      for (final n in [0, 1, 7]) {
        final t = '${MoodCopy.title(m)} ${MoodCopy.line(m, n)}'.toLowerCase();
        for (final w in ['should', 'failed', 'missed', 'again', 'behind']) {
          expect(t, isNot(contains(w)));
        }
      }
    }
  });
}
