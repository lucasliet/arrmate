/// Base class for all API-related errors.
sealed class ApiError implements Exception {
  const ApiError(this.message);

  /// A descriptive message for the error.
  final String message;

  @override
  String toString() => message;
}

/// Thrown when a URL is invalid.
class InvalidUrlError extends ApiError {
  const InvalidUrlError(String url) : super('Invalid URL: $url');
}

/// Thrown when the connection fails (e.g., no internet, DNS error).
class ConnectionError extends ApiError {
  const ConnectionError([String? message])
    : super(message ?? 'Connection failed. Please check your network.');
}

/// Thrown when the request times out.
class TimeoutError extends ApiError {
  const TimeoutError([String? message])
    : super(message ?? 'Request timed out. Please try again.');
}

/// Thrown when the server returns a 401 Unauthorized response.
class UnauthorizedError extends ApiError {
  const UnauthorizedError([String? message])
    : super(message ?? 'Unauthorized. Please check your API key.');
}

/// Thrown when the server returns a 404 Not Found response.
class NotFoundError extends ApiError {
  const NotFoundError([String? message])
    : super(message ?? 'Resource not found.');
}

/// Thrown when the server returns a 5xx error.
class ServerError extends ApiError {
  const ServerError([String? message])
    : super(message ?? 'Server error. Please try again later.');
}

/// Thrown when an unknown error occurs.
class UnknownApiError extends ApiError {
  const UnknownApiError([String? message])
    : super(message ?? 'An unknown error occurred.');
}

/// Thrown when the server returns a 422 Validation Error.
class ValidationError extends ApiError {
  /// A map of field-specific validation errors.
  final Map<String, dynamic>? errors;

  const ValidationError({String? message, this.errors})
    : super(message ?? 'Validation failed.');
}
