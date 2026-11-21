import 'dart:io';

import 'package:arrmate/core/services/torrent_file_export_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFilePicker extends FilePicker {
  _FakeFilePicker({this.saveFileResult});

  final String? saveFileResult;
  String? savedFileName;
  Uint8List? savedBytes;

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    savedFileName = fileName;
    savedBytes = bytes;
    return saveFileResult;
  }
}

void main() {
  group('TorrentFileExportService', () {
    final bytes = Uint8List.fromList([100, 52, 58, 101]);

    group('buildFileName', () {
      test('should append the torrent extension to the name', () {
        // When
        final fileName = TorrentFileExportService.buildFileName(
          'Some.Release.1080p',
        );

        // Then
        expect(fileName, 'Some.Release.1080p.torrent');
      });

      test('should replace characters a file system refuses', () {
        // When
        final fileName = TorrentFileExportService.buildFileName(
          'Show: S01/E01 "Pilot"?',
        );

        // Then
        expect(fileName, 'Show_ S01_E01 _Pilot__.torrent');
      });

      test('should fall back to a generic name when the name is blank', () {
        // When
        final fileName = TorrentFileExportService.buildFileName('  ');

        // Then
        expect(fileName, 'torrent.torrent');
      });
    });

    group('saveTorrentFile', () {
      test('should write the file to the path chosen on desktop', () async {
        // Given
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        final directory = await Directory.systemTemp.createTemp('arrmate');
        addTearDown(() => directory.delete(recursive: true));
        final path = '${directory.path}/chosen.torrent';
        final picker = _FakeFilePicker(saveFileResult: path);
        FilePicker.platform = picker;

        // When
        final fileName = await TorrentFileExportService().saveTorrentFile(
          'Movie 2024',
          bytes,
        );

        // Then
        expect(fileName, 'Movie 2024.torrent');
        expect(picker.savedFileName, 'Movie 2024.torrent');
        expect(File(path).readAsBytesSync(), bytes);
      });

      test('should hand the bytes to the picker on mobile', () async {
        // Given
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        final picker = _FakeFilePicker(saveFileResult: 'content://document/1');
        FilePicker.platform = picker;

        // When
        final fileName = await TorrentFileExportService().saveTorrentFile(
          'Movie 2024',
          bytes,
        );

        // Then
        expect(fileName, 'Movie 2024.torrent');
        expect(picker.savedBytes, bytes);
      });

      test('should return null when the save dialog is dismissed', () async {
        // Given
        FilePicker.platform = _FakeFilePicker(saveFileResult: null);

        // When
        final fileName = await TorrentFileExportService().saveTorrentFile(
          'Movie 2024',
          bytes,
        );

        // Then
        expect(fileName, isNull);
      });
    });
  });
}
