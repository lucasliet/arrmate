import 'update_service.dart';

/// Rejects native desktop installation in browser builds.
class DesktopUpdateService {
  /// Downloads and installs an update on a supported native runtime.
  Future<void> installUpdate(
    AppUpdateInfo info, {
    required void Function(int received, int total) onProgress,
    required void Function() onInstalling,
  }) =>
      Future.error(UnsupportedError('Desktop updates are unavailable on web.'));
}
