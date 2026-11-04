import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/notification_scheduler.dart';
import 'package:grind/features/companion/effort_score.dart';
import 'package:grind/features/focus/watch_connectivity/watch_connectivity.dart';

void main() {
  final now = DateTime.utc(2026, 11, 4, 8);

  ScheduledNotification reminder({
    required String id,
    required String taskId,
    required Duration fromNow,
    String title = 'Thesis',
    String body = 'If-then: open the thesis file',
    List<NotificationAction> actions = const [
      NotificationAction.done,
      NotificationAction.snooze,
      NotificationAction.startFocus,
    ],
  }) => ScheduledNotification(
    id: id,
    taskId: taskId,
    fireAt: now.add(fromNow),
    title: title,
    body: body,
    actions: actions,
  );

  const momentum = EffortScore(
    value: 62,
    recent: 40,
    carry: 22,
    level: MomentumLevel.strong,
    showedUpDays: 4,
    dayCounts: [0, 1, 2, 1, 0, 3, 1],
    eventCount: 8,
  );

  test('build: writtenAt is the UTC of now', () {
    final snap = WatchSnapshotBuilder.build(
      plan: const [],
      momentum: momentum,
      now: DateTime(2026, 11, 4, 8).toLocal(),
    );
    expect(snap.writtenAt.isUtc, isTrue);
    expect(snap.schema, WatchSnapshot.schemaVersion);
  });

  test('momentum is trimmed to value + level name (no 7-day strip)', () {
    final snap = WatchSnapshotBuilder.build(
      plan: const [],
      momentum: momentum,
      now: now,
    );
    expect(snap.momentum.value, 62);
    expect(snap.momentum.level, 'strong');
  });

  test('nextReminder is the soonest future task reminder', () {
    final plan = [
      reminder(id: 'n-1', taskId: 't-1', fromNow: const Duration(minutes: 30)),
      reminder(
        id: 'n-2',
        taskId: 't-2',
        fromNow: const Duration(hours: 2),
        title: 'Admin',
      ),
    ];
    final snap = WatchSnapshotBuilder.build(
      plan: plan,
      momentum: momentum,
      now: now,
    );
    expect(snap.nextReminder?.taskId, 't-1');
    expect(snap.nextReminder?.title, 'Thesis');
    expect(snap.nextReminder?.fireAt, now.add(const Duration(minutes: 30)));
  });

  test(
    'reminders in the past are dropped so the watch does not show stale lines',
    () {
      final plan = [
        reminder(
          id: 'n-past',
          taskId: 't-past',
          fromNow: const Duration(minutes: -5),
        ),
        reminder(
          id: 'n-future',
          taskId: 't-future',
          fromNow: const Duration(minutes: 20),
          title: 'Workout',
        ),
      ];
      final snap = WatchSnapshotBuilder.build(
        plan: plan,
        momentum: momentum,
        now: now,
      );
      expect(snap.nextReminder?.taskId, 't-future');
    },
  );

  test('a reminder whose fireAt equals now is treated as already fired', () {
    final plan = [
      reminder(id: 'n-now', taskId: 't-now', fromNow: Duration.zero),
    ];
    final snap = WatchSnapshotBuilder.build(
      plan: plan,
      momentum: momentum,
      now: now,
    );
    expect(snap.nextReminder, isNull);
  });

  test('morning / evening / recap prompts are skipped (no task to act on)', () {
    final plan = [
      ScheduledNotification(
        id: '${NotificationScheduler.morningPrefix}2026-11-04',
        taskId: '',
        fireAt: now.add(const Duration(minutes: 10)),
        title: 'Morning',
        body: 'Plan the day',
      ),
      ScheduledNotification(
        id: '${NotificationScheduler.eveningPrefix}2026-11-04',
        taskId: '',
        fireAt: now.add(const Duration(minutes: 15)),
        title: 'Evening',
        body: 'Review',
      ),
      ScheduledNotification(
        id: '${NotificationScheduler.recapPrefix}2026-45',
        taskId: '',
        fireAt: now.add(const Duration(minutes: 20)),
        title: 'Weekly recap',
        body: 'Last week',
      ),
      reminder(
        id: 'n-real',
        taskId: 't-real',
        fromNow: const Duration(minutes: 25),
      ),
    ];
    final snap = WatchSnapshotBuilder.build(
      plan: plan,
      momentum: momentum,
      now: now,
    );
    expect(snap.nextReminder?.taskId, 't-real');
  });

  test('entries with an empty taskId are skipped', () {
    final plan = [
      reminder(id: 'n-empty', taskId: '', fromNow: const Duration(minutes: 5)),
      reminder(
        id: 'n-real',
        taskId: 't-real',
        fromNow: const Duration(minutes: 10),
      ),
    ];
    final snap = WatchSnapshotBuilder.build(
      plan: plan,
      momentum: momentum,
      now: now,
    );
    expect(snap.nextReminder?.taskId, 't-real');
  });

  test('nextReminder is null when the plan has no eligible task reminders', () {
    final plan = [
      ScheduledNotification(
        id: '${NotificationScheduler.morningPrefix}2026-11-04',
        taskId: '',
        fireAt: now.add(const Duration(minutes: 10)),
        title: 'Morning',
        body: 'Plan',
      ),
      reminder(
        id: 'n-past',
        taskId: 't-past',
        fromNow: const Duration(hours: -1),
      ),
    ];
    final snap = WatchSnapshotBuilder.build(
      plan: plan,
      momentum: momentum,
      now: now,
    );
    expect(snap.nextReminder, isNull);
  });

  test('ifThenByTaskId attaches the if-then line to the chosen reminder', () {
    final plan = [
      reminder(id: 'n-1', taskId: 't-1', fromNow: const Duration(minutes: 30)),
    ];
    final snap = WatchSnapshotBuilder.build(
      plan: plan,
      momentum: momentum,
      now: now,
      ifThenByTaskId: const {'t-1': 'open the thesis file'},
    );
    expect(snap.nextReminder?.ifThen, 'open the thesis file');
  });

  test('a task missing from ifThenByTaskId keeps ifThen null', () {
    final plan = [
      reminder(id: 'n-1', taskId: 't-1', fromNow: const Duration(minutes: 30)),
    ];
    final snap = WatchSnapshotBuilder.build(
      plan: plan,
      momentum: momentum,
      now: now,
      ifThenByTaskId: const {'t-other': 'something else'},
    );
    expect(snap.nextReminder?.ifThen, isNull);
  });

  test(
    'an empty ifThen string is dropped so the Pip screen hides the cue line',
    () {
      final plan = [
        reminder(
          id: 'n-1',
          taskId: 't-1',
          fromNow: const Duration(minutes: 30),
        ),
      ];
      final snap = WatchSnapshotBuilder.build(
        plan: plan,
        momentum: momentum,
        now: now,
        ifThenByTaskId: const {'t-1': ''},
      );
      expect(snap.nextReminder?.ifThen, isNull);
    },
  );

  test('equal inputs produce byte-identical encoded JSON', () {
    // The watch skips a redraw when the payload bytes have not changed, so
    // the builder must not introduce jitter (e.g. map iteration order).
    final plan = [
      reminder(id: 'n-1', taskId: 't-1', fromNow: const Duration(minutes: 30)),
    ];
    final a = WatchSnapshotBuilder.build(
      plan: plan,
      momentum: momentum,
      now: now,
      ifThenByTaskId: const {'t-1': 'open the thesis file'},
    );
    final b = WatchSnapshotBuilder.build(
      plan: plan,
      momentum: momentum,
      now: now,
      ifThenByTaskId: const {'t-1': 'open the thesis file'},
    );
    expect(a.encode(), b.encode());
  });

  test('result roundtrips through WatchSnapshot.tryDecode', () {
    final plan = [
      reminder(id: 'n-1', taskId: 't-1', fromNow: const Duration(minutes: 30)),
    ];
    final built = WatchSnapshotBuilder.build(
      plan: plan,
      momentum: momentum,
      now: now,
      ifThenByTaskId: const {'t-1': 'open the thesis file'},
    );
    final decoded = WatchSnapshot.tryDecode(built.encode());
    expect(decoded, isNotNull);
    expect(decoded!.nextReminder?.taskId, 't-1');
    expect(decoded.nextReminder?.ifThen, 'open the thesis file');
    expect(decoded.momentum.level, 'strong');
    expect(decoded.momentum.value, 62);
  });
}
