import 'key_value_store_stub.dart'
    if (dart.library.js_interop) 'key_value_store_web.dart'
    if (dart.library.io) 'key_value_store_io.dart';

/// Tiny string store for sync state (sync tokens, the mirrored window).
///
/// iOS: `flutter_secure_storage` (Keychain). Web: `window.localStorage`.
/// Tests: [InMemoryKeyValueStore]. No OAuth tokens go here; `google_sign_in`
/// keeps those itself (Keychain on iOS, memory of the GIS session on web).
abstract interface class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);

  /// Delete every key starting with [prefix].
  Future<void> deletePrefix(String prefix);
}

class InMemoryKeyValueStore implements KeyValueStore {
  InMemoryKeyValueStore([Map<String, String>? seed]) : values = {...?seed};

  final Map<String, String> values;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<void> deletePrefix(String prefix) async =>
      values.removeWhere((k, _) => k.startsWith(prefix));
}

/// The platform store: Keychain on iOS, localStorage on web.
KeyValueStore platformKeyValueStore() => createPlatformKeyValueStore();
