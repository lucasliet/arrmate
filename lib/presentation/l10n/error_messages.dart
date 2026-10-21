import 'package:dio/dio.dart';

import '../../core/l10n/app_locale.dart';
import '../../core/network/api_error.dart';

/// English message of [UnknownApiError] when a request is cancelled.
///
/// Mirrors the literal used by `ApiClient`, so the cancellation can be
/// recognized and translated.
const _requestCancelledMessage = 'Request cancelled';

/// Turns [error] into a user-facing message in the language of [l10n].
///
/// [ApiError]s that still carry their built-in English default message are
/// translated; messages provided by the server (or by the caller that raised
/// the error) are returned untouched, since they cannot be translated
/// reliably. A [DioException] that reached the UI without being wrapped (the
/// download client has its own HTTP client) is translated by
/// [_describeDioError]. Any other error falls back to `error.toString()`.
String describeError(Object error, AppLocalizations l10n) {
  if (error is DioException) return _describeDioError(error, l10n);
  if (error is! ApiError) return error.toString();
  final message = error.message;
  return switch (error) {
    InvalidUrlError() => _invalidUrl(message, l10n),
    ConnectionError() when message == const ConnectionError().message =>
      l10n.errorConnectionFailed,
    TimeoutError() when message == const TimeoutError().message =>
      l10n.errorRequestTimedOut,
    UnauthorizedError() when message == const UnauthorizedError().message =>
      l10n.errorUnauthorized,
    NotFoundError() when message == const NotFoundError().message =>
      l10n.errorNotFound,
    ServerError() when message == const ServerError().message =>
      l10n.errorServer,
    UnknownApiError() when message == const UnknownApiError().message =>
      l10n.errorUnknown,
    UnknownApiError() when message == _requestCancelledMessage =>
      l10n.errorRequestCancelled,
    ValidationError() when message == const ValidationError().message =>
      l10n.errorValidationFailed,
    _ => message,
  };
}

/// Translates the [InvalidUrlError] message, keeping the offending URL.
String _invalidUrl(String message, AppLocalizations l10n) {
  const prefix = 'Invalid URL: ';
  if (!message.startsWith(prefix)) return message;
  return l10n.errorInvalidUrl(message.substring(prefix.length));
}

/// Translates a raw [DioException] the way `ApiClient` maps it to an
/// [ApiError].
///
/// The exception's own text is a multi-line dump that also carries the request
/// URL, so it is never shown; only the kind of failure is.
String _describeDioError(DioException error, AppLocalizations l10n) {
  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => l10n.errorRequestTimedOut,
    DioExceptionType.connectionError ||
    DioExceptionType.badCertificate => l10n.errorConnectionFailed,
    DioExceptionType.cancel => l10n.errorRequestCancelled,
    DioExceptionType.badResponse => switch (error.response?.statusCode) {
      401 || 403 => l10n.errorUnauthorized,
      404 => l10n.errorNotFound,
      final int status when status >= 500 => l10n.errorServer,
      _ => l10n.errorUnknown,
    },
    DioExceptionType.unknown => l10n.errorUnknown,
  };
}
