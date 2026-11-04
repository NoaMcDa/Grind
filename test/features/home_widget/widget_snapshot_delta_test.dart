import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/home_widget/home_widget.dart';

void main() {
  final writtenAt = DateTime.utc(2026, 11, 3, 6);
  final fireAt = writtenAt.add(const Duration(hours: 1));

  WidgetReminder reminder({
    String taskId = 'a',
    String notificationId = 'task:a:1',
    String title = 'Draft email',
    String body = 'If 7:00 then open the draft.',
    DateTime? at,
    bool canComplete = true,
    bool canStartFocus = true,
  }) => WidgetReminder(
    taskId: taskId,
    notificationId: notificationId,
    fireAt: at ?? fireAt,
    title: title,
    body: body,
    canComplete: canComplete,
    canStartFocus: canStartFocus,
  );

  const emptyMomentum = WidgetMomentum(
    value: 0,
    level: 'quiet',
    showedUpDays: 0,
    dayCounts: [0, 0, 0, 0, 0, 0, 0],
  );

  const steadyMomentum = WidgetMomentum(
    value: 42.5,
    level: 'steady',
    showedUpDays: 3,
    dayCounts: [0, 1, 2, 0, 1, 1, 0],
  );

  WidgetSnapshot snapshot({
    DateTime? at,
    WidgetReminder? next,
    WidgetMomentum momentum = steadyMomentum,
  }) => WidgetSnapshot(
    writtenAt: at ?? writtenAt,
    nextReminder: next,
    momentum: momentum,
  );

  group('first write (previous == null)', () {
    test('an empty snapshot returns none', () {
      final decision = WidgetSnapshotDeltaCalculator.diff(
        previous: null,
        next: snapshot(momentum: emptyMomentum),
      );
      expect(decision, WidgetSnapshotDelta.none);
      expect(
        WidgetSnapshotDeltaCalculator.shouldReload(
          previous: null,
          next: snapshot(momentum: emptyMomentum),
        ),
        isFalse,
      );
    });

    test('a snapshot with a reminder returns nextReminder', () {
      expect(
        WidgetSnapshotDeltaCalculator.diff(
          previous: null,
          next: snapshot(next: reminder(), momentum: emptyMomentum),
        ),
        WidgetSnapshotDelta.nextReminder,
      );
    });

    test('a snapshot with momentum but no reminder returns momentum', () {
      expect(
        WidgetSnapshotDeltaCalculator.diff(previous: null, next: snapshot()),
        WidgetSnapshotDelta.momentum,
      );
    });
  });

  group('next reminder changes', () {
    test('adding a reminder is a change', () {
      final previous = snapshot();
      final next = snapshot(next: reminder());
      expect(
        WidgetSnapshotDeltaCalculator.diff(previous: previous, next: next),
        WidgetSnapshotDelta.nextReminder,
      );
    });

    test('dropping a reminder is a change', () {
      final previous = snapshot(next: reminder());
      final next = snapshot();
      expect(
        WidgetSnapshotDeltaCalculator.diff(previous: previous, next: next),
        WidgetSnapshotDelta.nextReminder,
      );
    });

    test('swapping to a different task is a change', () {
      final previous = snapshot(next: reminder(taskId: 'a'));
      final next = snapshot(
        next: reminder(taskId: 'b', notificationId: 'task:b:1'),
      );
      expect(
        WidgetSnapshotDeltaCalculator.diff(previous: previous, next: next),
        WidgetSnapshotDelta.nextReminder,
      );
    });

    test('a changed title, body, fire time or action flag all count', () {
      final base = snapshot(next: reminder());
      final cases = [
        reminder(title: 'Reply to Jo'),
        reminder(body: 'If 7:05 then open the draft.'),
        reminder(at: fireAt.add(const Duration(minutes: 5))),
        reminder(canComplete: false),
        reminder(canStartFocus: false),
      ];
      for (final r in cases) {
        expect(
          WidgetSnapshotDeltaCalculator.diff(
            previous: base,
            next: snapshot(next: r),
          ),
          WidgetSnapshotDelta.nextReminder,
          reason: 'changed field in $r',
        );
      }
    });

    test('identical reminders and momentum return none', () {
      final previous = snapshot(next: reminder());
      final next = snapshot(next: reminder());
      expect(
        WidgetSnapshotDeltaCalculator.diff(previous: previous, next: next),
        WidgetSnapshotDelta.none,
      );
    });
  });

  group('momentum changes', () {
    test('a level change counts even when value is stable', () {
      final previous = snapshot(momentum: steadyMomentum);
      final next = snapshot(
        momentum: const WidgetMomentum(
          value: 42.5,
          level: 'strong',
          showedUpDays: 3,
          dayCounts: [0, 1, 2, 0, 1, 1, 0],
        ),
      );
      expect(
        WidgetSnapshotDeltaCalculator.diff(previous: previous, next: next),
        WidgetSnapshotDelta.momentum,
      );
    });

    test('a value change below the epsilon is ignored', () {
      final previous = snapshot(momentum: steadyMomentum);
      final next = snapshot(
        momentum: const WidgetMomentum(
          value: 42.7,
          level: 'steady',
          showedUpDays: 3,
          dayCounts: [0, 1, 2, 0, 1, 1, 0],
        ),
      );
      expect(
        WidgetSnapshotDeltaCalculator.diff(previous: previous, next: next),
        WidgetSnapshotDelta.none,
      );
    });

    test('a value change at or above the epsilon counts', () {
      final previous = snapshot(momentum: steadyMomentum);
      final next = snapshot(
        momentum: const WidgetMomentum(
          value: 43.0,
          level: 'steady',
          showedUpDays: 3,
          dayCounts: [0, 1, 2, 0, 1, 1, 0],
        ),
      );
      expect(
        WidgetSnapshotDeltaCalculator.diff(previous: previous, next: next),
        WidgetSnapshotDelta.momentum,
      );
    });

    test('a showed-up-days change counts', () {
      final previous = snapshot(momentum: steadyMomentum);
      final next = snapshot(
        momentum: const WidgetMomentum(
          value: 42.5,
          level: 'steady',
          showedUpDays: 4,
          dayCounts: [0, 1, 2, 0, 1, 1, 0],
        ),
      );
      expect(
        WidgetSnapshotDeltaCalculator.diff(previous: previous, next: next),
        WidgetSnapshotDelta.momentum,
      );
    });

    test('any day in the 7-day strip changes counts', () {
      final previous = snapshot(momentum: steadyMomentum);
      final next = snapshot(
        momentum: const WidgetMomentum(
          value: 42.5,
          level: 'steady',
          showedUpDays: 3,
          dayCounts: [0, 1, 2, 0, 1, 1, 1],
        ),
      );
      expect(
        WidgetSnapshotDeltaCalculator.diff(previous: previous, next: next),
        WidgetSnapshotDelta.momentum,
      );
    });

    test('reminder changes beat momentum changes in the returned reason', () {
      final previous = snapshot(next: reminder(), momentum: steadyMomentum);
      final next = snapshot(
        next: reminder(title: 'Reply to Jo'),
        momentum: emptyMomentum,
      );
      expect(
        WidgetSnapshotDeltaCalculator.diff(previous: previous, next: next),
        WidgetSnapshotDelta.nextReminder,
      );
    });
  });

  group('stale writtenAt', () {
    test('a bare writtenAt bump under the threshold is none', () {
      final previous = snapshot();
      final next = snapshot(at: writtenAt.add(const Duration(minutes: 5)));
      expect(
        WidgetSnapshotDeltaCalculator.diff(previous: previous, next: next),
        WidgetSnapshotDelta.none,
      );
    });

    test('a bare writtenAt bump at the threshold is stale', () {
      final previous = snapshot();
      final next = snapshot(at: writtenAt.add(const Duration(minutes: 15)));
      expect(
        WidgetSnapshotDeltaCalculator.diff(previous: previous, next: next),
        WidgetSnapshotDelta.stale,
      );
    });

    test('a clock going backwards is treated as not stale', () {
      final previous = snapshot(at: writtenAt.add(const Duration(hours: 1)));
      final next = snapshot();
      expect(
        WidgetSnapshotDeltaCalculator.diff(previous: previous, next: next),
        WidgetSnapshotDelta.none,
      );
    });

    test('custom tolerances override the defaults', () {
      final previous = snapshot();
      final next = snapshot(at: writtenAt.add(const Duration(minutes: 2)));
      expect(
        WidgetSnapshotDeltaCalculator.diff(
          previous: previous,
          next: next,
          tolerances: const WidgetSnapshotDeltaTolerances(
            staleAfter: Duration(minutes: 1),
          ),
        ),
        WidgetSnapshotDelta.stale,
      );
    });
  });

  test('shouldReload is true for every non-none result', () {
    final previous = snapshot();
    expect(
      WidgetSnapshotDeltaCalculator.shouldReload(
        previous: previous,
        next: snapshot(next: reminder()),
      ),
      isTrue,
    );
    expect(
      WidgetSnapshotDeltaCalculator.shouldReload(
        previous: previous,
        next: snapshot(),
      ),
      isFalse,
    );
  });
}
