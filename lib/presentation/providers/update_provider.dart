import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ota_update/ota_update.dart';
import '../../core/services/update_service.dart';
import '../../core/services/logger_service.dart';

// ... (UpdateStatus and UpdateState same as before)

enum UpdateStatus {
  idle,
  checking,
  available,
  downloading,
  installing,
  error,
  upToDate,
}

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

final updateProvider = NotifierProvider<UpdateNotifier, UpdateState>(() {
  return UpdateNotifier();
});

class UpdateNotifier extends Notifier<UpdateState> {
  StreamSubscription<OtaEvent>? _otaSubscription;

  @override
  UpdateState build() {
    ref.onDispose(() {
      _otaSubscription?.cancel();
    });
    return UpdateState();
  }

  /// Checks for updates from GitHub.
  /// [force] if true, ignores the daily check limit.
  Future<void> checkForUpdate({bool force = false}) async {
    state = state.copyWith(status: UpdateStatus.checking);

    final updateService = ref.read(updateServiceProvider);
    final info = await updateService.checkForUpdate(force: force);

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
          if (state.status == statusAfterCheck) {
            state = state.copyWith(status: UpdateStatus.idle);
          }
        });
      }
    }
  }

  /// Starts the update process.
  void startUpdate() {
    logger.info('UpdateNotifier: startUpdate() called');
    logger.info('UpdateNotifier: startUpdate() triggered');
    final info = state.info;
    if (info == null) {
      logger.warning('UpdateNotifier: startUpdate() aborted - info is null in state');
      return;
    }

    logger.info('UpdateNotifier: URL detected: ${info.downloadUrl}');
    _otaSubscription?.cancel();
    state = state.copyWith(status: UpdateStatus.downloading, progress: 0);

    try {
      logger.info('UpdateNotifier: Calling OtaUpdate().execute()...');
      _otaSubscription = OtaUpdate()
          .execute(
            info.downloadUrl,
            destinationFilename: 'arrmate_update.apk',
          )
          .listen(
            (OtaEvent event) {
              logger.debug('UpdateNotifier: OTA Event received: ${event.status} (${event.value})');
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
      state = state.copyWith(
        status: UpdateStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}
