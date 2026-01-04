import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ota_update/ota_update.dart';
import '../../core/services/update_service.dart';

enum UpdateStatus {
  idle,
  checking,
  available,
  downloading,
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
  @override
  UpdateState build() => UpdateState();

  /// Checks for updates from GitHub.
  /// [force] if true, ignores the daily check limit.
  Future<void> checkForUpdate({bool force = false}) async {
    state = state.copyWith(status: UpdateStatus.checking);
    
    final updateService = ref.read(updateServiceProvider);
    final info = await updateService.checkForUpdate(force: force);

    if (info != null) {
      state = state.copyWith(
        status: UpdateStatus.available,
        info: info,
      );
    } else {
      state = state.copyWith(status: force ? UpdateStatus.upToDate : UpdateStatus.idle);
      if (force) {
        // Reset to idle after a moment if it was a manual check
        Future.delayed(const Duration(seconds: 3), () {
          if (state.status == UpdateStatus.upToDate) {
            state = state.copyWith(status: UpdateStatus.idle);
          }
        });
      }
    }
  }

  /// Starts the update process.
  void startUpdate() {
    final info = state.info;
    if (info == null) return;

    state = state.copyWith(status: UpdateStatus.downloading, progress: 0);

    try {
      OtaUpdate().execute(
        info.downloadUrl,
        destinationFilename: 'arrmate_${info.version}.apk',
      ).listen(
        (OtaEvent event) {
          switch (event.status) {
            case OtaStatus.DOWNLOADING:
              state = state.copyWith(progress: double.tryParse(event.value ?? '0') ?? 0);
              break;
            case OtaStatus.INSTALLATION_DONE:
            case OtaStatus.INSTALLING:
              state = state.copyWith(status: UpdateStatus.idle);
              break;
            case OtaStatus.ALREADY_RUNNING_ERROR:
            case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
            case OtaStatus.INTERNAL_ERROR:
            case OtaStatus.DOWNLOAD_ERROR:
            case OtaStatus.CHECKSUM_ERROR:
            case OtaStatus.INSTALLATION_ERROR:
              state = state.copyWith(
                status: UpdateStatus.error,
                errorMessage: 'Erro na atualização: ${event.status.name}',
              );
              break;
          }
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
