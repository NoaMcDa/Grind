import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'helpers.dart';

/// Records what the service asks of the plugin.
class FakeBackend implements LocalNotificationsBackend {
  final Map<int, ({tz.TZDateTime at, String payload, bool withActions})>
  pending = {};
  void Function(RawNotificationResponse)? onResponse;
  RawNotificationResponse? launch;
  bool granted = false;
  int initCount = 0;

  @override
  Future<void> initialize({
    required void Function(RawNotificationResponse) onResponse,
  }) async {
    initCount++;
    this.onResponse = onResponse;
  }

  @override
  Future<RawNotificationResponse?> launchResponse() async => launch;

  @override
  Future<bool> requestPermission() async => granted = true;

  @override
  Future<bool> hasPermission() async => granted;

  @override
  Future<void> schedule({
    required int platformId,
    required tz.TZDateTime at,
    required String title,
    required String body,
    required String payload,
    required bool withActions,
  }) async {
    pending[platformId] = (at: at, payload: payload, withActions: withActions);
  }

  @override
  Future<void> cancel(int platformId) async => pending.remove(platformId);

  @override
  Future<void> cancelAllPending() async => pending.clear();

  List<String> get notificationIds => [
    for (final p in pending.values)
      (jsonDecode(p.payload) as Map)['notificationId'] as String,
  ];
}

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
      final withActions = backend.pending.values.where((p) => p.withActions);
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
}
