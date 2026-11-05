import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';

void main() {
  group('AssistantRetryPolicy.defaults', () {
    test('three tries, doubling 250ms, capped at 2s', () {
      final p = AssistantRetryPolicy.defaults;
      expect(p.maxAttempts, 3);
      expect(p.schedule, [
        Duration.zero,
        const Duration(milliseconds: 250),
        const Duration(milliseconds: 500),
      ]);
    });

    test('retries the transient kinds the gateway surfaces', () {
      final p = AssistantRetryPolicy.defaults;
      expect(p.shouldRetry(AssistantErrorKind.network), isTrue);
      expect(p.shouldRetry(AssistantErrorKind.timeout), isTrue);
      expect(p.shouldRetry(AssistantErrorKind.rateLimited), isTrue);
    });

    test('does not retry opt-out, schema or catch-all failures', () {
      final p = AssistantRetryPolicy.defaults;
      expect(p.shouldRetry(AssistantErrorKind.optedOut), isFalse);
      expect(p.shouldRetry(AssistantErrorKind.invalidResponse), isFalse);
      expect(p.shouldRetry(AssistantErrorKind.other), isFalse);
    });
  });

  group('AssistantRetryPolicy.noRetry', () {
    test('surfaces the first failure without waiting', () {
      final p = AssistantRetryPolicy.noRetry;
      expect(p.maxAttempts, 1);
      expect(p.schedule, [Duration.zero]);
      expect(p.shouldRetry(AssistantErrorKind.network), isFalse);
    });
  });

  group('AssistantRetryPolicy.delayFor', () {
    test('attempt 1 is always zero', () {
      expect(AssistantRetryPolicy.defaults.delayFor(1), Duration.zero);
    });

    test('attempt 2 is initialDelay', () {
      final p = AssistantRetryPolicy(
        maxAttempts: 4,
        initialDelay: const Duration(milliseconds: 100),
        maxDelay: const Duration(seconds: 10),
        multiplier: 2,
      );
      expect(p.delayFor(2), const Duration(milliseconds: 100));
    });

    test('later attempts compound by multiplier', () {
      final p = AssistantRetryPolicy(
        maxAttempts: 5,
        initialDelay: const Duration(milliseconds: 100),
        maxDelay: const Duration(seconds: 10),
        multiplier: 2,
      );
      expect(p.delayFor(3), const Duration(milliseconds: 200));
      expect(p.delayFor(4), const Duration(milliseconds: 400));
      expect(p.delayFor(5), const Duration(milliseconds: 800));
    });

    test('is capped at maxDelay, however aggressive the multiplier', () {
      final p = AssistantRetryPolicy(
        maxAttempts: 8,
        initialDelay: const Duration(milliseconds: 100),
        maxDelay: const Duration(milliseconds: 500),
        multiplier: 3,
      );
      // 100, 300, cap, cap, cap ...
      expect(p.delayFor(2), const Duration(milliseconds: 100));
      expect(p.delayFor(3), const Duration(milliseconds: 300));
      expect(p.delayFor(4), const Duration(milliseconds: 500));
      expect(p.delayFor(5), const Duration(milliseconds: 500));
      expect(p.delayFor(8), const Duration(milliseconds: 500));
    });

    test('honours a flat schedule (multiplier 1)', () {
      final p = AssistantRetryPolicy(
        maxAttempts: 4,
        initialDelay: const Duration(milliseconds: 200),
        maxDelay: const Duration(seconds: 5),
        multiplier: 1,
      );
      expect(p.schedule, [
        Duration.zero,
        const Duration(milliseconds: 200),
        const Duration(milliseconds: 200),
        const Duration(milliseconds: 200),
      ]);
    });

    test('rejects out-of-range attempts', () {
      final p = AssistantRetryPolicy.defaults;
      expect(() => p.delayFor(0), throwsArgumentError);
      expect(() => p.delayFor(-1), throwsArgumentError);
      expect(() => p.delayFor(p.maxAttempts + 1), throwsArgumentError);
    });
  });

  group('AssistantRetryPolicy.shouldRetryException', () {
    test('delegates to shouldRetry on the kind', () {
      final p = AssistantRetryPolicy.defaults;
      expect(
        p.shouldRetryException(
          const AssistantException('x', kind: AssistantErrorKind.network),
        ),
        isTrue,
      );
      expect(
        p.shouldRetryException(
          const AssistantException('x', kind: AssistantErrorKind.optedOut),
        ),
        isFalse,
      );
    });
  });

  group('AssistantRetryPolicy custom retryableKinds', () {
    test('honours a tighter set', () {
      final p = AssistantRetryPolicy(
        maxAttempts: 2,
        initialDelay: const Duration(milliseconds: 10),
        maxDelay: const Duration(milliseconds: 10),
        multiplier: 1,
        retryableKinds: const {AssistantErrorKind.timeout},
      );
      expect(p.shouldRetry(AssistantErrorKind.timeout), isTrue);
      // Network no longer retryable when the caller narrowed the set.
      expect(p.shouldRetry(AssistantErrorKind.network), isFalse);
    });

    test('is copied so callers cannot mutate it after construction', () {
      final mutable = {AssistantErrorKind.network};
      final p = AssistantRetryPolicy(
        maxAttempts: 2,
        initialDelay: const Duration(milliseconds: 10),
        maxDelay: const Duration(milliseconds: 10),
        multiplier: 1,
        retryableKinds: mutable,
      );
      mutable.add(AssistantErrorKind.other);
      expect(p.shouldRetry(AssistantErrorKind.other), isFalse);
    });
  });

  group('AssistantRetryPolicy.copyWith', () {
    test('swaps the named fields, keeps the rest', () {
      final base = AssistantRetryPolicy.defaults;
      final patched = base.copyWith(maxAttempts: 5);
      expect(patched.maxAttempts, 5);
      expect(patched.initialDelay, base.initialDelay);
      expect(patched.maxDelay, base.maxDelay);
      expect(patched.multiplier, base.multiplier);
      expect(patched.retryableKinds, base.retryableKinds);
    });

    test('leaves the receiver untouched', () {
      final base = AssistantRetryPolicy.defaults;
      // Ignore the return value — this is the point.
      // ignore: unused_local_variable
      final _ = base.copyWith(maxAttempts: 7);
      expect(base.maxAttempts, 3);
    });
  });

  group('AssistantRetryPolicy value equality', () {
    test('equal when every field matches', () {
      final a = AssistantRetryPolicy(
        maxAttempts: 3,
        initialDelay: const Duration(milliseconds: 100),
        maxDelay: const Duration(seconds: 1),
        multiplier: 2,
      );
      final b = AssistantRetryPolicy(
        maxAttempts: 3,
        initialDelay: const Duration(milliseconds: 100),
        maxDelay: const Duration(seconds: 1),
        multiplier: 2,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('not equal when a field differs', () {
      final a = AssistantRetryPolicy.defaults;
      final b = a.copyWith(maxAttempts: a.maxAttempts + 1);
      expect(a, isNot(b));
    });
  });

  group('AssistantRetryPolicy asserts', () {
    test('rejects maxAttempts < 1', () {
      expect(
        () => AssistantRetryPolicy(
          maxAttempts: 0,
          initialDelay: Duration.zero,
          maxDelay: Duration.zero,
          multiplier: 1,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects a multiplier below 1', () {
      expect(
        () => AssistantRetryPolicy(
          maxAttempts: 3,
          initialDelay: const Duration(milliseconds: 100),
          maxDelay: const Duration(seconds: 1),
          multiplier: 0.5,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects a maxDelay below initialDelay', () {
      expect(
        () => AssistantRetryPolicy(
          maxAttempts: 3,
          initialDelay: const Duration(seconds: 1),
          maxDelay: const Duration(milliseconds: 100),
          multiplier: 2,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
