import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/focus/live_activity/live_activity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(LiveActivityMethods.channel);
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

  test('start sends title, end, accessory and labels', () async {
    reply = (_) => true;
    final shown = await MethodChannelLiveActivityService().start(
      taskTitle: 'Thesis',
      endDate: end,
      accessory: 'scarf',
      focusingLabel: 'Focusing',
      pausedLabel: 'Paused',
    );
    expect(shown, isTrue);
    expect(calls.single.method, 'start');
    expect(calls.single.arguments, {
      'taskTitle': 'Thesis',
      'endDateMs': end.millisecondsSinceEpoch,
      'accessory': 'scarf',
      'pausedAtMs': null,
      'focusingLabel': 'Focusing',
      'pausedLabel': 'Paused',
    });
  });

  test('start reports false when iOS shows nothing', () async {
    reply = (_) => false;
    final shown = await MethodChannelLiveActivityService().start(
      taskTitle: 'Thesis',
      endDate: end,
    );
    expect(shown, isFalse);
  });

  test('update sends the pause time only while paused', () async {
    final service = MethodChannelLiveActivityService();
    await service.update(paused: true, endDate: end, pausedAt: pausedAt);
    await service.update(paused: false, endDate: end, pausedAt: pausedAt);
    expect(calls.map((c) => c.method), ['update', 'update']);
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

  test('end takes no arguments', () async {
    await MethodChannelLiveActivityService().end();
    expect(calls.single.method, 'end');
    expect(calls.single.arguments, isNull);
  });

  test('platform errors are swallowed', () async {
    reply = (call) => throw PlatformException(code: 'activityKit');
    final service = MethodChannelLiveActivityService();
    expect(await service.start(taskTitle: 'x', endDate: end), isFalse);
    await service.update(paused: true, endDate: end);
    await service.end();
    expect(calls, hasLength(3));
  });

  test('a missing plugin is a no-op', () async {
    messenger.setMockMethodCallHandler(channel, null);
    final service = MethodChannelLiveActivityService();
    expect(await service.start(taskTitle: 'x', endDate: end), isFalse);
    await service.update(paused: false, endDate: end);
    await service.end();
  });

  test('the no-op service does nothing and reports nothing shown', () async {
    const service = NoopLiveActivityService();
    expect(await service.start(taskTitle: 'x', endDate: end), isFalse);
    await service.update(paused: true, endDate: end);
    await service.end();
    expect(calls, isEmpty);
  });

  test('off iOS the provider is the no-op service', () {
    // Tests run on the host VM (Linux/macOS), never iOS.
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(liveActivityServiceProvider), isA<NoopLiveActivityService>());
  });

  test('the deep link path is the Focus tab route', () {
    final uri = Uri.parse(LiveActivityMethods.deepLink);
    expect(uri.scheme, 'grind');
    expect(uri.path, '/focus');
  });
}
