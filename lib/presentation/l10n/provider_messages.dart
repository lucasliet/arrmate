import 'dart:ui';

import 'package:apple_foundation_models/apple_foundation_models.dart';

import '../../core/l10n/app_locale.dart';
import '../../core/services/assistant_apple_intelligence_service.dart';
import '../../core/services/backup_service.dart';
import '../../core/services/google_auth.dart';
import 'error_messages.dart';

/// Messages the backup notifier reports to the user.
///
/// The notifier stores the kind (plus an optional detail) in its state instead
/// of translated text, so the screen translates it when it renders and a
/// language change applies to a message that is already on screen.
enum BackupMessageKind {
  /// A backup was requested without a Google session.
  signedOut,

  /// A Drive backup finished.
  completed,

  /// A Drive backup failed; the detail is the error.
  failed,

  /// Google Drive holds no backup.
  notFound,

  /// The backup file is corrupted or from an unsupported version.
  corrupt,

  /// Reading the Drive backup failed; the detail is the error.
  loadFailed,

  /// A local export finished.
  exported,

  /// A local export failed; the detail is the error.
  exportFailed,

  /// Reading a local backup file failed; the detail is the error.
  readFileFailed,

  /// A restore finished; the detail is a [BackupRestoreSummary].
  restored,

  /// A restore failed; the detail is the error.
  restoreFailed,

  /// The Google session was rejected.
  sessionExpired,

  /// Signing in failed; the detail is the error.
  signInFailed,
}

/// Translation of [BackupMessageKind].
extension BackupMessageKindL10n on BackupMessageKind {
  /// Returns this message in the language of [l10n].
  ///
  /// [detail] is the error or [BackupRestoreSummary] the notifier attached.
  String localize(AppLocalizations l10n, [Object? detail]) {
    String described() {
      final message = detail == null ? '' : describeError(detail, l10n).trim();
      return message.isEmpty ? l10n.providerBackupUnknownError : message;
    }

    return switch (this) {
      BackupMessageKind.signedOut => l10n.providerBackupSignedOut,
      BackupMessageKind.completed => l10n.providerBackupCompleted,
      BackupMessageKind.failed => l10n.providerBackupFailed(described()),
      BackupMessageKind.notFound => l10n.providerBackupNotFound,
      BackupMessageKind.corrupt => l10n.providerBackupCorrupt,
      BackupMessageKind.loadFailed => l10n.providerBackupLoadFailed(
        described(),
      ),
      BackupMessageKind.exported => l10n.providerBackupExported,
      BackupMessageKind.exportFailed => l10n.providerBackupExportFailed(
        described(),
      ),
      BackupMessageKind.readFileFailed => l10n.providerBackupReadFileFailed(
        described(),
      ),
      BackupMessageKind.restored when detail is BackupRestoreSummary =>
        l10n.providerBackupRestored(detail.restoredKeys, detail.instanceCount),
      BackupMessageKind.restored => l10n.providerBackupRestored(0, 0),
      BackupMessageKind.restoreFailed => l10n.providerBackupRestoreFailed(
        described(),
      ),
      BackupMessageKind.sessionExpired => l10n.providerBackupSessionExpired,
      BackupMessageKind.signInFailed when detail is GoogleOAuthException =>
        detail.localizedMessage(l10n),
      BackupMessageKind.signInFailed => l10n.providerBackupSignInFailed,
    };
  }

  /// Returns this message in English, the fallback kept in the state.
  String english([Object? detail]) =>
      localize(appLocalizationsFor(const Locale('en')), detail);
}

/// Failures the assistant notifier reports to the user.
///
/// Stored in the state instead of translated text, like [BackupMessageKind].
enum AssistantErrorKind {
  /// Initializing the assistant resources failed.
  initFailed,

  /// Refreshing the installed models failed.
  refreshModelsFailed,

  /// Importing a model failed.
  importFailed,

  /// Downloading a model failed; the detail is the error.
  downloadFailed,

  /// The selected model no longer exists.
  modelNotFound,

  /// Enabling the cloud model failed.
  enableOnlineFailed,

  /// Apple Intelligence is unavailable; the detail is the availability.
  appleUnavailable,

  /// A message was sent without a selected model.
  selectModelFirst,

  /// Apple Intelligence failed; the detail is the exception.
  appleFailed,

  /// Generating a reply failed.
  generateFailed,

  /// Deleting a model failed.
  deleteFailed,

  /// The selected model cannot call tools.
  noToolCalling,

  /// Loading the selected model failed.
  loadModelFailed,
}

/// Translation of [AssistantErrorKind].
extension AssistantErrorKindL10n on AssistantErrorKind {
  /// Returns this failure in the language of [l10n].
  ///
  /// [detail] is the error or availability the notifier attached.
  String localize(AppLocalizations l10n, [Object? detail]) {
    return switch (this) {
      AssistantErrorKind.initFailed => l10n.providerAssistantInitFailed,
      AssistantErrorKind.refreshModelsFailed =>
        l10n.providerAssistantRefreshModelsFailed,
      AssistantErrorKind.importFailed => l10n.providerAssistantImportFailed,
      AssistantErrorKind.downloadFailed => l10n.providerAssistantDownloadFailed(
        describeError(detail ?? '', l10n),
      ),
      AssistantErrorKind.modelNotFound => l10n.providerAssistantModelNotFound,
      AssistantErrorKind.enableOnlineFailed =>
        l10n.providerAssistantEnableOnlineFailed,
      AssistantErrorKind.appleUnavailable
          when detail is AppleFoundationModelsAvailability =>
        detail.localizedUnavailableReason(l10n) ?? '',
      AssistantErrorKind.appleUnavailable => '',
      AssistantErrorKind.selectModelFirst =>
        l10n.providerAssistantSelectModelFirst,
      AssistantErrorKind.appleFailed
          when detail is AssistantAppleIntelligenceException =>
        detail.localizedMessage(l10n),
      AssistantErrorKind.appleFailed => l10n.providerAssistantGenerateFailed,
      AssistantErrorKind.generateFailed => l10n.providerAssistantGenerateFailed,
      AssistantErrorKind.deleteFailed => l10n.providerAssistantDeleteFailed,
      AssistantErrorKind.noToolCalling => l10n.providerAssistantNoToolCalling,
      AssistantErrorKind.loadModelFailed =>
        l10n.providerAssistantLoadModelFailed,
    };
  }

  /// Returns this failure in English, the fallback kept in the state.
  String english([Object? detail]) =>
      localize(appLocalizationsFor(const Locale('en')), detail);
}
