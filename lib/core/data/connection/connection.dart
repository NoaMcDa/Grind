/// Opens the on-device database for the current platform.
///
/// - iOS (and other native targets): a sqlite3 file `grind.sqlite` in the
///   app documents directory, opened on a background isolate.
/// - Web: sqlite3 compiled to wasm, persisted in OPFS or IndexedDB
///   (whichever the browser supports best). Needs `web/sqlite3.wasm` and
///   `web/drift_worker.js`, see docs/adr/0001-local-database.md.
///
/// Tests use `NativeDatabase.memory()` (see `memory.dart`, which is not
/// exported because it pulls in `dart:ffi`).
library;

export 'unsupported.dart'
    if (dart.library.ffi) 'native.dart'
    if (dart.library.js_interop) 'web.dart';
