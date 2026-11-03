import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/focus/live_activity/live_activity.dart';

/// The Swift side cannot be compiled here (no Mac), so these string checks
/// keep the two sides of the channel from drifting silently.
void main() {
  String read(String path) => File(path).readAsStringSync();
  final plugin = read('ios/Runner/LiveActivityPlugin.swift');
  final attributes = read(
    'ios/GrindLiveActivity/FocusActivityAttributes.swift',
  );
  final widget = read('ios/GrindLiveActivity/FocusLiveActivity.swift');

  test('Swift handles every method the Dart side calls', () {
    expect(plugin, contains('"${LiveActivityMethods.channel}"'));
    for (final method in LiveActivityMethods.all) {
      expect(plugin, contains('case "$method":'), reason: method);
    }
  });

  test('Swift reads every argument key Dart sends', () {
    for (final key in LiveActivityMethods.keys) {
      expect(plugin, contains('args["$key"]'), reason: key);
    }
  });

  test('ActivityKit is guarded for iOS below 16.2', () {
    expect(plugin, contains('#available(iOS 16.2, *)'));
    expect(plugin, contains('@available(iOS 16.2, *)'));
    expect(plugin, contains('#if canImport(ActivityKit)'));
    expect(attributes, contains('ActivityAttributes'));
    expect(attributes, contains('@available(iOS 16.1, *)'));
  });

  test('the widget uses the system countdown and every island layout', () {
    expect(widget, contains('timerInterval:'));
    expect(widget, contains('pauseTime:'));
    for (final part in ['compactLeading:', 'compactTrailing:', 'minimal:']) {
      expect(widget, contains(part), reason: part);
    }
    expect(widget, contains('DynamicIslandExpandedRegion(.bottom)'));
  });

  test('the widget opens the same deep link Dart documents', () {
    expect(widget, contains('"${LiveActivityMethods.deepLink}"'));
    expect(widget, contains('.widgetURL('));
  });

  test('plugin is registered and the app declares Live Activities', () {
    expect(
      read('ios/Runner/AppDelegate.swift'),
      contains('LiveActivityPlugin.register'),
    );
    final plist = read('ios/Runner/Info.plist');
    expect(plist, contains('<key>NSSupportsLiveActivities</key>'));
    expect(plist, contains('<string>grind</string>'));
  });
}
