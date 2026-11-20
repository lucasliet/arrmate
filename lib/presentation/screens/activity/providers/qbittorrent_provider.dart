import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../domain/models/models.dart';
import '../../../../presentation/providers/data_providers.dart';
import '../../../../presentation/providers/instances_provider.dart';

final qbittorrentTorrentsProvider =
    AsyncNotifierProvider.autoDispose<QBittorrentNotifier, List<Torrent>>(
      QBittorrentNotifier.new,
    );

class QBittorrentNotifier extends AutoDisposeAsyncNotifier<List<Torrent>> {
  /// Pace of the polls that wait for qBittorrent to report a pause or resume.
  static const Duration _settleInterval = Duration(seconds: 1);

  /// How many quick polls a pause or resume may take before giving up.
  static const int _maxSettlePolls = 5;

  Timer? _timer;
  bool _isDisposed = false;

  /// Hashes whose pause or resume the server has not reported yet, mapped to
  /// whether they are expected to be paused.
  final Map<String, bool> _expectedPaused = {};
  int _settlePollsLeft = 0;

  @override
  Future<List<Torrent>> build() async {
    _isDisposed = false;
    ref.onDispose(() {
      _isDisposed = true;
      _timer?.cancel();
    });

    // Opening the list (or invalidating it) is something the user did, so it
    // may try to log in again after the credentials were refused.
    ref.read(qbittorrentServiceProvider)?.allowAuthenticationRetry();

    // Initial fetch
    return _fetchTorrents();
  }

  /// Fetches the list and schedules the next poll.
  ///
  /// With [keepOnError], a failure leaves the list already on screen in place
  /// instead of replacing it with the error. Only polls ask for it, since the
  /// user did not trigger them; opening and refreshing the list report it.
  Future<List<Torrent>> _fetchTorrents({bool keepOnError = false}) async {
    final service = ref.read(qbittorrentServiceProvider);
    if (service == null) {
      _schedulePolling(const Duration(seconds: 30));
      return [];
    }

    try {
      final torrents = await service.getTorrents();
      _schedulePolling(_nextPollInterval(torrents));
      return torrents;
    } catch (e, stack) {
      _clearExpectedStates();
      logger.error('[QBittorrentNotifier] Failed to fetch torrents', e, stack);
      // Refused credentials do not fix themselves. Polling on would ask the
      // server to log in again every minute, and qBittorrent bans an IP after a
      // few failed logins. The error also has to show even when a list is
      // already on screen, or the user would keep reading stale data.
      if (e is UnauthorizedError) rethrow;
      if (!_isDisposed) {
        // If error, retry slower
        _schedulePolling(const Duration(seconds: 60));
      }
      // A poll that fails keeps the data it has, to avoid flickering the UI.
      // An error already on screen stays: the old data it carries must not
      // replace it, or the failure would vanish by itself.
      if (keepOnError && state.hasValue && !state.hasError) {
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
        _fetchTorrents(keepOnError: true)
            .then((data) {
              if (!_isDisposed) state = AsyncValue.data(data);
            })
            .catchError((e, stack) {
              if (!_isDisposed) state = AsyncValue.error(e, stack);
            });
      }
    });
  }

  /// Records that [hashes] were just paused or resumed, so the next polls
  /// come quickly until the server reports it.
  void _expectPausedState(List<String> hashes, {required bool paused}) {
    for (final hash in hashes) {
      _expectedPaused[hash] = paused;
    }
    _settlePollsLeft = _maxSettlePolls;
  }

  /// Forgets the pauses and resumes still waiting for the server.
  void _clearExpectedStates() {
    _expectedPaused.clear();
    _settlePollsLeft = 0;
  }

  /// Returns how long to wait before the poll that follows [torrents].
  ///
  /// qBittorrent accepts a pause or resume at once but only reports the new
  /// state on its next refresh (1.5s by default), so the list read right after
  /// the action is still the old one. While a torrent in [torrents] has not
  /// reached the state asked for, the next poll comes after [_settleInterval],
  /// at most [_maxSettlePolls] times. Otherwise the regular pace applies.
  Duration _nextPollInterval(List<Torrent> torrents) {
    final pausedByHash = {
      for (final torrent in torrents) torrent.hash: torrent.status.isPaused,
    };
    _expectedPaused.removeWhere((hash, paused) {
      final reported = pausedByHash[hash];
      return reported == null || reported == paused;
    });

    if (_expectedPaused.isEmpty || _settlePollsLeft <= 0) {
      _clearExpectedStates();
      return _calculatePollingInterval(torrents);
    }

    _settlePollsLeft--;
    return _settleInterval;
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
    _clearExpectedStates();
    ref.read(qbittorrentServiceProvider)?.allowAuthenticationRetry();
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchTorrents);
  }

  Future<void> pauseTorrents(List<String> hashes) async {
    final service = ref.read(qbittorrentServiceProvider);
    if (service == null) return;
    await service.pauseTorrents(hashes);
    _expectPausedState(hashes, paused: true);
    ref.invalidateSelf();
  }

  Future<void> resumeTorrents(List<String> hashes) async {
    final service = ref.read(qbittorrentServiceProvider);
    if (service == null) return;
    await service.resumeTorrents(hashes);
    _expectPausedState(hashes, paused: false);
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
