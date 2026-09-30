import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Web-safe image cache that delegates transport caching to the browser.
class CustomCacheManager {
  /// Cache identifier shared by cache maintenance features.
  static const key = 'customCacheKey';

  /// Maximum age displayed by offline-state UI.
  static const stalePeriod = Duration(days: 7);

  /// Maximum object count retained by compatible cache implementations.
  static const maximumObjects = 200;

  /// Cache manager accepted by shared image widgets on web builds.
  static final CacheManager instance = DefaultCacheManager();
}
