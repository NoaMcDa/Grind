import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';

void main() {
  final now = DateTime.utc(2026, 11, 4, 8);

  WebPushSubscription sample({
    String deviceId = 'device-1',
    String endpoint = 'https://fcm.googleapis.com/fcm/send/abc',
    String p256dh = 'BNcRdreALRFXTkOOUHK1EtK2wtaz5Ry4YfYCA_0QTpQ',
    String auth = 'tBHItJI5svbpez7KI4CCXg',
    DateTime? createdAt,
    DateTime? expirationTime,
  }) => WebPushSubscription(
    deviceId: deviceId,
    endpoint: endpoint,
    p256dh: p256dh,
    auth: auth,
    createdAt: createdAt ?? now,
    expirationTime: expirationTime,
  );

  group('WebPushSubscription JSON', () {
    test('toJson nests keys and uses ISO-8601 UTC', () {
      final json = sample().toJson();
      expect(json['deviceId'], 'device-1');
      expect(json['endpoint'], 'https://fcm.googleapis.com/fcm/send/abc');
      expect(json['keys'], {
        'p256dh': 'BNcRdreALRFXTkOOUHK1EtK2wtaz5Ry4YfYCA_0QTpQ',
        'auth': 'tBHItJI5svbpez7KI4CCXg',
      });
      expect(json['createdAt'], '2026-11-04T08:00:00.000Z');
      expect(json.containsKey('expirationTime'), isFalse);
    });

    test('toJson includes expirationTime only when set, always UTC', () {
      final local = DateTime(2027, 1, 1, 12).toLocal();
      final json = sample(expirationTime: local).toJson();
      expect(json['expirationTime'], local.toUtc().toIso8601String());
    });

    test('round-trips through fromJson', () {
      final s = sample(expirationTime: DateTime.utc(2027, 2, 3, 4));
      expect(WebPushSubscription.fromJson(s.toJson()), s);
    });

    test('fromJson rejects malformed payloads', () {
      final good = sample().toJson();
      Map<String, Object?> clone() => {
        ...good,
        'keys': Map<String, Object?>.from(good['keys']! as Map),
      };

      for (final mut in <void Function(Map<String, Object?>)>[
        (m) => m['deviceId'] = '',
        (m) => m['deviceId'] = 42,
        (m) => m.remove('deviceId'),
        (m) => m['endpoint'] = 'http://insecure.example/push',
        (m) => m['endpoint'] = 'not-a-url',
        (m) => m['endpoint'] = '/relative/path',
        (m) => m['endpoint'] = 123,
        (m) => m.remove('endpoint'),
        (m) => m.remove('keys'),
        (m) => m['keys'] = 'oops',
        (m) => (m['keys']! as Map).remove('p256dh'),
        (m) => (m['keys']! as Map)['p256dh'] = 'has padding==',
        (m) => (m['keys']! as Map)['p256dh'] = 'has+plus/slash',
        (m) => (m['keys']! as Map)['p256dh'] = '',
        (m) => (m['keys']! as Map)['auth'] = 123,
        (m) => m['createdAt'] = 'yesterday',
        (m) => m.remove('createdAt'),
        (m) => m['createdAt'] = 12345,
        (m) => m['expirationTime'] = 'not a date',
        (m) => m['expirationTime'] = 0,
      ]) {
        final payload = clone();
        mut(payload);
        expect(
          () => WebPushSubscription.fromJson(payload),
          throwsFormatException,
          reason: '$payload should be rejected',
        );
      }
    });

    test(
      'fromJson accepts a mozilla autopush endpoint and Safari endpoint',
      () {
        for (final ep in const [
          'https://updates.push.services.mozilla.com/wpush/v2/gAAAAAB',
          'https://web.push.apple.com/QF7b',
        ]) {
          final json = {...sample().toJson(), 'endpoint': ep};
          expect(WebPushSubscription.fromJson(json).endpoint, ep);
        }
      },
    );
  });

  group('WebPushSubscription behaviour', () {
    test('copyWith keeps deviceId immutable and can clear expirationTime', () {
      final s = sample(expirationTime: now.add(const Duration(days: 30)));
      final rotated = s.copyWith(
        endpoint: 'https://fcm.googleapis.com/fcm/send/xyz',
        p256dh: 'otherKeyAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
        auth: 'otherAuthAAAAAAAAAAAAAA',
        createdAt: now.add(const Duration(days: 30)),
      );
      expect(rotated.deviceId, s.deviceId);
      expect(rotated.endpoint.endsWith('xyz'), isTrue);
      expect(rotated.expirationTime, s.expirationTime);
      expect(rotated.copyWith(expirationTime: null).expirationTime, isNull);
    });

    test('isExpired uses expirationTime inclusively', () {
      final exp = now.add(const Duration(days: 7));
      final s = sample(expirationTime: exp);
      expect(s.isExpired(now), isFalse);
      expect(s.isExpired(exp.subtract(const Duration(seconds: 1))), isFalse);
      expect(s.isExpired(exp), isTrue);
      expect(s.isExpired(exp.add(const Duration(days: 1))), isTrue);
      expect(sample().isExpired(now.add(const Duration(days: 365))), isFalse);
    });

    test('equality is by value across every field', () {
      expect(sample(), sample());
      expect(sample().hashCode, sample().hashCode);
      expect(
        sample(endpoint: 'https://fcm.googleapis.com/fcm/send/other'),
        isNot(sample()),
      );
    });
  });
}
