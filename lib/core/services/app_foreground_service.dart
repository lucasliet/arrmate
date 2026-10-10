import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'logger_service.dart';

/// Brings the app back in front of an external browser.
///
/// Some Android browsers do not hand control back to the app after an OAuth
/// redirect, leaving the user on the browser page. The app itself is still
/// running, so it can pull its own task forward once the result has arrived.
class AppForegroundService {
  static const MethodChannel _channel = MethodChannel(
    'br.com.lucasliet.arrmate/foreground',
  );

  final bool _isSupported;

  /// Creates the service; [isSupported] exists for tests and defaults to
  /// Android, the only platform with a native implementation.
  AppForegroundService({bool? isSupported})
    : _isSupported =
          isSupported ?? defaultTargetPlatform == TargetPlatform.android;

  /// Moves the app's task to the foreground, closing any browser tab that was
  /// opened on top of it.
  ///
  /// Does nothing on unsupported platforms. Failures are logged and never
  /// thrown, since returning to the app is a convenience and not a result the
  /// caller depends on.
  Future<void> bringToFront() async {
    if (!_isSupported) return;
    try {
      await _channel.invokeMethod<void>('bringToFront');
      logger.debug('[AppForeground] Requested the app to come to the front');
    } on PlatformException catch (error, stackTrace) {
      logger.warning(
        '[AppForeground] Bringing the app to the front failed',
        error,
        stackTrace,
      );
    } on MissingPluginException catch (error, stackTrace) {
      logger.warning(
        '[AppForeground] No native implementation available',
        error,
        stackTrace,
      );
    }
  }
}
