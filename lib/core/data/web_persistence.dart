/// Web durability: ask the browser not to evict Grind's storage.
///
/// Browsers may clear IndexedDB/OPFS under storage pressure unless the
/// origin holds a persistent-storage grant. Safari also deletes script-
/// writable storage after 7 days without a visit unless the site is
/// installed to the home screen. Since local storage is the only copy of the
/// user's data, call [requestPersistentStorage] at startup and nudge the user
/// to export a backup (see docs/adr/0001-local-database.md).
library;

export 'web_persistence_stub.dart'
    if (dart.library.js_interop) 'web_persistence_web.dart';
