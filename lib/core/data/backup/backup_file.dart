import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import 'backup_service.dart';

/// The real [BackupFileGateway]:
/// - iOS: the share sheet (save to Files, AirDrop, mail, ...).
/// - Web: a browser download of the `.json` file.
/// - Import everywhere: the system file picker, `.json` only.
///
/// Not unit-tested (platform channels); see the test plan in
/// docs/adr/0001-local-database.md.
class PlatformBackupFileGateway implements BackupFileGateway {
  const PlatformBackupFileGateway();

  static const _mime = 'application/json';

  @override
  Future<void> save({
    required String fileName,
    required String contents,
  }) async {
    final file = XFile.fromData(
      Uint8List.fromList(utf8.encode(contents)),
      mimeType: _mime,
      name: fileName,
    );
    if (kIsWeb) {
      // cross_file's web XFile.saveTo triggers an <a download> click.
      await file.saveTo(fileName);
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        files: [file],
        fileNameOverrides: [fileName],
        subject: 'Grind backup',
      ),
    );
  }

  @override
  Future<String?> pick() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    final bytes = result?.files.singleOrNull?.bytes;
    if (bytes == null) return null;
    return utf8.decode(bytes);
  }
}
