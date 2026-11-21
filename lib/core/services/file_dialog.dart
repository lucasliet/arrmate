import 'logger_service.dart';

/// Raised when the system has no service able to show a file dialog.
///
/// On Linux the dialogs come from the desktop portal over D-Bus; a session
/// without a FileChooser portal answers with a raw D-Bus error instead.
class FileDialogUnavailableError implements Exception {
  /// Creates a [FileDialogUnavailableError].
  const FileDialogUnavailableError();

  @override
  String toString() => 'The system file dialog is not available';
}

/// Prefix of every error name the D-Bus daemon itself answers with, such as
/// `ServiceUnknown` (no portal running) or `UnknownMethod` (a portal without
/// a FileChooser backend).
const _dbusErrorPrefix = 'org.freedesktop.DBus.Error.';

/// Whether [error] means the system could not provide a file dialog.
bool isFileDialogUnavailable(Object error) =>
    error.toString().contains(_dbusErrorPrefix);

/// Runs [open], which shows a platform file dialog, and turns a missing
/// dialog service into a [FileDialogUnavailableError].
///
/// Every other error is rethrown untouched.
Future<T> guardFileDialog<T>(Future<T> Function() open) async {
  try {
    return await open();
  } catch (error) {
    if (!isFileDialogUnavailable(error)) rethrow;
    logger.warning('[FileDialog] No file dialog service: ${error.runtimeType}');
    throw const FileDialogUnavailableError();
  }
}
