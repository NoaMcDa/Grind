/// The schema for a Web Push subscription Grind stores per device, so that a
/// future server can sign notifications with VAPID and POST them to the push
/// endpoint when the tab is closed (see `docs/web/push-limits.md`, issue #47).
///
/// The shape mirrors what `PushSubscription.toJSON()` returns in the browser
/// plus the fields the server needs to route and prune: a stable [deviceId]
/// generated client-side, [createdAt] for rotation, and an optional
/// [expirationTime] some push services supply.
///
/// This file is pure Dart on purpose. The browser-side `PushManager.subscribe`
/// call lands later; keeping the model here lets the repository, the
/// serializer and the tests ship first without pulling in `dart:js_interop`.
class WebPushSubscription {
  const WebPushSubscription({
    required this.deviceId,
    required this.endpoint,
    required this.p256dh,
    required this.auth,
    required this.createdAt,
    this.expirationTime,
  });

  /// A stable id for the device/browser profile, generated client-side (UUID).
  /// Lets the server replace a prior subscription for the same device instead
  /// of sending twice when the browser rotates the endpoint.
  final String deviceId;

  /// The push-service URL the server POSTs to. Different per browser:
  /// `https://fcm.googleapis.com/...` for Chrome, `https://web.push.apple.com/...`
  /// for Safari, Mozilla's autopush for Firefox. Must be an absolute HTTPS URL.
  final String endpoint;

  /// The client's ECDH public key, base64url without padding. Used by the
  /// server to encrypt the payload per RFC 8291.
  final String p256dh;

  /// The 16-byte auth secret, base64url without padding. Used alongside
  /// [p256dh] by the encryption step.
  final String auth;

  /// When this subscription was recorded on the client. The server uses it to
  /// prune stale subscriptions when the push service returns 404/410.
  final DateTime createdAt;

  /// Optional expiration the push service hints at. Null means "no known
  /// expiry"; Chrome and Firefox usually omit it, Safari sometimes sets it.
  final DateTime? expirationTime;

  WebPushSubscription copyWith({
    String? endpoint,
    String? p256dh,
    String? auth,
    DateTime? createdAt,
    Object? expirationTime = _unset,
  }) => WebPushSubscription(
    deviceId: deviceId,
    endpoint: endpoint ?? this.endpoint,
    p256dh: p256dh ?? this.p256dh,
    auth: auth ?? this.auth,
    createdAt: createdAt ?? this.createdAt,
    expirationTime: expirationTime == _unset
        ? this.expirationTime
        : expirationTime as DateTime?,
  );

  /// Writes the shape the server stores and that `fromJson` reads back. Keys
  /// are nested under `keys` to mirror the browser's `PushSubscription.toJSON`
  /// so a future `js_interop` layer can pass the subscription through with
  /// only the three top-level fields to add.
  Map<String, Object?> toJson() => {
    'deviceId': deviceId,
    'endpoint': endpoint,
    'keys': {'p256dh': p256dh, 'auth': auth},
    'createdAt': createdAt.toUtc().toIso8601String(),
    if (expirationTime != null)
      'expirationTime': expirationTime!.toUtc().toIso8601String(),
  };

  /// Reads the shape [toJson] writes. Validates every field explicitly so a
  /// malformed row from storage or the wire throws [FormatException] instead
  /// of surfacing as a cast error deep in the push pipeline.
  factory WebPushSubscription.fromJson(Map<String, Object?> json) {
    final deviceId = json['deviceId'];
    final endpoint = json['endpoint'];
    final keys = json['keys'];
    final createdAtRaw = json['createdAt'];
    if (deviceId is! String || deviceId.isEmpty) {
      throw const FormatException('deviceId must be a non-empty string.');
    }
    if (endpoint is! String || !_isHttpsUrl(endpoint)) {
      throw FormatException(
        'endpoint must be an absolute https:// URL, got $endpoint.',
      );
    }
    if (keys is! Map) {
      throw const FormatException(
        'keys must be an object with p256dh and auth.',
      );
    }
    final p256dh = keys['p256dh'];
    final auth = keys['auth'];
    if (p256dh is! String || !_isBase64Url(p256dh)) {
      throw const FormatException(
        'keys.p256dh must be a base64url string (no padding).',
      );
    }
    if (auth is! String || !_isBase64Url(auth)) {
      throw const FormatException(
        'keys.auth must be a base64url string (no padding).',
      );
    }
    if (createdAtRaw is! String) {
      throw const FormatException('createdAt must be an ISO-8601 string.');
    }
    final createdAt = DateTime.tryParse(createdAtRaw);
    if (createdAt == null) {
      throw FormatException(
        'createdAt is not a valid ISO-8601: $createdAtRaw.',
      );
    }
    DateTime? expirationTime;
    final expRaw = json['expirationTime'];
    if (expRaw != null) {
      if (expRaw is! String) {
        throw const FormatException(
          'expirationTime must be an ISO-8601 string or absent.',
        );
      }
      expirationTime = DateTime.tryParse(expRaw);
      if (expirationTime == null) {
        throw FormatException(
          'expirationTime is not a valid ISO-8601: $expRaw.',
        );
      }
    }
    return WebPushSubscription(
      deviceId: deviceId,
      endpoint: endpoint,
      p256dh: p256dh,
      auth: auth,
      createdAt: createdAt,
      expirationTime: expirationTime,
    );
  }

  /// True when [now] is at or past [expirationTime]. Subscriptions without an
  /// expiry never expire by this check; the push service's 410 response is
  /// the only other signal the server has.
  bool isExpired(DateTime now) {
    final exp = expirationTime;
    return exp != null && !now.isBefore(exp);
  }

  @override
  bool operator ==(Object other) =>
      other is WebPushSubscription &&
      other.deviceId == deviceId &&
      other.endpoint == endpoint &&
      other.p256dh == p256dh &&
      other.auth == auth &&
      other.createdAt == createdAt &&
      other.expirationTime == expirationTime;

  @override
  int get hashCode =>
      Object.hash(deviceId, endpoint, p256dh, auth, createdAt, expirationTime);

  @override
  String toString() => 'WebPushSubscription($deviceId, $endpoint)';
}

bool _isHttpsUrl(String s) {
  final uri = Uri.tryParse(s);
  return uri != null && uri.isAbsolute && uri.scheme == 'https';
}

/// Base64url without padding: [A-Za-z0-9_-]+, at least one char.
final _base64UrlRe = RegExp(r'^[A-Za-z0-9_-]+$');
bool _isBase64Url(String s) => s.isNotEmpty && _base64UrlRe.hasMatch(s);

const _unset = Object();
