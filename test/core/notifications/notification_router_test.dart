import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/notifications.dart';

import 'helpers.dart';

void main() {
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
}
