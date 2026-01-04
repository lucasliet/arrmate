sealed class ApiError implements Exception {
  const ApiError(this.message);
  final String message;

  @override
  String toString() => message;
}

class InvalidUrlError extends ApiError {
  const InvalidUrlError(String url) : super('Invalid URL: $url');
}

class ConnectionError extends ApiError {
  const ConnectionError([String? message])
      : super(message ?? 'Connection failed. Please check your network.');
}

class TimeoutError extends ApiError {
  const TimeoutError([String? message])
      : super(message ?? 'Request timed out. Please try again.');
}

class UnauthorizedError extends ApiError {
  const UnauthorizedError([String? message])
      : super(message ?? 'Unauthorized. Please check your API key.');
}

class NotFoundError extends ApiError {
  const NotFoundError([String? message])
      : super(message ?? 'Resource not found.');
}

class ServerError extends ApiError {
  const ServerError([String? message])
      : super(message ?? 'Server error. Please try again later.');
}

class UnknownApiError extends ApiError {
  const UnknownApiError([String? message])
      : super(message ?? 'An unknown error occurred.');
}

class ValidationError extends ApiError {
  final Map<String, dynamic>? errors;

  const ValidationError({String? message, this.errors})
      : super(message ?? 'Validation failed.');
}
