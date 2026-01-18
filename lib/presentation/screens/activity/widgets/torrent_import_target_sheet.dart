import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/models.dart';
import '../../../widgets/common_widgets.dart';
import '../providers/torrent_import_provider.dart';
import 'torrent_import_files_sheet.dart';

/// Bottom sheet for selecting the target movie or series for import.
class TorrentImportTargetSheet extends ConsumerStatefulWidget {
  final Torrent torrent;

  const TorrentImportTargetSheet({super.key, required this.torrent});

  @override
  ConsumerState<TorrentImportTargetSheet> createState() =>
      _TorrentImportTargetSheetState();
}

class _TorrentImportTargetSheetState
    extends ConsumerState<TorrentImportTargetSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              AppBar(
                title: const Text('Select Target'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
                bottom: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Movies', icon: Icon(Icons.movie_outlined)),
                    Tab(text: 'Series', icon: Icon(Icons.tv_outlined)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.toLowerCase());
                  },
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMoviesList(scrollController),
                    _buildSeriesList(scrollController),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoviesList(ScrollController scrollController) {
    final moviesState = ref.watch(moviesForImportProvider);

    return moviesState.when(
      data: (movies) {
        final filtered = movies.where((m) {
          if (_searchQuery.isEmpty) return true;
          return m.title.toLowerCase().contains(_searchQuery);
        }).toList();

        if (filtered.isEmpty) {
          return const EmptyState(
            icon: Icons.movie_outlined,
            title: 'No Movies Found',
            subtitle: 'No monitored movies match your search.',
          );
        }

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final movie = filtered[index];
            return _buildMovieItem(movie);
          },
        );
      },
      loading: () => const LoadingIndicator(message: 'Loading movies...'),
      error: (error, stack) => ErrorDisplay(
        message: 'Failed to load movies',
        onRetry: () => ref.refresh(moviesForImportProvider),
      ),
    );
  }

  Widget _buildSeriesList(ScrollController scrollController) {
    final seriesState = ref.watch(seriesForImportProvider);

    return seriesState.when(
      data: (series) {
        final filtered = series.where((s) {
          if (_searchQuery.isEmpty) return true;
          return s.title.toLowerCase().contains(_searchQuery);
        }).toList();

        if (filtered.isEmpty) {
          return const EmptyState(
            icon: Icons.tv_outlined,
            title: 'No Series Found',
            subtitle: 'No monitored series match your search.',
          );
        }

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final series = filtered[index];
            return _buildSeriesItem(series);
          },
        );
      },
      loading: () => const LoadingIndicator(message: 'Loading series...'),
      error: (error, stack) => ErrorDisplay(
        message: 'Failed to load series',
        onRetry: () => ref.refresh(seriesForImportProvider),
      ),
    );
  }

  Widget _buildMovieItem(Movie movie) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      child: ListTile(
        leading: movie.hasFile == true
            ? Icon(Icons.check_circle, color: Colors.green)
            : Icon(Icons.movie_outlined, color: theme.colorScheme.primary),
        title: Text(movie.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          movie.year?.toString() ?? 'Unknown year',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _navigateToFilesSheet(isMovie: true, movie: movie),
      ),
    );
  }

  Widget _buildSeriesItem(Series series) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      child: ListTile(
        leading: Icon(Icons.tv_outlined, color: theme.colorScheme.primary),
        title: Text(series.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          series.year?.toString() ?? 'Unknown year',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _navigateToFilesSheet(isMovie: false, series: series),
      ),
    );
  }

  void _navigateToFilesSheet({
    required bool isMovie,
    Movie? movie,
    Series? series,
  }) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TorrentImportFilesSheet(
        torrent: widget.torrent,
        isMovie: isMovie,
        movie: movie,
        series: series,
      ),
    );
  }
}
