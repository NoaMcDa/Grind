import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/focus/live_activity/live_activity.dart';
import 'package:grind/features/focus/providers.dart';

/// The focus controller drives the Live Activity through the real method
/// channel implementation over a mock channel, so these tests pin the exact
/// call sequence iOS receives.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(LiveActivityMethods.channel);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  final t0 = DateTime.utc(2026, 11, 3, 8);
  int ms(DateTime d) => d.millisecondsSinceEpoch;

  late FixedClock clock;
  late InMemoryTaskRepository tasks;
  late InMemoryFocusSessionRepository sessions;
  late InMemoryPreferencesRepository prefs;
  late List<MethodCall> calls;

  setUp(() {
    clock = FixedClock(t0);
    tasks = InMemoryTaskRepository([
      Task(id: 'thesis', title: 'Thesis', createdAt: t0, updatedAt: t0),
    ]);
    sessions = InMemoryFocusSessionRepository();
    prefs = InMemoryPreferencesRepository(
      const Preferences(pipAccessory: 'crown'),
    );
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'start' ? true : null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  ProviderContainer makeContainer({bool live = true}) {
    final c = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(clock),
        taskRepositoryProvider.overrideWithValue(tasks),
        focusSessionRepositoryProvider.overrideWithValue(sessions),
        preferencesRepositoryProvider.overrideWithValue(prefs),
        if (live)
          liveActivityServiceProvider.overrideWithValue(
            MethodChannelLiveActivityService(),
          ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<FocusController> ready(ProviderContainer c) async {
    await c.read(focusControllerProvider.future);
    return c.read(focusControllerProvider.notifier);
  }

  List<String> methods() => calls.map((c) => c.method).toList();
  Map<Object?, Object?> args(int i) =>
      calls[i].arguments as Map<Object?, Object?>;

  test('start, pause, resume, +5 min and end reach iOS in order', () async {
    final ctrl = await ready(makeContainer());
    await ctrl.liveActivitySettled;
    // Launch with no active session clears any leftover activity.
    expect(methods(), ['end']);
    calls.clear();

    await ctrl.start(taskId: 'thesis');
    final end = t0.add(const Duration(minutes: 25));

    clock.advance(const Duration(minutes: 10));
    await ctrl.pause();
    final pausedAt = clock.now();

    clock.advance(const Duration(minutes: 3));
    await ctrl.resume();
    final resumedEnd = end.add(const Duration(minutes: 3));

    await ctrl.extend();
    final extendedEnd = resumedEnd.add(const Duration(minutes: 5));

    await ctrl.end();
    await ctrl.liveActivitySettled;

    expect(methods(), ['start', 'update', 'update', 'update', 'end']);
    expect(args(0), {
      'taskTitle': 'Thesis',
      'endDateMs': ms(end),
      'accessory': 'crown',
      'pausedAtMs': null,
      'focusingLabel': 'Focusing',
      'pausedLabel': 'Paused',
    });
    expect(args(1), {
      'paused': true,
      'endDateMs': ms(end),
      'pausedAtMs': ms(pausedAt),
    });
    expect(args(2), {
      'paused': false,
      'endDateMs': ms(resumedEnd),
      'pausedAtMs': null,
    });
    expect(args(3), {
      'paused': false,
      'endDateMs': ms(extendedEnd),
      'pausedAtMs': null,
    });
  });

  test('a free session uses the localized free-focus title', () async {
    prefs = InMemoryPreferencesRepository(const Preferences(localeCode: 'he'));
    final ctrl = await ready(makeContainer());
    await ctrl.start();
    await ctrl.liveActivitySettled;
    final start = calls.firstWhere((c) => c.method == 'start');
    final a = start.arguments as Map<Object?, Object?>;
    expect(a['taskTitle'], isNot('Free focus'));
    expect(a['taskTitle'], isNotEmpty);
    expect(a['focusingLabel'], isNot('Focusing'));
  });

  test('+5 min while paused keeps the activity paused', () async {
    final ctrl = await ready(makeContainer());
    await ctrl.start(taskId: 'thesis');
    clock.advance(const Duration(minutes: 5));
    await ctrl.pause();
    final pausedAt = clock.now();
    await ctrl.extend();
    await ctrl.liveActivitySettled;
    final last = calls.last;
    expect(last.method, 'update');
    expect(last.arguments, {
      'paused': true,
      'endDateMs': ms(t0.add(const Duration(minutes: 30))),
      'pausedAtMs': ms(pausedAt),
    });
  });

  test('the timer running out ends the activity; breaks show none', () async {
    final ctrl = await ready(makeContainer());
    await ctrl.start(taskId: 'thesis');
    clock.advance(const Duration(minutes: 25));
    expect(await ctrl.tick(), FocusTick.sessionOver);
    clock.advance(const Duration(minutes: 5));
    expect(await ctrl.tick(), FocusTick.breakOver);
    await ctrl.liveActivitySettled;
    expect(methods(), ['end', 'start', 'end']);
  });

  test('starting over a running session ends it, then starts', () async {
    final ctrl = await ready(makeContainer());
    await ctrl.start(taskId: 'thesis');
    await ctrl.start();
    await ctrl.liveActivitySettled;
    expect(methods(), ['end', 'start', 'end', 'start']);
  });

  test('a restart while paused re-shows the activity frozen', () async {
    final first = await ready(makeContainer());
    await first.start(taskId: 'thesis');
    clock.advance(const Duration(minutes: 7));
    await first.pause();
    final pausedAt = clock.now();
    await first.liveActivitySettled;
    calls.clear();

    clock.advance(const Duration(minutes: 30));
    final second = await ready(makeContainer());
    await second.liveActivitySettled;
    expect(methods(), ['start']);
    expect(args(0)['pausedAtMs'], ms(pausedAt));
    expect(args(0)['endDateMs'], ms(t0.add(const Duration(minutes: 25))));
  });

  test('platform errors never break the timer', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      throw PlatformException(code: 'activityKit');
    });
    final c = makeContainer();
    final ctrl = await ready(c);
    await ctrl.start(taskId: 'thesis');
    await ctrl.pause();
    await ctrl.resume();
    await ctrl.end();
    await ctrl.liveActivitySettled;
    expect(methods(), ['end', 'start', 'update', 'update', 'end']);
    expect(c.read(focusControllerProvider).requireValue.phase, isNot(null));
  });

  test('off iOS (default provider) nothing reaches the channel', () async {
    final ctrl = await ready(makeContainer(live: false));
    await ctrl.start(taskId: 'thesis');
    await ctrl.pause();
    await ctrl.resume();
    await ctrl.extend();
    await ctrl.end();
    await ctrl.liveActivitySettled;
    expect(calls, isEmpty);
  });
}
