import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/models/models.dart';
import '../../shared/widgets/batch_action_bar.dart';
import '../../shared/widgets/batch_actions_handler.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/notification_icon_button.dart';
import '../../widgets/sort_bottom_sheet.dart';
import '../../providers/settings_provider.dart';
import '../../tour/app_tour_keys.dart';
import 'movie_add_sheet.dart';
import 'providers/movies_provider.dart';
import 'widgets/movie_card.dart';
import 'widgets/movie_list_tile.dart';

/// The main screen displaying the list of movies in the library, with sorting and filtering.
class MoviesScreen extends ConsumerStatefulWidget {
  const MoviesScreen({super.key});

  @override
  ConsumerState<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends ConsumerState<MoviesScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedIds = {};

  bool get _isSelecting => _selectedIds.isNotEmpty;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _clearSelection() => setState(() => _selectedIds.clear());

  void _selectAll(List<Movie> movies) {
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(movies.map((m) => m.id));
    });
  }

  List<Movie> _resolveSelected(List<Movie> movies) {
    return movies.where((m) => _selectedIds.contains(m.id)).toList();
  }

  void _showSortSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        final currentSort = ref.read(movieSortProvider);
        return SortBottomSheet<MovieSortOption, MovieFilter>(
          title: 'Sort & Filter',
          currentSort: currentSort.option,
          isAscending: currentSort.isAscending,
          currentFilter: currentSort.filter,
          sortOptions: MovieSortOption.values,
          filterOptions: MovieFilter.values,
          sortLabelBuilder: (option) => option.label,
          filterLabelBuilder: (filter) => filter.label,
          onSortChanged: (option) {
            ref
                .read(movieSortProvider.notifier)
                .update(currentSort.copyWith(option: option));
          },
          onAscendingChanged: (ascending) {
            ref
                .read(movieSortProvider.notifier)
                .update(currentSort.copyWith(isAscending: ascending));
          },
          onFilterChanged: (filter) {
            ref
                .read(movieSortProvider.notifier)
                .update(currentSort.copyWith(filter: filter));
          },
        );
      },
    );
  }

  Future<void> _runBatchAction(
    BuildContext context,
    Future<BatchActionResult?> Function(BatchActionsHandler handler) action,
  ) async {
    final handler = BatchActionsHandler(ref);
    final result = await action(handler);
    if (result != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    }
    _clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    final moviesAsync = ref.watch(filteredMoviesProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(movieSearchProvider.notifier).update('');
          _searchController.clear();
          await ref.read(moviesProvider.notifier).refresh();
        },
        child: CustomScrollView(
          slivers: [
            _isSelecting
                ? _buildSelectionAppBar(context, moviesAsync)
                : _isSearching
                ? _buildSearchAppBar(context)
                : _buildNormalAppBar(context, settings),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: moviesAsync.when(
                data: (movies) {
                  if (movies.isEmpty) {
                    final isFiltered =
                        ref.read(movieSearchProvider).isNotEmpty ||
                        ref.read(movieSortProvider).filter != MovieFilter.all;

                    return SliverFillRemaining(
                      child: EmptyState(
                        icon: isFiltered
                            ? Icons.filter_list_off
                            : Icons.movie_outlined,
                        title: isFiltered
                            ? 'No results found'
                            : 'No movies found',
                        subtitle: isFiltered
                            ? 'Try clearing or adjusting your search query or filters.'
                            : 'Add movies to your Radarr library to see them here.',
                      ),
                    );
                  }

                  if (settings.viewMode == ViewMode.list) {
                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final movie = movies[index];
                        return MovieListTile(
                          movie: movie,
                          isSelected: _selectedIds.contains(movie.id),
                          onTap: _isSelecting
                              ? () => _toggleSelection(movie.id)
                              : () => context.go('/movies/${movie.id}'),
                          onLongPress: () => _toggleSelection(movie.id),
                        );
                      }, childCount: movies.length),
                    );
                  }

                  return SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 120,
                          childAspectRatio: 2 / 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final movie = movies[index];
                      return MovieCard(
                        movie: movie,
                        isSelected: _selectedIds.contains(movie.id),
                        onTap: _isSelecting
                            ? () => _toggleSelection(movie.id)
                            : () => context.go('/movies/${movie.id}'),
                        onLongPress: () => _toggleSelection(movie.id),
                      );
                    }, childCount: movies.length),
                  );
                },
                error: (error, stack) => SliverFillRemaining(
                  child: ErrorDisplay(
                    message: error.toString(),
                    onRetry: () => ref.read(moviesProvider.notifier).refresh(),
                  ),
                ),
                loading: () => const SliverFillRemaining(
                  child: LoadingIndicator(message: 'Loading movies...'),
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
          ],
        ),
      ),
      bottomNavigationBar: _isSelecting
          ? BatchActionBar(
              selectedCount: _selectedIds.length,
              actions: [
                BatchAction(
                  icon: Icons.visibility_outlined,
                  label: 'Monitor',
                  onPressed: () => _runBatchAction(
                    context,
                    (h) => h.setMoviesMonitored(
                      context,
                      _resolveSelected(
                        moviesAsync.valueOrNull ?? const <Movie>[],
                      ),
                      monitored: true,
                    ),
                  ),
                ),
                BatchAction(
                  icon: Icons.visibility_off_outlined,
                  label: 'Unmonitor',
                  onPressed: () => _runBatchAction(
                    context,
                    (h) => h.setMoviesMonitored(
                      context,
                      _resolveSelected(
                        moviesAsync.valueOrNull ?? const <Movie>[],
                      ),
                      monitored: false,
                    ),
                  ),
                ),
                BatchAction(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  isDestructive: true,
                  onPressed: () => _runBatchAction(
                    context,
                    (h) => h.deleteMovies(
                      context,
                      _selectedIds.toList(),
                      deleteFiles: false,
                    ),
                  ),
                ),
                BatchAction(
                  icon: Icons.delete_sweep,
                  label: 'Delete files',
                  isDestructive: true,
                  onPressed: () => _runBatchAction(
                    context,
                    (h) => h.deleteMovieFiles(context, _selectedIds.toList()),
                  ),
                ),
                BatchAction(
                  icon: Icons.delete_forever,
                  label: 'Purge',
                  isDestructive: true,
                  onPressed: () => _runBatchAction(
                    context,
                    (h) => h.purgeMovies(context, _selectedIds.toList()),
                  ),
                ),
              ],
            )
          : null,
      floatingActionButton: _isSelecting
          ? null
          : FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => const MovieAddSheet(),
                );
              },
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildNormalAppBar(BuildContext context, SettingsState settings) {
    final tourKeys = ref.watch(appTourKeysProvider);
    return SliverAppBar.medium(
      pinned: false,
      floating: false,
      title: const Text('Movies'),
      actions: [
        IconButton(
          key: tourKeys.moviesSearchKey,
          icon: const Icon(Icons.search),
          onPressed: () => setState(() => _isSearching = true),
        ),
        IconButton(
          key: tourKeys.moviesSortKey,
          icon: const Icon(Icons.sort),
          onPressed: () => _showSortSheet(context, ref),
        ),
        IconButton(
          icon: Icon(
            settings.viewMode == ViewMode.grid
                ? Icons.view_list
                : Icons.grid_view,
          ),
          tooltip: settings.viewMode == ViewMode.grid
              ? 'Switch to List'
              : 'Switch to Grid',
          onPressed: () {
            final newMode = settings.viewMode == ViewMode.grid
                ? ViewMode.list
                : ViewMode.grid;
            ref.read(settingsProvider.notifier).setViewMode(newMode);
          },
        ),
        const NotificationIconButton(),
      ],
    );
  }

  Widget _buildSearchAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      toolbarHeight: 64,
      title: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search movies...',
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) =>
              ref.read(movieSearchProvider.notifier).update(value),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchController.clear();
            });
            ref.read(movieSearchProvider.notifier).update('');
          },
        ),
      ],
    );
  }

  Widget _buildSelectionAppBar(
    BuildContext context,
    AsyncValue<List<Movie>> moviesAsync,
  ) {
    final allMovies = moviesAsync.valueOrNull ?? const <Movie>[];
    return SliverAppBar(
      pinned: true,
      title: Text('${_selectedIds.length} selected'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _clearSelection,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.select_all),
          tooltip: 'Select all',
          onPressed: () => _selectAll(allMovies),
        ),
      ],
    );
  }
}
