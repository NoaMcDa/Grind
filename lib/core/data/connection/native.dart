import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// File name of the database (native) / database name (web).
const databaseName = 'grind';

/// `<app documents>/grind.sqlite`, opened lazily on a background isolate.
/// The documents directory is backed up by iCloud/iTunes on iOS and is not
/// purged by the OS, unlike caches.
QueryExecutor openConnection({String name = databaseName}) =>
    LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, '$name.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
