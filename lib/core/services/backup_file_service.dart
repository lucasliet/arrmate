import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'backup_file_writer.dart';
import 'logger_service.dart';

/// Moves backups through local files: saving a payload through the platform
/// save dialog and reading a payload picked by the user.
class BackupFileService {
  /// File extension carried by exported backup files.
  static const String fileExtension = 'json';

  /// Builds the default export file name for a backup created at [createdAt],
  /// for example `arrmate-backup-2026-10-11.json`.
  static String buildFileName(DateTime createdAt) {
    final month = createdAt.month.toString().padLeft(2, '0');
    final day = createdAt.day.toString().padLeft(2, '0');
    return 'arrmate-backup-${createdAt.year}-$month-$day.$fileExtension';
  }

  /// Opens the platform save dialog and writes [encodedJson] to the chosen
  /// location.
  ///
  /// Returns the exported file name, or null when the dialog was aborted. On
  /// the web the download starts immediately and the chosen name is returned
  /// even though no path exists. Android and iOS write the picked document
  /// themselves from the given bytes, so only desktop builds need to fill the
  /// returned plain path.
  Future<String?> exportBackup(String encodedJson) async {
    final fileName = buildFileName(DateTime.now());
    final bytes = Uint8List.fromList(utf8.encode(encodedJson));
    final path = await FilePicker.platform.saveFile(
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const [fileExtension],
      bytes: bytes,
    );
    if (path == null && !kIsWeb) return null;
    final writesNativeFile =
        !kIsWeb &&
        defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS;
    if (path != null && writesNativeFile) await writeBackupFile(path, bytes);
    logger.info(
      '[BackupFileService] Backup exported to ${path ?? fileName} '
      '(${bytes.length} bytes)',
    );
    return fileName;
  }

  /// Opens the file picker and returns the contents of the picked backup
  /// file, or null when nothing was picked or the file has no readable
  /// content.
  Future<String?> importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [fileExtension],
      withData: true,
    );
    final files = result?.files;
    if (files == null || files.isEmpty) return null;
    final bytes = files.first.bytes;
    if (bytes == null) {
      logger.warning(
        '[BackupFileService] Picked backup file has no readable content',
      );
      return null;
    }
    return utf8.decode(bytes);
  }
}
