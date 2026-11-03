import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/calendar/apple/apple_calendar.dart';

/// The Swift plugin cannot be compiled here (no Mac), so these string checks
/// keep the two sides of the channel from drifting silently.
void main() {
  final swift = File('ios/Runner/AppleCalendarPlugin.swift').readAsStringSync();

  test('Swift handles every method the Dart side calls', () {
    for (final method in AppleCalendarMethods.all) {
      expect(swift, contains('case "$method":'), reason: method);
    }
  });

  test('channel names and the change event match', () {
    expect(swift, contains('"${AppleCalendarMethods.channel}"'));
    expect(swift, contains('"${AppleCalendarMethods.changesChannel}"'));
    expect(swift, contains('"${AppleCalendarMethods.changeEvent}"'));
    expect(swift, contains('EKEventStoreChanged'));
  });

  test('Swift reads and writes the map keys Dart uses', () {
    const keys = [
      // arguments
      'calendarIds', 'fromMs', 'toMs', 'calendarId', 'eventId', 'title',
      'startMs', 'endMs', 'notes', 'taskId',
      // calendar maps
      'id', 'allowsContentModifications', 'isPrimary',
      // event maps
      'eventIdentifier', 'calendarIdentifier', 'isAllDay', 'isBusy',
      'isRecurring', 'url', 'createdMs', 'updatedMs',
    ];
    for (final key in keys) {
      expect(swift, contains('"$key"'), reason: key);
    }
  });

  test('Swift reports every status Dart parses', () {
    for (final status in AppleAuthStatus.values) {
      expect(swift, contains('"${status.name}"'), reason: status.name);
    }
  });

  test('Swift uses the iOS 17 APIs with a fallback', () {
    expect(swift, contains('requestFullAccessToEvents'));
    expect(swift, contains('requestWriteOnlyAccessToEvents'));
    expect(swift, contains('#available(iOS 17.0, *)'));
    expect(swift, contains('requestAccess(to: .event'));
  });

  test('Swift writes the same URL marker Dart parses', () {
    expect(swift, contains('grind://task/'));
    expect(WriteBackMarker.parse(url: WriteBackMarker.urlFor('abc')), 'abc');
  });

  test('plugin is registered and compiled, usage strings exist', () {
    final delegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    expect(delegate, contains('AppleCalendarPlugin.register'));
    expect(delegate, contains('FlutterLocalNotificationsPlugin'));

    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    expect(project, contains('AppleCalendarPlugin.swift in Sources'));

    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    for (final key in const [
      'NSCalendarsFullAccessUsageDescription',
      'NSCalendarsWriteOnlyAccessUsageDescription',
      'NSCalendarsUsageDescription',
    ]) {
      expect(plist, contains('<key>$key</key>'), reason: key);
    }
  });
}
