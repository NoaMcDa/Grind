import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/notification_scheduler.dart';
import 'package:grind/features/recurrence/occurrence_completion.dart';
import 'package:grind/features/recurrence/occurrence_expander.dart';
import 'package:grind/features/recurrence/recurrence.dart';
import 'package:grind/features/recurrence/recurrence_notifications.dart';
import 'package:grind/features/recurrence/series_edit.dart';
import 'package:timezone/timezone.dart' as tz;

const zone = 'Asia/Jerusalem';

ReminderRule rule(
  String rrule, {
  int lead = 0,
  DateTime? until,
  String taskId = 't1',
}) => ReminderRule(
  id: 'r-$taskId',
  taskId: taskId,
  rrule: rrule,
  leadMinutes: lead,
  until: until,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

Task task(String id, DateTime remindAt, {String? firstAction}) => Task(
  id: id,
  title: 'Take meds',
  remindAt: remindAt,
  firstAction: firstAction,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

String hm(tz.TZDateTime t) =>
    '${t.year}-${t.month.toString().padLeft(2, '0')}-'
    '${t.day.toString().padLeft(2, '0')} '
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

void main() {
  ensureTimeZonesInitialized();
  final loc = tz.getLocation(zone);
  // Jerusalem wall clock (default 07:00) -> instant.
  DateTime at(int y, int m, int d, [int h = 7, int mi = 0]) =>
      tz.TZDateTime(loc, y, m, d, h, mi).toUtc();

  group('expandOccurrences', () {
    test('a window that ends before the anchor gives nothing', () {
      // Today's list asks for one day while the series already moved on to
      // next week (a completed occurrence); this used to trip an assertion
      // inside the rrule package.
      final out = expandOccurrences(
        rule: rule('FREQ=WEEKLY;BYDAY=TU'),
        anchor: at(2026, 11, 10),
        from: at(2026, 11, 3, 0),
        to: at(2026, 11, 4, 0),
        timeZoneName: zone,
      );
      expect(out, isEmpty);
    });

    test('Mon/Wed/Fri 07:00 stays 07:00 across the March DST change', () {
      // Israel springs forward Fri 27 Mar 2026 (02:00 -> 03:00).
      final out = expandOccurrences(
        rule: rule('FREQ=WEEKLY;BYDAY=MO,WE,FR'),
        anchor: at(2026, 3, 23),
        from: at(2026, 3, 23, 0),
        to: at(2026, 3, 31, 0),
        timeZoneName: zone,
      );
      expect(out.map(hm), [
        '2026-03-23 07:00',
        '2026-03-25 07:00',
        '2026-03-27 07:00',
        '2026-03-30 07:00',
      ]);
      // The UTC offset really changed between Wed and Fri.
      expect(out[1].toUtc().hour, 5);
      expect(out[2].toUtc().hour, 4);
    });

    test('Mon/Wed/Fri 07:00 stays 07:00 across the October DST change', () {
      // Israel falls back Sun 25 Oct 2026 (02:00 -> 01:00).
      final out = expandOccurrences(
        rule: rule('FREQ=WEEKLY;BYDAY=MO,WE,FR'),
        anchor: at(2026, 10, 19),
        from: at(2026, 10, 19, 0),
        to: at(2026, 10, 31, 0),
        timeZoneName: zone,
      );
      expect(out.map(hm), [
        '2026-10-19 07:00',
        '2026-10-21 07:00',
        '2026-10-23 07:00',
        '2026-10-26 07:00',
        '2026-10-28 07:00',
        '2026-10-30 07:00',
      ]);
      expect(out[2].toUtc().hour, 4);
      expect(out[3].toUtc().hour, 5);
    });

    test('monthly on the 31st skips short months', () {
      final out = expandOccurrences(
        rule: rule('FREQ=MONTHLY;BYMONTHDAY=31'),
        anchor: at(2026, 1, 31),
        from: at(2026, 1, 1, 0),
        to: at(2026, 8, 1, 0),
        timeZoneName: zone,
      );
      expect(out.map(hm), [
        '2026-01-31 07:00',
        '2026-03-31 07:00',
        '2026-05-31 07:00',
        '2026-07-31 07:00',
      ]);
    });

    test('interval and rule.until', () {
      final out = expandOccurrences(
        rule: rule('FREQ=DAILY;INTERVAL=3', until: at(2026, 4, 9, 23)),
        anchor: at(2026, 4, 1),
        from: at(2026, 3, 30, 0),
        to: at(2026, 4, 30, 0),
        timeZoneName: zone,
      );
      expect(out.map(hm), [
        '2026-04-01 07:00',
        '2026-04-04 07:00',
        '2026-04-07 07:00',
      ]);
    });

    test('RRULE UNTIL and COUNT', () {
      final until = Recurrence.daily(until: DateTime(2026, 4, 3)).toRRule();
      expect(
        expandOccurrences(
          rule: rule(until),
          anchor: at(2026, 4, 1),
          from: at(2026, 4, 1, 0),
          to: at(2026, 4, 30, 0),
          timeZoneName: zone,
        ),
        hasLength(3),
      );
      expect(
        expandOccurrences(
          rule: rule('FREQ=DAILY;COUNT=4'),
          anchor: at(2026, 4, 1),
          from: at(2026, 4, 1, 0),
          to: at(2026, 4, 30, 0),
          timeZoneName: zone,
        ),
        hasLength(4),
      );
    });

    test('lead minutes shift fire times', () {
      final out = expandOccurrences(
        rule: rule('FREQ=DAILY', lead: 60),
        anchor: at(2026, 4, 1),
        from: at(2026, 4, 1, 0),
        to: at(2026, 4, 3, 0),
        timeZoneName: zone,
      );
      expect(out.map(hm), ['2026-04-01 06:00', '2026-04-02 06:00']);
    });

    test('never emits outside [from, to)', () {
      for (final rrule in [
        'FREQ=DAILY',
        'FREQ=WEEKLY;BYDAY=MO,WE,FR',
        'FREQ=MONTHLY;BYMONTHDAY=31',
        'FREQ=WEEKLY;INTERVAL=2;BYDAY=SU',
      ]) {
        for (final lead in [0, 30, 600]) {
          for (var day = 0; day < 40; day += 7) {
            final from = at(2026, 3, 20, 5, 17).add(Duration(days: day));
            final to = from.add(const Duration(days: 9, hours: 3));
            final out = expandOccurrences(
              rule: rule(rrule, lead: lead),
              anchor: at(2026, 1, 5),
              from: from,
              to: to,
              timeZoneName: zone,
            );
            for (final t in out) {
              expect(t.toUtc().isBefore(from), isFalse, reason: rrule);
              expect(t.toUtc().isBefore(to), isTrue, reason: rrule);
            }
          }
        }
      }
    });

    test('exdate skips an occurrence', () {
      final text = RruleText.parse(
        'FREQ=DAILY',
      ).withExdate(tz.TZDateTime(loc, 2026, 4, 2, 7));
      final out = expandOccurrences(
        rule: rule(text.toString()),
        anchor: at(2026, 4, 1),
        from: at(2026, 4, 1, 0),
        to: at(2026, 4, 4, 0),
        timeZoneName: zone,
      );
      expect(out.map(hm), ['2026-04-01 07:00', '2026-04-03 07:00']);
    });
  });

  group('Recurrence', () {
    final presets = <Recurrence>[
      const Recurrence.daily(),
      const Recurrence.daily(interval: 2),
      const Recurrence.weekdays(),
      const Recurrence.weekly({1, 3, 5}),
      const Recurrence.weekly({7}, interval: 2),
      const Recurrence.monthly(15),
      const Recurrence.monthly(31, interval: 3),
      Recurrence.daily(until: DateTime(2026, 12, 31)),
      const Recurrence.weekly({2}, count: 6),
    ];

    test('round trips every preset', () {
      for (final r in presets) {
        final parsed = Recurrence.parse(r.toRRule());
        expect(parsed, r, reason: r.toRRule());
        expect(parsed.preset, r.preset);
        expect(parsed.until, r.until);
        expect(parsed.count, r.count);
      }
    });

    test('emits expected RRULE', () {
      expect(
        const Recurrence.weekly({5, 1, 3}).toRRule(),
        'FREQ=WEEKLY;BYDAY=MO,WE,FR',
      );
      expect(
        const Recurrence.weekdays().toRRule(),
        'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR',
      );
    });

    test('rejects unsupported rules', () {
      expect(
        () => Recurrence.parse('FREQ=YEARLY'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => Recurrence.parse('garbage'),
        throwsA(isA<FormatException>()),
      );
    });

    test('describe in English and Hebrew', () {
      const en = Locale('en');
      const he = Locale('he');
      expect(
        const Recurrence.weekly({1, 3, 5}).describe(en),
        'Every Mon, Wed, Fri',
      );
      expect(
        const Recurrence.weekly({1, 3, 5}).describe(he),
        'כל יום שני, רביעי ושישי',
      );
      expect(const Recurrence.daily().describe(en), 'Every day');
      expect(const Recurrence.weekdays().describe(en), 'Every weekday');
      expect(
        const Recurrence.monthly(22).describe(en),
        'Every month on the 22nd',
      );
      expect(const Recurrence.monthly(22).describe(he), 'כל חודש ב-22');
    });
  });

  group('extra notifications', () {
    final clock = FixedClock(at(2026, 3, 22, 12));
    const prefs = Preferences(timeZoneName: zone);

    test('stable ids, open tasks only, pending set under cap', () async {
      final tasks = <Task>[];
      final rules = <ReminderRule>[];
      for (var i = 0; i < 30; i++) {
        final t = task('t$i', at(2026, 3, 23, 7, i));
        tasks.add(t);
        rules.add(rule('FREQ=DAILY', taskId: t.id));
      }
      tasks.add(
        task('done', at(2026, 3, 23)).copyWith(status: TaskStatus.done),
      );
      rules.add(rule('FREQ=DAILY', taskId: 'done'));
      final extra = recurrenceExtraNotifications(
        InMemoryReminderRepository(rules),
        horizonDays: 7,
        clock: clock,
      );
      final a = await extra(tasks, prefs);
      final b = await extra(tasks, prefs);
      expect(a.map((n) => n.id), b.map((n) => n.id));
      expect(a.map((n) => n.id).toSet(), hasLength(a.length));
      expect(a.any((n) => n.taskId == 'done'), isFalse);
      expect(a.first.id, startsWith('task:'));

      final plan = NotificationScheduler.plan(
        tasks: tasks,
        prefs: prefs,
        clock: clock,
        extra: a,
      );
      expect(a.length, greaterThan(50));
      expect(plan.length, lessThanOrEqualTo(50));
    });

    test('copy mirrors the one-time reminder and applies lead', () async {
      final t = task('t', at(2026, 3, 23), firstAction: 'open the app');
      final out = await recurrenceExtraNotifications(
        InMemoryReminderRepository([rule('FREQ=DAILY', lead: 10, taskId: 't')]),
        horizonDays: 2,
        clock: clock,
      )([t], prefs);
      // Same builder as one-time reminders (NotificationScheduler.copyFor):
      // if-then body at the occurrence time plus an encouraging line.
      expect(out.first.title, isNotEmpty);
      expect(out.first.body, startsWith('07:00 — open the app.'));
      expect(out.first.fireAt, at(2026, 3, 23, 6, 50));
    });
  });

  group('series operations', () {
    final now = DateTime.utc(2026, 3, 22);

    test('completeOccurrence advances the series, not completes it', () {
      final next = completeOccurrence(
        task: task('t1', at(2026, 3, 23)),
        rule: rule('FREQ=DAILY'),
        occurrenceAt: at(2026, 3, 23),
        timeZoneName: zone,
        now: now,
      );
      expect(next.status, TaskStatus.open);
      // Stored as a plain UTC DateTime, not a TZDateTime.
      expect(next.remindAt!.isAtSameMomentAs(at(2026, 3, 24)), isTrue);
    });

    test('completing the last occurrence finishes the task', () {
      final done = completeOccurrence(
        task: task('t1', at(2026, 3, 23)),
        rule: rule('FREQ=DAILY;COUNT=1'),
        occurrenceAt: at(2026, 3, 23),
        timeZoneName: zone,
        now: now,
      );
      expect(done.status, TaskStatus.done);
    });

    test('editThisOccurrence detaches and excludes', () async {
      final tasks = InMemoryTaskRepository();
      final rules = InMemoryReminderRepository();
      final t = task('t1', at(2026, 3, 23));
      await tasks.upsert(t);
      await rules.upsert(rule('FREQ=DAILY'));
      final one = await editThisOccurrence(
        tasks: tasks,
        rules: rules,
        task: t,
        rule: rule('FREQ=DAILY'),
        occurrenceAt: at(2026, 3, 25),
        timeZoneName: zone,
        now: now,
        edit: (d) => d.copyWith(title: 'Only today'),
      );
      expect(one.title, 'Only today');
      expect(one.remindAt, at(2026, 3, 25));
      final stored = (await rules.getForTask('t1'))!;
      final fires = expandOccurrences(
        rule: stored,
        anchor: t.remindAt!,
        from: at(2026, 3, 23, 0),
        to: at(2026, 3, 27, 0),
        timeZoneName: zone,
      );
      expect(fires.map(hm), [
        '2026-03-23 07:00',
        '2026-03-24 07:00',
        '2026-03-26 07:00',
      ]);
      expect(await tasks.getById(one.id), isNotNull);
    });

    test('editAllFuture ends the old rule and starts a new one', () async {
      final tasks = InMemoryTaskRepository();
      final rules = InMemoryReminderRepository();
      final t = task('t1', at(2026, 3, 23));
      await tasks.upsert(t);
      await rules.upsert(rule('FREQ=DAILY'));
      final future = await editAllFuture(
        tasks: tasks,
        rules: rules,
        task: t,
        rule: rule('FREQ=DAILY'),
        occurrenceAt: at(2026, 3, 25),
        timeZoneName: zone,
        now: now,
        newRRule: 'FREQ=WEEKLY;BYDAY=WE',
        edit: (f) => f.copyWith(title: 'New plan'),
      );
      final oldRule = (await rules.getForTask('t1'))!;
      final oldFires = expandOccurrences(
        rule: oldRule,
        anchor: t.remindAt!,
        from: at(2026, 3, 23, 0),
        to: at(2026, 4, 10, 0),
        timeZoneName: zone,
      );
      expect(oldFires.map(hm), ['2026-03-23 07:00', '2026-03-24 07:00']);
      final newRule = (await rules.getForTask(future.id))!;
      expect(newRule.rrule, 'FREQ=WEEKLY;BYDAY=WE');
      expect(future.title, 'New plan');
      expect(future.remindAt, at(2026, 3, 25));
    });
  });
}
