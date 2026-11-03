import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/focus/providers.dart';

void main() {
  final t0 = DateTime.utc(2026, 11, 3, 8);
  late FixedClock clock;
  late InMemoryTaskRepository tasks;
  late InMemoryFocusSessionRepository sessions;

  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(clock),
        taskRepositoryProvider.overrideWithValue(tasks),
        focusSessionRepositoryProvider.overrideWithValue(sessions),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    clock = FixedClock(t0);
    tasks = InMemoryTaskRepository([
      Task(id: 'thesis', title: 'Thesis', createdAt: t0, updatedAt: t0),
    ]);
    sessions = InMemoryFocusSessionRepository();
  });

  Future<(ProviderContainer, FocusController)> ready() async {
    final c = makeContainer();
    await c.read(focusControllerProvider.future);
    return (c, c.read(focusControllerProvider.notifier));
  }

  FocusState stateOf(ProviderContainer c) =>
      c.read(focusControllerProvider).requireValue;

  test('starts idle at 25 minutes and persists a new session', () async {
    final (c, ctrl) = await ready();
    expect(stateOf(c).phase, FocusPhase.idle);
    expect(stateOf(c).remaining(t0), const Duration(minutes: 25));

    await ctrl.start(taskId: 'thesis');
    final s = stateOf(c);
    expect(s.phase, FocusPhase.focusing);
    expect(s.endsAt, t0.add(const Duration(minutes: 25)));
    final active = (await sessions.getActive())!;
    expect(active.taskId, 'thesis');
    expect(active.plannedMinutes, 25);
    expect(active.startedAt, t0);
  });

  test('remaining comes from timestamps, not ticks', () async {
    final (c, ctrl) = await ready();
    await ctrl.start(taskId: 'thesis');
    // Twelve minutes pass with no tick at all (app in background).
    clock.advance(const Duration(minutes: 12));
    expect(stateOf(c).remaining(clock.now()), const Duration(minutes: 13));
    expect(stateOf(c).progress(clock.now()), closeTo(12 / 25, 1e-9));
  });

  test('pause freezes the timer and resume pushes the end later', () async {
    final (c, ctrl) = await ready();
    await ctrl.start(taskId: 'thesis');
    clock.advance(const Duration(minutes: 10));
    ctrl.pause();
    expect(stateOf(c).phase, FocusPhase.paused);
    clock.advance(const Duration(minutes: 7));
    expect(stateOf(c).remaining(clock.now()), const Duration(minutes: 15));

    ctrl.resume();
    final s = stateOf(c);
    expect(s.phase, FocusPhase.focusing);
    expect(s.pausedTotal, const Duration(minutes: 7));
    expect(s.endsAt, t0.add(const Duration(minutes: 32)));
    expect(s.remaining(clock.now()), const Duration(minutes: 15));
  });

  test('+5 min extends the session and is persisted', () async {
    final (c, ctrl) = await ready();
    await ctrl.start(taskId: 'thesis');
    clock.advance(const Duration(minutes: 20));
    await ctrl.extend();
    expect(stateOf(c).remaining(clock.now()), const Duration(minutes: 10));
    expect((await sessions.getActive())!.plannedMinutes, 30);
  });

  test('ending early logs focused minutes on the task, no cycle dot', () async {
    final (c, ctrl) = await ready();
    await ctrl.start(taskId: 'thesis');
    clock.advance(const Duration(minutes: 8));
    ctrl.pause();
    clock.advance(const Duration(minutes: 5));
    await ctrl.end();

    final s = stateOf(c);
    expect(s.phase, FocusPhase.idle);
    expect(s.completedInCycle, 0);
    expect(s.outcome!.completed, isFalse);
    expect(s.outcome!.focusedMinutes, 8);
    expect(await sessions.getActive(), isNull);
    final stored = (await sessions.getBetween(t0, clock.now())).single;
    expect(stored.completed, isFalse);
    expect(stored.endedAt, t0.add(const Duration(minutes: 13)));
    expect((await tasks.getById('thesis'))!.actualMinutes, 8);
  });

  test('time up completes at the true end and starts a break', () async {
    final (c, ctrl) = await ready();
    await ctrl.start(taskId: 'thesis');
    clock.advance(const Duration(minutes: 27)); // 2 min past the end
    expect(await ctrl.tick(), FocusTick.sessionOver);

    final s = stateOf(c);
    expect(s.phase, FocusPhase.onBreak);
    expect(s.completedInCycle, 1);
    expect(s.breakEndsAt, t0.add(const Duration(minutes: 30)));
    expect(s.remaining(clock.now()), const Duration(minutes: 3));
    final stored = (await sessions.getBetween(t0, clock.now())).single;
    expect(stored.completed, isTrue);
    expect(stored.endedAt, t0.add(const Duration(minutes: 25)));
    expect((await tasks.getById('thesis'))!.actualMinutes, 25);

    clock.advance(const Duration(minutes: 3));
    expect(await ctrl.tick(), FocusTick.breakOver);
    expect(stateOf(c).phase, FocusPhase.idle);
  });

  test('actual minutes accumulate over sessions', () async {
    final (_, ctrl) = await ready();
    await ctrl.start(taskId: 'thesis');
    clock.advance(const Duration(minutes: 10));
    await ctrl.end();
    await ctrl.start(taskId: 'thesis');
    clock.advance(const Duration(minutes: 6));
    await ctrl.end();
    expect((await tasks.getById('thesis'))!.actualMinutes, 16);
  });

  test('fourth session earns a long break, then the cycle resets', () async {
    final (c, ctrl) = await ready();
    for (var i = 0; i < 4; i++) {
      await ctrl.start();
      clock.advance(const Duration(minutes: 25));
      await ctrl.tick();
    }
    var s = stateOf(c);
    expect(s.completedInCycle, 4);
    expect(s.breakLength, const Duration(minutes: 15));
    expect(s.currentNumber, 4);

    await ctrl.start();
    s = stateOf(c);
    expect(s.completedInCycle, 0);
    expect(s.currentNumber, 1);
  });

  test('settings change the lengths (adjustable breaks)', () async {
    final (c, ctrl) = await ready();
    ctrl.updateSettings(
      const FocusSettings(focusMinutes: 50, shortBreakMinutes: 10),
    );
    await ctrl.start();
    clock.advance(const Duration(minutes: 50));
    await ctrl.tick();
    expect(stateOf(c).breakLength, const Duration(minutes: 10));
  });

  test('idle length picker stays within bounds', () async {
    final (c, ctrl) = await ready();
    for (var i = 0; i < 10; i++) {
      ctrl.adjustNextLength(-5);
    }
    expect(stateOf(c).settings.focusMinutes, FocusSettings.minFocusMinutes);
    ctrl.adjustNextLength(5);
    expect(stateOf(c).planned, const Duration(minutes: 10));
  });

  group('restart recovery', () {
    test('a running session is restored from the repository', () async {
      final (first, ctrl) = await ready();
      await ctrl.start(taskId: 'thesis');
      first.dispose();

      clock.advance(const Duration(minutes: 9));
      final (c, _) = await ready();
      final s = stateOf(c);
      expect(s.phase, FocusPhase.focusing);
      expect(s.session!.taskId, 'thesis');
      expect(s.remaining(clock.now()), const Duration(minutes: 16));
    });

    test('a session that ended while closed is finalized', () async {
      final (first, ctrl) = await ready();
      await ctrl.start(taskId: 'thesis');
      first.dispose();

      clock.advance(const Duration(hours: 2));
      final (c, _) = await ready();
      final s = stateOf(c);
      expect(s.phase, FocusPhase.idle); // break also long over
      expect(s.outcome!.completed, isTrue);
      expect(s.completedInCycle, 1);
      expect(await sessions.getActive(), isNull);
      final stored = (await sessions.getBetween(t0, clock.now())).single;
      expect(stored.endedAt, t0.add(const Duration(minutes: 25)));
      expect((await tasks.getById('thesis'))!.actualMinutes, 25);
    });

    test('cycle dots are rebuilt from today\'s completed sessions', () async {
      for (var i = 0; i < 2; i++) {
        final start = t0.subtract(Duration(hours: 3 - i));
        await sessions.start(
          FocusSession(
            id: 's$i',
            plannedMinutes: 25,
            startedAt: start,
            endedAt: start.add(const Duration(minutes: 25)),
            completed: true,
            createdAt: start,
            updatedAt: start,
          ),
        );
      }
      final (c, _) = await ready();
      expect(stateOf(c).completedInCycle, 2);
      expect(stateOf(c).currentNumber, 3);
    });
  });
}
