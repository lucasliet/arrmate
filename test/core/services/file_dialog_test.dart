import 'package:arrmate/core/services/file_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

class _DBusError implements Exception {
  _DBusError(this.text);

  final String text;

  @override
  String toString() => text;
}

void main() {
  group('guardFileDialog', () {
    test('should return what the dialog returns', () async {
      // When
      final result = await guardFileDialog(() async => '/tmp/file.torrent');

      // Then
      expect(result, '/tmp/file.torrent');
    });

    test('should report a session without a desktop portal', () {
      // Given
      final error = _DBusError(
        'org.freedesktop.DBus.Error.ServiceUnknown: The name '
        'org.freedesktop.portal.Desktop was not provided by any .service files',
      );

      // When / Then
      expect(
        guardFileDialog<String?>(() => Future.error(error)),
        throwsA(isA<FileDialogUnavailableError>()),
      );
    });

    test('should report a portal without a file chooser', () {
      // Given
      final error = _DBusError(
        'org.freedesktop.DBus.Error.UnknownMethod: No such interface '
        '"org.freedesktop.portal.FileChooser"',
      );

      // When / Then
      expect(
        guardFileDialog<String?>(() => Future.error(error)),
        throwsA(isA<FileDialogUnavailableError>()),
      );
    });

    test('should report an unreachable session bus on Linux', () {
      // Given
      final error = _DBusError(
        'SocketException: Connection failed (OS Error: No such file or '
        'directory, errno = 2), address = /run/user/1000/bus, port = 0',
      );

      // When / Then
      expect(
        guardFileDialog<String?>(
          () => Future.error(error),
          isLinuxDesktop: true,
        ),
        throwsA(isA<FileDialogUnavailableError>()),
      );
    });

    test('should keep a socket failure outside Linux untouched', () {
      // Given
      final error = _DBusError('SocketException: Connection failed');

      // When / Then
      expect(
        guardFileDialog<String?>(
          () => Future.error(error),
          isLinuxDesktop: false,
        ),
        throwsA(same(error)),
      );
    });

    test('should rethrow any other failure untouched', () {
      // Given
      final error = StateError('disk full');

      // When / Then
      expect(
        guardFileDialog<String?>(() => Future.error(error)),
        throwsA(same(error)),
      );
    });
  });
}
