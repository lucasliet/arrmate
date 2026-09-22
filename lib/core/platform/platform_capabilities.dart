import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Describes platform features that may be unavailable in the current runtime.
@immutable
class PlatformCapabilities {
  /// Creates an immutable capability set.
  const PlatformCapabilities({
    required this.isWeb,
    required this.supportsAppUpdates,
    required this.supportsBackgroundNotifications,
    required this.supportsLocalAssistant,
    required this.supportsFileSystemCache,
    required this.supportsBrowserFileInput,
  });

  /// Builds the capability set for the active Flutter target.
  factory PlatformCapabilities.current() => PlatformCapabilities(
    isWeb: kIsWeb,
    supportsAppUpdates:
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
    supportsBackgroundNotifications: !kIsWeb,
    supportsLocalAssistant: !kIsWeb,
    supportsFileSystemCache: !kIsWeb,
    supportsBrowserFileInput: kIsWeb,
  );

  /// Whether the application is running in a browser.
  final bool isWeb;

  /// Whether native package installation is available.
  final bool supportsAppUpdates;

  /// Whether notifications can be processed while the application is closed.
  final bool supportsBackgroundNotifications;

  /// Whether an on-device assistant runtime is available.
  final bool supportsLocalAssistant;

  /// Whether persistent file-system image caching is available.
  final bool supportsFileSystemCache;

  /// Whether browser byte-based file selection is available.
  final bool supportsBrowserFileInput;
}

/// Provides the capabilities of the active platform to application features.
final platformCapabilitiesProvider = Provider<PlatformCapabilities>(
  (ref) => PlatformCapabilities.current(),
);
