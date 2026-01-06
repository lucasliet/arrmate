import 'package:dio/dio.dart';

import 'api_error.dart';
import '../constants/api_constants.dart';
import 'secure_log_interceptor.dart';

/// A wrapper around [Dio] for making HTTP requests with standardized error handling and logging.
class ApiClient {
  final Dio _dio;

  /// The base URL for the API.
  final String baseUrl;

  /// The default headers to include in every request.
  final Map<String, String> headers;

  /// The default timeout for requests.
  final Duration timeout;

  /// Creates a new [ApiClient] instance.
  ///
  /// [baseUrl] is the root URL for the API.
  /// [headers] are standard headers (e.g., API Key).
  /// [timeout] defaults to [ApiConstants.defaultTimeout].
  ApiClient({
    required this.baseUrl,
    required this.headers,
    this.timeout = ApiConstants.defaultTimeout,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: timeout,
           receiveTimeout: timeout,
           sendTimeout: timeout,
           headers: headers,
         ),
       ) {
    _dio.interceptors.add(SecureLogInterceptor());
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
      () => _dio.get(
        path,
        queryParameters: queryParameters,
        options: _optionsWithTimeout(customTimeout),
      ),
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
      () => _dio.post(
        path,
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
      () => _dio.put(
        path,
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
      () => _dio.delete(
        path,
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

  /// Wraps a Dio request with error handling to throw [ApiError]s.
  Future<T> _request<T>(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      return response.data as T;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
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
        return UnknownApiError(e.message);
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

  /// Extracts a human-readable error message from the response data.
  String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;
    if (data is String) return data;
    if (data is Map) {
      return data['message'] as String? ?? data['error'] as String?;
    }
    return null;
  }
}
