import 'dart:js_interop';

import 'key_value_store.dart';

KeyValueStore createPlatformKeyValueStore() => LocalStorageKeyValueStore();

@JS('localStorage')
external _Storage get _localStorage;

extension type _Storage._(JSObject _) implements JSObject {
  external int get length;
  external String? key(int index);
  external String? getItem(String key);
  external void setItem(String key, String value);
  external void removeItem(String key);
}

/// `window.localStorage` store (web). Per origin, survives reloads.
class LocalStorageKeyValueStore implements KeyValueStore {
  @override
  Future<String?> read(String key) async => _localStorage.getItem(key);

  @override
  Future<void> write(String key, String value) async =>
      _localStorage.setItem(key, value);

  @override
  Future<void> delete(String key) async => _localStorage.removeItem(key);

  @override
  Future<void> deletePrefix(String prefix) async {
    final keys = [
      for (var i = 0; i < _localStorage.length; i++) _localStorage.key(i),
    ].whereType<String>().where((k) => k.startsWith(prefix)).toList();
    for (final k in keys) {
      _localStorage.removeItem(k);
    }
  }
}
