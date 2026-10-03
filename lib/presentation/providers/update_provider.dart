import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ota_update/ota_update.dart';
import '../../core/services/update_service.dart';
import '../../core/services/logger_service.dart';
import '../../core/services/desktop_update_service.dart';
import '../../core/platform/platform_capabilities.dart';

/// Provides the native desktop package installer.
final desktopUpdateServiceProvider = Provider((ref) => DesktopUpdateService());

/// Enumerates the possible statuses of the update process.
enum UpdateStatus {
  idle,
  checking,
  available,
  downloading,
  installing,
  error,
  upToDate,
}

/// State for [UpdateNotifier].
class UpdateState {
  final UpdateStatus status;
  final AppUpdateInfo? info;
  final double progress;
  final String? errorMessage;

  UpdateState({
    this.status = UpdateStatus.idle,
    this.info,
    this.progress = 0,
    this.errorMessage,
  });

  UpdateState copyWith({
    UpdateStatus? status,
    AppUpdateInfo? info,
    double? progress,
    String? errorMessage,
  }) {
    return UpdateState(
      status: status ?? this.status,
      info: info ?? this.info,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Manages the application update process, including checking, downloading, and installing updates.
final updateProvider = NotifierProvider<UpdateNotifier, UpdateState>(() {
  return UpdateNotifier();
});

class UpdateNotifier extends Notifier<UpdateState> {
  StreamSubscription<OtaEvent>? _otaSubscription;
  bool _disposed = false;

  @override
  UpdateState build() {
    ref.onDispose(() {
      _disposed = true;
      _otaSubscription?.cancel();
    });
    return UpdateState();
  }

  /// Checks for updates from GitHub.
  /// [force] if true, ignores the daily check limit.
  Future<void> checkForUpdate({bool force = false}) async {
    if (!ref.read(platformCapabilitiesProvider).supportsAppUpdates ||
        {
          UpdateStatus.checking,
          UpdateStatus.downloading,
          UpdateStatus.installing,
        }.contains(state.status)) {
      return;
    }
    state = state.copyWith(status: UpdateStatus.checking);

    final updateService = ref.read(updateServiceProvider);
    final AppUpdateInfo? info;
    try {
      info = await updateService.checkForUpdate(force: force);
    } catch (error, stack) {
      logger.error('[UpdateNotifier] Update check failed', error, stack);
      if (!_disposed) {
        state = state.copyWith(
          status: UpdateStatus.error,
          errorMessage: 'Could not check for updates. Please try again.',
        );
      }
      return;
    }
    if (_disposed) return;

    if (info != null) {
      state = state.copyWith(status: UpdateStatus.available, info: info);
    } else {
      final statusAfterCheck = force
          ? UpdateStatus.upToDate
          : UpdateStatus.idle;
      state = state.copyWith(status: statusAfterCheck);

      if (force) {
        // Reset to idle after a moment if it was a manual check
        Future.delayed(const Duration(seconds: 3), () {
          if (!_disposed && state.status == statusAfterCheck) {
            state = state.copyWith(status: UpdateStatus.idle);
          }
        });
      }
    }
  }

  /// Starts the update process.
  Future<void> startUpdate() async {
    if (!ref.read(platformCapabilitiesProvider).supportsAppUpdates) return;
    if (state.status != UpdateStatus.available &&
        state.status != UpdateStatus.error) {
      return;
    }
    logger.info('UpdateNotifier: startUpdate() called');
    logger.info('UpdateNotifier: startUpdate() triggered');
    final info = state.info;
    if (info == null) {
      logger.warning(
        'UpdateNotifier: startUpdate() aborted - info is null in state',
      );
      return;
    }

    logger.info('UpdateNotifier: URL detected: ${info.downloadUrl}');
    _otaSubscription?.cancel();
    state = state.copyWith(status: UpdateStatus.downloading, progress: 0);

    try {
      if (!kIsWeb &&
          {
            TargetPlatform.windows,
            TargetPlatform.linux,
            TargetPlatform.macOS,
          }.contains(defaultTargetPlatform)) {
        await ref
            .read(desktopUpdateServiceProvider)
            .installUpdate(
              info,
              onProgress: (received, total) {
                if (!_disposed) {
                  state = state.copyWith(
                    progress: total > 0 ? received / total * 100 : 0,
                  );
                }
              },
              onInstalling: () {
                if (!_disposed) {
                  state = state.copyWith(status: UpdateStatus.installing);
                }
              },
            );
        return;
      }
      logger.info('UpdateNotifier: Calling OtaUpdate().execute()...');
      _otaSubscription = OtaUpdate()
          .execute(info.downloadUrl, destinationFilename: 'arrmate_update.apk')
          .listen(
            (OtaEvent event) {
              logger.debug(
                'UpdateNotifier: OTA Event received: ${event.status} (${event.value})',
              );
              switch (event.status) {
                case OtaStatus.DOWNLOADING:
                  state = state.copyWith(
                    progress: double.tryParse(event.value ?? '0') ?? 0,
                  );
                  break;
                case OtaStatus.INSTALLING:
                  logger.info('OTA Update: Starting installation');
                  state = state.copyWith(status: UpdateStatus.installing);
                  break;
                case OtaStatus.INSTALLATION_DONE:
                  logger.info('OTA Update: Installation prompt triggered');
                  state = state.copyWith(status: UpdateStatus.idle);
                  _otaSubscription?.cancel();
                  _otaSubscription = null;
                  break;
                case OtaStatus.ALREADY_RUNNING_ERROR:
                case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
                case OtaStatus.INTERNAL_ERROR:
                case OtaStatus.DOWNLOAD_ERROR:
                case OtaStatus.CHECKSUM_ERROR:
                case OtaStatus.INSTALLATION_ERROR:
                case OtaStatus.CANCELED:
                  logger.error('OTA Update Failed: ${event.status.name}');
                  state = state.copyWith(
                    status: UpdateStatus.error,
                    errorMessage: 'Erro na atualização: ${event.status.name}',
                  );
                  _otaSubscription?.cancel();
                  _otaSubscription = null;
                  break;
              }
            },
            onError: (e, stack) {
              logger.error('OTA Update Stream Error', e, stack);
              state = state.copyWith(
                status: UpdateStatus.error,
                errorMessage: e.toString(),
              );
              _otaSubscription?.cancel();
              _otaSubscription = null;
            },
          );
    } catch (e) {
      if (_disposed) return;
      state = state.copyWith(
        status: UpdateStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}
