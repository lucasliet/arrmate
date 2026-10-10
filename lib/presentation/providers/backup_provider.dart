import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/google_oauth_config.dart';
import '../../core/services/backup_scheduler.dart';
import '../../core/services/backup_service.dart';
import '../../core/services/google_auth.dart';
import '../../core/services/google_drive_service.dart';
import '../../core/services/google_oauth_service.dart';
import '../../core/services/logger_service.dart';
import 'instances_provider.dart';
import 'settings_provider.dart';

/// Exposes the [BackupService] that snapshots and restores preferences.
final backupServiceProvider = Provider<BackupService>((ref) => BackupService());

/// Exposes the Google Drive client wired to the shared OAuth session.
final googleDriveServiceProvider = Provider<GoogleDriveService>(
  (ref) =>
      GoogleDriveService(tokenProvider: ref.watch(googleOAuthServiceProvider)),
);

/// Temporarily disables automatic backups, e.g. right after a restore.
final backupAutoBackupSuppressedProvider = StateProvider<bool>((ref) => false);

/// Exposes whether this build carries the OAuth client configuration.
///
/// Wrapped in a provider so tests can replace it; production always reads
/// [isGoogleOAuthConfigured].
final backupConfiguredProvider = Provider<bool>(
  (ref) => isGoogleOAuthConfigured,
);

/// State of the Google Drive backup feature.
class BackupState {
  /// Whether this build carries the OAuth client configuration.
  final bool isConfigured;

  /// Whether a Google session is currently authorized.
  final bool isSignedIn;

  /// E-mail of the signed-in account, when signed in.
  final String? accountEmail;

  /// When the last backup finished, persisted across sessions.
  final DateTime? lastBackupAt;

  /// When the backup stored in Google Drive was last modified, or null when
  /// none exists or it has not been checked yet.
  final DateTime? remoteBackupAt;

  /// Drive modification time of the backup this device last uploaded or
  /// restored, persisted across sessions.
  final DateTime? syncedRemoteAt;

  /// Whether a long-running action (sign-in, backup, restore) is running.
  final bool isWorking;

  /// Last user-readable error, cleared when the next action starts.
  final String? errorMessage;

  /// Transient hint for the user, e.g. the web sign-in redirect notice.
  final String? statusMessage;

  const BackupState({
    this.isConfigured = false,
    this.isSignedIn = false,
    this.accountEmail,
    this.lastBackupAt,
    this.remoteBackupAt,
    this.syncedRemoteAt,
    this.isWorking = false,
    this.errorMessage,
    this.statusMessage,
  });

  /// Whether Google Drive holds a backup this device has neither uploaded nor
  /// restored, for example one made from another device.
  ///
  /// A device that has backed up before the sync time was tracked counts as in
  /// sync, so an upgrade does not raise a false prompt.
  bool get hasRemoteBackupToRestore {
    final remote = remoteBackupAt;
    if (remote == null) return false;
    final synced = syncedRemoteAt;
    if (synced != null) return remote.isAfter(synced);
    return lastBackupAt == null;
  }

  /// Returns a copy of this state with the given fields replaced.
  BackupState copyWith({
    bool? isConfigured,
    bool? isSignedIn,
    String? accountEmail,
    DateTime? lastBackupAt,
    DateTime? remoteBackupAt,
    DateTime? syncedRemoteAt,
    bool? isWorking,
    String? errorMessage,
    String? statusMessage,
  }) {
    return BackupState(
      isConfigured: isConfigured ?? this.isConfigured,
      isSignedIn: isSignedIn ?? this.isSignedIn,
      accountEmail: accountEmail ?? this.accountEmail,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      remoteBackupAt: remoteBackupAt ?? this.remoteBackupAt,
      syncedRemoteAt: syncedRemoteAt ?? this.syncedRemoteAt,
      isWorking: isWorking ?? this.isWorking,
      errorMessage: errorMessage ?? this.errorMessage,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

/// Drives the Google Drive backup: session, manual actions, auto-backup.
class BackupNotifier extends Notifier<BackupState> {
  /// SharedPreferences key holding the last successful backup timestamp.
  static const String lastBackupKey = 'last_backup_at';

  /// SharedPreferences key holding the Drive modification time of the backup
  /// this device last uploaded or restored.
  static const String syncedRemoteBackupKey = 'last_backup_remote_at';

  static const String _sessionExpiredMessage =
      'Google session expired. Sign in again.';
  static const String _redirectPendingMessage =
      'Finish signing in in the browser, then reopen Arrmate.';
  static const String _signedOutBackupMessage = 'Sign in to Google first.';
  static const String _backupCompletedMessage = 'Backup completed.';
  static const String _noBackupMessage =
      'No backup found in your Google Drive.';
  static const String _corruptBackupMessage =
      'The backup file is corrupted or from an unsupported version.';
  static const Duration _suppressionDuration = Duration(minutes: 2);

  Timer? _suppressionTimer;
  bool _disposed = false;

  @override
  BackupState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _suppressionTimer?.cancel();
      _suppressionTimer = null;
    });
    unawaited(_init());
    return const BackupState();
  }

  /// Restores the persisted backup timestamp and, on configured builds, the
  /// previously authorized Google session.
  Future<void> _init() async {
    try {
      final isConfigured = ref.read(backupConfiguredProvider);
      final prefs = await SharedPreferences.getInstance();
      final lastBackupRaw = prefs.getString(lastBackupKey);
      final syncedRemoteRaw = prefs.getString(syncedRemoteBackupKey);
      var nextState = state.copyWith(
        isConfigured: isConfigured,
        lastBackupAt: lastBackupRaw == null
            ? null
            : DateTime.tryParse(lastBackupRaw),
        syncedRemoteAt: syncedRemoteRaw == null
            ? null
            : DateTime.tryParse(syncedRemoteRaw),
      );
      if (isConfigured) {
        try {
          final account = await ref
              .read(googleOAuthServiceProvider)
              .restoreSession();
          if (account != null) {
            nextState = nextState.copyWith(
              isSignedIn: true,
              accountEmail: account.email,
            );
            logger.info('[Backup] Session restored for ${account.email}');
          }
        } catch (error, stackTrace) {
          logger.warning('[Backup] Session restore failed', error, stackTrace);
        }
      }
      if (_disposed) return;
      state = nextState;
      if (nextState.isSignedIn) await refreshRemoteBackup();
    } catch (error, stackTrace) {
      logger.warning('[Backup] Initialization failed', error, stackTrace);
    }
  }

  /// Looks up the backup stored in Google Drive so the screen can show when it
  /// was made and offer to restore a backup created on another device.
  ///
  /// Failures other than an expired session are logged and leave the state
  /// untouched, since this check is informational.
  Future<void> refreshRemoteBackup() async {
    if (!state.isSignedIn) return;
    try {
      final info = await ref.read(googleDriveServiceProvider).findBackupFile();
      if (_disposed) return;
      state = state.copyWith(remoteBackupAt: info?.modifiedTime);
      logger.info(
        '[Backup] Remote backup: ${info?.modifiedTime.toIso8601String() ?? 'none'}',
      );
    } on DriveAuthException {
      logger.warning('[Backup] Session expired while checking the backup');
      if (_disposed) return;
      state = _sessionExpiredState();
    } catch (error, stackTrace) {
      logger.warning('[Backup] Remote backup check failed', error, stackTrace);
    }
  }

  /// Runs the interactive Google sign-in flow and updates the session state.
  ///
  /// A pending web redirect is surfaced through
  /// [BackupState.statusMessage] instead of an error.
  Future<void> signIn() async {
    state = _workingState();
    try {
      final account = await ref.read(googleOAuthServiceProvider).signIn();
      state = state.copyWith(
        isSignedIn: true,
        accountEmail: account.email,
        isWorking: false,
      );
      logger.info('[Backup] Signed in as ${account.email}');
      await refreshRemoteBackup();
    } on GoogleOAuthRedirectPending {
      logger.info('[Backup] Sign-in continues in the browser');
      state = state.copyWith(
        isWorking: false,
        statusMessage: _redirectPendingMessage,
      );
    } catch (error, stackTrace) {
      logger.error('[Backup] Sign-in failed', error, stackTrace);
      state = state.copyWith(
        isWorking: false,
        errorMessage: _signInErrorMessage(error),
      );
    }
  }

  /// Revokes the Google session while keeping the last backup timestamp.
  Future<void> signOut() async {
    state = _workingState();
    try {
      await ref.read(googleOAuthServiceProvider).signOut();
      logger.info('[Backup] Signed out');
    } catch (error, stackTrace) {
      logger.warning('[Backup] Sign-out failed', error, stackTrace);
    } finally {
      if (!_disposed) {
        state = BackupState(
          isConfigured: state.isConfigured,
          lastBackupAt: state.lastBackupAt,
          syncedRemoteAt: state.syncedRemoteAt,
        );
      }
    }
  }

  /// Uploads a fresh payload to Google Drive and persists the timestamp.
  Future<void> backupNow() async {
    if (!state.isSignedIn) {
      state = _workingState().copyWith(
        isWorking: false,
        errorMessage: _signedOutBackupMessage,
      );
      return;
    }
    state = _workingState();
    try {
      final payload = await ref.read(backupServiceProvider).createPayload();
      final backup = await ref
          .read(googleDriveServiceProvider)
          .uploadBackup(payload.toEncodedJson());
      await _recordSync(payload.createdAt, backup.modifiedTime);
      if (_disposed) return;
      state = state.copyWith(
        isWorking: false,
        lastBackupAt: payload.createdAt,
        remoteBackupAt: backup.modifiedTime,
        syncedRemoteAt: backup.modifiedTime,
        statusMessage: _backupCompletedMessage,
      );
      logger.info('[Backup] Backup uploaded as ${backup.id}');
    } on DriveAuthException {
      logger.warning('[Backup] Session expired during backup');
      if (_disposed) return;
      state = _sessionExpiredState();
    } catch (error, stackTrace) {
      logger.error('[Backup] Backup failed', error, stackTrace);
      if (_disposed) return;
      state = state.copyWith(
        isWorking: false,
        errorMessage: 'Backup failed: ${_describe(error)}',
      );
    }
  }

  /// Uploads a fresh payload silently, skipping failures without disturbing
  /// the UI state.
  ///
  /// Returns immediately when automatic backups are suppressed, no session is
  /// authorized or another backup action is already running.
  Future<void> runAutoBackup() async {
    final suppressed = ref.read(backupAutoBackupSuppressedProvider);
    if (suppressed || !state.isSignedIn || state.isWorking) return;
    if (state.hasRemoteBackupToRestore) {
      logger.info(
        '[Backup] Automatic backup skipped: Drive holds a backup this device '
        'has not restored',
      );
      return;
    }
    try {
      final payload = await ref.read(backupServiceProvider).createPayload();
      final backup = await ref
          .read(googleDriveServiceProvider)
          .uploadBackup(payload.toEncodedJson());
      await _recordSync(payload.createdAt, backup.modifiedTime);
      if (_disposed) return;
      state = state.copyWith(
        lastBackupAt: payload.createdAt,
        remoteBackupAt: backup.modifiedTime,
        syncedRemoteAt: backup.modifiedTime,
      );
      logger.info('[Backup] Automatic backup completed');
    } catch (error, stackTrace) {
      logger.warning('[Backup] Automatic backup failed', error, stackTrace);
    }
  }

  /// Downloads the stored backup and parses it for a restore preview, or
  /// returns null with an [BackupState.errorMessage] when it cannot be read.
  Future<BackupPayload?> fetchBackupPreview() async {
    state = _workingState();
    try {
      final encoded = await ref
          .read(googleDriveServiceProvider)
          .downloadBackup();
      final payload = await ref
          .read(backupServiceProvider)
          .loadBackupPreview(encoded);
      if (!_disposed) {
        state = state.copyWith(isWorking: false);
      }
      return payload;
    } on DriveBackupNotFoundException {
      logger.warning('[Backup] No backup file exists in Google Drive');
      if (_disposed) return null;
      state = state.copyWith(isWorking: false, errorMessage: _noBackupMessage);
      return null;
    } on BackupFormatException catch (error) {
      logger.warning('[Backup] Backup file rejected: $error');
      if (_disposed) return null;
      state = state.copyWith(
        isWorking: false,
        errorMessage: _corruptBackupMessage,
      );
      return null;
    } on DriveAuthException {
      logger.warning('[Backup] Session expired while downloading backup');
      if (_disposed) return null;
      state = _sessionExpiredState();
      return null;
    } catch (error, stackTrace) {
      logger.error('[Backup] Backup preview failed', error, stackTrace);
      if (_disposed) return null;
      state = state.copyWith(
        isWorking: false,
        errorMessage: 'Could not load the backup: ${_describe(error)}',
      );
      return null;
    }
  }

  /// Restores [payload] and refreshes every affected provider, suppressing
  /// automatic backups for a short window afterwards.
  ///
  /// Returns whether the restore completed successfully.
  Future<bool> restoreFrom(BackupPayload payload) async {
    if (state.isWorking) return false;
    state = _workingState();
    ref.read(backupAutoBackupSuppressedProvider.notifier).state = true;
    try {
      final summary = await ref.read(backupServiceProvider).restore(payload);
      final restoredRemoteAt = state.remoteBackupAt;
      await _recordSync(payload.createdAt, restoredRemoteAt);
      ref.invalidate(instancesProvider);
      ref.invalidate(settingsProvider);
      if (!_disposed) {
        state = state.copyWith(
          isWorking: false,
          lastBackupAt: payload.createdAt,
          syncedRemoteAt: restoredRemoteAt,
          statusMessage:
              'Restored ${summary.restoredKeys} settings and '
              '${summary.instanceCount} instances.',
        );
        logger.info('[Backup] ${state.statusMessage}');
      }
      _scheduleSuppressionReEnable();
      return true;
    } catch (error, stackTrace) {
      logger.error('[Backup] Restore failed', error, stackTrace);
      _clearSuppression();
      if (!_disposed) {
        state = state.copyWith(
          isWorking: false,
          errorMessage: 'Restore failed: ${_describe(error)}',
        );
      }
      return false;
    }
  }

  /// Persists that this device is in sync with the backup made at [createdAt],
  /// whose Drive modification time was [remoteModifiedAt] when known.
  Future<void> _recordSync(
    DateTime createdAt,
    DateTime? remoteModifiedAt,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lastBackupKey, createdAt.toIso8601String());
    if (remoteModifiedAt != null) {
      await prefs.setString(
        syncedRemoteBackupKey,
        remoteModifiedAt.toIso8601String(),
      );
    }
  }

  /// Re-enables automatic backups once the restored data has settled.
  void _scheduleSuppressionReEnable() {
    _suppressionTimer?.cancel();
    _suppressionTimer = Timer(_suppressionDuration, () {
      _suppressionTimer = null;
      if (_disposed) return;
      ref.read(backupAutoBackupSuppressedProvider.notifier).state = false;
      logger.debug('[Backup] Automatic backups re-enabled after restore');
    });
  }

  /// Cancels any pending re-enable and turns automatic backups back on.
  void _clearSuppression() {
    _suppressionTimer?.cancel();
    _suppressionTimer = null;
    if (_disposed) return;
    ref.read(backupAutoBackupSuppressedProvider.notifier).state = false;
  }

  /// Copies the current session into a working state with transient messages
  /// cleared and [BackupState.isWorking] set.
  BackupState _workingState() {
    return BackupState(
      isConfigured: state.isConfigured,
      isSignedIn: state.isSignedIn,
      accountEmail: state.accountEmail,
      lastBackupAt: state.lastBackupAt,
      remoteBackupAt: state.remoteBackupAt,
      syncedRemoteAt: state.syncedRemoteAt,
      isWorking: true,
    );
  }

  /// Copies the persisted facts into a signed-out state reporting an expired
  /// session.
  BackupState _sessionExpiredState() {
    return BackupState(
      isConfigured: state.isConfigured,
      lastBackupAt: state.lastBackupAt,
      syncedRemoteAt: state.syncedRemoteAt,
      errorMessage: _sessionExpiredMessage,
    );
  }

  /// Picks the user-readable message for a failed sign-in.
  String _signInErrorMessage(Object error) {
    if (error is GoogleOAuthException) return error.message;
    return 'Sign-in failed. Check your connection and try again.';
  }

  /// Trims [error] into a short text safe to embed in an error message.
  String _describe(Object error) {
    final message = error.toString().trim();
    return message.isEmpty ? 'unknown error' : message;
  }
}

/// Provider for [BackupNotifier], the state of the Google Drive backup.
final backupProvider = NotifierProvider<BackupNotifier, BackupState>(
  BackupNotifier.new,
);

/// Reacts to instance and settings changes by scheduling an auto-backup.
///
/// Must be watched once from the app root (see `ArrmateApp`) so the internal
/// listeners stay alive for the whole session.
final automaticBackupListenerProvider = Provider<void>((ref) {
  void schedule() {
    ref.read(backupSchedulerProvider).schedule(() {
      ref.read(backupProvider.notifier).runAutoBackup();
    });
  }

  ref.listen(instancesProvider, (previous, next) {
    if (!identical(previous?.instances, next.instances)) schedule();
  });
  ref.listen(settingsProvider, (previous, next) {
    if (previous != next) schedule();
  });
});
