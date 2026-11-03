import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/foundation.dart';

/// File name of the database (native) / database name (web).
const databaseName = 'grind';

/// sqlite3 compiled to WebAssembly, run in a (shared) web worker. Drift picks
/// the most durable storage the browser offers (OPFS, else IndexedDB).
///
/// `sqlite3.wasm` and `drift_worker.js` are served from `web/`; their
/// versions must match the `sqlite3` and `drift` packages in pubspec.lock.
QueryExecutor openConnection({String name = databaseName}) =>
    DatabaseConnection.delayed(
      Future(() async {
        final result = await WasmDatabase.open(
          databaseName: name,
          sqlite3Uri: Uri.parse('sqlite3.wasm'),
          driftWorkerUri: Uri.parse('drift_worker.js'),
        );
        if (result.missingFeatures.isNotEmpty) {
          debugPrint(
            'Grind db: using ${result.chosenImplementation}; '
            'browser lacks ${result.missingFeatures}.',
          );
        }
        return result.resolvedExecutor;
      }),
    );
