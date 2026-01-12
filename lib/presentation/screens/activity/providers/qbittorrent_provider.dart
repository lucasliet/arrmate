import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/logger_service.dart';
import '../../../../domain/models/models.dart';
import '../../../../presentation/providers/data_providers.dart';
import '../../../../presentation/providers/instances_provider.dart';

final qbittorrentTorrentsProvider =
    AsyncNotifierProvider.autoDispose<QBittorrentNotifier, List<Torrent>>(
      QBittorrentNotifier.new,
    );

class QBittorrentNotifier extends AutoDisposeAsyncNotifier<List<Torrent>> {
  Timer? _timer;
  bool _isDisposed = false;

  @override
  Future<List<Torrent>> build() async {
    _isDisposed = false;
    ref.onDispose(() {
      _isDisposed = true;
      _timer?.cancel();
    });

    // Initial fetch
    return _fetchTorrents();
  }

  Future<List<Torrent>> _fetchTorrents() async {
    final service = ref.read(qbittorrentServiceProvider);
    if (service == null) {
      _schedulePolling(const Duration(seconds: 30));
      return [];
    }

    try {
      final torrents = await service.getTorrents();
      _schedulePolling(_calculatePollingInterval(torrents));
      return torrents;
    } catch (e, stack) {
      if (!_isDisposed) {
        // If error, retry slower
        _schedulePolling(const Duration(seconds: 60));
      }
      logger.error('[QBittorrentNotifier] Failed to fetch torrents', e, stack);
      // If we already have data, keep it and just log error (to avoid flickering UI)
      if (state.hasValue) {
        return state.value!;
      }
      rethrow;
    }
  }

  void _schedulePolling(Duration interval) {
    _timer?.cancel();
    if (_isDisposed) return;

    _timer = Timer(interval, () {
      if (!_isDisposed) {
        // Use ref.invalidateSelf() or just call _fetchTorrents() and update state
        // InvalidateSelf will trigger build() again which calls _fetchTorrents
        _fetchTorrents()
            .then((data) {
              if (!_isDisposed) state = AsyncValue.data(data);
            })
            .catchError((e, stack) {
              if (!_isDisposed) state = AsyncValue.error(e, stack);
            });
      }
    });
  }

  Duration _calculatePollingInterval(List<Torrent> torrents) {
    final instance = ref.read(currentQBittorrentInstanceProvider);
    final isSlow = instance?.mode == InstanceMode.slow;

    if (torrents.isEmpty) {
      return isSlow ? const Duration(minutes: 1) : const Duration(seconds: 30);
    }

    // Check if any is downloading or active checking
    final hasActiveDownloads = torrents.any(
      (t) =>
          t.status == TorrentStatus.downloading ||
          t.status == TorrentStatus.checkingDL ||
          t.status == TorrentStatus.checkingResumeData,
    );

    if (hasActiveDownloads) {
      // 3s normal, 10s slow
      return isSlow ? const Duration(seconds: 10) : const Duration(seconds: 3);
    }

    // Check if any is seeding or checking upload
    final hasActiveUploads = torrents.any(
      (t) =>
          t.status == TorrentStatus.uploading ||
          t.status == TorrentStatus.checkingUP,
    );

    if (hasActiveUploads) {
      // 15s normal, 30s slow
      return isSlow ? const Duration(seconds: 30) : const Duration(seconds: 15);
    }

    // If all paused or stalled or error
    // 60s normal, 2m slow
    return isSlow ? const Duration(minutes: 2) : const Duration(seconds: 60);
  }

  /// Refreshes the list manually and resets polling.
  Future<void> refresh() async {
    _timer?.cancel();
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchTorrents);
  }

  Future<void> pauseTorrents(List<String> hashes) async {
    final service = ref.read(qbittorrentServiceProvider);
    if (service == null) return;
    await service.pauseTorrents(hashes);
    ref.invalidateSelf();
  }

  Future<void> resumeTorrents(List<String> hashes) async {
    final service = ref.read(qbittorrentServiceProvider);
    if (service == null) return;
    await service.resumeTorrents(hashes);
    ref.invalidateSelf();
  }

  Future<void> deleteTorrents(
    List<String> hashes, {
    bool deleteFiles = false,
  }) async {
    final service = ref.read(qbittorrentServiceProvider);
    if (service == null) return;
    await service.deleteTorrents(hashes, deleteFiles: deleteFiles);
    ref.invalidateSelf();
  }

  Future<void> recheckTorrents(List<String> hashes) async {
    final service = ref.read(qbittorrentServiceProvider);
    if (service == null) return;
    await service.recheckTorrents(hashes);
    ref.invalidateSelf();
  }

  Future<void> addTorrentUrl(AddTorrentRequest request) async {
    final service = ref.read(qbittorrentServiceProvider);
    if (service == null) return;
    await service.addTorrentUrl(request);
    ref.invalidateSelf();
  }

  Future<void> addTorrentFile(AddTorrentRequest request) async {
    final service = ref.read(qbittorrentServiceProvider);
    if (service == null) return;
    await service.addTorrentFile(request);
    ref.invalidateSelf();
  }

  Future<List<String>> fetchCategories() async {
    final service = ref.read(qbittorrentServiceProvider);
    if (service == null) return [];
    try {
      return await service.getCategories();
    } catch (e) {
      logger.error('[QBittorrentNotifier] Failed to fetch categories', e);
      return [];
    }
  }

  Future<List<String>> fetchTags() async {
    final service = ref.read(qbittorrentServiceProvider);
    if (service == null) return [];
    try {
      return await service.getTags();
    } catch (e) {
      logger.error('[QBittorrentNotifier] Failed to fetch tags', e);
      return [];
    }
  }
}
