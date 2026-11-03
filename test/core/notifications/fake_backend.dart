import 'dart:convert';

import 'package:grind/core/notifications/notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Records what the service asks of the plugin.
class FakeBackend implements LocalNotificationsBackend {
  final Map<int, ({tz.TZDateTime at, String payload, String? category})>
  pending = {};
  void Function(RawNotificationResponse)? onResponse;
  RawNotificationResponse? launch;
  bool granted = false;
  int initCount = 0;

  @override
  Future<void> initialize({
    required void Function(RawNotificationResponse) onResponse,
  }) async {
    initCount++;
    this.onResponse = onResponse;
  }

  @override
  Future<RawNotificationResponse?> launchResponse() async => launch;

  @override
  Future<bool> requestPermission() async => granted = true;

  @override
  Future<bool> hasPermission() async => granted;

  @override
  Future<void> schedule({
    required int platformId,
    required tz.TZDateTime at,
    required String title,
    required String body,
    required String payload,
    required String? category,
  }) async {
    pending[platformId] = (at: at, payload: payload, category: category);
  }

  @override
  Future<void> cancel(int platformId) async => pending.remove(platformId);

  @override
  Future<void> cancelAllPending() async => pending.clear();

  List<String> get notificationIds => [
    for (final p in pending.values)
      (jsonDecode(p.payload) as Map)['notificationId'] as String,
  ];
}
