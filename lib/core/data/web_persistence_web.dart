import 'dart:js_interop';

import 'package:flutter/foundation.dart';

@JS('navigator.storage')
external _StorageManager? get _storage;

/// The bits of `StorageManager` we use. `package:web` is not a direct
/// dependency, so a tiny extension type is enough.
extension type _StorageManager._(JSObject _) implements JSObject {
  external JSPromise<JSBoolean> persist();
  external JSPromise<JSBoolean> persisted();
}

/// Calls `navigator.storage.persist()` unless already granted. Returns
/// whether storage is persistent. Never throws: false when unsupported.
Future<bool> requestPersistentStorage() async {
  if (!kIsWeb) return true;
  try {
    final storage = _storage;
    if (storage == null) return false;
    if ((await storage.persisted().toDart).toDart) return true;
    return (await storage.persist().toDart).toDart;
  } catch (e) {
    debugPrint('Grind: navigator.storage.persist() failed: $e');
    return false;
  }
}

/// Whether the browser has granted persistent storage. False when unknown.
Future<bool> isStoragePersisted() async {
  if (!kIsWeb) return true;
  try {
    final storage = _storage;
    if (storage == null) return false;
    return (await storage.persisted().toDart).toDart;
  } catch (_) {
    return false;
  }
}
