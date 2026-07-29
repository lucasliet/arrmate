import 'package:dio/dio.dart';
import '../services/logger_service.dart';
import '../utils/sensitive_data_redactor.dart';

/// A Dio [Interceptor] that logs HTTP traffic while masking sensitive
/// information — credentials, endpoints and tokens — so logs are safe to
/// share in diagnostic reports.
class SecureLogInterceptor extends Interceptor {
  /// Header substrings whose values must always be masked in logs.
  static const _sensitiveHeaderSubstrings = [
    'api-key',
    'apikey',
    'authorization',
    'token',
    'secret',
    'cookie',
    'set-cookie',
    'password',
  ];

  /// Query parameter substrings whose values must always be masked in logs.
  static const _sensitiveQueryParamSubstrings = [
    'apikey',
    'api-key',
    'token',
    'secret',
    'password',
    'passkey',
    'auth',
  ];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final sanitizedHeaders = _sanitizeHeaders(options.headers);
    final sanitizedQueryParams = _sanitizeQueryParams(options.queryParameters);
    final sanitizedPath = SensitiveDataRedactor.redact(options.path);
    final bodyType = options.data?.runtimeType.toString() ?? 'none';

    logger.debug(
      '[API] Request: ${options.method} $sanitizedPath\n'
      'Query: $sanitizedQueryParams\n'
      'Headers: $sanitizedHeaders\n'
      'Body type: $bodyType',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final sanitizedPath = SensitiveDataRedactor.redact(
      response.requestOptions.path,
    );
    logger.debug(
      '[API] Response: ${response.statusCode} $sanitizedPath\n'
      'Body type: ${response.data?.runtimeType ?? 'none'}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final sanitizedMessage = SensitiveDataRedactor.redactOptional(err.message);
    final sanitizedPath = SensitiveDataRedactor.redact(err.requestOptions.path);
    logger.error(
      '[API] Error: $sanitizedMessage (${err.type})\n'
      'Path: $sanitizedPath\n'
      'Status: ${err.response?.statusCode ?? 'unavailable'}',
      err,
      err.stackTrace,
    );
    handler.next(err);
  }

  /// Returns a copy of [headers] with sensitive values masked.
  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = Map<String, dynamic>.from(headers);
    for (final key in sanitized.keys) {
      if (_isSensitive(key, _sensitiveHeaderSubstrings)) {
        sanitized[key] = '***MASKED***';
      }
    }
    return sanitized;
  }

  /// Returns a copy of [params] with sensitive values masked.
  Map<String, dynamic> _sanitizeQueryParams(Map<String, dynamic> params) {
    final sanitized = Map<String, dynamic>.from(params);
    for (final key in sanitized.keys) {
      if (_isSensitive(key, _sensitiveQueryParamSubstrings)) {
        sanitized[key] = '***MASKED***';
      }
    }
    return sanitized;
  }

  bool _isSensitive(String key, List<String> substrings) {
    final normalized = key.toLowerCase();
    return substrings.any((s) => normalized.contains(s));
  }
}
