import 'dart:typed_data';

/// No-op on the web build, where the file picker hands the bytes straight to
/// a browser download and there is no file system path to write to.
Future<void> writeBackupFile(String path, Uint8List bytes) async {}
