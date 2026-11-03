import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'json_doc_store.dart';

JsonDocStore createPlatformJsonDocStore() => FileJsonDocStore();

/// One `grind_<name>.json` file per document in the app documents folder.
class FileJsonDocStore implements JsonDocStore {
  FileJsonDocStore([Future<Directory> Function()? dir])
    : _dir = dir ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _dir;

  Future<File> _file(String name) async =>
      File('${(await _dir()).path}/grind_$name.json');

  @override
  Future<String?> read(String name) async {
    try {
      final f = await _file(name);
      return await f.exists() ? await f.readAsString() : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String name, String value) async {
    try {
      await (await _file(name)).writeAsString(value, flush: true);
    } catch (_) {
      // Best effort: the log is a hint for a future ranker, not user data.
    }
  }
}
