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
/// reliably. Any other error falls back to `error.toString()`.
String describeError(Object error, AppLocalizations l10n) {
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
