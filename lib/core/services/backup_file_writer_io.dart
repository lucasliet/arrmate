import 'dart:io';
import 'dart:typed_data';

/// Writes the exported backup bytes to the file chosen in the platform save
/// dialog, which returns the path but never writes the content itself.
Future<void> writeBackupFile(String path, Uint8List bytes) =>
    File(path).writeAsBytes(bytes);
