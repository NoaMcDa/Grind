import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/home_widget/home_widget.dart';

void main() {
  final writtenAt = DateTime.utc(2026, 11, 3, 6);

  const momentum = WidgetMomentum(
    value: 42.5,
    level: 'steady',
    showedUpDays: 3,
    dayCounts: [0, 1, 2, 0, 1, 1, 0],
  );

  WidgetSnapshot snapshot({DateTime? at}) =>
      WidgetSnapshot(writtenAt: at ?? writtenAt, momentum: momentum);

  group('grade (default thresholds)', () {
    test('null snapshot grades as expired', () {
      expect(
        WidgetSnapshotFreshnessCalculator.grade(snapshot: null, now: writtenAt),
        WidgetSnapshotFreshness.expired,
      );
    });

    test('just-written snapshot is fresh', () {
      expect(
        WidgetSnapshotFreshnessCalculator.grade(
          snapshot: snapshot(),
          now: writtenAt,
        ),
        WidgetSnapshotFreshness.fresh,
      );
    });

    test('one minute old is still fresh (inside the 2-min band)', () {
      expect(
        WidgetSnapshotFreshnessCalculator.grade(
          snapshot: snapshot(),
          now: writtenAt.add(const Duration(minutes: 1)),
        ),
        WidgetSnapshotFreshness.fresh,
      );
    });

    test('exactly at agingAfter is aging, not fresh (boundary inclusive)', () {
      // The boundary belongs to the newer band on the "older" side: a
      // snapshot that has been aging for exactly 2 min is in aging.
      expect(
        WidgetSnapshotFreshnessCalculator.grade(
          snapshot: snapshot(),
          now: writtenAt.add(const Duration(minutes: 2)),
        ),
        WidgetSnapshotFreshness.aging,
      );
    });

    test('ten minutes old is aging', () {
      expect(
        WidgetSnapshotFreshnessCalculator.grade(
          snapshot: snapshot(),
          now: writtenAt.add(const Duration(minutes: 10)),
        ),
        WidgetSnapshotFreshness.aging,
      );
    });

    test('exactly at staleAfter is stale, not aging', () {
      expect(
        WidgetSnapshotFreshnessCalculator.grade(
          snapshot: snapshot(),
          now: writtenAt.add(const Duration(minutes: 15)),
        ),
        WidgetSnapshotFreshness.stale,
      );
    });

    test('thirty minutes old is stale', () {
      expect(
        WidgetSnapshotFreshnessCalculator.grade(
          snapshot: snapshot(),
          now: writtenAt.add(const Duration(minutes: 30)),
        ),
        WidgetSnapshotFreshness.stale,
      );
    });

    test('exactly at expiredAfter is expired, not stale', () {
      expect(
        WidgetSnapshotFreshnessCalculator.grade(
          snapshot: snapshot(),
          now: writtenAt.add(const Duration(hours: 1)),
        ),
        WidgetSnapshotFreshness.expired,
      );
    });

    test('three hours old is expired', () {
      expect(
        WidgetSnapshotFreshnessCalculator.grade(
          snapshot: snapshot(),
          now: writtenAt.add(const Duration(hours: 3)),
        ),
        WidgetSnapshotFreshness.expired,
      );
    });
  });

  group('clock skew', () {
    test('future-dated snapshot grades as fresh (no exception)', () {
      // The reader's now ran behind the writer's; the widget must not
      // flicker to the fallback the first time the user crosses a zone.
      expect(
        WidgetSnapshotFreshnessCalculator.grade(
          snapshot: snapshot(at: writtenAt.add(const Duration(hours: 2))),
          now: writtenAt,
        ),
        WidgetSnapshotFreshness.fresh,
      );
    });

    test('grader normalises both sides to UTC', () {
      // Local-zoned `now` with a matching UTC instant: zero elapsed → fresh.
      final nowLocal = DateTime(2026, 11, 3, 6).toLocal();
      expect(
        WidgetSnapshotFreshnessCalculator.grade(
          snapshot: WidgetSnapshot(
            writtenAt: nowLocal.toUtc(),
            momentum: momentum,
          ),
          now: nowLocal,
        ),
        WidgetSnapshotFreshness.fresh,
      );
    });
  });

  group('custom thresholds', () {
    test('tighter thresholds move boundaries earlier', () {
      const tight = WidgetSnapshotFreshnessThresholds.raw(
        agingAfter: Duration(seconds: 30),
        staleAfter: Duration(minutes: 2),
        expiredAfter: Duration(minutes: 10),
      );
      expect(
        WidgetSnapshotFreshnessCalculator.grade(
          snapshot: snapshot(),
          now: writtenAt.add(const Duration(minutes: 1)),
          thresholds: tight,
        ),
        // Would be fresh under defaults, aging here.
        WidgetSnapshotFreshness.aging,
      );
      expect(
        WidgetSnapshotFreshnessCalculator.grade(
          snapshot: snapshot(),
          now: writtenAt.add(const Duration(minutes: 11)),
          thresholds: tight,
        ),
        WidgetSnapshotFreshness.expired,
      );
    });

    test('misordered thresholds assert in debug', () {
      expect(
        () => WidgetSnapshotFreshnessThresholds(
          agingAfter: const Duration(minutes: 10),
          staleAfter: const Duration(minutes: 5),
          expiredAfter: const Duration(minutes: 20),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('negative thresholds assert in debug', () {
      expect(
        () => WidgetSnapshotFreshnessThresholds(
          agingAfter: const Duration(seconds: -1),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('default thresholds pin to the documented values', () {
      // The grader's default-parameter const value must match the public
      // class exactly — a drift would silently change the widget's bands.
      const defaults = WidgetSnapshotFreshnessThresholds.raw();
      expect(defaults.agingAfter, const Duration(minutes: 2));
      expect(defaults.staleAfter, const Duration(minutes: 15));
      expect(defaults.expiredAfter, const Duration(hours: 1));
    });
  });

  group('shouldShowReminder', () {
    test('true for fresh, aging and stale; false for expired and null', () {
      expect(
        WidgetSnapshotFreshnessCalculator.shouldShowReminder(
          snapshot: snapshot(),
          now: writtenAt,
        ),
        isTrue,
      );
      expect(
        WidgetSnapshotFreshnessCalculator.shouldShowReminder(
          snapshot: snapshot(),
          now: writtenAt.add(const Duration(minutes: 10)),
        ),
        isTrue,
      );
      expect(
        WidgetSnapshotFreshnessCalculator.shouldShowReminder(
          snapshot: snapshot(),
          now: writtenAt.add(const Duration(minutes: 30)),
        ),
        isTrue,
      );
      expect(
        WidgetSnapshotFreshnessCalculator.shouldShowReminder(
          snapshot: snapshot(),
          now: writtenAt.add(const Duration(hours: 3)),
        ),
        isFalse,
      );
      expect(
        WidgetSnapshotFreshnessCalculator.shouldShowReminder(
          snapshot: null,
          now: writtenAt,
        ),
        isFalse,
      );
    });
  });

  group('ordering', () {
    test('enum index is strictly older → larger', () {
      expect(
        WidgetSnapshotFreshness.fresh.index <
            WidgetSnapshotFreshness.aging.index,
        isTrue,
      );
      expect(
        WidgetSnapshotFreshness.aging.index <
            WidgetSnapshotFreshness.stale.index,
        isTrue,
      );
      expect(
        WidgetSnapshotFreshness.stale.index <
            WidgetSnapshotFreshness.expired.index,
        isTrue,
      );
    });

    test('switch over WidgetSnapshotFreshness is exhaustive', () {
      // Compile-time check: a `switch` with no default must cover every
      // value. Adding a band without updating the UI would fail analysis.
      String label(WidgetSnapshotFreshness f) => switch (f) {
        WidgetSnapshotFreshness.fresh => 'fresh',
        WidgetSnapshotFreshness.aging => 'aging',
        WidgetSnapshotFreshness.stale => 'stale',
        WidgetSnapshotFreshness.expired => 'expired',
      };
      expect(label(WidgetSnapshotFreshness.fresh), 'fresh');
      expect(label(WidgetSnapshotFreshness.aging), 'aging');
      expect(label(WidgetSnapshotFreshness.stale), 'stale');
      expect(label(WidgetSnapshotFreshness.expired), 'expired');
    });
  });
}
