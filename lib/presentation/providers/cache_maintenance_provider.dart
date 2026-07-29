import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/cache_maintenance_service.dart';

/// Provides the single [CacheMaintenanceService] used across the app.
final cacheMaintenanceProvider = Provider<CacheMaintenanceService>((ref) {
  return CacheMaintenanceService();
});
