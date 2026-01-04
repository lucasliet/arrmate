import 'package:arrmate/core/network/custom_cache_manager.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getTemporaryDirectory' ||
            methodCall.method == 'getApplicationSupportDirectory') {
          return '.';
        }
        return null;
      },
    );
  });

  group('CustomCacheManager', () {
    test('should provide a singleton instance', () {
      final instance1 = CustomCacheManager.instance;
      final instance2 = CustomCacheManager.instance;
      
      expect(instance1, isA<CacheManager>());
      expect(instance1, equals(instance2));
    });

    test('should use correct cache key', () {
      expect(CustomCacheManager.key, 'customCacheKey');
    });
  });
}
