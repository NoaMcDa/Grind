import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/notifications.dart';
import 'package:grind/features/reminders/reminder_copy.dart';
import 'package:timezone/timezone.dart' as tz;

import 'helpers.dart';

const noPrompts = PromptSettings(morningEnabled: false, eveningEnabled: false);

void main() {
  setUpAll(ensureTimeZones);

  final now = DateTime.utc(2026, 11, 3, 6);
  final clock = FixedClock(now);

  group('cap and horizon', () {
    // 100 reminders spread over the next 30 days, every 7.2 hours.
    final tasks = [
      for (var i = 0; i < 100; i++)
        task('t$i', remindAt: now.add(Duration(minutes: 30 + i * 432))),
    ];

    test('keeps every reminder of the next 7 days, soonest first', () {
      final plan = NotificationScheduler.plan(
        tasks: tasks,
        prefs: utcPrefs,
        clock: clock,
      );
      final inWeek = tasks
          .where((t) => t.remindAt!.isBefore(now.add(const Duration(days: 7))))
          .map((t) => t.id)
          .toSet();
      expect(inWeek.length, greaterThan(20));
      final planned = plan.map((n) => n.taskId).toSet();
      expect(planned.containsAll(inWeek), isTrue);
      expect(plan.length, lessThanOrEqualTo(50));
      for (var i = 1; i < plan.length; i++) {
        expect(plan[i].fireAt.isBefore(plan[i - 1].fireAt), isFalse);
      }
      // Nothing beyond the horizon.
      expect(
        plan.every(
          (n) => n.fireAt.isBefore(now.add(const Duration(days: 7, hours: 1))),
        ),
        isTrue,
      );
    });

    test('a 30-day horizon is trimmed to the soonest cap', () {
      final plan = NotificationScheduler.plan(
        tasks: tasks,
        prefs: utcPrefs,
        clock: clock,
        horizonDays: 30,
        prompts: noPrompts,
      );
      expect(plan.map((n) => n.taskId), [for (var i = 0; i < 50; i++) 't$i']);
    });

    test('skips done, deleted, past and unset reminders', () {
      final plan = NotificationScheduler.plan(
        tasks: [
          task(
            'done',
            remindAt: now.add(const Duration(hours: 1)),
          ).copyWith(status: TaskStatus.done),
          task(
            'gone',
            remindAt: now.add(const Duration(hours: 1)),
          ).copyWith(deletedAt: now),
          task('past', remindAt: now.subtract(const Duration(minutes: 1))),
          task('none'),
          task('ok', remindAt: now.add(const Duration(hours: 1))),
        ],
        prefs: utcPrefs,
        clock: clock,
        prompts: noPrompts,
      );
      expect(plan.map((n) => n.taskId), ['ok']);
    });
  });

  test('ids are stable across two runs', () {
    final tasks = [
      task('a', remindAt: now.add(const Duration(hours: 3))),
      task('b', remindAt: now.add(const Duration(days: 2))),
    ];
    List<String> ids() => NotificationScheduler.plan(
      tasks: tasks,
      prefs: utcPrefs,
      clock: FixedClock(now),
    ).map((n) => n.id).toList();
    expect(ids(), ids());
    final fireMinutes =
        now.add(const Duration(hours: 3)).millisecondsSinceEpoch ~/ 60000;
    expect(ids(), contains('task:a:$fireMinutes'));
    expect(ids(), contains('prompt:morning:2026-11-04'));
    expect(ids(), contains('prompt:evening:2026-11-03'));
  });

  test('prompts default to 08:00 and 20:30 local, one per day', () {
    final plan = NotificationScheduler.plan(
      tasks: const [],
      prefs: const Preferences(),
      clock: clock,
    );
    final loc = tz.getLocation('Asia/Jerusalem');
    final morning = plan.where((n) => n.id.startsWith('prompt:morning:'));
    final evening = plan.where((n) => n.id.startsWith('prompt:evening:'));
    // Today's 08:00 is exactly now (not after), so six mornings.
    expect(morning.length, 6);
    expect(evening.length, 7);
    for (final n in morning) {
      final l = tz.TZDateTime.from(n.fireAt, loc);
      expect((l.hour, l.minute), (8, 0));
      expect(n.actions, isEmpty);
    }
    for (final n in evening) {
      final l = tz.TZDateTime.from(n.fireAt, loc);
      expect((l.hour, l.minute), (20, 30));
    }
  });

  test('prompts speak Hebrew when the app language is Hebrew', () {
    const he = Preferences(localeCode: 'he');
    final plan = NotificationScheduler.plan(
      tasks: const [],
      prefs: he,
      clock: clock,
      prompts: const PromptSettings().withPreferences(he),
    );
    final morning = plan.firstWhere((n) => n.id.startsWith('prompt:morning:'));
    final evening = plan.firstWhere((n) => n.id.startsWith('prompt:evening:'));
    expect(morning.title, PromptSettings.hebrewMorningTitle);
    expect(evening.body, PromptSettings.hebrewEveningBody);
    // English stays English.
    expect(
      const PromptSettings().withPreferences(const Preferences()).morningTitle,
      'Good morning',
    );
  });

  test('quiet hours shift a reminder to their end', () {
    final prefs = utcPrefs.copyWith(quietHours: TimeRange.hm(0, 0, 7, 30));
    final plan = NotificationScheduler.plan(
      tasks: [
        task('night', remindAt: DateTime.utc(2026, 11, 4, 2, 15)),
        task('day', remindAt: DateTime.utc(2026, 11, 4, 9)),
      ],
      prefs: prefs,
      clock: clock,
      prompts: noPrompts,
    );
    expect(plan.map((n) => (n.taskId, n.fireAt)), [
      ('night', DateTime.utc(2026, 11, 4, 7, 30)),
      ('day', DateTime.utc(2026, 11, 4, 9)),
    ]);
  });

  test('quiet hours are read in the user zone', () {
    final prefs = const Preferences(
      timeZoneName: 'Asia/Jerusalem',
    ).copyWith(quietHours: TimeRange.hm(22, 0, 24, 0));
    final loc = tz.getLocation('Asia/Jerusalem');
    final at = tz.TZDateTime(loc, 2026, 11, 4, 23, 10).toUtc();
    final plan = NotificationScheduler.plan(
      tasks: [task('late', remindAt: at)],
      prefs: prefs,
      clock: clock,
      prompts: noPrompts,
    );
    expect(
      tz.TZDateTime.from(plan.single.fireAt, loc),
      tz.TZDateTime(loc, 2026, 11, 5),
    );
  });

  group('quiet hours across midnight (22:00-07:00)', () {
    final loc = () {
      ensureTimeZones();
      return tz.getLocation('Asia/Jerusalem');
    }();
    final prefs = const Preferences(timeZoneName: 'Asia/Jerusalem').copyWith(
      quietHours: const TimeRange.wrapping(
        startMinutes: 22 * 60,
        endMinutes: 7 * 60,
      ),
    );
    List<tz.TZDateTime> fire(List<tz.TZDateTime> at) => [
      for (final n in NotificationScheduler.plan(
        tasks: [
          for (final (i, t) in at.indexed) task('t$i', remindAt: t.toUtc()),
        ],
        prefs: prefs,
        clock: clock,
        prompts: noPrompts,
      ))
        tz.TZDateTime.from(n.fireAt, loc),
    ];

    test('23:30 moves to 07:00 the next day, not midnight', () {
      expect(fire([tz.TZDateTime(loc, 2026, 11, 4, 23, 30)]), [
        tz.TZDateTime(loc, 2026, 11, 5, 7),
      ]);
    });

    test('02:00 moves to 07:00 the same day', () {
      expect(fire([tz.TZDateTime(loc, 2026, 11, 5, 2)]), [
        tz.TZDateTime(loc, 2026, 11, 5, 7),
      ]);
    });

    test('times outside the range are kept (21:59, 07:00)', () {
      expect(
        fire([
          tz.TZDateTime(loc, 2026, 11, 4, 21, 59),
          tz.TZDateTime(loc, 2026, 11, 5, 7),
        ]),
        [
          tz.TZDateTime(loc, 2026, 11, 4, 21, 59),
          tz.TZDateTime(loc, 2026, 11, 5, 7),
        ],
      );
    });
  });

  group('DST in Asia/Jerusalem keeps 07:00 local', () {
    final loc = () {
      ensureTimeZones();
      return tz.getLocation('Asia/Jerusalem');
    }();
    const prefs = Preferences(timeZoneName: 'Asia/Jerusalem');
    const sevenAm = PromptSettings(
      morningMinutes: 7 * 60,
      eveningEnabled: false,
    );

    void check(DateTime start, DateTime before, DateTime after) {
      final plan = NotificationScheduler.plan(
        tasks: const [],
        prefs: prefs,
        clock: FixedClock(start),
        horizonDays: 4,
        prompts: sevenAm,
      );
      expect(plan, hasLength(4));
      for (final n in plan) {
        final l = tz.TZDateTime.from(n.fireAt, loc);
        expect((l.hour, l.minute), (7, 0), reason: n.id);
      }
      final offsets = plan
          .map((n) => tz.TZDateTime.from(n.fireAt, loc).timeZoneOffset)
          .toSet();
      expect(offsets, hasLength(2), reason: 'window must cross DST');
      expect(plan.map((n) => n.fireAt.hour).toSet(), {before.hour, after.hour});
    }

    test('autumn (25 Oct 2026, +3 -> +2)', () {
      check(
        DateTime.utc(2026, 10, 23, 12),
        DateTime.utc(2026, 10, 24, 4),
        DateTime.utc(2026, 10, 25, 5),
      );
    });

    test('spring (27 Mar 2026, +2 -> +3)', () {
      check(
        DateTime.utc(2026, 3, 25, 12),
        DateTime.utc(2026, 3, 26, 5),
        DateTime.utc(2026, 3, 27, 4),
      );
    });

    test('a task reminder at 07:00 on the transition day', () {
      final at = tz.TZDateTime(loc, 2026, 10, 25, 7).toUtc();
      expect(at, DateTime.utc(2026, 10, 25, 5));
      final plan = NotificationScheduler.plan(
        tasks: [task('run', remindAt: at, firstAction: 'lace up')],
        prefs: prefs,
        clock: FixedClock(DateTime.utc(2026, 10, 24)),
        prompts: const PromptSettings(
          morningEnabled: false,
          eveningEnabled: false,
        ),
      );
      // The if-then part; an encouraging line follows (#9).
      expect(plan.single.body, startsWith('07:00 — lace up. '));
    });
  });

  test('copy: if-then body with a first action, title otherwise', () {
    final plan = NotificationScheduler.plan(
      tasks: [
        task(
          'a',
          title: 'Thesis',
          firstAction: 'open the thesis file',
          remindAt: DateTime.utc(2026, 11, 3, 7),
        ),
        task('b', title: 'Call mum', remindAt: DateTime.utc(2026, 11, 3, 8)),
      ],
      prefs: utcPrefs,
      clock: clock,
      prompts: noPrompts,
    );
    // Since #9 every body ends with a line from ReminderCopy's pool.
    expect(plan[0].title, 'Thesis');
    expect(plan[0].body, startsWith('07:00 — open the thesis file. '));
    expect(plan[1].title, 'Grind');
    expect(plan[1].body, startsWith('Call mum. '));
    expect(
      plan.every((n) => ReminderCopy.pool('en').any(n.body.endsWith)),
      isTrue,
    );
    final words = RegExp(
      r'\b(missed|failed|behind|overdue|again|lazy)\b',
      caseSensitive: false,
    );
    final all = NotificationScheduler.plan(
      tasks: const [],
      prefs: utcPrefs,
      clock: clock,
    );
    for (final n in [...plan, ...all]) {
      expect(words.hasMatch('${n.title} ${n.body}'), isFalse);
    }
  });

  test('extra notifications are merged, windowed and deduplicated', () {
    final extra = [
      ScheduledNotification(
        id: 'rec:x:1',
        taskId: 'x',
        fireAt: now.add(const Duration(hours: 2)),
        title: 'Gym',
        body: 'Gym',
      ),
      ScheduledNotification(
        id: 'rec:x:1',
        taskId: 'x',
        fireAt: now.add(const Duration(hours: 3)),
        title: 'dup',
        body: 'dup',
      ),
      ScheduledNotification(
        id: 'rec:x:far',
        taskId: 'x',
        fireAt: now.add(const Duration(days: 9)),
        title: 'far',
        body: 'far',
      ),
    ];
    final plan = NotificationScheduler.plan(
      tasks: const [],
      prefs: utcPrefs,
      clock: clock,
      prompts: noPrompts,
      extra: extra,
    );
    expect(plan.map((n) => n.title), ['Gym']);
  });

  group('smart snooze (#12)', () {
    List<ScheduledNotification> planFor(int snoozes) =>
        NotificationScheduler.plan(
          tasks: [
            task(
              's',
              title: 'Thesis',
              firstAction: 'open the thesis file',
              remindAt: now.add(const Duration(minutes: 15)),
            ).copyWith(snoozeCount: snoozes),
          ],
          prefs: utcPrefs,
          clock: clock,
          prompts: noPrompts,
        );

    test('0 and 1 snoozes: the normal reminder category', () {
      for (final n in [...planFor(0), ...planFor(1)]) {
        expect(n.actions, NotificationScheduler.reminderActions);
        expect(categoryFor(n.actions), grindReminderCategory);
        expect(n.body, startsWith('06:15 — open the thesis file. '));
      }
    });

    test('from the 2nd snooze: reschedule category and the move offer', () {
      for (final n in [...planFor(2), ...planFor(5)]) {
        expect(n.actions, NotificationScheduler.rescheduleActions);
        expect(categoryFor(n.actions), grindRescheduleCategory);
        expect(n.body, startsWith('Want to move this instead?'));
        expect(n.body, contains('Thesis'));
        expect(
          RegExp(
            r'\b(again|snoozed?)\b',
            caseSensitive: false,
          ).hasMatch('${n.title} ${n.body}'),
          isFalse,
        );
      }
      // Same id as before: a re-plan replaces the request in place.
      expect(planFor(2).single.id, planFor(0).single.id);
    });

    test('prompts keep no category', () {
      expect(categoryFor(const []), isNull);
    });
  });

  group('reminder time and lead time', () {
    final due = now.add(const Duration(hours: 5));
    Task dueTask({DateTime? remindAt, DateTime? dueAt}) => Task(
      id: 'd',
      title: 'Essay',
      remindAt: remindAt,
      dueAt: dueAt,
      createdAt: epoch,
      updatedAt: epoch,
    );

    test('remindAt wins over the due time', () {
      final at = now.add(const Duration(hours: 1));
      expect(
        NotificationScheduler.reminderTimeFor(
          dueTask(remindAt: at, dueAt: due),
          utcPrefs.copyWith(defaultReminderLeadMinutes: 30),
        ),
        at,
      );
    });

    test('a due time without remindAt fires lead minutes before', () {
      final prefs = utcPrefs.copyWith(defaultReminderLeadMinutes: 30);
      final plan = NotificationScheduler.plan(
        tasks: [dueTask(dueAt: due)],
        prefs: prefs,
        clock: clock,
        prompts: noPrompts,
      );
      expect(plan.single.fireAt, due.subtract(const Duration(minutes: 30)));
    });

    test('a date-only due (end of day or midnight) gets no reminder', () {
      for (final d in [
        DateTime.utc(2026, 11, 4, 23, 59, 59),
        DateTime.utc(2026, 11, 4),
      ]) {
        expect(
          NotificationScheduler.reminderTimeFor(dueTask(dueAt: d), utcPrefs),
          isNull,
        );
      }
    });
  });
}
