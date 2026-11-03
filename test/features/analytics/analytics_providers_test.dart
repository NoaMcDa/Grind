import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/analytics/analytics_providers.dart';
import 'package:grind/features/focus/providers.dart';

final _now = DateTime.utc(2026, 11, 3, 10);

Task _done(String id, String cat, int est, int actual, int day) => Task(
  id: id,
  title: id,
  category: cat,
  estimatedMinutes: est,
  actualMinutes: actual,
  status: TaskStatus.done,
  completedAt: DateTime.utc(2026, 11, day, 9),
  dueAt: DateTime.utc(2026, 11, day, 9),
  createdAt: _now,
  updatedAt: _now,
);

ProviderContainer _container(List<Task> tasks, List<FocusSession> sessions) {
  final c = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(FixedClock(_now)),
      taskRepositoryProvider.overrideWithValue(InMemoryTaskRepository(tasks)),
      focusSessionRepositoryProvider.overrideWithValue(
        InMemoryFocusSessionRepository(sessions),
      ),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

Future<void> _settle() async {
  for (var i = 0; i < 4; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('providers derive from repos, clock and preferences', () async {
    final tasks = [
      for (var i = 0; i < 5; i++) _done('t$i', 'study', 30, 45, 1 + i % 3),
    ];
    final session = FocusSession(
      id: 's',
      plannedMinutes: 25,
      startedAt: DateTime.utc(2026, 11, 3, 8),
      endedAt: DateTime.utc(2026, 11, 3, 8, 25),
      completed: true,
      createdAt: _now,
      updatedAt: _now,
    );
    final c = _container(tasks, [session]);
    c.listen(tasksProvider, (_, _) {});
    c.listen(preferencesProvider, (_, _) {});
    c.listen(focusWeekProvider, (_, _) {});
    await _settle();

    final week = c.read(focusWeekProvider).value!;
    expect(week.length, 14);
    expect(week.last.minutes, 25);
    expect(week.first.isRest, isTrue);

    final trend = c.read(completionTrendProvider);
    expect(trend.length, 8);
    expect(trend.last.completed, 5);

    final acc = c.read(estimateAccuracyProvider).single;
    expect(acc.ratio, closeTo(1.5, 1e-9));

    final stats = c.read(userStatsProvider);
    expect(stats.durationRatioByCategory['study']!.median, closeTo(1.5, 1e-9));
  });

  test('empty repos give empty-but-valid values', () async {
    final c = _container(const [], const []);
    c.listen(tasksProvider, (_, _) {});
    c.listen(focusWeekProvider, (_, _) {});
    await _settle();
    expect(c.read(userStatsProvider).durationRatioByCategory, isEmpty);
    expect(c.read(estimateAccuracyProvider), isEmpty);
    expect(
      c.read(completionTrendProvider).every((w) => w.rate == null),
      isTrue,
    );
  });
}
