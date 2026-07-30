import 'package:arrmate/core/services/cache_maintenance_service.dart';
import 'package:arrmate/presentation/providers/cache_maintenance_provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCacheManager extends Mock implements CacheManager {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CacheMaintenanceService', () {
    test(
      'should clear the disk cache and record the last cleared timestamp',
      () async {
        // Given
        final cacheManager = MockCacheManager();
        when(cacheManager.emptyCache).thenAnswer((_) async {});
        final service = CacheMaintenanceService(cacheManager: cacheManager);

        // When
        await service.clearImageCache();

        // Then
        verify(cacheManager.emptyCache).called(1);
        expect(service.lastClearedAt, isNotNull);
      },
    );

    test(
      'should keep clearing the in-memory cache even when disk clear fails',
      () async {
        // Given
        final cacheManager = MockCacheManager();
        when(cacheManager.emptyCache).thenThrow(Exception('disk unavailable'));
        final service = CacheMaintenanceService(cacheManager: cacheManager);

        // When
        await service.clearImageCache();

        // Then
        expect(service.lastClearedAt, isNotNull);
        verify(cacheManager.emptyCache).called(1);
      },
    );
  });

  group('cacheMaintenanceProvider', () {
    test('should build a service wired to the default cache manager', () {
      // Given
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // When
      final service = container.read(cacheMaintenanceProvider);

      // Then
      expect(service, isA<CacheMaintenanceService>());
    });
  });
}
