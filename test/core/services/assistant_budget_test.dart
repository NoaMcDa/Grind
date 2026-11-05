import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';

void main() {
  group('AssistantDailyBudget', () {
    test('defaults carry the generous cap', () {
      expect(AssistantDailyBudget.defaults.maxCalls, 200);
      expect(AssistantDailyBudget.defaults.maxTokens, 200000);
    });

    test('unlimited means neither axis is metered', () {
      expect(AssistantDailyBudget.unlimited.maxCalls, isNull);
      expect(AssistantDailyBudget.unlimited.maxTokens, isNull);
    });

    test('is a value type', () {
      const a = AssistantDailyBudget(maxCalls: 10, maxTokens: 1000);
      const b = AssistantDailyBudget(maxCalls: 10, maxTokens: 1000);
      const c = AssistantDailyBudget(maxCalls: 10, maxTokens: 2000);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });
  });

  group('AssistantDailyUsage', () {
    test('empty constructor zeroes all counters at the given date', () {
      final usage = AssistantDailyUsage.empty(DateTime(2026, 11, 4));
      expect(usage.date, DateTime(2026, 11, 4));
      expect(usage.calls, 0);
      expect(usage.inputTokens, 0);
      expect(usage.outputTokens, 0);
      expect(usage.totalTokens, 0);
    });

    test('totalTokens sums input and output', () {
      final usage = AssistantDailyUsage(
        date: DateTime(2026, 11, 4),
        calls: 3,
        inputTokens: 100,
        outputTokens: 250,
      );
      expect(usage.totalTokens, 350);
    });

    test('is a value type', () {
      final a = AssistantDailyUsage(
        date: DateTime(2026, 11, 4),
        calls: 1,
        inputTokens: 10,
        outputTokens: 20,
      );
      final b = AssistantDailyUsage(
        date: DateTime(2026, 11, 4),
        calls: 1,
        inputTokens: 10,
        outputTokens: 20,
      );
      final c = AssistantDailyUsage(
        date: DateTime(2026, 11, 5),
        calls: 1,
        inputTokens: 10,
        outputTokens: 20,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });
  });

  group('AssistantBudgetTracker.usageFor', () {
    test('starts at zero on today for an unknown user', () {
      final clock = FixedClock(DateTime(2026, 11, 4, 9, 30));
      final tracker = AssistantBudgetTracker(clock: clock);
      final usage = tracker.usageFor('u1');
      expect(usage.date, DateTime(2026, 11, 4));
      expect(usage.calls, 0);
      expect(usage.inputTokens, 0);
      expect(usage.outputTokens, 0);
    });

    test('keeps counters separate per user', () {
      final clock = FixedClock(DateTime(2026, 11, 4, 9));
      final tracker = AssistantBudgetTracker(clock: clock);
      tracker.record('alice', inputTokens: 10, outputTokens: 20);
      tracker.record('bob', inputTokens: 5, outputTokens: 5);
      expect(tracker.usageFor('alice').totalTokens, 30);
      expect(tracker.usageFor('bob').totalTokens, 10);
    });
  });

  group('AssistantBudgetTracker.record', () {
    test('accumulates calls and tokens on today', () {
      final clock = FixedClock(DateTime(2026, 11, 4, 9));
      final tracker = AssistantBudgetTracker(clock: clock);
      tracker.record('u1', inputTokens: 100, outputTokens: 200);
      tracker.record('u1', inputTokens: 50, outputTokens: 50);
      final usage = tracker.usageFor('u1');
      expect(usage.calls, 2);
      expect(usage.inputTokens, 150);
      expect(usage.outputTokens, 250);
      expect(usage.totalTokens, 400);
    });

    test('returns the post-record snapshot', () {
      final clock = FixedClock(DateTime(2026, 11, 4, 9));
      final tracker = AssistantBudgetTracker(clock: clock);
      final result = tracker.record('u1', inputTokens: 5, outputTokens: 7);
      expect(result.calls, 1);
      expect(result.totalTokens, 12);
    });

    test('a record over the cap still counts (the call already ran)', () {
      final clock = FixedClock(DateTime(2026, 11, 4, 9));
      final tracker = AssistantBudgetTracker(
        clock: clock,
        budget: const AssistantDailyBudget(maxCalls: 1, maxTokens: 10),
      );
      tracker.record('u1', inputTokens: 8, outputTokens: 12);
      final usage = tracker.usageFor('u1');
      expect(usage.calls, 1);
      expect(usage.totalTokens, 20);
    });
  });

  group('AssistantBudgetTracker.canSpend', () {
    test('true when both caps have headroom', () {
      final clock = FixedClock(DateTime(2026, 11, 4, 9));
      final tracker = AssistantBudgetTracker(
        clock: clock,
        budget: const AssistantDailyBudget(maxCalls: 10, maxTokens: 1000),
      );
      tracker.record('u1', inputTokens: 100, outputTokens: 100);
      expect(tracker.canSpend('u1', tokens: 500, calls: 1), isTrue);
    });

    test('false when a spend would cross the call cap', () {
      final clock = FixedClock(DateTime(2026, 11, 4, 9));
      final tracker = AssistantBudgetTracker(
        clock: clock,
        budget: const AssistantDailyBudget(maxCalls: 2, maxTokens: 1000),
      );
      tracker.record('u1', inputTokens: 10, outputTokens: 10);
      tracker.record('u1', inputTokens: 10, outputTokens: 10);
      expect(tracker.canSpend('u1', tokens: 10), isFalse);
    });

    test('false when a spend would cross the token cap', () {
      final clock = FixedClock(DateTime(2026, 11, 4, 9));
      final tracker = AssistantBudgetTracker(
        clock: clock,
        budget: const AssistantDailyBudget(maxCalls: 100, maxTokens: 500),
      );
      tracker.record('u1', inputTokens: 200, outputTokens: 200);
      expect(tracker.canSpend('u1', tokens: 200), isFalse);
      expect(tracker.canSpend('u1', tokens: 100), isTrue);
    });

    test('exactly filling the cap is allowed; one over is not', () {
      final clock = FixedClock(DateTime(2026, 11, 4, 9));
      final tracker = AssistantBudgetTracker(
        clock: clock,
        budget: const AssistantDailyBudget(maxCalls: 1, maxTokens: 100),
      );
      expect(tracker.canSpend('u1', tokens: 100, calls: 1), isTrue);
      expect(tracker.canSpend('u1', tokens: 101, calls: 1), isFalse);
    });

    test('unlimited budget accepts every spend', () {
      final clock = FixedClock(DateTime(2026, 11, 4, 9));
      final tracker = AssistantBudgetTracker(
        clock: clock,
        budget: AssistantDailyBudget.unlimited,
      );
      tracker.record('u1', inputTokens: 1000000, outputTokens: 1000000);
      expect(tracker.canSpend('u1', tokens: 1 << 30, calls: 1 << 20), isTrue);
    });

    test('zero spend is always allowed', () {
      final clock = FixedClock(DateTime(2026, 11, 4, 9));
      final tracker = AssistantBudgetTracker(
        clock: clock,
        budget: const AssistantDailyBudget(maxCalls: 1, maxTokens: 10),
      );
      tracker.record('u1', inputTokens: 100, outputTokens: 100);
      // Already over on tokens, over on calls — a zero spend still returns
      // true, because it costs nothing.
      expect(tracker.canSpend('u1', tokens: 0, calls: 0), isTrue);
    });
  });

  group('AssistantBudgetTracker.checkCanSpend', () {
    test('throws with callLimit when the call cap trips first', () {
      final clock = FixedClock(DateTime(2026, 11, 4, 9));
      final tracker = AssistantBudgetTracker(
        clock: clock,
        budget: const AssistantDailyBudget(maxCalls: 1, maxTokens: 100000),
      );
      tracker.record('u1', inputTokens: 10, outputTokens: 10);
      expect(
        () => tracker.checkCanSpend('u1', tokens: 10),
        throwsA(
          isA<BudgetExceededException>().having(
            (e) => e.reason,
            'reason',
            BudgetExceededReason.callLimit,
          ),
        ),
      );
    });

    test('names the user whose budget was exceeded', () {
      final clock = FixedClock(DateTime(2026, 11, 4, 9));
      final tracker = AssistantBudgetTracker(
        clock: clock,
        budget: const AssistantDailyBudget(maxCalls: 1),
      );
      tracker.record('u1', inputTokens: 1, outputTokens: 1);
      expect(
        () => tracker.checkCanSpend('u1'),
        throwsA(
          isA<BudgetExceededException>().having(
            (e) => e.userId,
            'userId',
            'u1',
          ),
        ),
      );
    });

    test('throws with tokenLimit when calls fit but tokens do not', () {
      final clock = FixedClock(DateTime(2026, 11, 4, 9));
      final tracker = AssistantBudgetTracker(
        clock: clock,
        budget: const AssistantDailyBudget(maxCalls: 100, maxTokens: 50),
      );
      tracker.record('u1', inputTokens: 20, outputTokens: 20);
      expect(
        () => tracker.checkCanSpend('u1', tokens: 20),
        throwsA(
          isA<BudgetExceededException>().having(
            (e) => e.reason,
            'reason',
            BudgetExceededReason.tokenLimit,
          ),
        ),
      );
    });

    test('does not throw when the spend fits', () {
      final clock = FixedClock(DateTime(2026, 11, 4, 9));
      final tracker = AssistantBudgetTracker(
        clock: clock,
        budget: const AssistantDailyBudget(maxCalls: 10, maxTokens: 100),
      );
      tracker.checkCanSpend('u1', tokens: 50);
    });
  });

  group('AssistantBudgetTracker day rollover', () {
    test('counters reset on the first operation after local midnight', () {
      final clock = FixedClock(DateTime(2026, 11, 4, 23, 50));
      final tracker = AssistantBudgetTracker(clock: clock);
      tracker.record('u1', inputTokens: 100, outputTokens: 100);
      expect(tracker.usageFor('u1').totalTokens, 200);

      clock.set(DateTime(2026, 11, 5, 0, 5));
      final after = tracker.usageFor('u1');
      expect(after.date, DateTime(2026, 11, 5));
      expect(after.calls, 0);
      expect(after.totalTokens, 0);
    });

    test('a spend on the new day accumulates from zero, not yesterday', () {
      final clock = FixedClock(DateTime(2026, 11, 4, 20));
      final tracker = AssistantBudgetTracker(clock: clock);
      tracker.record('u1', inputTokens: 50, outputTokens: 50);

      clock.set(DateTime(2026, 11, 5, 9));
      tracker.record('u1', inputTokens: 10, outputTokens: 10);
      final usage = tracker.usageFor('u1');
      expect(usage.date, DateTime(2026, 11, 5));
      expect(usage.calls, 1);
      expect(usage.totalTokens, 20);
    });

    test('rollover frees users who were blocked yesterday', () {
      final clock = FixedClock(DateTime(2026, 11, 4, 23));
      final tracker = AssistantBudgetTracker(
        clock: clock,
        budget: const AssistantDailyBudget(maxCalls: 1, maxTokens: 10),
      );
      tracker.record('u1', inputTokens: 5, outputTokens: 5);
      expect(tracker.canSpend('u1', tokens: 1), isFalse);

      clock.set(DateTime(2026, 11, 5, 0, 1));
      expect(tracker.canSpend('u1', tokens: 1), isTrue);
    });

    test('untilReset counts to the next local midnight', () {
      final clock = FixedClock(DateTime(2026, 11, 4, 23));
      final tracker = AssistantBudgetTracker(clock: clock);
      expect(tracker.untilReset(), const Duration(hours: 1));

      clock.set(DateTime(2026, 11, 4, 9, 15, 30));
      expect(
        tracker.untilReset(),
        const Duration(hours: 14, minutes: 44, seconds: 30),
      );
    });
  });

  group('AssistantBudgetTracker.reset', () {
    test('resetFor drops one user without touching the others', () {
      final clock = FixedClock(DateTime(2026, 11, 4, 9));
      final tracker = AssistantBudgetTracker(clock: clock);
      tracker.record('alice', inputTokens: 10, outputTokens: 10);
      tracker.record('bob', inputTokens: 5, outputTokens: 5);
      tracker.resetFor('alice');
      expect(tracker.usageFor('alice').totalTokens, 0);
      expect(tracker.usageFor('bob').totalTokens, 10);
    });

    test('resetAll drops every user', () {
      final clock = FixedClock(DateTime(2026, 11, 4, 9));
      final tracker = AssistantBudgetTracker(clock: clock);
      tracker.record('alice', inputTokens: 10, outputTokens: 10);
      tracker.record('bob', inputTokens: 5, outputTokens: 5);
      tracker.resetAll();
      expect(tracker.usageFor('alice').totalTokens, 0);
      expect(tracker.usageFor('bob').totalTokens, 0);
    });
  });

  group('AssistantBudgetTracker.budget setter', () {
    test('tightening the cap at runtime applies to the next check', () {
      final clock = FixedClock(DateTime(2026, 11, 4, 9));
      final tracker = AssistantBudgetTracker(
        clock: clock,
        budget: AssistantDailyBudget.unlimited,
      );
      tracker.record('u1', inputTokens: 100, outputTokens: 100);
      tracker.budget = const AssistantDailyBudget(maxTokens: 50);
      expect(tracker.canSpend('u1'), isFalse);
      expect(tracker.budget.maxTokens, 50);
    });

    test('loosening the cap lets a previously-blocked spend through', () {
      final clock = FixedClock(DateTime(2026, 11, 4, 9));
      final tracker = AssistantBudgetTracker(
        clock: clock,
        budget: const AssistantDailyBudget(maxCalls: 1),
      );
      tracker.record('u1', inputTokens: 1, outputTokens: 1);
      expect(tracker.canSpend('u1'), isFalse);
      tracker.budget = const AssistantDailyBudget(maxCalls: 10);
      expect(tracker.canSpend('u1'), isTrue);
    });
  });
}
