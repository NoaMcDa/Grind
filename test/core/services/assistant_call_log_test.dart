import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';

void main() {
  DateTime t(int sec) => DateTime.utc(2026, 1, 1, 0, 0, sec);

  AssistantCallMetric ok(
    String intent, {
    ModelTier tier = ModelTier.haiku,
    int ms = 100,
    int at = 0,
  }) => AssistantCallMetric(
    intent: intent,
    tier: tier,
    latency: Duration(milliseconds: ms),
    outcome: AssistantCallOutcome.success,
    startedAt: t(at),
  );

  AssistantCallMetric fail(
    String intent,
    AssistantErrorKind kind, {
    ModelTier? tier = ModelTier.haiku,
    int ms = 100,
    int at = 0,
  }) => AssistantCallMetric(
    intent: intent,
    tier: tier,
    latency: Duration(milliseconds: ms),
    outcome: AssistantCallOutcome.failed,
    errorKind: kind,
    startedAt: t(at),
  );

  group('AssistantCallMetric', () {
    test('accepts a well-formed success row', () {
      final m = ok('capture', ms: 250);
      expect(m.intent, 'capture');
      expect(m.tier, ModelTier.haiku);
      expect(m.latency, const Duration(milliseconds: 250));
      expect(m.outcome, AssistantCallOutcome.success);
      expect(m.errorKind, isNull);
    });

    test('accepts a well-formed failure row', () {
      final m = fail('capture', AssistantErrorKind.timeout);
      expect(m.outcome, AssistantCallOutcome.failed);
      expect(m.errorKind, AssistantErrorKind.timeout);
    });

    test('accepts a tier-less entry (opted out / budget refused)', () {
      final m = AssistantCallMetric(
        intent: 'capture',
        tier: null,
        latency: Duration.zero,
        outcome: AssistantCallOutcome.failed,
        errorKind: AssistantErrorKind.optedOut,
        startedAt: t(0),
      );
      expect(m.tier, isNull);
    });

    test('rejects empty intent', () {
      expect(
        () => AssistantCallMetric(
          intent: '',
          latency: Duration.zero,
          outcome: AssistantCallOutcome.success,
          startedAt: t(0),
        ),
        throwsArgumentError,
      );
    });

    test('rejects negative latency', () {
      expect(
        () => AssistantCallMetric(
          intent: 'capture',
          latency: const Duration(milliseconds: -1),
          outcome: AssistantCallOutcome.success,
          startedAt: t(0),
        ),
        throwsArgumentError,
      );
    });

    test('rejects a non-UTC startedAt', () {
      expect(
        () => AssistantCallMetric(
          intent: 'capture',
          latency: Duration.zero,
          outcome: AssistantCallOutcome.success,
          startedAt: DateTime(2026, 1, 1),
        ),
        throwsArgumentError,
      );
    });

    test('rejects errorKind on a success row', () {
      expect(
        () => AssistantCallMetric(
          intent: 'capture',
          latency: Duration.zero,
          outcome: AssistantCallOutcome.success,
          errorKind: AssistantErrorKind.network,
          startedAt: t(0),
        ),
        throwsArgumentError,
      );
    });

    test('rejects a failure row without errorKind', () {
      expect(
        () => AssistantCallMetric(
          intent: 'capture',
          latency: Duration.zero,
          outcome: AssistantCallOutcome.failed,
          startedAt: t(0),
        ),
        throwsArgumentError,
      );
    });

    test('value equality compares every field', () {
      final a = ok('capture', ms: 100, at: 10);
      final b = ok('capture', ms: 100, at: 10);
      final c = ok('capture', ms: 101, at: 10);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });
  });

  group('AssistantCallLog.record', () {
    test('starts empty', () {
      final log = AssistantCallLog();
      expect(log.isEmpty, isTrue);
      expect(log.isNotEmpty, isFalse);
      expect(log.length, 0);
      expect(log.entries, isEmpty);
    });

    test('appends newest first and notifies listeners', () {
      final log = AssistantCallLog();
      var notifications = 0;
      log.addListener(() => notifications++);
      log.record(ok('capture', at: 1));
      log.record(ok('praise', at: 2));
      expect(log.entries.map((e) => e.intent).toList(), ['praise', 'capture']);
      expect(notifications, 2);
    });

    test('drops the oldest entry past capacity', () {
      final log = AssistantCallLog(capacity: 2);
      log.record(ok('a', at: 1));
      log.record(ok('b', at: 2));
      log.record(ok('c', at: 3));
      expect(log.length, 2);
      expect(log.entries.map((e) => e.intent).toList(), ['c', 'b']);
    });

    test('capacity must be positive', () {
      expect(() => AssistantCallLog(capacity: 0), throwsAssertionError);
      expect(() => AssistantCallLog(capacity: -1), throwsAssertionError);
    });

    test('accepts the same intent twice (unlike the action log)', () {
      // Latency rows are not undoable; duplicates are the common case.
      final log = AssistantCallLog();
      log.record(ok('capture', at: 1));
      log.record(ok('capture', at: 2));
      expect(log.length, 2);
    });
  });

  group('AssistantCallLog.clear', () {
    test('empties the log and notifies when there was anything to clear', () {
      final log = AssistantCallLog()..record(ok('capture'));
      var notifications = 0;
      log.addListener(() => notifications++);
      log.clear();
      expect(log.isEmpty, isTrue);
      expect(notifications, 1);
    });

    test('is a silent no-op when already empty', () {
      final log = AssistantCallLog();
      var notifications = 0;
      log.addListener(() => notifications++);
      log.clear();
      expect(notifications, 0);
    });
  });

  group('AssistantCallLog.where & countBy', () {
    late AssistantCallLog log;
    setUp(() {
      log = AssistantCallLog()
        ..record(ok('capture', tier: ModelTier.haiku, at: 1))
        ..record(ok('capture', tier: ModelTier.haiku, at: 2))
        ..record(fail('capture', AssistantErrorKind.timeout, at: 3))
        ..record(ok('planExplanation', tier: ModelTier.sonnet, at: 4));
    });

    test('filters by intent', () {
      expect(log.where(intent: 'capture').length, 3);
      expect(log.where(intent: 'planExplanation').length, 1);
      expect(log.countBy(intent: 'capture'), 3);
    });

    test('filters by tier', () {
      expect(log.countBy(tier: ModelTier.haiku), 3);
      expect(log.countBy(tier: ModelTier.sonnet), 1);
    });

    test('filters by outcome', () {
      expect(log.countBy(outcome: AssistantCallOutcome.success), 3);
      expect(log.countBy(outcome: AssistantCallOutcome.failed), 1);
    });

    test('filters compose', () {
      expect(
        log.countBy(intent: 'capture', outcome: AssistantCallOutcome.failed),
        1,
      );
      expect(
        log.countBy(intent: 'capture', outcome: AssistantCallOutcome.success),
        2,
      );
    });

    test('where returns a fresh list, newest first', () {
      final rows = log.where(intent: 'capture');
      expect(rows.map((e) => e.startedAt.second).toList(), [3, 2, 1]);
      rows.clear();
      // Mutating the snapshot does not disturb the log.
      expect(log.countBy(intent: 'capture'), 3);
    });
  });

  group('AssistantCallLog.averageLatency', () {
    test('null when no entry matches', () {
      final log = AssistantCallLog();
      expect(log.averageLatency(), isNull);
      log.record(ok('capture', ms: 100));
      expect(log.averageLatency(intent: 'planExplanation'), isNull);
    });

    test('is the mean of matching entries', () {
      final log = AssistantCallLog()
        ..record(ok('capture', ms: 100, at: 1))
        ..record(ok('capture', ms: 300, at: 2))
        ..record(ok('planExplanation', ms: 1000, at: 3));
      expect(
        log.averageLatency(intent: 'capture'),
        const Duration(milliseconds: 200),
      );
      expect(log.averageLatency(), const Duration(microseconds: 466666));
    });

    test('filters cross intent and tier', () {
      final log = AssistantCallLog()
        ..record(ok('capture', tier: ModelTier.haiku, ms: 100, at: 1))
        ..record(ok('capture', tier: ModelTier.sonnet, ms: 500, at: 2));
      expect(
        log.averageLatency(intent: 'capture', tier: ModelTier.haiku),
        const Duration(milliseconds: 100),
      );
    });
  });

  group('AssistantCallLog.successRate', () {
    test('null when no entry matches', () {
      final log = AssistantCallLog();
      expect(log.successRate(), isNull);
    });

    test('is the matching-success fraction', () {
      final log = AssistantCallLog()
        ..record(ok('capture', at: 1))
        ..record(ok('capture', at: 2))
        ..record(ok('capture', at: 3))
        ..record(fail('capture', AssistantErrorKind.timeout, at: 4));
      expect(log.successRate(intent: 'capture'), closeTo(0.75, 1e-9));
      expect(log.successRate(intent: 'nope'), isNull);
    });
  });
}
