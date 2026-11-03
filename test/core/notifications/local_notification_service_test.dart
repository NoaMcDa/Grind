import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/notifications.dart';

import 'fake_backend.dart';
import 'helpers.dart';

void main() {
  setUpAll(ensureTimeZones);

  final now = DateTime.utc(2026, 11, 3, 6);

  test(
    '100 reminders over a month: the soonest 7 days are always scheduled',
    () async {
      final backend = FakeBackend();
      final service = LocalNotificationService(
        backend: backend,
        store: MemoryNotificationStore(),
        clock: FixedClock(now),
        timeZoneName: 'Asia/Jerusalem',
      );
      final tasks = [
        for (var i = 0; i < 100; i++)
          task('t$i', remindAt: now.add(Duration(minutes: 30 + i * 432))),
      ];
      final plan = NotificationScheduler.plan(
        tasks: tasks,
        prefs: const Preferences(),
        clock: FixedClock(now),
      );
      await service.replaceAll(plan);

      expect(backend.pending.length, plan.length);
      expect(backend.pending.length, lessThanOrEqualTo(64));
      final weekEnd = now.add(const Duration(days: 7));
      final dueThisWeek = [
        for (final t in tasks)
          if (t.remindAt!.isBefore(weekEnd))
            NotificationScheduler.taskNotificationId(t.id, t.remindAt!),
      ];
      expect(backend.notificationIds, containsAll(dueThisWeek));
      expect(
        backend.pending.values.every(
          (p) => p.at.location.name == 'Asia/Jerusalem',
        ),
        isTrue,
      );
      // Task reminders carry the action category; prompts do not.
      final withActions = backend.pending.values.where(
        (p) => p.category != null,
      );
      expect(withActions.length, dueThisWeek.length);
    },
  );

  test('hard-trims an oversized set to maxPending, soonest first', () async {
    final backend = FakeBackend();
    final service = LocalNotificationService(
      backend: backend,
      store: MemoryNotificationStore(),
      clock: FixedClock(now),
    );
    final many = [
      for (var i = 100; i > 0; i--)
        ScheduledNotification(
          id: 'n$i',
          taskId: 't$i',
          fireAt: now.add(Duration(hours: i)),
          title: 't',
          body: 'b',
        ),
      ScheduledNotification(
        id: 'past',
        taskId: 'p',
        fireAt: now.subtract(const Duration(minutes: 1)),
        title: 't',
        body: 'b',
      ),
    ];
    await service.replaceAll(many);
    expect(service.scheduledIds, [for (var i = 1; i <= 60; i++) 'n$i']);
    expect(backend.pending.length, 60);
  });

  test('replaceAll replaces; cancelForTask works after a relaunch', () async {
    final store = MemoryNotificationStore();
    final backend = FakeBackend();
    ScheduledNotification n(String id, String taskId, int h) =>
        ScheduledNotification(
          id: id,
          taskId: taskId,
          fireAt: now.add(Duration(hours: h)),
          title: 't',
          body: 'b',
        );
    final first = LocalNotificationService(
      backend: backend,
      store: store,
      clock: FixedClock(now),
    );
    await first.replaceAll([n('a1', 'a', 1), n('b1', 'b', 2)]);
    await first.replaceAll([n('a1', 'a', 1), n('a2', 'a', 3), n('c1', 'c', 4)]);
    expect(backend.notificationIds, ['a1', 'a2', 'c1']);

    // New process: same OS state, index read back from the store.
    final second = LocalNotificationService(
      backend: backend,
      store: store,
      clock: FixedClock(now),
    );
    await second.cancelForTask('a');
    expect(backend.notificationIds, ['c1']);
    expect(second.scheduledIds, ['c1']);
  });

  test('replays journalled background responses, then the launch tap, '
      'then live ones', () async {
    final store = MemoryNotificationStore();
    String payload(String id, String taskId) =>
        jsonEncode({'taskId': taskId, 'notificationId': id});
    // What the background isolate wrote while the app was not running.
    await appendPendingResponse(
      store,
      RawNotificationResponse(actionId: 'done', payload: payload('n1', 't1')),
    );
    await appendPendingResponse(
      store,
      RawNotificationResponse(actionId: 'snooze', payload: payload('n2', 't2')),
    );
    final backend = FakeBackend()
      ..launch = RawNotificationResponse(payload: payload('n3', 't3'));
    final service = LocalNotificationService(backend: backend, store: store);

    final got = <NotificationResponse>[];
    final sub = service.responses.listen(got.add);
    await service.ready;
    await pumpEventQueue();
    backend.onResponse!(
      RawNotificationResponse(
        actionId: 'start_focus',
        payload: payload('n4', 't4'),
      ),
    );
    backend.onResponse!(const RawNotificationResponse(payload: 'garbage'));
    await pumpEventQueue();

    expect(got.map((r) => (r.taskId, r.action)), [
      ('t1', NotificationAction.done),
      ('t2', NotificationAction.snooze),
      ('t3', null),
      ('t4', NotificationAction.startFocus),
    ]);
    expect(await drainPendingResponses(store), isEmpty);
    await sub.cancel();
  });

  test('permission is delegated to the plugin', () async {
    final backend = FakeBackend();
    final service = LocalNotificationService(
      backend: backend,
      store: MemoryNotificationStore(),
    );
    expect(await service.hasPermission(), isFalse);
    expect(await service.requestPermission(), isTrue);
    expect(await service.hasPermission(), isTrue);
    expect(backend.initCount, 1);
  });

  test('platform ids are stable and positive', () {
    expect(platformIdFor('task:a:1'), platformIdFor('task:a:1'));
    expect(platformIdFor('task:a:1'), isNot(platformIdFor('task:a:2')));
    expect(platformIdFor('x'), inInclusiveRange(0, 0x7fffffff));
  });

  test(
    'category follows the actions; replaceTaskReminders is scoped',
    () async {
      final backend = FakeBackend();
      final service = LocalNotificationService(
        backend: backend,
        store: MemoryNotificationStore(),
        clock: FixedClock(now),
      );
      ScheduledNotification n(
        String id,
        String taskId,
        int hours, [
        List<NotificationAction> actions =
            NotificationScheduler.reminderActions,
      ]) => ScheduledNotification(
        id: id,
        taskId: taskId,
        fireAt: now.add(Duration(hours: hours)),
        title: 't',
        body: 'b',
        actions: actions,
      );
      await service.replaceAll([
        n('task:a:1', 'a', 1),
        n('rec:a:1', 'a', 2),
        n('task:b:1', 'b', 3, NotificationScheduler.rescheduleActions),
        n('prompt:morning:2026-11-04', '', 4, const []),
      ]);
      String? categoryOf(String id) => backend.pending.values
          .firstWhere(
            (p) => (jsonDecode(p.payload) as Map)['notificationId'] == id,
          )
          .category;
      expect(categoryOf('task:a:1'), grindReminderCategory);
      expect(categoryOf('task:b:1'), grindRescheduleCategory);
      expect(categoryOf('prompt:morning:2026-11-04'), isNull);

      await service.replaceTaskReminders('a', [n('task:a:2', 'a', 5)]);
      expect(backend.notificationIds.toSet(), {
        'rec:a:1',
        'task:b:1',
        'prompt:morning:2026-11-04',
        'task:a:2',
      });
      expect(service.scheduledIds, contains('task:a:2'));

      // A past reminder is not scheduled.
      await service.replaceTaskReminders('a', [n('task:a:0', 'a', -1)]);
      expect(backend.notificationIds, isNot(contains('task:a:0')));
      expect(backend.notificationIds, isNot(contains('task:a:2')));
    },
  );

  test('replayJournal: false leaves the journal for the next launch', () async {
    final store = MemoryNotificationStore();
    await appendPendingResponse(
      store,
      const RawNotificationResponse(actionId: 'done', payload: '{}'),
    );
    final service = LocalNotificationService(
      backend: FakeBackend(),
      store: store,
      clock: FixedClock(now),
      replayJournal: false,
    );
    await service.ready;
    expect(store.docs.containsKey(pendingResponsesDocument), isTrue);
  });
}
