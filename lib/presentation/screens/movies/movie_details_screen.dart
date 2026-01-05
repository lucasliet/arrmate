import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/models/models.dart';
import '../../providers/instances_provider.dart';
import '../../shared/widgets/releases_sheet.dart';
import '../../widgets/common_widgets.dart';
import 'providers/movie_details_provider.dart';
import 'widgets/movie_poster.dart';
import 'movie_edit_screen.dart';

class MovieDetailsScreen extends ConsumerWidget {
  final int movieId;

  const MovieDetailsScreen({super.key, required this.movieId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movieState = ref.watch(movieDetailsProvider(movieId));

    return Scaffold(
      body: movieState.when(
        data: (movie) => _buildContent(context, ref, movie),
        error: (error, stack) => Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: ErrorDisplay(
            message: error.toString(),
            onRetry: () => ref.refresh(movieDetailsProvider(movieId)),
          ),
        ),
        loading: () => const Scaffold(
          body: LoadingIndicator(message: 'Loading details...'),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Movie movie) {
    final instance = ref.watch(currentRadarrInstanceProvider);
    final fanartUrl = movie.images.where((i) => i.isFanart).firstOrNull?.url;
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (fanartUrl != null && instance != null)
                  CachedNetworkImage(
                    imageUrl: '${instance.url.endsWith('/') ? instance.url.substring(0, instance.url.length - 1) : instance.url}$fanartUrl',
                    httpHeaders: instance.authHeaders,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                  )
                else
                  Container(color: theme.colorScheme.surfaceContainerHighest),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        theme.colorScheme.surface.withValues(alpha: 0.5),
                        theme.colorScheme.surface,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                movie.monitored ? Icons.bookmark : Icons.bookmark_border,
              ),
              tooltip: movie.monitored ? 'Unmonitor' : 'Monitor',
              onPressed: () async {
                try {
                  await ref
                      .read(movieControllerProvider(movieId))
                      .toggleMonitor(movie);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          movie.monitored ? 'Unmonitored' : 'Monitored',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: theme.colorScheme.error,
                      ),
                    );
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.travel_explore),
              tooltip: 'Search Releases',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => ReleasesSheet(
                    id: movie.id,
                    isMovie: true,
                    title: movie.title,
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MovieEditScreen(movie: movie),
                  ),
                );
              },
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Movie'),
                      content: const Text(
                        'Are you sure you want to delete this movie?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    try {
                      await ref
                          .read(movieControllerProvider(movieId))
                          .deleteMovie();
                      if (context.mounted) {
                        context.pop(); // Pop details screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Movie deleted')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to delete: $e'),
                            backgroundColor: theme.colorScheme.error,
                          ),
                        );
                      }
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: AspectRatio(
                        aspectRatio: 2 / 3,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(radiusMd),
                          child: MoviePoster(movie: movie),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movie.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (movie.year > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${movie.year} • ${formatRuntime(movie.runtime)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          _buildStatusChip(context, movie),
                          const SizedBox(height: 8),
                          _buildRatings(context, movie),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (movie.overview != null) ...[
                  Text(
                    'Overview',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(movie.overview!, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 24),
                ],
                _buildInfoGrid(context, movie),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context, Movie movie) {
    Color color;
    String label = movie.status.label;

    if (movie.isDownloaded) {
      color = Colors.green;
      label = 'Downloaded';
    } else if (!movie.monitored) {
      color = Colors.grey;
      label = 'Unmonitored';
    } else if (movie.isAvailable) {
      color = Colors.red;
      label = 'Missing';
    } else {
      color = Colors.blue;
      label = movie.status.label;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRatings(BuildContext context, Movie movie) {
    if (movie.ratings == null) return const SizedBox();

    return Row(
      children: [
        if (movie.ratings!.imdb != null) ...[
          const Icon(Icons.star, color: Colors.amber, size: 16),
          const SizedBox(width: 4),
          Text(
            movie.ratings!.imdb!.value.toString(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 12),
        ],
        if (movie.ratings!.tmdb != null) ...[
          const Icon(Icons.movie, color: Colors.blue, size: 16),
          const SizedBox(width: 4),
          Text(
            '${(movie.ratings!.tmdb!.value * 10).toInt()}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoGrid(BuildContext context, Movie movie) {
    final items = [
      if (movie.studio != null) _InfoItem('Studio', movie.studio!),
      _InfoItem('Status', movie.status.label),
      _InfoItem(
        'Quality Profile',
        movie.qualityProfileId.toString(),
      ), // TODO: Lookup profile name
      if (movie.sizeOnDisk != null && movie.sizeOnDisk! > 0)
        _InfoItem('Size', formatBytes(movie.sizeOnDisk!)),
      if (movie.path != null) _InfoItem('Path', movie.path!),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: items.map((item) {
        return SizedBox(
          width:
              (MediaQuery.of(context).size.width - 48) / 2, // 2 columns roughly
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(item.value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  _InfoItem(this.label, this.value);
}
