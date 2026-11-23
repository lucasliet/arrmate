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

/// Thrown when a browser could not read the answer of a username and
/// password request sent to a qBittorrent on another origin.
///
/// The browser reports a blocked cross-origin answer (qBittorrent sends no
/// CORS headers and refuses a foreign `Origin`) the same way as a server that
/// is down, so the message covers both. Logging in again cannot help, and
/// every attempt still reaches the server.
class BrowserCrossOriginBlockedError extends UnauthorizedError {
  const BrowserCrossOriginBlockedError()
    : super(
        'The browser blocked or could not reach qBittorrent on another '
        'domain. On the web, username and password only work when '
        'qBittorrent is served from the same domain as Arrmate (reverse '
        'proxy), or when it allows credentialed requests from this site '
        '(CORS).',
      );
}

/// Thrown when qBittorrent accepts a username and password login in a
/// browser, but keeps rejecting the requests that follow it.
///
/// A browser owns the session cookie and only sends it back when qBittorrent
/// is served from the same site as the app, so the credentials are not the
/// problem and logging in again cannot help.
class BrowserSessionUnavailableError extends UnauthorizedError {
  const BrowserSessionUnavailableError()
    : super(
        'The browser did not keep the qBittorrent session. On the web, '
        'username and password only work when qBittorrent is served from '
        'the same domain as Arrmate (reverse proxy). Otherwise use an API '
        'key.',
      );
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

/// Thrown when a request cannot be built because required data is missing.
///
/// Unlike the other cases, this one is raised before the request leaves the
/// app, so the message describes what the user has to fix rather than what the
/// server answered.
class MissingDataError extends ApiError {
  const MissingDataError(super.message);
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
