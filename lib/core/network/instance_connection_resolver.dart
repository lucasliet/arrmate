import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../../domain/models/models.dart';

/// Selects an instance URL based on the active network and safe probes.
class InstanceConnectionResolver {
  final Connectivity _connectivity;
  final Future<List<ConnectivityResult>> Function() _loadConnectivity;
  final Future<bool> Function(Uri) _ping;
  final Stream<List<ConnectivityResult>>? _connectivityChanges;

  /// Creates a resolver with injectable network and probe operations.
  InstanceConnectionResolver({
    Connectivity? connectivity,
    Future<List<ConnectivityResult>> Function()? loadConnectivity,
    Future<bool> Function(Uri)? ping,
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
      if (await _ping(_pingUri(candidate))) {
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
        connectivity.contains(ConnectivityResult.satellite);

    return hasRemoteNetwork && !hasLocalNetwork
        ? [alternativeUrl, primaryUrl]
        : [primaryUrl, alternativeUrl];
  }

  Uri _pingUri(String baseUrl) {
    final baseUri = Uri.parse(baseUrl);
    final basePath = baseUri.path.endsWith('/')
        ? baseUri.path.substring(0, baseUri.path.length - 1)
        : baseUri.path;
    return baseUri.replace(
      userInfo: '',
      path: '$basePath/ping',
      queryParameters: null,
      fragment: null,
    );
  }

  static Dio _configureDio(Dio dio) {
    dio.options.connectTimeout ??= const Duration(seconds: 5);
    return dio;
  }

  static Future<bool> Function(Uri) _createPing(Dio dio) {
    return (uri) async {
      try {
        final response = await dio.getUri<dynamic>(
          uri,
          options: Options(
            followRedirects: false,
            validateStatus: (status) =>
                status != null && status >= 200 && status < 300,
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ),
        );
        final status = response.data is Map
            ? (response.data as Map<dynamic, dynamic>)['status']?.toString()
            : null;
        return response.realUri.host == uri.host &&
            status?.toUpperCase() == 'OK';
      } on DioException {
        return false;
      }
    };
  }
}
