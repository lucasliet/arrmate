import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/shared/providers/releases_provider.dart';
import 'package:arrmate/presentation/widgets/common_widgets.dart';

/// A modal sheet that searches for and displays available releases for a movie or episode.
class ReleasesSheet extends ConsumerStatefulWidget {
  final int id;
  final bool isMovie; // true for Movie, false for Episode
  final String title;
  final String? episodeCode; // e.g., S01E01 for subtitle

  const ReleasesSheet({
    super.key,
    required this.id,
    required this.isMovie,
    required this.title,
    this.episodeCode,
  });

  @override
  ConsumerState<ReleasesSheet> createState() => _ReleasesSheetState();
}

class _ReleasesSheetState extends ConsumerState<ReleasesSheet> {
  ReleaseSortOption _sortOption = ReleaseSortOption.score;
  bool _sortAscending = false;
  // ignore: unused_field
  final bool _showRejected = true;

  @override
  void initState() {
    super.initState();
    // Default to score descending (best first), rejected handling is done in sort
  }

  List<Release> _sortReleases(List<Release> releases) {
    if (releases.isEmpty) return [];

    final sorted = List<Release>.from(releases);

    sorted.sort((a, b) {
      // Always push rejected to bottom unless we strictly want to sort by other criteria regardless
      // But typically "Non-rejected first" is a heavy weight rule.
      if (a.rejected != b.rejected) {
        return a.rejected ? 1 : -1; // Rejected comes last
      }

      int comparison = 0;
      switch (_sortOption) {
        case ReleaseSortOption.score:
          comparison = a.score.compareTo(b.score);
          break;
        case ReleaseSortOption.seeders:
          comparison = a.seeders.compareTo(b.seeders);
          break;
        case ReleaseSortOption.age:
          comparison = a.age.compareTo(b.age);
          break;
        case ReleaseSortOption.size:
          comparison = a.size.compareTo(b.size);
          break;
        case ReleaseSortOption.indexer:
          comparison = a.indexer.compareTo(b.indexer);
          break;
      }

      return _sortAscending ? comparison : -comparison;
    });

    return sorted;
  }

  Future<void> _onDownload(Release release) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Download Release'),
          content: Text('Are you sure you want to grab "${release.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Download'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      if (!mounted) return;

      await ref
          .read(releaseActionsProvider.notifier)
          .downloadRelease(
            guid: release.guid,
            indexerId: release.indexerId,
            isMovie: widget.isMovie,
          );

      if (!mounted) return;
      Navigator.of(context).pop(); // Close sheet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Release grabbed successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error grabbing release: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine provider
    final releaseListAsync = widget.isMovie
        ? ref.watch(movieReleasesProvider(widget.id))
        : ref.watch(episodeReleasesProvider(widget.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            AppBar(
              title: Column(
                children: [
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.episodeCode != null)
                    Text(
                      widget.episodeCode!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
              centerTitle: true,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  PopupMenuButton<ReleaseSortOption>(
                    icon: const Icon(Icons.sort),
                    initialValue: _sortOption,
                    tooltip: 'Sort by',
                    onSelected: (value) => setState(() => _sortOption = value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: ReleaseSortOption.score,
                        child: Text('Score'),
                      ),
                      const PopupMenuItem(
                        value: ReleaseSortOption.seeders,
                        child: Text('Seeders'),
                      ),
                      const PopupMenuItem(
                        value: ReleaseSortOption.age,
                        child: Text('Age'),
                      ),
                      const PopupMenuItem(
                        value: ReleaseSortOption.size,
                        child: Text('Size'),
                      ),
                      const PopupMenuItem(
                        value: ReleaseSortOption.indexer,
                        child: Text('Indexer'),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      _sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                    ),
                    tooltip: _sortAscending ? 'Ascending' : 'Descending',
                    onPressed: () =>
                        setState(() => _sortAscending = !_sortAscending),
                  ),
                  const Spacer(),
                  Text(
                    '${_sortReleases(releaseListAsync.valueOrNull ?? []).length} results',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: releaseListAsync.when(
                data: (releases) {
                  if (releases.isEmpty) {
                    return const Center(child: Text('No releases found'));
                  }

                  final sortedReleases = _sortReleases(releases);

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: sortedReleases.length,
                    itemBuilder: (context, index) {
                      final release = sortedReleases[index];
                      return _ReleaseTile(
                        release: release,
                        onTap: () => _onDownload(release),
                      );
                    },
                  );
                },
                loading: () => const Center(child: LoadingIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReleaseTile extends StatelessWidget {
  final Release release;
  final VoidCallback onTap;

  const _ReleaseTile({required this.release, required this.onTap});

  String _formatSize(int bytes) {
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRejected = release.rejected;

    return Opacity(
      opacity: isRejected ? 0.5 : 1.0,
      child: ListTile(
        title: Text(
          release.title,
          style: theme.textTheme.bodyMedium?.copyWith(
            decoration: isRejected ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Badge(
                  label: release.quality.quality.name,
                  color: Colors.blueAccent,
                ),
                const SizedBox(width: 4),
                _Badge(label: _formatSize(release.size), color: Colors.grey),
                const SizedBox(width: 4),
                _Badge(label: '${release.age}d', color: Colors.orange),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(release.indexer),
                const Spacer(),
                Icon(Icons.arrow_upward, size: 14, color: Colors.green),
                Text('${release.seeders}'),
                const SizedBox(width: 8),
                Icon(Icons.arrow_downward, size: 14, color: Colors.red),
                Text('${release.leechers}'),
              ],
            ),
            if (isRejected && release.rejections.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  release.rejections.first,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
                ),
              ),
          ],
        ),
        onTap: isRejected ? null : onTap,
        enabled: !isRejected,
        trailing: IconButton(
          icon: const Icon(Icons.download),
          onPressed: isRejected ? null : onTap,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

enum ReleaseSortOption { score, seeders, age, size, indexer }
