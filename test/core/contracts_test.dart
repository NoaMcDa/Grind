import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';

void main() {
  final now = DateTime.utc(2026, 11, 3, 8);
  Task task(String id, {DateTime? remindAt}) => Task(
    id: id,
    title: 'T$id',
    remindAt: remindAt,
    createdAt: now,
    updatedAt: now,
  );

  group('InMemoryTaskRepository', () {
    test('upsert, get, soft delete', () async {
      final repo = InMemoryTaskRepository();
      await repo.upsert(task('a'));
      expect((await repo.getAll()).length, 1);
      await repo.delete('a');
      expect(await repo.getAll(), isEmpty);
      expect(await repo.getById('a'), isNull);
    });

    test('getDueBetween filters by remindAt and open status', () async {
      final repo = InMemoryTaskRepository([
        task('in', remindAt: now.add(const Duration(hours: 1))),
        task('out', remindAt: now.add(const Duration(days: 9))),
        task(
          'done',
          remindAt: now.add(const Duration(hours: 2)),
        ).copyWith(status: TaskStatus.done),
      ]);
      final due = await repo.getDueBetween(
        now,
        now.add(const Duration(days: 7)),
      );
      expect(due.map((t) => t.id), ['in']);
    });

    test('watchAll emits current value then changes', () async {
      final repo = InMemoryTaskRepository();
      final emissions = <int>[];
      final sub = repo.watchAll().listen((l) => emissions.add(l.length));
      await Future<void>.delayed(Duration.zero);
      await repo.upsert(task('a'));
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(emissions, [0, 1]);
    });
  });

  test('Task.copyWith can clear nullable fields', () {
    final t = task('a', remindAt: now).copyWith(remindAt: null);
    expect(t.remindAt, isNull);
  });

  test('Preferences defaults describe a working week', () {
    const p = Preferences();
    expect(p.workingHours.containsKey(DateTime.saturday), isFalse);
    expect(p.deepWindows.single.durationMinutes, 180);
  });

  test('contracts v2 fields round-trip through copyWith', () {
    final t = task('a').copyWith(notBefore: now, minutesDone: 20);
    expect(t.notBefore, now);
    expect(t.minutesDone, 20);
    expect(t.copyWith(notBefore: null).notBefore, isNull);
    const p = Preferences();
    expect(p.morningPromptMinutes, 8 * 60);
    final off = p.copyWith(morningPromptMinutes: null);
    expect(off.morningPromptMinutes, isNull);
    final sel = p.copyWith(
      selectedCalendarIds: {
        CalendarSource.google: ['a', 'b'],
      },
    );
    expect(sel.selectedCalendarIds[CalendarSource.google], ['a', 'b']);
    expect(p.backupHintShown, isFalse);
  });

  group('contracts v3', () {
    test('ReminderRule.lastCompletedAt and CalendarEvent.htmlLink', () {
      final r = ReminderRule(
        id: 'r',
        taskId: 't',
        rrule: 'FREQ=DAILY',
        createdAt: now,
        updatedAt: now,
      );
      expect(r.lastCompletedAt, isNull);
      final done = r.copyWith(lastCompletedAt: now);
      expect(done.lastCompletedAt, now);
      expect(done.copyWith(lastCompletedAt: null).lastCompletedAt, isNull);
      expect(done.copyWith(rrule: 'FREQ=WEEKLY').lastCompletedAt, now);

      final e = CalendarEvent(
        id: 'e',
        source: CalendarSource.google,
        externalId: 'x',
        title: 'E',
        start: now,
        end: now.add(const Duration(hours: 1)),
        htmlLink: 'https://calendar.example/e',
        createdAt: now,
        updatedAt: now,
      );
      expect(e.copyWith(title: 'F').htmlLink, 'https://calendar.example/e');
      expect(e.copyWith(htmlLink: null).htmlLink, isNull);
    });

    test('FocusSession defaults and copyWith', () {
      final s = FocusSession(
        id: 's',
        plannedMinutes: 25,
        startedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      expect(
        (s.pausedMs, s.pausedAt, s.win, s.kind, s.deletedAt, s.isPaused),
        (0, null, null, FocusSessionKind.focus, null, false),
      );
      final paused = s.copyWith(pausedAt: now, pausedMs: 1500, win: 'w');
      expect(paused.isPaused, isTrue);
      expect(paused.paused, const Duration(milliseconds: 1500));
      final ended = paused.copyWith(
        pausedAt: null,
        endedAt: now.add(const Duration(minutes: 30)),
        kind: FocusSessionKind.breakTime,
        deletedAt: now,
      );
      expect(ended.isPaused, isFalse);
      expect(ended.win, 'w');
      expect(ended.kind, FocusSessionKind.breakTime);
      expect(ended.deletedAt, now);
      expect(ended.actualMinutes, 30);
      expect(ended.copyWith(win: null, taskId: 't').win, isNull);
    });

    test('Goal v3 fields default and copy', () {
      final g = Goal(id: 'g', title: 'G', createdAt: now, updatedAt: now);
      expect(g.status, GoalStatus.active);
      expect(g.targetDate, isNull);
      expect(g.metricKind, isNull);
      final m = g.copyWith(
        targetDate: now,
        status: GoalStatus.paused,
        notes: 'n',
        metricKind: 'finite',
        metricTarget: 12,
        metricUnit: 'lessons',
        metricCurrent: 3,
        metricSource: 'manual',
        metricPeriod: 'week',
      );
      expect(
        (m.status, m.notes, m.metricTarget, m.metricUnit, m.metricPeriod),
        (GoalStatus.paused, 'n', 12, 'lessons', 'week'),
      );
      final cleared = m.copyWith(metricKind: null, targetDate: null);
      expect(cleared.metricKind, isNull);
      expect(cleared.targetDate, isNull);
      expect(cleared.metricTarget, 12);
    });

    test('Preferences.pipAccessory defaults to scarf', () {
      const p = Preferences();
      expect(p.pipAccessory, 'scarf');
      expect(p.copyWith(pipAccessory: 'beanie').pipAccessory, 'beanie');
      expect(
        p
            .copyWith(pipAccessory: 'beanie')
            .copyWith(localeCode: 'he')
            .pipAccessory,
        'beanie',
      );
    });
  });

  group('TimeRange', () {
    test('a plain range does not wrap', () {
      final r = TimeRange.hm(9, 0, 12, 0);
      expect(r.wrapsMidnight, isFalse);
      expect(r.durationMinutes, 180);
      expect(r.contains(9 * 60), isTrue);
      expect(r.contains(12 * 60), isFalse, reason: 'end is exclusive');
      expect(r.contains(8 * 60 + 59), isFalse);
    });

    test('22:00-07:00 wraps midnight', () {
      const r = TimeRange.wrapping(startMinutes: 22 * 60, endMinutes: 7 * 60);
      expect(r.wrapsMidnight, isTrue);
      expect(r.durationMinutes, 9 * 60);
      expect(r.contains(23 * 60 + 30), isTrue);
      expect(r.contains(0), isTrue);
      expect(r.contains(6 * 60 + 59), isTrue);
      expect(r.contains(7 * 60), isFalse);
      expect(r.contains(21 * 60 + 59), isFalse);
    });

    test('wrapping with end > start is a plain range', () {
      const r = TimeRange.wrapping(startMinutes: 22 * 60, endMinutes: 24 * 60);
      expect(r.wrapsMidnight, isFalse);
      expect(r, TimeRange.hm(22, 0, 24, 0));
    });

    test('fromJson validates without asserts', () {
      expect(
        TimeRange.fromJson({'start': 540, 'end': 600}),
        TimeRange.hm(9, 0, 10, 0),
      );
      for (final bad in [
        {'start': 600, 'end': 540},
        {'start': 600, 'end': 600},
        {'start': -1, 'end': 60},
        {'start': 0, 'end': 1441},
        {'start': '9', 'end': 600},
        <String, Object?>{},
      ]) {
        expect(
          () => TimeRange.fromJson(bad),
          throwsFormatException,
          reason: '$bad',
        );
      }
      final wrap = TimeRange.fromJson({
        'start': 1320,
        'end': 420,
      }, allowWrap: true);
      expect(wrap.wrapsMidnight, isTrue);
      expect(
        () => TimeRange.fromJson({'start': 600, 'end': 600}, allowWrap: true),
        throwsFormatException,
      );
    });
  });

  test('FixedClock advances', () {
    final c = FixedClock(now);
    c.advance(const Duration(hours: 1));
    expect(c.now(), now.add(const Duration(hours: 1)));
  });

  test('FakeCalendarProvider round trip', () async {
    final p = FakeCalendarProvider(CalendarSource.google);
    expect(await p.isConnected(), isFalse);
    await p.connect();
    expect((await p.listCalendars()).single.isPrimary, isTrue);
  });
}
