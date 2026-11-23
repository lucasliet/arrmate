import 'package:flutter/foundation.dart';

import 'logger_service.dart';

/// Raised when the system has no service able to show a file dialog.
///
/// On Linux the dialogs come from the desktop portal over D-Bus; a session
/// without a FileChooser portal, or without a reachable session bus, fails
/// with a raw D-Bus or socket error instead.
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

/// Whether [error], raised while opening a file dialog, means the system
/// could not provide one.
///
/// [isLinuxDesktop] defaults to the running platform. There a dialog only
/// talks to the session bus, so a socket failure means the bus itself is
/// unreachable.
bool isFileDialogUnavailable(Object error, {bool? isLinuxDesktop}) {
  final text = error.toString();
  if (text.contains(_dbusErrorPrefix)) return true;
  final onLinux =
      isLinuxDesktop ??
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux);
  return onLinux && text.startsWith('SocketException');
}

/// Runs [open], which shows a platform file dialog, and turns a missing
/// dialog service into a [FileDialogUnavailableError].
///
/// [open] must do nothing but open the dialog. Every other error is rethrown
/// untouched.
Future<T> guardFileDialog<T>(
  Future<T> Function() open, {
  bool? isLinuxDesktop,
}) async {
  try {
    return await open();
  } catch (error) {
    if (!isFileDialogUnavailable(error, isLinuxDesktop: isLinuxDesktop)) {
      rethrow;
    }
    logger.warning('[FileDialog] No file dialog service: ${error.runtimeType}');
    throw const FileDialogUnavailableError();
  }
}
