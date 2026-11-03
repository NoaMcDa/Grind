import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'notification_store.dart';

/// [NotificationStore] as JSON files under the app support directory.
/// Not available on web (imported only from the io factory).
class FileNotificationStore implements NotificationStore {
  FileNotificationStore({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _directory;

  Future<File> _file(String name) async {
    final dir = await _directory();
    if (!await dir.exists()) await dir.create(recursive: true);
    return File(p.join(dir.path, name));
  }

  @override
  Future<String?> read(String name) async {
    final f = await _file(name);
    return await f.exists() ? f.readAsString() : null;
  }

  @override
  Future<void> write(String name, String contents) async {
    final f = await _file(name);
    // Write then rename so a kill mid-write never leaves half a file.
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(contents, flush: true);
    await tmp.rename(f.path);
  }

  @override
  Future<void> delete(String name) async {
    final f = await _file(name);
    if (await f.exists()) await f.delete();
  }
}
