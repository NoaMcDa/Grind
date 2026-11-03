import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'key_value_store.dart';

KeyValueStore createPlatformKeyValueStore() => SecureKeyValueStore();

/// Keychain-backed store (iOS). Survives app restarts, not reinstalls.
class SecureKeyValueStore implements KeyValueStore {
  SecureKeyValueStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deletePrefix(String prefix) async {
    final all = await _storage.readAll();
    for (final k in all.keys.where((k) => k.startsWith(prefix))) {
      await _storage.delete(key: k);
    }
  }
}
