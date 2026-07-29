import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../network/custom_cache_manager.dart';
import 'logger_service.dart';

/// Handles cache maintenance operations such as clearing the image cache.
class CacheMaintenanceService {
  final CacheManager _cacheManager;
  DateTime? _lastClearedAt;

  CacheMaintenanceService({CacheManager? cacheManager})
    : _cacheManager = cacheManager ?? CustomCacheManager.instance;

  /// Returns the last time the image cache was cleared, or null when it has
  /// never been cleared during this session.
  DateTime? get lastClearedAt => _lastClearedAt;

  /// Removes every cached image from memory and disk storage.
  Future<void> clearImageCache() async {
    logger.info('[CacheMaintenance] Clearing image cache');
    try {
      await _cacheManager.emptyCache();
    } catch (error, stackTrace) {
      logger.warning(
        '[CacheMaintenance] Disk cache clear failed',
        error,
        stackTrace,
      );
    }
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    _lastClearedAt = DateTime.now();
    logger.info('[CacheMaintenance] Image cache cleared');
  }
}
