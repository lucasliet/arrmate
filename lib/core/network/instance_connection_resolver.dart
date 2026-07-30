import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../../domain/models/models.dart';

/// Selects an instance URL based on the active network and safe probes.
class InstanceConnectionResolver {
  final Connectivity _connectivity;
  final Future<List<ConnectivityResult>> Function() _loadConnectivity;
  final Future<bool> Function(Instance, Uri) _ping;
  final Stream<List<ConnectivityResult>>? _connectivityChanges;

  /// Creates a resolver with injectable network and probe operations.
  InstanceConnectionResolver({
    Connectivity? connectivity,
    Future<List<ConnectivityResult>> Function()? loadConnectivity,
    Future<bool> Function(Instance, Uri)? ping,
    Stream<List<ConnectivityResult>>? connectivityChanges,
    Dio? dio,
  }) : _connectivity = connectivity ?? Connectivity(),
       _loadConnectivity =
           loadConnectivity ??
           (connectivity ?? Connectivity()).checkConnectivity,
       _ping = ping ?? _createPing(_configureDio(dio ?? Dio())),
       _connectivityChanges = connectivityChanges;

  /// Emits every connectivity change reported by the platform.
  Stream<List<ConnectivityResult>> get connectivityChanges =>
      _connectivityChanges ?? _connectivity.onConnectivityChanged;

  /// Resolves and probes the preferred URL for [instance].
  Future<Instance> resolve(Instance instance) async {
    final alternativeUrl = instance.alternativeUrl?.trim();
    if (alternativeUrl == null ||
        alternativeUrl.isEmpty ||
        alternativeUrl == instance.url) {
      return instance;
    }

    final connectivity = await _loadConnectivity();
    final candidates = _orderedCandidates(
      primaryUrl: instance.url,
      alternativeUrl: alternativeUrl,
      connectivity: connectivity,
    );

    for (final candidate in candidates) {
      if (await _ping(instance, _pingUri(instance, candidate))) {
        return instance.copyWith(activeUrl: candidate);
      }
    }

    return instance.copyWith(activeUrl: candidates.first);
  }

  List<String> _orderedCandidates({
    required String primaryUrl,
    required String alternativeUrl,
    required List<ConnectivityResult> connectivity,
  }) {
    final hasLocalNetwork =
        connectivity.contains(ConnectivityResult.wifi) ||
        connectivity.contains(ConnectivityResult.ethernet) ||
        connectivity.contains(ConnectivityResult.vpn);
    final hasRemoteNetwork =
        connectivity.contains(ConnectivityResult.mobile) ||
        connectivity.contains(ConnectivityResult.other);

    return hasRemoteNetwork && !hasLocalNetwork
        ? [alternativeUrl, primaryUrl]
        : [primaryUrl, alternativeUrl];
  }

  Uri _pingUri(Instance instance, String baseUrl) {
    final baseUri = Uri.parse(baseUrl);
    final basePath = baseUri.path.endsWith('/')
        ? baseUri.path.substring(0, baseUri.path.length - 1)
        : baseUri.path;
    final probePath = instance.type == InstanceType.qbittorrent
        ? '$basePath/api/v2/app/version'
        : '$basePath/ping';
    return baseUri.replace(
      userInfo: '',
      path: probePath,
      queryParameters: null,
      fragment: null,
    );
  }

  static Dio _configureDio(Dio dio) {
    dio.options.connectTimeout ??= const Duration(seconds: 5);
    return dio;
  }

  static Future<bool> Function(Instance, Uri) _createPing(Dio dio) {
    return (instance, uri) async {
      try {
        final response = await dio.getUri<dynamic>(
          uri,
          options: Options(
            followRedirects: false,
            validateStatus: (status) => status != null,
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ),
        );
        if (response.realUri.host != uri.host) {
          return false;
        }
        // qBittorrent's WebUI rejects unauthenticated requests with 403/401,
        // so any HTTP response proves the host is reachable. Radarr/Sonarr
        // expose a public /ping that returns {"status": "OK"}.
        if (instance.type == InstanceType.qbittorrent) {
          return true;
        }
        final status = response.data is Map
            ? (response.data as Map<dynamic, dynamic>)['status']?.toString()
            : null;
        return status?.toUpperCase() == 'OK';
      } on DioException {
        return false;
      }
    };
  }
}
