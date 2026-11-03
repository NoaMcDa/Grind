import 'json_doc_store_stub.dart'
    if (dart.library.js_interop) 'json_doc_store_web.dart'
    if (dart.library.io) 'json_doc_store_io.dart';

/// A tiny named-string store for the capacity feature's JSON documents
/// (the preference log, the weights). iOS: a file in the app documents
/// directory (`path_provider`). Web: `window.localStorage`. Tests:
/// [InMemoryJsonDocStore].
///
/// Reads and writes never throw: a store that cannot reach the platform
/// (no plugin, blocked storage) behaves like an empty one.
abstract interface class JsonDocStore {
  Future<String?> read(String name);
  Future<void> write(String name, String value);
}

class InMemoryJsonDocStore implements JsonDocStore {
  InMemoryJsonDocStore([Map<String, String>? seed]) : docs = {...?seed};

  final Map<String, String> docs;

  @override
  Future<String?> read(String name) async => docs[name];

  @override
  Future<void> write(String name, String value) async => docs[name] = value;
}

/// The platform store (file on iOS, localStorage on web).
JsonDocStore platformJsonDocStore() => createPlatformJsonDocStore();
