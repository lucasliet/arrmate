import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// On-device assistant runtimes a platform can host.
enum LocalAssistantRuntime {
  /// No on-device runtime; only the cloud assistant is offered.
  none,

  /// LiteRT-LM models downloaded or imported by the user.
  liteRt,

  /// The Apple Intelligence system language model.
  appleIntelligence,
}

/// Describes platform features that may be unavailable in the current runtime.
@immutable
class PlatformCapabilities {
  /// Creates an immutable capability set.
  const PlatformCapabilities({
    required this.isWeb,
    required this.supportsAppUpdates,
    required this.supportsBackgroundNotifications,
    required this.localAssistantRuntime,
    required this.supportsFileSystemCache,
    required this.supportsBrowserFileInput,
  });

  /// Builds a capability set for a specific Flutter target.
  ///
  /// Supplying the target explicitly keeps capability policy deterministic and
  /// independently testable without changing Flutter globals.
  factory PlatformCapabilities.forPlatform({
    required bool isWeb,
    required TargetPlatform targetPlatform,
  }) => PlatformCapabilities(
    isWeb: isWeb,
    supportsAppUpdates:
        !isWeb &&
        {
          TargetPlatform.android,
          TargetPlatform.windows,
          TargetPlatform.linux,
          TargetPlatform.macOS,
        }.contains(targetPlatform),
    supportsBackgroundNotifications: !isWeb,
    localAssistantRuntime: isWeb
        ? LocalAssistantRuntime.none
        : switch (targetPlatform) {
            TargetPlatform.android => LocalAssistantRuntime.liteRt,
            TargetPlatform.iOS ||
            TargetPlatform.macOS => LocalAssistantRuntime.appleIntelligence,
            _ => LocalAssistantRuntime.none,
          },
    supportsFileSystemCache: !isWeb,
    supportsBrowserFileInput: isWeb,
  );

  /// Builds the capability set for the active Flutter target.
  factory PlatformCapabilities.current() => PlatformCapabilities.forPlatform(
    isWeb: kIsWeb,
    targetPlatform: defaultTargetPlatform,
  );

  /// Whether the application is running in a browser.
  final bool isWeb;

  /// Whether native package installation is available.
  final bool supportsAppUpdates;

  /// Whether notifications can be processed while the application is closed.
  final bool supportsBackgroundNotifications;

  /// On-device assistant runtime offered next to the cloud assistant.
  final LocalAssistantRuntime localAssistantRuntime;

  /// Whether persistent file-system image caching is available.
  final bool supportsFileSystemCache;

  /// Whether browser byte-based file selection is available.
  final bool supportsBrowserFileInput;
}

/// Provides the capabilities of the active platform to application features.
final platformCapabilitiesProvider = Provider<PlatformCapabilities>(
  (ref) => PlatformCapabilities.current(),
);
