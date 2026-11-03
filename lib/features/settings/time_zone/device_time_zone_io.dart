import 'dart:io' show Platform;

import 'package:flutter_timezone/flutter_timezone.dart';

/// The device zone from the native layer (iOS). Other `dart:io` platforms
/// (tests, desktop tooling) report null.
Future<String?> readDeviceTimeZone() async {
  if (!Platform.isIOS) return null;
  final info = await FlutterTimezone.getLocalTimezone();
  return info.identifier;
}
