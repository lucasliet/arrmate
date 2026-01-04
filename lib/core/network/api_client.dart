import 'package:dio/dio.dart';
import '../services/logger_service.dart';
import 'api_error.dart';
import '../constants/api_constants.dart';

class ApiClient {
  final Dio _dio;
  final String baseUrl;
  final Map<String, String> headers;
  final Duration timeout;

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
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => logger.debug('[API] $obj'),
      ),
    );
  }

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

  Options? _optionsWithTimeout(Duration? customTimeout) {
    if (customTimeout == null) return null;
    return Options(receiveTimeout: customTimeout, sendTimeout: customTimeout);
  }

  Future<T> _request<T>(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      return response.data as T;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

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

  String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;
    if (data is String) return data;
    if (data is Map) {
      return data['message'] as String? ?? data['error'] as String?;
    }
    return null;
  }
}
