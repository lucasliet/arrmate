import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/io_client.dart';

/// Native image cache that preserves support for explicitly trusted servers.
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
      fileService: HttpFileService(
        httpClient: IOClient(
          HttpClient()
            ..badCertificateCallback = (
              X509Certificate certificate,
              String host,
              int port,
            ) => true,
        ),
      ),
    ),
  );
}
