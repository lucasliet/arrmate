import 'package:arrmate/core/platform/platform_capabilities.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlatformCapabilities', () {
    test('disables native-only features on web', () {
      final capabilities = PlatformCapabilities.forPlatform(
        isWeb: true,
        targetPlatform: TargetPlatform.android,
      );

      expect(capabilities.supportsAppUpdates, isFalse);
      expect(capabilities.supportsBackgroundNotifications, isFalse);
      expect(capabilities.supportsLocalAssistant, isFalse);
      expect(capabilities.supportsFileSystemCache, isFalse);
      expect(capabilities.supportsBrowserFileInput, isTrue);
    });

    test('enables native update installation only on Android', () {
      for (final platform in TargetPlatform.values) {
        final capabilities = PlatformCapabilities.forPlatform(
          isWeb: false,
          targetPlatform: platform,
        );

        expect(
          capabilities.supportsAppUpdates,
          platform == TargetPlatform.android,
        );
        expect(capabilities.supportsBackgroundNotifications, isTrue);
        expect(capabilities.supportsLocalAssistant, isTrue);
        expect(capabilities.supportsFileSystemCache, isTrue);
        expect(capabilities.supportsBrowserFileInput, isFalse);
      }
    });
  });
}
