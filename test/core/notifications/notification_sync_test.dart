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

/// Refuses the first replaceAll, like an OS that rejects one request.
class FlakyService extends CountingService {
  @override
  Future<void> replaceAll(List<ScheduledNotification> notifications) async {
    calls++;
    if (calls == 1) throw StateError('os said no');
    pending
      ..clear()
      ..addAll(notifications);
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

  test('rules: a rule-only edit re-plans and skips the rule task\'s '
      'remindAt', () async {
    final rules = InMemoryReminderRepository();
    final withRules = NotificationSync(
      tasks: tasks,
      preferences: prefs,
      reminders: rules,
      service: service,
      clock: FixedClock(now),
      debounce: debounce,
    );
    addTearDown(withRules.dispose);
    await tasks.upsert(task('r', remindAt: now.add(const Duration(hours: 1))));
    withRules.start();
    await settle();
    final before = service.calls;
    expect(service.pending.where((n) => n.taskId == 'r'), hasLength(1));

    await rules.upsert(
      ReminderRule(
        id: 'rule1',
        taskId: 'r',
        rrule: 'FREQ=DAILY',
        createdAt: epoch,
        updatedAt: epoch,
      ),
    );
    await settle();
    expect(service.calls, before + 1);
    expect(service.pending.where((n) => n.taskId == 'r'), isEmpty);
  });

  test('an identical plan is retried after replaceAll failed', () async {
    final flaky = FlakyService();
    final retry = NotificationSync(
      tasks: tasks,
      preferences: prefs,
      service: flaky,
      clock: FixedClock(now),
      debounce: debounce,
    );
    addTearDown(retry.dispose);
    await expectLater(retry.refresh(), throwsStateError);
    await retry.refresh();
    expect(flaky.calls, 2);
    expect(flaky.pending, isNotEmpty);
  });
}
