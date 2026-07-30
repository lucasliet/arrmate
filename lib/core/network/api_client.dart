import 'package:dio/dio.dart';

import 'api_error.dart';
import '../constants/api_constants.dart';
import '../services/logger_service.dart';
import '../utils/sensitive_data_redactor.dart';
import 'request_diagnostics.dart';
import 'secure_log_interceptor.dart';

/// A wrapper around [Dio] for making HTTP requests with standardized error handling and logging.
class ApiClient {
  final Dio _dio;

  /// The base URL for the API.
  final String baseUrl;

  /// The default headers to include in every request.
  final Map<String, String> headers;

  /// Alternative API base URLs used after a connection failure.
  final List<String> fallbackBaseUrls;

  /// The default timeout for requests.
  final Duration timeout;

  final List<String> _candidateBaseUrls;

  /// The base URL currently considered active. Starts as [baseUrl] and is
  /// promoted to a fallback only after that fallback returns a successful
  /// response, so a fallback that answers with 401/404/500 never traps the
  /// client on it.
  String _activeBaseUrl;

  /// Creates a new [ApiClient] instance.
  ///
  /// [baseUrl] is the root URL for the API.
  /// [headers] are standard headers (e.g., API Key).
  /// [timeout] defaults to [ApiConstants.defaultTimeout].
  ApiClient({
    required this.baseUrl,
    required this.headers,
    this.fallbackBaseUrls = const [],
    this.timeout = ApiConstants.defaultTimeout,
    String? diagnosticSource,
    Dio? dio,
  }) : _candidateBaseUrls = _uniqueUrls([baseUrl, ...fallbackBaseUrls]),
       _activeBaseUrl = baseUrl,
       _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = baseUrl
      ..connectTimeout = timeout
      ..receiveTimeout = timeout
      ..sendTimeout = timeout
      ..headers.addAll(headers);
    _dio.interceptors.add(SecureLogInterceptor());
    _dio.interceptors.add(
      RequestDiagnosticsInterceptor(
        source: diagnosticSource ?? Uri.parse(baseUrl).host,
      ),
    );
  }

  /// Performs a GET request.
  ///
  /// [path] is the endpoint path (relative to [baseUrl]).
  /// [queryParameters] are optional query parameters.
  /// [customTimeout] overrides the default timeout for this specific request.
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Duration? customTimeout,
  }) async {
    return _request<T>(
      path,
      (resolvedPath, baseUrl) => _dio.get(
        resolvedPath,
        queryParameters: queryParameters,
        options: _optionsWithTimeout(customTimeout),
      ),
      allowFailover: true,
    );
  }

  /// Performs a POST request.
  ///
  /// [path] is the endpoint path.
  /// [data] is the request body.
  /// [queryParameters] are optional query parameters.
  /// [customTimeout] overrides the default timeout.
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Duration? customTimeout,
  }) async {
    return _request<T>(
      path,
      (resolvedPath, baseUrl) => _dio.post(
        resolvedPath,
        data: data,
        queryParameters: queryParameters,
        options: _optionsWithTimeout(customTimeout),
      ),
    );
  }

  /// Performs a PUT request.
  ///
  /// [path] is the endpoint path.
  /// [data] is the request body.
  /// [queryParameters] are optional query parameters.
  /// [customTimeout] overrides the default timeout.
  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Duration? customTimeout,
  }) async {
    return _request<T>(
      path,
      (resolvedPath, baseUrl) => _dio.put(
        resolvedPath,
        data: data,
        queryParameters: queryParameters,
        options: _optionsWithTimeout(customTimeout),
      ),
    );
  }

  /// Performs a DELETE request.
  ///
  /// [path] is the endpoint path.
  /// [data] is the optional request body.
  /// [queryParameters] are optional query parameters.
  /// [customTimeout] overrides the default timeout.
  Future<T> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Duration? customTimeout,
  }) async {
    return _request<T>(
      path,
      (resolvedPath, baseUrl) => _dio.delete(
        resolvedPath,
        data: data,
        queryParameters: queryParameters,
        options: _optionsWithTimeout(customTimeout),
      ),
    );
  }

  /// Creates Dio [Options] with a custom timeout if one is provided.
  Options? _optionsWithTimeout(Duration? customTimeout) {
    if (customTimeout == null) return null;
    return Options(receiveTimeout: customTimeout, sendTimeout: customTimeout);
  }

  /// Resolves [path] against [baseUrl]. When the candidate differs from the
  /// shared Dio base URL, the absolute URL is returned so the request runs
  /// against the fallback without mutating [_dio.options.baseUrl] — keeping
  /// failover attempts isolated until a candidate is confirmed reachable.
  String _resolvePath(String path, String baseUrl) {
    if (baseUrl == _dio.options.baseUrl) return path;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final separator = baseUrl.endsWith('/') || path.startsWith('/') ? '' : '/';
    return '$baseUrl$separator$path';
  }

  /// Wraps a Dio request with error handling to throw [ApiError]s.
  ///
  /// Each attempt runs against a request-local base URL. On a connection-level
  /// failure the next candidate URL is tried; on a successful response the
  /// active base URL is promoted to the one that answered. A fallback that
  /// fails with a non-connection error (401/404/500) is never promoted, so the
  /// client stays on the previously confirmed URL instead of getting stuck.
  Future<T> _request<T>(
    String path,
    Future<Response<dynamic>> Function(String resolvedPath, String baseUrl)
    request, {
    bool allowFailover = false,
  }) async {
    final attemptedBaseUrls = <String>{};
    var currentBaseUrl = _activeBaseUrl;

    while (true) {
      attemptedBaseUrls.add(currentBaseUrl);
      try {
        final resolvedPath = _resolvePath(path, currentBaseUrl);
        final response = await request(resolvedPath, currentBaseUrl);
        _activeBaseUrl = currentBaseUrl;
        return response.data as T;
      } on DioException catch (error) {
        final nextBaseUrl = _nextBaseUrl(attemptedBaseUrls);
        if (!allowFailover || !_canFailOver(error) || nextBaseUrl == null) {
          throw _mapDioError(error);
        }
        logger.warning(
          '[ApiClient] Connection failed, retrying with an alternative instance URL',
        );
        currentBaseUrl = nextBaseUrl;
      }
    }
  }

  bool _canFailOver(DioException error) {
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout;
  }

  String? _nextBaseUrl(Set<String> attemptedBaseUrls) {
    return _candidateBaseUrls
        .where((candidate) => !attemptedBaseUrls.contains(candidate))
        .firstOrNull;
  }

  /// Maps a [DioException] to a strictly typed [ApiError].
  ApiError _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutError();
      case DioExceptionType.connectionError:
        return const ConnectionError();
      case DioExceptionType.badResponse:
        return _mapStatusCode(e.response?.statusCode, e.response?.data);
      case DioExceptionType.cancel:
        return const UnknownApiError('Request cancelled');
      default:
        return UnknownApiError(SensitiveDataRedactor.redactOptional(e.message));
    }
  }

  /// Maps HTTP status codes to specific [ApiError] subclasses.
  ApiError _mapStatusCode(int? statusCode, dynamic data) {
    final message = _extractErrorMessage(data);

    switch (statusCode) {
      case 401:
        return UnauthorizedError(message);
      case 404:
        return NotFoundError(message);
      case 422:
        return ValidationError(
          message: message,
          errors: data is Map ? data['errors'] : null,
        );
      case 500:
      case 502:
      case 503:
        return ServerError(message);
      default:
        return UnknownApiError(message ?? 'HTTP $statusCode');
    }
  }

  /// Extracts a human-readable error message from the response data, redacting
  /// any hostnames, IP addresses or tokens so instance endpoints never leak
  /// into user-facing errors or diagnostic reports.
  String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;
    String? raw;
    if (data is String) {
      raw = data;
    } else if (data is Map) {
      raw = data['message'] as String? ?? data['error'] as String?;
    }
    return SensitiveDataRedactor.redactOptional(raw);
  }

  static List<String> _uniqueUrls(List<String> urls) {
    return urls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toSet()
        .toList();
  }
}
