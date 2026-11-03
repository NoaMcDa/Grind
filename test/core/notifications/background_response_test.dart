import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/data/connection/memory.dart';
import 'package:grind/core/data/data.dart';
import 'package:grind/core/notifications/notifications.dart';

import 'fake_backend.dart';
import 'helpers.dart';

/// Fails every write, like a locked or unopenable database.
class _BrokenTasks extends InMemoryTaskRepository {
  _BrokenTasks(super.seed);

  @override
  Future<void> upsert(Task task) => Future.error(StateError('locked'));
}

void main() {
  setUpAll(ensureTimeZones);

  final now = DateTime.utc(2026, 11, 3, 9);
  final clock = FixedClock(now);
  final prefs = InMemoryPreferencesRepository(utcPrefs);

  NotificationResponse r(String taskId, NotificationAction action) =>
      NotificationResponse(
        notificationId: 'task:$taskId:1',
        taskId: taskId,
        action: action,
      );

  late FakeBackend backend;
  late LocalNotificationService service;

  setUp(() async {
    backend = FakeBackend();
    service = LocalNotificationService(
      backend: backend,
      store: MemoryNotificationStore(),
      clock: clock,
      replayJournal: false,
    );
  });

  Future<void> seedPending(List<Task> tasks) => service.replaceAll(
    NotificationScheduler.plan(
      tasks: tasks,
      prefs: utcPrefs,
      clock: clock,
      prompts: const PromptSettings(
        morningEnabled: false,
        eveningEnabled: false,
      ),
    ),
  );

  test('Done on a killed app lands in the Drift database at once', () async {
    final db = openInMemoryDatabase();
    addTearDown(db.close);
    final tasks = DriftTaskRepository(db);
    final a = task('a', remindAt: now.add(const Duration(minutes: 5)));
    await tasks.upsert(a);
    await seedPending([a]);
    expect(backend.pending, isNotEmpty);

    await applyResponseInBackground(
      response: r('a', NotificationAction.done),
      tasks: tasks,
      preferences: DriftPreferencesRepository(db),
      clock: clock,
      service: service,
    );

    final stored = await tasks.getById('a');
    expect(stored!.status, TaskStatus.done);
    expect(stored.completedAt, now);
    expect(backend.pending, isEmpty, reason: 'other reminders cancelled');
  });

  test('Snooze schedules the next reminder right away', () async {
    final tasks = InMemoryTaskRepository([
      task('a', remindAt: now.subtract(const Duration(minutes: 1))),
      task('b', remindAt: now.add(const Duration(hours: 2))),
    ]);
    await seedPending(await tasks.getAll());
    expect(backend.notificationIds, hasLength(1)); // a is in the past

    await applyResponseInBackground(
      response: r('a', NotificationAction.snooze),
      tasks: tasks,
      preferences: prefs,
      clock: clock,
      service: service,
    );
    final at = now.add(const Duration(minutes: 15));
    expect(
      backend.notificationIds,
      containsAll([
        NotificationScheduler.taskNotificationId('a', at),
        NotificationScheduler.taskNotificationId(
          'b',
          now.add(const Duration(hours: 2)),
        ),
      ]),
    );
    expect(backend.pending.values.map((p) => p.category).toSet(), {
      grindReminderCategory,
    });

    // The second snooze: the next one offers to move instead.
    await applyResponseInBackground(
      response: r('a', NotificationAction.snooze),
      tasks: tasks,
      preferences: prefs,
      clock: clock,
      service: service,
    );
    final a = (await tasks.getById('a'))!;
    expect(a.snoozeCount, 2);
    final next = backend.pending.values.firstWhere(
      (p) => p.payload.contains(
        NotificationScheduler.taskNotificationId('a', a.remindAt!),
      ),
    );
    expect(next.category, grindRescheduleCategory);
    expect(backend.notificationIds, hasLength(2));
  });

  test('Tonight resets the count and schedules a normal reminder', () async {
    final tasks = InMemoryTaskRepository([
      task('a', remindAt: now).copyWith(snoozeCount: 2),
    ]);
    await applyResponseInBackground(
      response: r('a', NotificationAction.moveToTonight),
      tasks: tasks,
      preferences: prefs,
      clock: clock,
      service: service,
    );
    final a = (await tasks.getById('a'))!;
    expect(a.remindAt, DateTime.utc(2026, 11, 3, 20));
    expect(a.snoozeCount, 0);
    expect(backend.pending.values.single.category, grindReminderCategory);
  });

  test('a failed write throws so the caller can journal it', () async {
    final tasks = _BrokenTasks([task('a', remindAt: now)]);
    await expectLater(
      applyResponseInBackground(
        response: r('a', NotificationAction.done),
        tasks: tasks,
        preferences: prefs,
        clock: clock,
        service: service,
      ),
      throwsStateError,
    );
  });

  test('a recurring task keeps its pending occurrences', () async {
    final a = task('a', remindAt: now.add(const Duration(minutes: 1)));
    final tasks = InMemoryTaskRepository([a]);
    await seedPending([a]);
    final before = backend.notificationIds.toList();
    await applyResponseInBackground(
      response: r('a', NotificationAction.snooze),
      tasks: tasks,
      preferences: prefs,
      clock: clock,
      service: service,
      reminders: InMemoryReminderRepository([
        ReminderRule(
          id: 'rule',
          taskId: 'a',
          rrule: 'FREQ=DAILY',
          createdAt: epoch,
          updatedAt: epoch,
        ),
      ]),
    );
    // The series anchor is left alone, and so are its pending occurrences.
    final after = (await tasks.getById('a'))!;
    expect(after.snoozeCount, 0);
    expect(after.remindAt, a.remindAt);
    expect(backend.notificationIds, before);
  });
}
