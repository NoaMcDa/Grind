import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/domain/energy.dart';
import 'package:grind/core/domain/task.dart';
import 'package:grind/core/notifications/time_zones.dart';
import 'package:grind/features/assistant/assistant.dart';
import 'package:grind/features/recurrence/recurrence.dart';
import 'package:grind/features/tasks/day_bounds.dart' show fromZoneWall;
import 'package:timezone/timezone.dart' as tz;

void main() {
  // A fixed zone with no DST so the test's wall-clock conversion is stable
  // on any CI machine. Asia/Jerusalem is the app's default, and the test
  // dates sit outside the DST switch (Nov).
  late tz.Location loc;
  setUpAll(() {
    ensureTimeZones();
    loc = tz.getLocation('Asia/Jerusalem');
  });

  final now = DateTime.utc(2026, 11, 4, 7, 0);
  const resolver = TaskDraftResolver();

  group('TaskDraftResolver', () {
    test('date + time → scheduledStart/End in zone, locked, remindAt', () {
      const draft = TaskDraft(
        title: 'Gym',
        date: '2026-11-05',
        time: '07:00',
        durationMinutes: 45,
        energy: Energy.light,
        firstAction: 'pack your bag',
      );
      final r = resolver.resolve(draft, location: loc, now: now, id: 't1');
      // 07:00 Asia/Jerusalem on 2026-11-05 is 05:00 UTC (IST +02:00).
      expect(r.task.scheduledStart, DateTime.utc(2026, 11, 5, 5));
      expect(r.task.scheduledEnd, DateTime.utc(2026, 11, 5, 5, 45));
      expect(r.task.remindAt, r.task.scheduledStart);
      expect(r.task.lockedStart, isTrue);
      expect(r.task.estimatedMinutes, 45);
      expect(r.task.energy, Energy.light);
      expect(r.task.firstAction, 'pack your bag');
      expect(r.task.id, 't1');
      // dueAt is end-of-day in the zone: 2026-11-05 23:59 local → 21:59 UTC.
      expect(r.task.dueAt, DateTime.utc(2026, 11, 5, 21, 59));
      expect(r.recurrence, isNull);
    });

    test('date only → dueAt at end-of-day, no scheduledStart', () {
      const draft = TaskDraft(title: 'Call Mom', date: '2026-11-06');
      final r = resolver.resolve(draft, location: loc, now: now, id: 't2');
      expect(r.task.scheduledStart, isNull);
      expect(r.task.scheduledEnd, isNull);
      expect(r.task.remindAt, isNull);
      expect(r.task.lockedStart, isFalse);
      expect(r.task.dueAt, DateTime.utc(2026, 11, 6, 21, 59));
      // No draft duration → the class default.
      expect(r.task.estimatedMinutes, 30);
      expect(r.task.energy, Energy.light);
    });

    test('no date, no time → backlog task with defaults', () {
      const draft = TaskDraft(title: 'Read book');
      final r = resolver.resolve(draft, location: loc, now: now, id: 't3');
      expect(r.task.scheduledStart, isNull);
      expect(r.task.scheduledEnd, isNull);
      expect(r.task.dueAt, isNull);
      expect(r.task.remindAt, isNull);
      expect(r.task.lockedStart, isFalse);
      expect(r.task.estimatedMinutes, 30);
      expect(r.task.energy, Energy.light);
    });

    test('draft duration overrides default; energy flows through', () {
      const draft = TaskDraft(
        title: 'Thesis chapter 2',
        date: '2026-11-07',
        time: '09:30',
        durationMinutes: 90,
        energy: Energy.deep,
      );
      final r = resolver.resolve(draft, location: loc, now: now, id: 't4');
      expect(r.task.estimatedMinutes, 90);
      expect(r.task.energy, Energy.deep);
      expect(
        r.task.scheduledEnd!.difference(r.task.scheduledStart!),
        const Duration(minutes: 90),
      );
    });

    test('scheduledStart/End and remindAt are plain UTC DateTimes', () {
      const draft = TaskDraft(
        title: 'Run',
        date: '2026-11-05',
        time: '06:00',
        durationMinutes: 30,
      );
      final r = resolver.resolve(draft, location: loc, now: now, id: 't5');
      expect(r.task.scheduledStart!.isUtc, isTrue);
      expect(r.task.scheduledEnd!.isUtc, isTrue);
      expect(r.task.remindAt!.isUtc, isTrue);
      expect(r.task.dueAt!.isUtc, isTrue);
      expect(r.task.createdAt.isUtc, isTrue);
      expect(r.task.updatedAt.isUtc, isTrue);
    });

    test('recurring draft with date+time keeps scheduledStart as anchor', () {
      const draft = TaskDraft(
        title: 'Standup',
        date: '2026-11-05',
        time: '09:00',
        durationMinutes: 15,
        recurrenceRrule: 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR',
      );
      final r = resolver.resolve(draft, location: loc, now: now, id: 't6');
      expect(r.task.remindAt, isNotNull);
      expect(r.task.remindAt, r.task.scheduledStart);
      expect(r.recurrence, isNotNull);
      expect(r.recurrence!.preset, RecurrencePreset.weekdays);
    });

    test('recurring draft without a time seeds remindAt at midnight', () {
      const draft = TaskDraft(title: 'Vitamins', recurrenceRrule: 'FREQ=DAILY');
      final r = resolver.resolve(draft, location: loc, now: now, id: 't7');
      expect(r.recurrence, isNotNull);
      expect(r.recurrence!.preset, RecurrencePreset.daily);
      // Without a draft date, the anchor is today in the zone: 2026-11-04
      // 00:00 Asia/Jerusalem = 2026-11-03 22:00 UTC.
      expect(r.task.remindAt, DateTime.utc(2026, 11, 3, 22));
      expect(r.task.scheduledStart, isNull);
    });

    test('unparseable RRULE drops to null, task still resolves', () {
      const draft = TaskDraft(
        title: 'Bad',
        date: '2026-11-05',
        recurrenceRrule: 'FREQ=NOPE',
      );
      final r = resolver.resolve(draft, location: loc, now: now, id: 't8');
      expect(r.recurrence, isNull);
      expect(r.task.title, 'Bad');
    });

    test('malformed draft date is ignored, the task still resolves', () {
      const draft = TaskDraft(title: 'Bad date', date: 'not-a-date');
      final r = resolver.resolve(draft, location: loc, now: now, id: 't9');
      expect(r.task.scheduledStart, isNull);
      expect(r.task.dueAt, isNull);
    });

    test('malformed draft time with a valid date → dueAt only', () {
      const draft = TaskDraft(
        title: 'Bad time',
        date: '2026-11-05',
        time: 'bogus',
      );
      final r = resolver.resolve(draft, location: loc, now: now, id: 't10');
      expect(r.task.scheduledStart, isNull);
      expect(r.task.dueAt, DateTime.utc(2026, 11, 5, 21, 59));
    });

    test('createdAt/updatedAt track the given now', () {
      const draft = TaskDraft(title: 'Now check');
      final r = resolver.resolve(draft, location: loc, now: now, id: 't11');
      expect(r.task.createdAt, now);
      expect(r.task.updatedAt, now);
    });

    test('non-UTC now is stored as UTC', () {
      final localNow = DateTime(2026, 11, 4, 9);
      const draft = TaskDraft(title: 'Local now');
      final r = resolver.resolve(
        draft,
        location: loc,
        now: localNow,
        id: 't12',
      );
      expect(r.task.createdAt.isUtc, isTrue);
      expect(r.task.createdAt, localNow.toUtc());
    });

    test('UTC zone matches the raw date+time (round-trip sanity)', () {
      const draft = TaskDraft(
        title: 'UTC gym',
        date: '2026-11-05',
        time: '07:00',
        durationMinutes: 30,
      );
      final r = resolver.resolve(draft, location: tz.UTC, now: now, id: 't13');
      expect(r.task.scheduledStart, DateTime.utc(2026, 11, 5, 7));
      expect(r.task.scheduledEnd, DateTime.utc(2026, 11, 5, 7, 30));
      expect(
        r.task.scheduledStart,
        fromZoneWall(DateTime(2026, 11, 5, 7), tz.UTC),
      );
    });

    test('custom defaults flow when the draft is silent', () {
      const resolverA = TaskDraftResolver(
        defaultDurationMinutes: 25,
        defaultEnergy: Energy.deep,
      );
      const draft = TaskDraft(title: 'Pomodoro');
      final r = resolverA.resolve(draft, location: loc, now: now, id: 't14');
      expect(r.task.estimatedMinutes, 25);
      expect(r.task.energy, Energy.deep);
    });

    test('ResolvedTaskDraft holds the passed id', () {
      const draft = TaskDraft(title: 'Id check');
      final r = resolver.resolve(
        draft,
        location: loc,
        now: now,
        id: 'the-specific-uuid',
      );
      expect(r.task.id, 'the-specific-uuid');
    });

    test('status is open and minutesDone is 0 for a fresh draft', () {
      const draft = TaskDraft(title: 'Fresh');
      final r = resolver.resolve(draft, location: loc, now: now, id: 't15');
      expect(r.task.status, TaskStatus.open);
      expect(r.task.minutesDone, 0);
      expect(r.task.completedAt, isNull);
    });
  });
}
