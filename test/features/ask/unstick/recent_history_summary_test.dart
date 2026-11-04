import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/ask/unstick/recent_history_summary.dart';
import 'package:grind/features/ask/unstick/unstick_request.dart';

void main() {
  final anchor = DateTime(2026, 11, 4, 9, 0);

  RecentEvent event(RecentEventKind kind, String title, {int addMinutes = 0}) =>
      RecentEvent(
        kind: kind,
        taskTitle: title,
        when: anchor.add(Duration(minutes: addMinutes)),
      );

  group('summarizeRecentHistory counts', () {
    test('empty list returns a zero summary', () {
      final s = summarizeRecentHistory(const []);

      expect(s.isEmpty, isTrue);
      expect(s.total, 0);
      expect(s.hasAnyProgress, isFalse);
      expect(s.hasDropStreak, isFalse);
      expect(s.trailingDropCount, 0);
      expect(s.lastDropTitle, isNull);
    });

    test('tallies each kind independently', () {
      final s = summarizeRecentHistory([
        event(RecentEventKind.completed, 'Morning routine'),
        event(RecentEventKind.completed, 'Email triage', addMinutes: 15),
        event(RecentEventKind.skipped, 'Yesterday write-up', addMinutes: 60),
        event(RecentEventKind.missed, 'Reading', addMinutes: 120),
        event(RecentEventKind.started, 'Focus block A', addMinutes: 180),
        event(RecentEventKind.rescheduled, 'Dentist prep', addMinutes: 200),
      ]);

      expect(s.completed, 2);
      expect(s.skipped, 1);
      expect(s.missed, 1);
      expect(s.started, 1);
      expect(s.rescheduled, 1);
      expect(s.total, 6);
      expect(s.isEmpty, isFalse);
    });
  });

  group('trailing drop streak', () {
    test('counts the tail run of skipped and missed events', () {
      final s = summarizeRecentHistory([
        event(RecentEventKind.completed, 'Morning routine'),
        event(RecentEventKind.skipped, 'Write-up', addMinutes: 60),
        event(RecentEventKind.missed, 'Reading', addMinutes: 120),
      ]);

      expect(s.trailingDropCount, 2);
      expect(s.hasDropStreak, isTrue);
      // lastDropTitle is the most recent drop (walking from the tail).
      expect(s.lastDropTitle, 'Reading');
    });

    test('a non-drop tail resets the streak to zero', () {
      final s = summarizeRecentHistory([
        event(RecentEventKind.skipped, 'Write-up'),
        event(RecentEventKind.missed, 'Reading', addMinutes: 30),
        event(RecentEventKind.completed, 'Email triage', addMinutes: 60),
      ]);

      expect(s.trailingDropCount, 0);
      expect(s.hasDropStreak, isFalse);
      expect(s.lastDropTitle, isNull);
    });

    test('rescheduled breaks the streak even when it is the last event', () {
      final s = summarizeRecentHistory([
        event(RecentEventKind.skipped, 'Write-up'),
        event(RecentEventKind.missed, 'Reading', addMinutes: 30),
        event(RecentEventKind.rescheduled, 'Dentist prep', addMinutes: 60),
      ]);

      expect(s.trailingDropCount, 0);
      expect(s.hasDropStreak, isFalse);
    });

    test('a single trailing drop is not yet a streak', () {
      final s = summarizeRecentHistory([
        event(RecentEventKind.completed, 'Morning routine'),
        event(RecentEventKind.skipped, 'Write-up', addMinutes: 30),
      ]);

      expect(s.trailingDropCount, 1);
      expect(s.hasDropStreak, isFalse);
      expect(s.lastDropTitle, 'Write-up');
    });
  });

  group('hasAnyProgress', () {
    test('true when at least one task was completed', () {
      final s = summarizeRecentHistory([
        event(RecentEventKind.completed, 'Morning routine'),
        event(RecentEventKind.skipped, 'Write-up', addMinutes: 30),
      ]);

      expect(s.hasAnyProgress, isTrue);
    });

    test('false when nothing was completed, even if tasks started', () {
      final s = summarizeRecentHistory([
        event(RecentEventKind.started, 'Focus block A'),
        event(RecentEventKind.skipped, 'Write-up', addMinutes: 30),
      ]);

      expect(s.hasAnyProgress, isFalse);
    });
  });

  group('equality', () {
    test('same inputs produce equal summaries', () {
      final events = [
        event(RecentEventKind.completed, 'Morning routine'),
        event(RecentEventKind.skipped, 'Write-up', addMinutes: 30),
        event(RecentEventKind.missed, 'Reading', addMinutes: 60),
      ];

      final a = summarizeRecentHistory(events);
      final b = summarizeRecentHistory(List.of(events));

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('different drop titles do not compare equal', () {
      final a = summarizeRecentHistory([
        event(RecentEventKind.skipped, 'A'),
        event(RecentEventKind.missed, 'B', addMinutes: 30),
      ]);
      final b = summarizeRecentHistory([
        event(RecentEventKind.skipped, 'A'),
        event(RecentEventKind.missed, 'C', addMinutes: 30),
      ]);

      expect(a == b, isFalse);
    });
  });

  group('recentHistoryHeadline (en)', () {
    test('empty summary returns an empty string', () {
      final headline = recentHistoryHeadline(summarizeRecentHistory(const []));
      expect(headline, isEmpty);
    });

    test('drop streak reads as "N tasks skipped in a row"', () {
      final s = summarizeRecentHistory([
        event(RecentEventKind.completed, 'Morning routine'),
        event(RecentEventKind.skipped, 'Write-up', addMinutes: 30),
        event(RecentEventKind.missed, 'Reading', addMinutes: 60),
      ]);

      expect(recentHistoryHeadline(s), '2 tasks skipped in a row.');
    });

    test('progress with no drop streak reads as "N done so far today"', () {
      final s = summarizeRecentHistory([
        event(RecentEventKind.completed, 'Morning routine'),
        event(RecentEventKind.completed, 'Email triage', addMinutes: 30),
      ]);

      expect(recentHistoryHeadline(s), '2 done so far today.');
    });

    test('non-drop, non-progress events read as "N moves so far today"', () {
      final s = summarizeRecentHistory([
        event(RecentEventKind.started, 'Focus block A'),
        event(RecentEventKind.rescheduled, 'Dentist prep', addMinutes: 30),
      ]);

      expect(recentHistoryHeadline(s), '2 moves so far today.');
    });

    test('isolated drops read as "N tasks slipped today"', () {
      final s = summarizeRecentHistory([
        event(RecentEventKind.skipped, 'Write-up'),
        event(RecentEventKind.completed, 'Email triage', addMinutes: 30),
      ]);

      // One skipped, one completed, tail is completed — hasAnyProgress wins.
      expect(recentHistoryHeadline(s), '1 done so far today.');
    });
  });

  group('recentHistoryHeadline (he)', () {
    test('drop streak localises to Hebrew', () {
      final s = summarizeRecentHistory([
        event(RecentEventKind.skipped, 'משימה א'),
        event(RecentEventKind.missed, 'משימה ב', addMinutes: 30),
      ]);

      expect(
        recentHistoryHeadline(s, localeCode: 'he'),
        '2 משימות ברצף לא התחילו.',
      );
    });

    test('progress localises to Hebrew', () {
      final s = summarizeRecentHistory([
        event(RecentEventKind.completed, 'Morning'),
      ]);

      expect(recentHistoryHeadline(s, localeCode: 'he'), '1 הושלמו היום.');
    });

    test('unknown locale falls back to English', () {
      final s = summarizeRecentHistory([
        event(RecentEventKind.completed, 'Morning'),
      ]);

      expect(recentHistoryHeadline(s, localeCode: 'fr'), '1 done so far today.');
    });
  });
}
