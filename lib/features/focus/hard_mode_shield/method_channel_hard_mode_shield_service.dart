import 'package:flutter/services.dart';

import '../../../app/logging.dart';
import 'hard_mode_shield_service.dart';

/// Names shared with the (future) `ios/Runner/HardModeShieldPlugin.swift`. A
/// contract test will check the Swift side uses the same strings once the
/// plugin lands. Keeping them in one place now means the native work and
/// the Dart work can start in parallel.
abstract final class HardModeShieldMethods {
  static const channel = 'grind/hard_mode_shield';

  /// Ask for the Family Controls authorization. No arguments. Returns a
  /// bool: true when authorized after the prompt.
  static const requestAuthorization = 'requestAuthorization';

  /// Read the current authorization state. No arguments. Returns a bool.
  static const isAuthorized = 'isAuthorized';

  /// Install the shield on the given application tokens. Takes
  /// [applicationTokens]. Returns a bool: true when the shield is in place.
  static const enable = 'enable';

  /// Remove the shield. No arguments.
  static const disable = 'disable';

  static const all = [requestAuthorization, isAuthorized, enable, disable];

  /// Argument keys.
  static const applicationTokens = 'applicationTokens';
  static const keys = [applicationTokens];
}

/// [HardModeShieldService] over the `grind/hard_mode_shield` method channel.
/// iOS only; [hardModeShieldServiceProvider] picks it there. Swallows
/// platform errors (a missing plugin, Family Controls refusing, the user
/// not authorizing) so the timer never fails because of the shield.
class MethodChannelHardModeShieldService implements HardModeShieldService {
  MethodChannelHardModeShieldService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(HardModeShieldMethods.channel);

  final MethodChannel _channel;

  Future<T?> _invoke<T>(String method, [Map<String, Object?>? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException catch (e, st) {
      log('hard mode shield $method failed', error: e, stackTrace: st);
    } on MissingPluginException {
      // Plugin not registered (older build, Android, or a background isolate).
    }
    return null;
  }

  @override
  Future<bool> requestAuthorization() async {
    final ok = await _invoke<bool>(HardModeShieldMethods.requestAuthorization);
    return ok ?? false;
  }

  @override
  Future<bool> isAuthorized() async {
    final ok = await _invoke<bool>(HardModeShieldMethods.isAuthorized);
    return ok ?? false;
  }

  @override
  Future<bool> enable({required List<String> applicationTokens}) async {
    final ok = await _invoke<bool>(HardModeShieldMethods.enable, {
      HardModeShieldMethods.applicationTokens: applicationTokens,
    });
    return ok ?? false;
  }

  @override
  Future<void> disable() => _invoke<void>(HardModeShieldMethods.disable);
}
