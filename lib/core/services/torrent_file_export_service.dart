import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'backup_file_writer.dart';
import 'file_dialog.dart';
import 'logger_service.dart';

/// Saves a `.torrent` file exported from the download client through the
/// platform save dialog.
class TorrentFileExportService {
  /// File extension carried by exported torrent files.
  static const String fileExtension = 'torrent';

  static final RegExp _unsafeFileNameCharacters = RegExp(
    r'[\\/:*?"<>|\x00-\x1F]',
  );

  /// Builds the suggested file name for the torrent called [torrentName], for
  /// example `Some.Release.1080p.torrent`.
  ///
  /// Characters a file system refuses are replaced with `_`; a name left
  /// empty falls back to `torrent`.
  static String buildFileName(String torrentName) {
    final safeName = torrentName
        .replaceAll(_unsafeFileNameCharacters, '_')
        .trim();
    return '${safeName.isEmpty ? fileExtension : safeName}.$fileExtension';
  }

  /// Opens the platform save dialog and writes [bytes] as the `.torrent` file
  /// of the torrent called [torrentName].
  ///
  /// Returns the exported file name, or null when the dialog was aborted, and
  /// throws [FileDialogUnavailableError] when the system has no dialog. On
  /// the web the download starts immediately. Android and iOS write the
  /// picked document themselves from the given bytes, so only desktop builds
  /// need to fill the returned plain path.
  Future<String?> saveTorrentFile(String torrentName, Uint8List bytes) async {
    final fileName = buildFileName(torrentName);
    // No extension filter: Android resolves it to a MIME type and has none
    // registered for `.torrent`. The suggested name already carries it.
    final path = await guardFileDialog(
      () => FilePicker.platform.saveFile(fileName: fileName, bytes: bytes),
    );
    if (path == null && !kIsWeb) return null;
    final writesNativeFile =
        !kIsWeb &&
        defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS;
    if (path != null && writesNativeFile) await writeBackupFile(path, bytes);
    logger.info(
      '[TorrentFileExportService] Torrent file exported '
      '(${bytes.length} bytes)',
    );
    return fileName;
  }
}
