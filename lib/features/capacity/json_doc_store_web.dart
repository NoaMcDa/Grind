import 'dart:js_interop';

import 'json_doc_store.dart';

JsonDocStore createPlatformJsonDocStore() => LocalStorageJsonDocStore();

@JS('localStorage')
external _Storage get _localStorage;

extension type _Storage._(JSObject _) implements JSObject {
  external String? getItem(String key);
  external void setItem(String key, String value);
}

/// `window.localStorage` store (web), keys `grind_<name>`.
class LocalStorageJsonDocStore implements JsonDocStore {
  @override
  Future<String?> read(String name) async {
    try {
      return _localStorage.getItem('grind_$name');
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String name, String value) async {
    try {
      _localStorage.setItem('grind_$name', value);
    } catch (_) {}
  }
}
