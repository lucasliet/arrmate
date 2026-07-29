import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/io_client.dart';

/// A custom implementation of [CacheManager] used to handle image caching securely.
///
/// It accepts self-signed certificates by using a custom [HttpClient].
class CustomCacheManager {
  static const key = 'customCacheKey';
  static const stalePeriod = Duration(days: 7);
  static const maximumObjects = 200;

  /// The singleton instance of the cache manager.
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: stalePeriod,
      maxNrOfCacheObjects: maximumObjects,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(
        httpClient: IOClient(
          HttpClient()
            ..badCertificateCallback =
                (X509Certificate cert, String host, int port) => true,
        ),
      ),
    ),
  );
}
