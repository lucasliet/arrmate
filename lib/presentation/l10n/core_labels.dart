import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_locale.dart';
import '../../core/services/desktop_update_failure.dart';
import '../providers/locale_provider.dart';
import '../providers/update_provider.dart';
import 'error_messages.dart';

/// Returns the translations for the current interface language from [ref],
/// for providers and services that build user-facing text without a
/// [BuildContext].
///
/// The app root keeps [currentLocaleProvider] alive, so it is always
/// initialized while the app runs. When it is not (plain provider containers
/// in tests), English is returned instead of initializing the settings
/// provider, which would hit SharedPreferences.
AppLocalizations readAppLocalizations(Ref ref) {
  if (ref.exists(currentLocaleProvider)) {
    return ref.read(appLocalizationsProvider);
  }
  return appLocalizationsFor(const Locale('en'));
}

/// Translation of the failure held by an [UpdateState].
extension UpdateStateL10n on UpdateState {
  /// Returns [UpdateState.errorMessage] in the language of [l10n], or `null`
  /// when the state holds no error.
  String? localizedErrorMessage(AppLocalizations l10n) {
    final message = errorMessage;
    if (message == null) return null;
    final detail = errorDetail;
    return switch (errorKind) {
      UpdateErrorKind.checkFailed => l10n.coreUpdateCheckFailed,
      UpdateErrorKind.otaFailed => l10n.coreUpdateOtaFailed('$detail'),
      UpdateErrorKind.installFailed when detail is DesktopUpdateException =>
        detail.localizedMessage(l10n),
      UpdateErrorKind.installFailed when detail != null => describeError(
        detail,
        l10n,
      ),
      _ => message,
    };
  }
}
