import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/focus/hard_mode_shield/hard_mode_shield.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(HardModeShieldMethods.channel);
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

  test('requestAuthorization reports what iOS says', () async {
    reply = (_) => true;
    final ok = await MethodChannelHardModeShieldService()
        .requestAuthorization();
    expect(ok, isTrue);
    expect(calls.single.method, 'requestAuthorization');
    expect(calls.single.arguments, isNull);
  });

  test('requestAuthorization reports false when the user declines', () async {
    reply = (_) => false;
    final ok = await MethodChannelHardModeShieldService()
        .requestAuthorization();
    expect(ok, isFalse);
  });

  test('isAuthorized reads the OS state without prompting', () async {
    reply = (_) => true;
    expect(await MethodChannelHardModeShieldService().isAuthorized(), isTrue);
    expect(calls.single.method, 'isAuthorized');
    expect(calls.single.arguments, isNull);
  });

  test('enable sends the full set of application tokens', () async {
    reply = (_) => true;
    final ok = await MethodChannelHardModeShieldService().enable(
      applicationTokens: const ['token-a', 'token-b', 'token-c'],
    );
    expect(ok, isTrue);
    expect(calls.single.method, 'enable');
    expect(calls.single.arguments, {
      'applicationTokens': ['token-a', 'token-b', 'token-c'],
    });
  });

  test('enable reports false when the shield did not go in', () async {
    reply = (_) => false;
    final ok = await MethodChannelHardModeShieldService().enable(
      applicationTokens: const ['token-a'],
    );
    expect(ok, isFalse);
  });

  test(
    'enable with an empty list still reaches iOS (clears the shield)',
    () async {
      reply = (_) => true;
      await MethodChannelHardModeShieldService().enable(
        applicationTokens: const [],
      );
      expect(calls.single.arguments, {'applicationTokens': <String>[]});
    },
  );

  test('disable takes no arguments', () async {
    await MethodChannelHardModeShieldService().disable();
    expect(calls.single.method, 'disable');
    expect(calls.single.arguments, isNull);
  });

  test('platform errors are swallowed', () async {
    reply = (call) => throw PlatformException(code: 'familyControls');
    final service = MethodChannelHardModeShieldService();
    expect(await service.requestAuthorization(), isFalse);
    expect(await service.isAuthorized(), isFalse);
    expect(
      await service.enable(applicationTokens: const ['x']),
      isFalse,
    );
    await service.disable();
    expect(calls, hasLength(4));
  });

  test('a missing plugin is a no-op', () async {
    messenger.setMockMethodCallHandler(channel, null);
    final service = MethodChannelHardModeShieldService();
    expect(await service.requestAuthorization(), isFalse);
    expect(await service.isAuthorized(), isFalse);
    expect(
      await service.enable(applicationTokens: const ['x']),
      isFalse,
    );
    await service.disable();
  });

  test(
    'the no-op service does nothing and reports nothing shielded',
    () async {
      const service = NoopHardModeShieldService();
      expect(await service.requestAuthorization(), isFalse);
      expect(await service.isAuthorized(), isFalse);
      expect(
        await service.enable(applicationTokens: const ['token-a']),
        isFalse,
      );
      await service.disable();
      expect(calls, isEmpty);
    },
  );

  test('off iOS the provider is the no-op service', () {
    // Tests run on the host VM (Linux/macOS), never iOS.
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(
      c.read(hardModeShieldServiceProvider),
      isA<NoopHardModeShieldService>(),
    );
  });

  test('supportsHardMode is false off iOS', () {
    // Tests run on the host VM (Linux/macOS), never iOS.
    expect(supportsHardMode(), isFalse);
  });

  test('every method name the service uses has a constant', () {
    expect(HardModeShieldMethods.all, [
      'requestAuthorization',
      'isAuthorized',
      'enable',
      'disable',
    ]);
    expect(HardModeShieldMethods.keys, ['applicationTokens']);
  });
}
