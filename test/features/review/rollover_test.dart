import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/review/review.dart';

Task task(
  String id, {
  DateTime? remindAt,
  DateTime? dueAt,
  TaskStatus status = TaskStatus.open,
}) {
  final t = DateTime(2026, 11, 3).toUtc();
  return Task(
    id: id,
    title: id,
    remindAt: remindAt?.toUtc(),
    dueAt: dueAt?.toUtc(),
    status: status,
    createdAt: t,
    updatedAt: t,
  );
}

void main() {
  final now = DateTime(2026, 11, 3, 21, 0);

  test('tomorrow keeps the local wall time, across month end', () {
    final t = task('a', remindAt: DateTime(2026, 11, 30, 23, 30));
    final moved = rolloverTask(t, 1, now: now)!;
    expect(moved.remindAt!.toLocal(), DateTime(2026, 12, 1, 23, 30));
  });

  test('never moves past dueAt', () {
    final t = task(
      'a',
      remindAt: DateTime(2026, 11, 3, 18),
      dueAt: DateTime(2026, 11, 3, 23, 59),
    );
    expect(rolloverTask(t, 1, now: now), isNull);
    expect(optionsFor(t), [
      RolloverChoice.keep,
      RolloverChoice.tomorrowAnyway,
      RolloverChoice.drop,
    ]);
  });

  test('later this week is capped by a nearer deadline', () {
    final t = task(
      'a',
      remindAt: DateTime(2026, 11, 3, 18),
      dueAt: DateTime(2026, 11, 4, 23, 59),
    );
    expect(optionsFor(t), [RolloverChoice.tomorrow, RolloverChoice.drop]);
    expect(rolloverTask(t, 2, now: now), isNull);
  });

  test('tomorrow anyway pushes the deadline too', () {
    final t = task(
      'a',
      remindAt: DateTime(2026, 11, 3, 18),
      dueAt: DateTime(2026, 11, 3, 23, 59),
    );
    final moved = rolloverTask(t, 1, now: now, pushDeadline: true)!;
    expect(moved.dueAt!.toLocal(), DateTime(2026, 11, 4, 23, 59));
    expect(moved.remindAt!.toLocal(), DateTime(2026, 11, 4, 18));
  });

  test('reviewTasksFor picks open tasks of the local day only', () {
    final list = reviewTasksFor([
      task('today', remindAt: DateTime(2026, 11, 3, 9)),
      task('late', remindAt: DateTime(2026, 11, 3, 23, 50)),
      task('tomorrow', remindAt: DateTime(2026, 11, 4, 0, 5)),
      task('done', remindAt: DateTime(2026, 11, 3, 9), status: TaskStatus.done),
      task('due', dueAt: DateTime(2026, 11, 3, 12)),
    ], now);
    expect(list.map((t) => t.id), ['today', 'due', 'late']);
  });

  group('due provider', () {
    Future<bool> due(DateTime at, ReviewRepository repo, {int? mins}) async {
      final prefs = InMemoryPreferencesRepository();
      await prefs.save(
        (await prefs.get()).copyWith(
          eveningPromptMinutes: mins ?? 20 * 60 + 30,
        ),
      );
      final c = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(FixedClock(at)),
          preferencesRepositoryProvider.overrideWithValue(prefs),
          reviewRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(c.dispose);
      return c.read(eveningReviewDueProvider.future);
    }

    test('only after the prompt time and not yet handled', () async {
      final repo = InMemoryReviewRepository();
      expect(await due(DateTime(2026, 11, 3, 20, 29), repo), isFalse);
      expect(await due(DateTime(2026, 11, 3, 20, 30), repo), isTrue);
      await repo.markHandled('2026-11-03');
      expect(await due(DateTime(2026, 11, 3, 22), repo), isFalse);
      expect(await due(DateTime(2026, 11, 4, 21), repo), isTrue);
    });
  });
}
