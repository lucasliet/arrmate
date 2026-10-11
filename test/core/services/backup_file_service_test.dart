import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:arrmate/core/services/backup_file_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFilePicker extends FilePicker {
  _FakeFilePicker({this.saveFileResult, this.pickResult});

  final String? saveFileResult;
  final FilePickerResult? pickResult;
  String? savedFileName;
  Uint8List? savedBytes;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    @Deprecated('No longer has any effect.') bool allowCompression = false,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    return pickResult;
  }

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
  group('BackupFileService', () {
    group('buildFileName', () {
      test('shouldBuildDatedFileName', () {
        // Given
        final createdAt = DateTime(2026, 10, 11);

        // When
        final fileName = BackupFileService.buildFileName(createdAt);

        // Then
        expect(fileName, 'arrmate-backup-2026-10-11.json');
      });
    });

    group('exportBackup', () {
      test('shouldWriteBackupToChosenPath_whenSaveDialogConfirmed', () async {
        // Given
        final directory = await Directory.systemTemp.createTemp('arrmate');
        addTearDown(() => directory.delete(recursive: true));
        final path = '${directory.path}/chosen.json';
        final picker = _FakeFilePicker(saveFileResult: path);
        FilePicker.platform = picker;

        // When
        final fileName = await BackupFileService().exportBackup('{"schema":1}');

        // Then
        expect(fileName, isNotNull);
        expect(picker.savedBytes, utf8.encode('{"schema":1}'));
        expect(File(path).readAsStringSync(), '{"schema":1}');
      });

      test('shouldSuggestDatedFileName_whenExporting', () async {
        // Given
        final picker = _FakeFilePicker(saveFileResult: null);
        FilePicker.platform = picker;

        // When
        await BackupFileService().exportBackup('{"schema":1}');

        // Then
        expect(
          picker.savedFileName,
          BackupFileService.buildFileName(DateTime.now()),
        );
      });

      test('shouldReturnNull_whenSaveDialogAborted', () async {
        // Given
        final picker = _FakeFilePicker(saveFileResult: null);
        FilePicker.platform = picker;

        // When
        final fileName = await BackupFileService().exportBackup('{"schema":1}');

        // Then
        expect(fileName, isNull);
      });
    });

    group('importBackup', () {
      test('shouldReturnPickedContent_whenFileSelected', () async {
        // Given
        final picker = _FakeFilePicker(
          pickResult: FilePickerResult([
            PlatformFile(
              name: 'backup.json',
              size: 13,
              bytes: Uint8List.fromList(utf8.encode('{"schema":1}')),
            ),
          ]),
        );
        FilePicker.platform = picker;

        // When
        final content = await BackupFileService().importBackup();

        // Then
        expect(content, '{"schema":1}');
      });

      test('shouldReturnNull_whenFilePickCancelled', () async {
        // Given
        FilePicker.platform = _FakeFilePicker(pickResult: null);

        // When
        final content = await BackupFileService().importBackup();

        // Then
        expect(content, isNull);
      });

      test('shouldReturnNull_whenPickedFileHasNoBytes', () async {
        // Given
        FilePicker.platform = _FakeFilePicker(
          pickResult: FilePickerResult([
            PlatformFile(name: 'backup.json', size: 0),
          ]),
        );

        // When
        final content = await BackupFileService().importBackup();

        // Then
        expect(content, isNull);
      });
    });
  });
}
