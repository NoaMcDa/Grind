import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/focus/watch_connectivity/watch_connectivity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(WatchConnectivityMethods.channel);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];
  Object? Function(MethodCall call) reply = (_) => null;

  setUp(() {
    calls.clear();
    reply = (_) => null;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return reply(call);
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  final end = DateTime.utc(2026, 11, 3, 8, 25);
  final pausedAt = DateTime.utc(2026, 11, 3, 8, 10);
  final eventAt = DateTime.utc(2026, 11, 3, 8, 12);

  test('startSession sends title, end and no pause by default', () async {
    reply = (_) => true;
    final service = MethodChannelWatchConnectivityService();
    addTearDown(service.dispose);
    final mirrored = await service.startSession(
      taskTitle: 'Thesis',
      endDate: end,
    );
    expect(mirrored, isTrue);
    expect(calls.single.method, 'startSession');
    expect(calls.single.arguments, {
      'taskTitle': 'Thesis',
      'endDateMs': end.millisecondsSinceEpoch,
      'pausedAtMs': null,
    });
  });

  test(
    'startSession forwards pausedAt when resuming after a restart',
    () async {
      reply = (_) => true;
      final service = MethodChannelWatchConnectivityService();
      addTearDown(service.dispose);
      await service.startSession(
        taskTitle: 'Thesis',
        endDate: end,
        pausedAt: pausedAt,
      );
      expect(
        calls.single.arguments,
        containsPair('pausedAtMs', pausedAt.millisecondsSinceEpoch),
      );
    },
  );

  test('startSession reports false when nothing was mirrored', () async {
    reply = (_) => false;
    final service = MethodChannelWatchConnectivityService();
    addTearDown(service.dispose);
    expect(await service.startSession(taskTitle: 'x', endDate: end), isFalse);
  });

  test('updateSession sends the pause time only while paused', () async {
    final service = MethodChannelWatchConnectivityService();
    addTearDown(service.dispose);
    await service.updateSession(paused: true, endDate: end, pausedAt: pausedAt);
    await service.updateSession(
      paused: false,
      endDate: end,
      pausedAt: pausedAt,
    );
    expect(calls.map((c) => c.method), ['updateSession', 'updateSession']);
    expect(calls[0].arguments, {
      'paused': true,
      'endDateMs': end.millisecondsSinceEpoch,
      'pausedAtMs': pausedAt.millisecondsSinceEpoch,
    });
    expect(calls[1].arguments, {
      'paused': false,
      'endDateMs': end.millisecondsSinceEpoch,
      'pausedAtMs': null,
    });
  });

  test('endSession takes no arguments', () async {
    final service = MethodChannelWatchConnectivityService();
    addTearDown(service.dispose);
    await service.endSession();
    expect(calls.single.method, 'endSession');
    expect(calls.single.arguments, isNull);
  });

  test('platform errors are swallowed', () async {
    reply = (_) => throw PlatformException(code: 'watchConnectivity');
    final service = MethodChannelWatchConnectivityService();
    addTearDown(service.dispose);
    expect(await service.startSession(taskTitle: 'x', endDate: end), isFalse);
    await service.updateSession(paused: true, endDate: end);
    await service.endSession();
    expect(calls, hasLength(3));
  });

  test('a missing plugin is a no-op', () async {
    messenger.setMockMethodCallHandler(channel, null);
    final service = MethodChannelWatchConnectivityService();
    addTearDown(service.dispose);
    expect(await service.startSession(taskTitle: 'x', endDate: end), isFalse);
    await service.updateSession(paused: false, endDate: end);
    await service.endSession();
  });

  test('incoming sessionEvent is parsed and broadcast', () async {
    final service = MethodChannelWatchConnectivityService();
    addTearDown(service.dispose);
    final seen = <WatchSessionEvent>[];
    final sub = service.events().listen(seen.add);
    addTearDown(sub.cancel);

    void deliver(Map<String, Object?> args) => service.handleIncoming(
      MethodCall(WatchConnectivityMethods.sessionEvent, args),
    );

    deliver({
      'kind': 'start',
      'taskId': 't-1',
      'atMs': eventAt.millisecondsSinceEpoch,
    });
    deliver({'kind': 'stop', 'atMs': eventAt.millisecondsSinceEpoch});
    deliver({'kind': 'nope'}); // unknown kind: dropped
    deliver(const {}); // missing kind: dropped
    // Unknown method names on the same channel are also dropped.
    service.handleIncoming(const MethodCall('other', {'kind': 'start'}));

    // Give the broadcast controller a microtask to deliver each event.
    await Future<void>.delayed(Duration.zero);

    expect(seen, [
      WatchSessionEvent(
        kind: WatchSessionEventKind.start,
        taskId: 't-1',
        at: eventAt,
      ),
      WatchSessionEvent(kind: WatchSessionEventKind.stop, at: eventAt),
    ]);
  });

  test('the no-op service does nothing and emits no events', () async {
    const service = NoopWatchConnectivityService();
    expect(await service.startSession(taskTitle: 'x', endDate: end), isFalse);
    await service.updateSession(paused: true, endDate: end);
    await service.endSession();
    expect(await service.events().isEmpty, isTrue);
    expect(calls, isEmpty);
  });

  test('off iOS the provider is the no-op service', () {
    // Tests run on the host VM (Linux/macOS), never iOS.
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(
      c.read(watchConnectivityServiceProvider),
      isA<NoopWatchConnectivityService>(),
    );
  });

  test('the method and arg keys match what the Swift bridge expects', () {
    expect(WatchConnectivityMethods.channel, 'grind/watch_connectivity');
    expect(
      WatchConnectivityMethods.outgoing,
      containsAll(<String>['startSession', 'updateSession', 'endSession']),
    );
    expect(WatchConnectivityMethods.sessionEvent, 'sessionEvent');
    expect(
      WatchConnectivityMethods.keys,
      containsAll(<String>[
        'taskTitle',
        'taskId',
        'endDateMs',
        'paused',
        'pausedAtMs',
        'atMs',
        'kind',
      ]),
    );
  });

  test('WatchSessionEvent equality covers kind, taskId and at', () {
    final a = WatchSessionEvent(
      kind: WatchSessionEventKind.start,
      taskId: 't',
      at: eventAt,
    );
    final b = WatchSessionEvent(
      kind: WatchSessionEventKind.start,
      taskId: 't',
      at: eventAt,
    );
    final c = WatchSessionEvent(
      kind: WatchSessionEventKind.pause,
      taskId: 't',
      at: eventAt,
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(c));
  });
}
