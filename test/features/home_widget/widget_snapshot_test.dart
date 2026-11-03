import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/companion/effort_score.dart';
import 'package:grind/features/home_widget/home_widget.dart';

void main() {
  final now = DateTime.utc(2026, 11, 3, 6);

  ScheduledNotification taskReminder(
    String taskId,
    DateTime fireAt, {
    String title = 'Draft email',
    String body = 'If 7:00 then open the draft.',
    List<NotificationAction> actions = const [
      NotificationAction.done,
      NotificationAction.snooze,
      NotificationAction.startFocus,
    ],
  }) => ScheduledNotification(
    id: 'task:$taskId:${fireAt.millisecondsSinceEpoch ~/ 60000}',
    taskId: taskId,
    fireAt: fireAt,
    title: title,
    body: body,
    actions: actions,
  );

  ScheduledNotification prompt(String id, DateTime fireAt) =>
      ScheduledNotification(
        id: id,
        taskId: '',
        fireAt: fireAt,
        title: 'Plan the day',
        body: '',
        actions: const [],
      );

  group('builder', () {
    test('picks the soonest future task reminder and skips prompts', () {
      final plan = [
        prompt('prompt:morning:2026-11-03', now.add(const Duration(hours: 2))),
        taskReminder('a', now.add(const Duration(hours: 3))),
        taskReminder('b', now.add(const Duration(hours: 5))),
      ];

      final snapshot = WidgetSnapshotBuilder.build(
        plan: plan,
        momentum: EffortScore.empty,
        now: now,
      );

      expect(snapshot.nextReminder, isNotNull);
      expect(snapshot.nextReminder!.taskId, 'a');
      expect(snapshot.nextReminder!.title, 'Draft email');
      expect(snapshot.nextReminder!.canComplete, isTrue);
      expect(snapshot.nextReminder!.canStartFocus, isTrue);
    });

    test('drops reminders that already fired', () {
      final snapshot = WidgetSnapshotBuilder.build(
        plan: [
          taskReminder('old', now.subtract(const Duration(minutes: 1))),
          taskReminder('next', now.add(const Duration(hours: 2))),
        ],
        momentum: EffortScore.empty,
        now: now,
      );
      expect(snapshot.nextReminder!.taskId, 'next');
    });

    test('nextReminder is null when the plan has no task reminders', () {
      final snapshot = WidgetSnapshotBuilder.build(
        plan: [
          prompt(
            'prompt:evening:2026-11-03',
            now.add(const Duration(hours: 1)),
          ),
        ],
        momentum: EffortScore.empty,
        now: now,
      );
      expect(snapshot.nextReminder, isNull);
    });

    test('smart-snooze actions drop the Done and Start-focus flags', () {
      final snapshot = WidgetSnapshotBuilder.build(
        plan: [
          taskReminder(
            't',
            now.add(const Duration(hours: 1)),
            actions: const [
              NotificationAction.moveToTonight,
              NotificationAction.moveToTomorrow,
            ],
          ),
        ],
        momentum: EffortScore.empty,
        now: now,
      );
      expect(snapshot.nextReminder!.canComplete, isFalse);
      expect(snapshot.nextReminder!.canStartFocus, isFalse);
    });

    test('momentum is copied as-is from the effort score', () {
      final score = EffortScore.compute(
        tasks: [
          Task(
            id: 'done-today',
            title: 'Done',
            status: TaskStatus.done,
            completedAt: now.subtract(const Duration(hours: 2)),
            createdAt: now.subtract(const Duration(days: 1)),
            updatedAt: now.subtract(const Duration(hours: 2)),
          ),
        ],
        now: now,
      );

      final snapshot = WidgetSnapshotBuilder.build(
        plan: const [],
        momentum: score,
        now: now,
      );

      expect(snapshot.momentum.value, score.value);
      expect(snapshot.momentum.level, score.level.name);
      expect(snapshot.momentum.showedUpDays, score.showedUpDays);
      expect(snapshot.momentum.dayCounts, score.dayCounts);
    });

    test('writtenAt is the given time in UTC', () {
      final local = DateTime(2026, 11, 3, 12).toLocal();
      final snapshot = WidgetSnapshotBuilder.build(
        plan: const [],
        momentum: EffortScore.empty,
        now: local,
      );
      expect(snapshot.writtenAt.isUtc, isTrue);
      expect(
        snapshot.writtenAt.millisecondsSinceEpoch,
        local.toUtc().millisecondsSinceEpoch,
      );
    });
  });

  group('encode / decode', () {
    test('round-trips a full snapshot', () {
      final original = WidgetSnapshot(
        writtenAt: now,
        nextReminder: WidgetReminder(
          taskId: 'abc',
          notificationId: 'task:abc:9000000',
          fireAt: now.add(const Duration(hours: 1)),
          title: 'Draft email',
          body: 'If 7:00 then open the draft.',
        ),
        momentum: const WidgetMomentum(
          value: 42.5,
          level: 'steady',
          showedUpDays: 3,
          dayCounts: [0, 1, 2, 0, 1, 1, 0],
        ),
      );

      final decoded = WidgetSnapshot.tryDecode(original.encode());

      expect(decoded, isNotNull);
      expect(decoded!.schema, WidgetSnapshot.schemaVersion);
      expect(decoded.writtenAt, original.writtenAt);
      expect(decoded.nextReminder!.taskId, 'abc');
      expect(decoded.nextReminder!.notificationId, 'task:abc:9000000');
      expect(decoded.nextReminder!.fireAt, original.nextReminder!.fireAt);
      expect(decoded.momentum.value, 42.5);
      expect(decoded.momentum.level, 'steady');
      expect(decoded.momentum.showedUpDays, 3);
      expect(decoded.momentum.dayCounts, [0, 1, 2, 0, 1, 1, 0]);
    });

    test('round-trips a snapshot with no next reminder', () {
      final original = WidgetSnapshot(
        writtenAt: now,
        momentum: const WidgetMomentum(
          value: 0,
          level: 'quiet',
          showedUpDays: 0,
          dayCounts: [0, 0, 0, 0, 0, 0, 0],
        ),
      );
      final decoded = WidgetSnapshot.tryDecode(original.encode());
      expect(decoded, isNotNull);
      expect(decoded!.nextReminder, isNull);
      final jsonMap = jsonDecode(original.encode()) as Map<String, Object?>;
      expect(jsonMap.containsKey('nextReminder'), isFalse);
    });

    test('rejects missing, empty, broken and future-schema payloads', () {
      expect(WidgetSnapshot.tryDecode(null), isNull);
      expect(WidgetSnapshot.tryDecode(''), isNull);
      expect(WidgetSnapshot.tryDecode('not json'), isNull);

      final future = jsonEncode({
        'schema': WidgetSnapshot.schemaVersion + 1,
        'writtenAt': now.toIso8601String(),
        'momentum': {
          'value': 0,
          'level': 'quiet',
          'showedUpDays': 0,
          'dayCounts': [0, 0, 0, 0, 0, 0, 0],
        },
      });
      expect(WidgetSnapshot.tryDecode(future), isNull);

      final noMomentum = jsonEncode({
        'schema': WidgetSnapshot.schemaVersion,
        'writtenAt': now.toIso8601String(),
      });
      expect(WidgetSnapshot.tryDecode(noMomentum), isNull);
    });
  });
}
