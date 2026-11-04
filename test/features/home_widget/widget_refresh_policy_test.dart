import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/home_widget/widget_refresh_policy.dart';

void main() {
  final now = DateTime.utc(2026, 11, 4, 9);

  group('authoritative triggers', () {
    const policy = WidgetRefreshPolicy();

    test('scheduler replan always refreshes, even just after a refresh', () {
      final decision = policy.decide(
        trigger: WidgetRefreshTrigger.schedulerReplan,
        now: now,
        lastRefreshAt: now.subtract(const Duration(seconds: 1)),
      );
      expect(decision.shouldRefresh, isTrue);
      expect(decision.trigger, WidgetRefreshTrigger.schedulerReplan);
      expect(decision.skipReason, isNull);
    });

    test('manual always refreshes, ignoring the rate limit', () {
      final decision = policy.decide(
        trigger: WidgetRefreshTrigger.manual,
        now: now,
        lastRefreshAt: now,
      );
      expect(decision.shouldRefresh, isTrue);
      expect(decision.trigger, WidgetRefreshTrigger.manual);
    });
  });

  group('best-effort triggers', () {
    const policy = WidgetRefreshPolicy();

    test('first ever refresh goes through', () {
      for (final trigger in const [
        WidgetRefreshTrigger.taskChanged,
        WidgetRefreshTrigger.focusStateChanged,
        WidgetRefreshTrigger.appResumed,
      ]) {
        final decision = policy.decide(
          trigger: trigger,
          now: now,
          lastRefreshAt: null,
        );
        expect(
          decision.shouldRefresh,
          isTrue,
          reason: '$trigger with no prior refresh should refresh',
        );
        expect(decision.trigger, trigger);
      }
    });

    test('inside the rate-limit window skips with tooSoon', () {
      final decision = policy.decide(
        trigger: WidgetRefreshTrigger.taskChanged,
        now: now,
        lastRefreshAt: now.subtract(const Duration(seconds: 10)),
      );
      expect(decision.shouldRefresh, isFalse);
      expect(decision.skipReason, WidgetRefreshSkipReason.tooSoon);
      expect(decision.trigger, isNull);
    });

    test('at or after the rate-limit window refreshes', () {
      // Exactly at the window boundary: elapsed == minInterval → allowed.
      final boundary = policy.decide(
        trigger: WidgetRefreshTrigger.focusStateChanged,
        now: now,
        lastRefreshAt: now.subtract(policy.minInterval),
      );
      expect(boundary.shouldRefresh, isTrue);
      expect(boundary.trigger, WidgetRefreshTrigger.focusStateChanged);

      // Plenty of time passed.
      final later = policy.decide(
        trigger: WidgetRefreshTrigger.appResumed,
        now: now,
        lastRefreshAt: now.subtract(const Duration(minutes: 5)),
      );
      expect(later.shouldRefresh, isTrue);
    });

    test('a clock going backwards does not block future refreshes', () {
      // Time-zone change or NTP step put `now` before `lastRefreshAt`.
      final decision = policy.decide(
        trigger: WidgetRefreshTrigger.taskChanged,
        now: now,
        lastRefreshAt: now.add(const Duration(hours: 1)),
      );
      expect(decision.shouldRefresh, isTrue);
    });
  });

  test('custom minInterval is honored', () {
    const policy = WidgetRefreshPolicy(minInterval: Duration(seconds: 5));
    final inside = policy.decide(
      trigger: WidgetRefreshTrigger.taskChanged,
      now: now,
      lastRefreshAt: now.subtract(const Duration(seconds: 3)),
    );
    final outside = policy.decide(
      trigger: WidgetRefreshTrigger.taskChanged,
      now: now,
      lastRefreshAt: now.subtract(const Duration(seconds: 6)),
    );
    expect(inside.shouldRefresh, isFalse);
    expect(outside.shouldRefresh, isTrue);
  });
}
