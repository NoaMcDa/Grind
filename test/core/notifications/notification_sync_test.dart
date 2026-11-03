import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/notifications.dart';

import 'helpers.dart';

/// Counts replaceAll calls on top of the core fake.
class CountingService extends FakeNotificationService {
  int calls = 0;

  @override
  Future<void> replaceAll(List<ScheduledNotification> notifications) {
    calls++;
    return super.replaceAll(notifications);
  }
}

void main() {
  setUpAll(ensureTimeZones);

  final now = DateTime.utc(2026, 11, 3, 6);
  const debounce = Duration(milliseconds: 60);
  late InMemoryTaskRepository tasks;
  late InMemoryPreferencesRepository prefs;
  late CountingService service;
  late NotificationSync sync;

  setUp(() {
    tasks = InMemoryTaskRepository();
    prefs = InMemoryPreferencesRepository(utcPrefs);
    service = CountingService();
    sync = NotificationSync(
      tasks: tasks,
      preferences: prefs,
      service: service,
      clock: FixedClock(now),
      debounce: debounce,
    );
  });

  tearDown(() => sync.dispose());

  Future<void> settle() => Future.delayed(debounce * 3);

  test('debounces a burst of edits into one replaceAll', () async {
    sync.start();
    await settle(); // initial values from both repositories
    expect(service.calls, 1);

    for (var i = 0; i < 5; i++) {
      await tasks.upsert(
        task('t$i', remindAt: now.add(Duration(hours: i + 1))),
      );
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(service.calls, 1, reason: 'still inside the debounce window');
    await settle();
    expect(service.calls, 2);
    expect(service.pending.where((n) => n.taskId.isNotEmpty), hasLength(5));
  });

  test('preference changes re-plan; identical plans are skipped', () async {
    sync.start();
    await settle();
    await tasks.upsert(task('a', remindAt: DateTime.utc(2026, 11, 4, 2)));
    await settle();
    expect(service.calls, 2);

    // An edit that does not change the plan.
    await tasks.upsert(
      task('a', remindAt: DateTime.utc(2026, 11, 4, 2)).copyWith(notes: 'x'),
    );
    await settle();
    expect(service.calls, 2);

    await prefs.save(utcPrefs.copyWith(quietHours: TimeRange.hm(0, 0, 7, 0)));
    await settle();
    expect(service.calls, 3);
    expect(
      service.pending.firstWhere((n) => n.taskId == 'a').fireAt,
      DateTime.utc(2026, 11, 4, 7),
    );
  });

  test('refresh plans immediately without start()', () async {
    await tasks.upsert(task('a', remindAt: now.add(const Duration(hours: 1))));
    await sync.refresh();
    expect(service.calls, 1);
    expect(service.pending.first.taskId, 'a');
    await sync.refresh(force: true);
    expect(service.calls, 2);
  });

  test('a done task drops out of the pending set', () async {
    final router = NotificationRouter(tasks: tasks, clock: FixedClock(now));
    await tasks.upsert(task('a', remindAt: now.add(const Duration(hours: 1))));
    sync.start();
    await settle();
    expect(service.pending.any((n) => n.taskId == 'a'), isTrue);
    await router.handle(
      const NotificationResponse(
        notificationId: 'task:a:1',
        taskId: 'a',
        action: NotificationAction.done,
      ),
    );
    await settle();
    expect(service.pending.any((n) => n.taskId == 'a'), isFalse);
    await router.dispose();
  });

  test('extra notifications are included', () async {
    final withExtra = NotificationSync(
      tasks: tasks,
      preferences: prefs,
      service: service,
      clock: FixedClock(now),
      extra: (_, _) => [
        ScheduledNotification(
          id: 'rec:1',
          taskId: 'r',
          fireAt: now.add(const Duration(hours: 2)),
          title: 'Gym',
          body: 'Gym',
        ),
      ],
    );
    await withExtra.refresh();
    expect(service.pending.map((n) => n.id), contains('rec:1'));
    await withExtra.dispose();
  });
}
