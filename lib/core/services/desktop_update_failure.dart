import 'dart:ui';

import '../l10n/app_locale.dart';

/// Why a native desktop update could not be prepared or installed.
enum DesktopUpdateFailure {
  /// The detached installer did not report readiness in time.
  installerNotStarted,

  /// The release asset does not match the expected verified package.
  unverifiedPackage,

  /// The folder holding the installed application is not writable.
  readOnlyFolder,

  /// The downloaded package failed its size or SHA-256 verification.
  verificationFailed,

  /// The Linux package is not an x64 AppImage.
  notAppImage,

  /// The downloaded application reports another version than the release.
  versionMismatch,

  /// The running Linux build was not started from an AppImage.
  linuxRequiresAppImage,

  /// The running Windows build is not a complete release directory.
  windowsIncomplete,

  /// The running macOS build is not an installed `Arrmate.app` bundle.
  macBundleRequired,

  /// A platform tool used to prepare the package failed; the detail names it.
  prepareFailed,

  /// The update archive contains a path escaping the staging folder.
  archiveUnsafePath,

  /// The update archive exceeds its extraction size or entry limits.
  archiveTooLarge,

  /// The update archive contains a symbolic link escaping the staging folder.
  archiveUnsafeLink,

  /// The update archive writes a file through a symbolic link.
  archiveWritesThroughLink,

  /// The update archive lacks files the application needs.
  archiveMissingFiles,
}

/// Error raised while preparing or installing a desktop update.
///
/// Extends [StateError] so existing handlers keep working; [message] stays in
/// English for logs, while [localizedMessage] gives the text to show users.
class DesktopUpdateException extends StateError {
  /// Creates the error for [failure], with an optional [detail] (the tool
  /// name for [DesktopUpdateFailure.prepareFailed]).
  DesktopUpdateException(this.failure, [this.detail])
    : super(
        _describe(failure, detail, appLocalizationsFor(const Locale('en'))),
      );

  /// Why the update failed.
  final DesktopUpdateFailure failure;

  /// Value interpolated in the message, when [failure] needs one.
  final String? detail;

  /// Returns the user-facing message in the language of [l10n].
  String localizedMessage(AppLocalizations l10n) =>
      _describe(failure, detail, l10n);
}

String _describe(
  DesktopUpdateFailure failure,
  String? detail,
  AppLocalizations l10n,
) {
  return switch (failure) {
    DesktopUpdateFailure.installerNotStarted =>
      l10n.coreUpdateInstallerNotStarted,
    DesktopUpdateFailure.unverifiedPackage => l10n.coreUpdateUnverifiedPackage,
    DesktopUpdateFailure.readOnlyFolder => l10n.coreUpdateReadOnlyFolder,
    DesktopUpdateFailure.verificationFailed =>
      l10n.coreUpdateVerificationFailed,
    DesktopUpdateFailure.notAppImage => l10n.coreUpdateNotAppImage,
    DesktopUpdateFailure.versionMismatch => l10n.coreUpdateVersionMismatch,
    DesktopUpdateFailure.linuxRequiresAppImage =>
      l10n.coreUpdateLinuxRequiresAppImage,
    DesktopUpdateFailure.windowsIncomplete => l10n.coreUpdateWindowsIncomplete,
    DesktopUpdateFailure.macBundleRequired => l10n.coreUpdateMacBundleRequired,
    DesktopUpdateFailure.prepareFailed => l10n.coreUpdatePrepareFailed(
      detail ?? '',
    ),
    DesktopUpdateFailure.archiveUnsafePath => l10n.coreUpdateArchiveUnsafePath,
    DesktopUpdateFailure.archiveTooLarge => l10n.coreUpdateArchiveTooLarge,
    DesktopUpdateFailure.archiveUnsafeLink => l10n.coreUpdateArchiveUnsafeLink,
    DesktopUpdateFailure.archiveWritesThroughLink =>
      l10n.coreUpdateArchiveWritesThroughLink,
    DesktopUpdateFailure.archiveMissingFiles =>
      l10n.coreUpdateArchiveMissingFiles,
  };
}
