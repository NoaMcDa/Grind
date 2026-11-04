import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/domain/energy.dart';
import 'package:grind/features/assistant/assistant.dart';

void main() {
  // Wed 2026-11-04 09:00 local — "today" in every test.
  final now = DateTime(2026, 11, 4, 9);

  group('TaskDraftPreview — English', () {
    test('title only', () {
      const d = TaskDraft(title: 'Call Mom');
      expect(TaskDraftPreview.format(d, now: now), 'Call Mom');
    });

    test('tomorrow + time + duration + energy', () {
      const d = TaskDraft(
        title: 'Gym',
        date: '2026-11-05',
        time: '07:00',
        durationMinutes: 45,
        energy: Energy.light,
      );
      expect(
        TaskDraftPreview.format(d, now: now),
        'Gym · Tomorrow 07:00 · 45 min · light',
      );
    });

    test('today when draft date matches now', () {
      const d = TaskDraft(title: 'Standup', date: '2026-11-04', time: '10:30');
      expect(
        TaskDraftPreview.format(d, now: now),
        'Standup · Today 10:30',
      );
    });

    test('yesterday when draft date is day before', () {
      const d = TaskDraft(title: 'Recap', date: '2026-11-03');
      expect(TaskDraftPreview.format(d, now: now), 'Recap · Yesterday');
    });

    test('weekday name for a date within the coming week', () {
      // 2026-11-04 is Wed. 2026-11-08 is next Sunday (delta = 4).
      const d = TaskDraft(title: 'Brunch', date: '2026-11-08', time: '11:00');
      expect(
        TaskDraftPreview.format(d, now: now),
        'Brunch · Sunday 11:00',
      );
    });

    test('short absolute date for a far-future date', () {
      const d = TaskDraft(title: 'Launch', date: '2027-03-15');
      expect(TaskDraftPreview.format(d, now: now), 'Launch · Mar 15');
    });

    test('duration formatted with hours and minutes', () {
      const a = TaskDraft(title: 'Read', durationMinutes: 60);
      expect(TaskDraftPreview.format(a, now: now), 'Read · 1h');
      const b = TaskDraft(title: 'Read', durationMinutes: 90);
      expect(TaskDraftPreview.format(b, now: now), 'Read · 1h 30 min');
      const c = TaskDraft(title: 'Read', durationMinutes: 120);
      expect(TaskDraftPreview.format(c, now: now), 'Read · 2h');
    });

    test('recurrence preset shown when present', () {
      const d = TaskDraft(
        title: 'Standup',
        time: '09:00',
        recurrenceRrule: 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR',
      );
      expect(
        TaskDraftPreview.format(d, now: now),
        'Standup · 09:00 · weekdays',
      );
    });

    test('daily and monthly recurrences', () {
      const daily = TaskDraft(title: 'Vitamins', recurrenceRrule: 'FREQ=DAILY');
      expect(TaskDraftPreview.format(daily, now: now), 'Vitamins · daily');
      const monthly = TaskDraft(
        title: 'Rent',
        recurrenceRrule: 'FREQ=MONTHLY;BYMONTHDAY=1',
      );
      expect(TaskDraftPreview.format(monthly, now: now), 'Rent · monthly');
    });

    test('malformed rrule is silently dropped', () {
      const d = TaskDraft(title: 'Bad', recurrenceRrule: 'FREQ=NOPE');
      expect(TaskDraftPreview.format(d, now: now), 'Bad');
    });

    test('malformed date and time are silently dropped', () {
      const d = TaskDraft(title: 'x', date: 'not-a-date', time: '99:99');
      expect(TaskDraftPreview.format(d, now: now), 'x');
    });

    test('energy only, no date or time', () {
      const d = TaskDraft(title: 'Thesis', energy: Energy.deep);
      expect(TaskDraftPreview.format(d, now: now), 'Thesis · deep');
    });
  });

  group('TaskDraftPreview — Hebrew', () {
    test('tomorrow + time + duration + energy', () {
      const d = TaskDraft(
        title: 'חדר כושר',
        date: '2026-11-05',
        time: '07:00',
        durationMinutes: 45,
        energy: Energy.light,
      );
      expect(
        TaskDraftPreview.format(d, now: now, locale: 'he'),
        'חדר כושר · מחר 07:00 · 45 דק׳ · קל',
      );
    });

    test('today', () {
      const d = TaskDraft(title: 'דייל סטנדאפ', date: '2026-11-04');
      expect(
        TaskDraftPreview.format(d, now: now, locale: 'he'),
        'דייל סטנדאפ · היום',
      );
    });

    test('weekday name for a date in the coming week', () {
      // 2026-11-08 is Sunday.
      const d = TaskDraft(title: 'ארוחה', date: '2026-11-08', time: '11:00');
      expect(
        TaskDraftPreview.format(d, now: now, locale: 'he'),
        'ארוחה · יום ראשון 11:00',
      );
    });

    test('hour phrasing: one, two, many', () {
      const a = TaskDraft(title: 'לקרוא', durationMinutes: 60);
      expect(
        TaskDraftPreview.format(a, now: now, locale: 'he'),
        'לקרוא · שעה',
      );
      const b = TaskDraft(title: 'לקרוא', durationMinutes: 120);
      expect(
        TaskDraftPreview.format(b, now: now, locale: 'he'),
        'לקרוא · שעתיים',
      );
      const c = TaskDraft(title: 'לקרוא', durationMinutes: 180);
      expect(
        TaskDraftPreview.format(c, now: now, locale: 'he'),
        'לקרוא · 3 שעות',
      );
    });

    test('recurrence preset shown in Hebrew', () {
      const d = TaskDraft(
        title: 'סטנדאפ',
        recurrenceRrule: 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR',
      );
      expect(
        TaskDraftPreview.format(d, now: now, locale: 'he'),
        'סטנדאפ · ימי חול',
      );
    });

    test('unknown locale falls back to EN', () {
      const d = TaskDraft(title: 'Ping', date: '2026-11-05');
      expect(
        TaskDraftPreview.format(d, now: now, locale: 'fr'),
        'Ping · Tomorrow',
      );
    });
  });
}
