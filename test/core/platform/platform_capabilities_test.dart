import 'package:arrmate/core/platform/platform_capabilities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('capability values remain internally consistent', () {
    final capabilities = PlatformCapabilities.current();

    if (capabilities.isWeb) {
      expect(capabilities.supportsAppUpdates, isFalse);
      expect(capabilities.supportsBackgroundNotifications, isFalse);
      expect(capabilities.supportsLocalAssistant, isFalse);
      expect(capabilities.supportsFileSystemCache, isFalse);
      expect(capabilities.supportsBrowserFileInput, isTrue);
    } else {
      expect(capabilities.supportsBackgroundNotifications, isTrue);
      expect(capabilities.supportsLocalAssistant, isTrue);
      expect(capabilities.supportsFileSystemCache, isTrue);
      expect(capabilities.supportsBrowserFileInput, isFalse);
    }
  });
}
