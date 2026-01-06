import 'package:dio/dio.dart';
import '../services/logger_service.dart';

/// A Dio [Interceptor] that logs HTTP traffic while masking sensitive information.
class SecureLogInterceptor extends Interceptor {
  /// Headers that should be masked in logs.
  final Set<String> _maskedHeaders = {'X-Api-Key', 'apikey', 'authorization'};

  /// Query parameters that should be masked in logs.
  final Set<String> _maskedQueryParams = {'apikey', 'apiKey'};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final sanitizedHeaders = _sanitizeHeaders(options.headers);
    final sanitizedQueryParams = _sanitizeQueryParams(options.queryParameters);

    logger.debug(
      '[API] Request: ${options.method} ${options.path}\n'
      'Query: $sanitizedQueryParams\n'
      'Headers: $sanitizedHeaders\n'
      'Data: ${options.data}',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logger.debug(
      '[API] Response: ${response.statusCode} ${response.requestOptions.path}\n'
      'Data: ${response.data}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.error(
      '[API] Error: ${err.message} (${err.type})\n'
      'Path: ${err.requestOptions.path}\n'
      'Data: ${err.response?.data}',
      err,
      err.stackTrace,
    );
    handler.next(err);
  }

  /// Returns a copy of [headers] with sensitive values masked.
  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = Map<String, dynamic>.from(headers);
    for (final key in sanitized.keys) {
      if (_maskedHeaders.any((h) => h.toLowerCase() == key.toLowerCase())) {
        sanitized[key] = '***MASKED***';
      }
    }
    return sanitized;
  }

  /// Returns a copy of [params] with sensitive values masked.
  Map<String, dynamic> _sanitizeQueryParams(Map<String, dynamic> params) {
    final sanitized = Map<String, dynamic>.from(params);
    for (final key in sanitized.keys) {
      if (_maskedQueryParams.any((h) => h.toLowerCase() == key.toLowerCase())) {
        sanitized[key] = '***MASKED***';
      }
    }
    return sanitized;
  }
}
