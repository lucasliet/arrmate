import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Native image cache with standard TLS certificate validation.
class CustomCacheManager {
  /// Cache identifier shared by cache maintenance features.
  static const key = 'customCacheKey';

  /// Maximum age of a cached image.
  static const stalePeriod = Duration(days: 7);

  /// Maximum number of cached image objects.
  static const maximumObjects = 200;

  /// Singleton native cache manager.
  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: stalePeriod,
      maxNrOfCacheObjects: maximumObjects,
      repo: JsonCacheInfoRepository(databaseName: key),
    ),
  );
}
