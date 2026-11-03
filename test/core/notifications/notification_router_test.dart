import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/notifications.dart';

import 'helpers.dart';

void main() {
  setUpAll(ensureTimeZones);

  final now = DateTime.utc(2026, 11, 3, 9);
  late InMemoryTaskRepository repo;
  late NotificationRouter router;

  setUp(() {
    repo = InMemoryTaskRepository([
      task('a', remindAt: DateTime.utc(2026, 11, 3, 8, 55)),
      task('b', remindAt: DateTime.utc(2026, 11, 3, 7)),
    ]);
    router = NotificationRouter(tasks: repo, clock: FixedClock(now));
  });

  tearDown(() => router.dispose());

  NotificationResponse r(String taskId, NotificationAction? action) =>
      NotificationResponse(
        notificationId: 'task:$taskId:1',
        taskId: taskId,
        action: action,
      );

  test('done marks the task done with completedAt', () async {
    await router.handle(r('a', NotificationAction.done));
    final a = await repo.getById('a');
    expect(a!.status, TaskStatus.done);
    expect(a.completedAt, now);
    expect(a.updatedAt, now);
  });

  test('done twice is harmless', () async {
    await router.handle(r('a', NotificationAction.done));
    await router.handle(r('a', NotificationAction.done));
    expect((await repo.getById('a'))!.completedAt, now);
  });

  test('snooze moves remindAt by 15 minutes and counts it', () async {
    // Snoozed from the reminder at 08:55, tapped at 09:00: never in the past.
    await router.handle(r('a', NotificationAction.snooze));
    final a = await repo.getById('a');
    expect(a!.remindAt, now.add(const Duration(minutes: 15)));
    expect(a.snoozeCount, 1);
    expect(a.status, TaskStatus.open);
    await router.handle(r('a', NotificationAction.snooze));
    final again = await repo.getById('a');
    expect(again!.remindAt, now.add(const Duration(minutes: 30)));
    expect(again.snoozeCount, 2);
  });

  test('snooze on a future reminder adds to it', () async {
    await repo.upsert(task('c', remindAt: now.add(const Duration(hours: 1))));
    await router.handle(r('c', NotificationAction.snooze));
    expect(
      (await repo.getById('c'))!.remindAt,
      now.add(const Duration(hours: 1, minutes: 15)),
    );
  });

  test('start focus emits the task id, body tap emits opened', () async {
    final focus = <String>[];
    final opened = <NotificationResponse>[];
    router.focusRequests.listen(focus.add);
    router.opened.listen(opened.add);
    await router.handle(r('b', NotificationAction.startFocus));
    await router.handle(r('b', null));
    await pumpEventQueue();
    expect(focus, ['b']);
    expect(opened.single.taskId, 'b');
    expect(NotificationRouter.focusLocation('b'), '/focus?taskId=b');
    expect((await repo.getById('b'))!.status, TaskStatus.open);
  });

  test('unknown tasks and prompts are ignored', () async {
    await router.handle(r('missing', NotificationAction.done));
    await router.handle(
      const NotificationResponse(
        notificationId: 'prompt:morning:2026-11-03',
        taskId: '',
        action: NotificationAction.done,
      ),
    );
    expect((await repo.getAll()).every((t) => !t.isDone), isTrue);
  });

  test('attach applies a response stream', () async {
    final sub = router.attach(
      Stream.fromIterable([r('a', NotificationAction.done)]),
    );
    await pumpEventQueue();
    expect((await repo.getById('a'))!.isDone, isTrue);
    await sub.cancel();
  });

  group('all five actions with notifications and preferences', () {
    // 09:00Z = 11:00 in Asia/Jerusalem (UTC+2 in November).
    late FakeNotificationService notifications;
    late NotificationRouter full;

    setUp(() {
      ensureTimeZones();
      notifications = FakeNotificationService();
      full = NotificationRouter(
        tasks: repo,
        clock: FixedClock(now),
        notifications: notifications,
        preferences: InMemoryPreferencesRepository(
          const Preferences(timeZoneName: 'Asia/Jerusalem'),
        ),
      );
    });

    tearDown(() => full.dispose());

    test('done cancels the task\'s other pending notifications', () async {
      await full.handle(r('a', NotificationAction.done));
      expect((await repo.getById('a'))!.isDone, isTrue);
      expect(notifications.cancelledTaskIds, ['a']);
    });

    test('move to tonight: 20:00 local, snooze count reset', () async {
      await repo.upsert((await repo.getById('a'))!.copyWith(snoozeCount: 2));
      await full.handle(r('a', NotificationAction.moveToTonight));
      final a = (await repo.getById('a'))!;
      expect(a.remindAt, DateTime.utc(2026, 11, 3, 18));
      expect(a.snoozeCount, 0);
      expect(a.status, TaskStatus.open);
    });

    test('move to tomorrow: same local time next day, reset', () async {
      await repo.upsert((await repo.getById('b'))!.copyWith(snoozeCount: 3));
      await full.handle(r('b', NotificationAction.moveToTomorrow));
      final b = (await repo.getById('b'))!;
      // b reminded at 07:00Z (09:00 local) -> 09:00 local on the 4th.
      expect(b.remindAt, DateTime.utc(2026, 11, 4, 7));
      expect(b.snoozeCount, 0);
    });

    test('snooze, start focus and body tap still behave', () async {
      final focus = <String>[];
      final opened = <NotificationResponse>[];
      full.focusRequests.listen(focus.add);
      full.opened.listen(opened.add);
      await full.handle(r('a', NotificationAction.snooze));
      await full.handle(r('a', NotificationAction.startFocus));
      await full.handle(r('a', null));
      await pumpEventQueue();
      expect((await repo.getById('a'))!.snoozeCount, 1);
      expect(focus, ['a']);
      expect(NotificationRouter.openLocation(opened.single), '/task/a');
      expect(notifications.cancelledTaskIds, isEmpty);
    });

    test('a move on a done task is ignored', () async {
      await full.handle(r('a', NotificationAction.done));
      final before = (await repo.getById('a'))!.remindAt;
      await full.handle(r('a', NotificationAction.moveToTomorrow));
      expect((await repo.getById('a'))!.remindAt, before);
    });
  });

  test('openLocation: evening prompt opens the review, morning stays', () {
    expect(
      NotificationRouter.openLocation(
        const NotificationResponse(
          notificationId: 'prompt:evening:2026-11-03',
          taskId: '',
        ),
      ),
      '/review',
    );
    expect(
      NotificationRouter.openLocation(
        const NotificationResponse(
          notificationId: 'prompt:morning:2026-11-03',
          taskId: '',
        ),
      ),
      isNull,
    );
  });

  test('"Pick a time" decodes to a body tap', () {
    final raw = RawNotificationResponse(
      actionId: actionIdPickTime,
      payload: encodePayload(
        ScheduledNotification(
          id: 'task:a:1',
          taskId: 'a',
          fireAt: now,
          title: 't',
          body: 'b',
        ),
      ),
    );
    final decoded = raw.decode()!;
    expect(decoded.action, isNull);
    expect(decoded.taskId, 'a');
    expect(
      actionFromId(actionIdMoveToTonight),
      NotificationAction.moveToTonight,
    );
    expect(
      actionFromId(actionIdFor(NotificationAction.moveToTomorrow)),
      NotificationAction.moveToTomorrow,
    );
  });

  group('recurring tasks', () {
    // Daily 07:00 series anchored on 1 Nov; "now" is the 3rd at 09:00.
    final anchor = DateTime.utc(2026, 11, 1, 7);
    late InMemoryReminderRepository rules;
    late NotificationRouter recurring;

    setUp(() async {
      await repo.upsert(task('daily', remindAt: anchor));
      rules = InMemoryReminderRepository([
        ReminderRule(
          id: 'rule-daily',
          taskId: 'daily',
          rrule: 'FREQ=DAILY',
          createdAt: epoch,
          updatedAt: epoch,
        ),
      ]);
      recurring = NotificationRouter(
        tasks: repo,
        clock: FixedClock(now),
        reminders: rules,
        preferences: InMemoryPreferencesRepository(utcPrefs),
      );
    });

    tearDown(() => recurring.dispose());

    test('done completes the occurrence, not the series', () async {
      await recurring.handle(r('daily', NotificationAction.done));
      final t = (await repo.getById('daily'))!;
      expect(t.status, TaskStatus.open);
      expect(t.completedAt, isNull);
      expect(t.remindAt, DateTime.utc(2026, 11, 4, 7));
    });

    test('snooze and moves leave the series anchor alone', () async {
      for (final a in [
        NotificationAction.snooze,
        NotificationAction.moveToTonight,
        NotificationAction.moveToTomorrow,
      ]) {
        await recurring.handle(r('daily', a));
      }
      final t = (await repo.getById('daily'))!;
      expect(t.remindAt, anchor);
      expect(t.snoozeCount, 0);
    });
  });
}
