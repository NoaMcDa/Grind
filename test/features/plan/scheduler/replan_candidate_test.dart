import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/domain/domain.dart';
import 'package:grind/features/plan/scheduler/scheduler.dart';

import 'fixtures.dart';

void main() {
  group('isStarted', () {
    test('false when minutesDone is 0', () {
      expect(isStarted(task('fresh')), isFalse);
    });

    test('true when minutesDone is positive', () {
      expect(isStarted(task('started').copyWith(minutesDone: 10)), isTrue);
    });

    test('unaffected by status or lockedStart', () {
      final started = task('x').copyWith(minutesDone: 25);
      expect(isStarted(started.copyWith(status: TaskStatus.done)), isTrue);
      expect(isStarted(started.copyWith(status: TaskStatus.skipped)), isTrue);
    });
  });

  group('isReplanCandidate', () {
    test('a fresh open task may move', () {
      expect(isReplanCandidate(task('a')), isTrue);
    });

    test('done is untouched', () {
      expect(
        isReplanCandidate(task('a').copyWith(status: TaskStatus.done)),
        isFalse,
      );
    });

    test('skipped is untouched', () {
      expect(
        isReplanCandidate(task('a').copyWith(status: TaskStatus.skipped)),
        isFalse,
      );
    });

    test('soft-deleted is untouched', () {
      expect(
        isReplanCandidate(task('a').copyWith(deletedAt: at(0, 7))),
        isFalse,
      );
    });

    test('pinned is untouched', () {
      final pinned = task(
        'pin',
        lockedStart: at(0, 9),
        lockedEnd: at(0, 9, 30),
      );
      expect(isReplanCandidate(pinned), isFalse);
    });

    test('already started is untouched', () {
      expect(isReplanCandidate(task('a').copyWith(minutesDone: 15)), isFalse);
    });

    test('scheduled but neither pinned nor started may still move', () {
      // The scheduler placed it; the user has not touched or started it, so
      // another re-plan is free to move it.
      final placed = task(
        'a',
      ).copyWith(scheduledStart: at(0, 10), scheduledEnd: at(0, 10, 30));
      expect(isReplanCandidate(placed), isTrue);
    });
  });

  group('partitionForReplan', () {
    test('empty in, empty out', () {
      final p = partitionForReplan(const []);
      expect(p.movable, isEmpty);
      expect(p.untouched, isEmpty);
      expect(p, ReplanPartition.empty);
    });

    test('separates the four buckets from epic #18', () {
      final fresh = task('fresh');
      final done = task('done').copyWith(status: TaskStatus.done);
      final pinned = task(
        'pin',
        lockedStart: at(0, 9),
        lockedEnd: at(0, 9, 30),
      );
      final started = task('started').copyWith(minutesDone: 20);
      final skipped = task('skip').copyWith(status: TaskStatus.skipped);

      final p = partitionForReplan([fresh, done, pinned, started, skipped]);

      expect(p.movable.map((t) => t.id), ['fresh']);
      expect(p.untouched.map((t) => t.id), ['done', 'pin', 'started', 'skip']);
    });

    test('keeps input order inside each bucket', () {
      // Determinism: a re-plan diff rendered in input order never reshuffles
      // between calls even when only the bucket contents change.
      final tasks = [
        task('m1'),
        task('u1').copyWith(status: TaskStatus.done),
        task('m2'),
        task('u2').copyWith(minutesDone: 5),
        task('m3'),
      ];
      final p = partitionForReplan(tasks);
      expect(p.movable.map((t) => t.id), ['m1', 'm2', 'm3']);
      expect(p.untouched.map((t) => t.id), ['u1', 'u2']);
    });

    test('every task lands in exactly one bucket', () {
      final tasks = [
        task('a'),
        task('b').copyWith(status: TaskStatus.done),
        task('c', lockedStart: at(0, 10), lockedEnd: at(0, 10, 30)),
        task('d').copyWith(minutesDone: 5),
      ];
      final p = partitionForReplan(tasks);
      expect(p.movable.length + p.untouched.length, tasks.length);
      for (final t in tasks) {
        final inMovable = p.movable.any((x) => x.id == t.id);
        final inUntouched = p.untouched.any((x) => x.id == t.id);
        expect(
          inMovable ^ inUntouched,
          isTrue,
          reason: '${t.id} must be in exactly one bucket',
        );
      }
    });
  });
}
