import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/qbittorrent/qbittorrent_models.dart';
import '../../../../presentation/providers/data_providers.dart';
import 'qbittorrent_provider.dart';

/// Fetches the list of files for a specific torrent.
final torrentFilesProvider = FutureProvider.family<List<TorrentFile>, String>((
  ref,
  hash,
) async {
  final service = ref.watch(qbittorrentServiceProvider);
  if (service == null) return [];
  return service.getTorrentFiles(hash);
});

/// Controller for torrent file actions (priority, location).
final torrentActionProvider =
    AsyncNotifierProvider.autoDispose<TorrentActionNotifier, void>(
      TorrentActionNotifier.new,
    );

class TorrentActionNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // No initial state implementation needed
  }

  /// Sets priority for specific files.
  Future<void> setFilePriority(
    String hash,
    List<int> fileIndices,
    FilePriority priority,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(qbittorrentServiceProvider);
      if (service == null) return;
      await service.setFilePriority(hash, fileIndices, priority.value);
      // Invalidate files provider to refresh UI
      ref.invalidate(torrentFilesProvider(hash));
    });
  }

  /// Sets priority for a single file.
  Future<void> setSingleFilePriority(
    String hash,
    int fileIndex,
    FilePriority priority,
  ) async {
    await setFilePriority(hash, [fileIndex], priority);
  }

  /// Moves torrents to a new location.
  Future<void> setTorrentLocation(List<String> hashes, String location) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(qbittorrentServiceProvider);
      if (service == null) return;
      await service.setTorrentLocation(hashes, location);
      // Invalidate main torrents list as location might be shown there (future proofing)
      // or simply because it's a major change.
      // Ideally we should just continue, but invalidating might be good practice.
      // But getTorrents doesn't return location IIRC.
      // Let's just invalidate for safety.
      ref.invalidate(qbittorrentTorrentsProvider);
    });
  }
}
