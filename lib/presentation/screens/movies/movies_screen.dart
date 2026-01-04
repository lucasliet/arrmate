import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/models/models.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/sort_bottom_sheet.dart';
import 'movie_add_sheet.dart';
import 'providers/movies_provider.dart';
import 'widgets/movie_card.dart';

class MoviesScreen extends ConsumerStatefulWidget {
  const MoviesScreen({super.key});

  @override
  ConsumerState<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends ConsumerState<MoviesScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            ref.read(movieSortProvider.notifier).update(currentSort.copyWith(option: option));
          },
          onAscendingChanged: (ascending) {
            ref.read(movieSortProvider.notifier).update(currentSort.copyWith(isAscending: ascending));
          },
          onFilterChanged: (filter) {
            ref.read(movieSortProvider.notifier).update(currentSort.copyWith(filter: filter));
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final moviesAsync = ref.watch(filteredMoviesProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
            ref.read(movieSearchProvider.notifier).update('');
            _searchController.clear();
            await ref.read(moviesProvider.notifier).refresh();
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar.medium(
              title: _isSearching
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search movies...',
                        border: InputBorder.none,
                      ),
                      onChanged: (value) => ref.read(movieSearchProvider.notifier).update(value),
                    )
                  : const Text('Movies'),
              actions: [
                if (_isSearching)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                         _isSearching = false;
                         _searchController.clear();
                      });
                      ref.read(movieSearchProvider.notifier).update('');
                    },
                  )
                else ...[
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => setState(() => _isSearching = true),
                  ),
                  IconButton(
                    icon: const Icon(Icons.sort),
                    onPressed: () => _showSortSheet(context, ref),
                  ),
                ],
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: moviesAsync.when(
                data: (movies) {
                  if (movies.isEmpty) {
                    final isFiltered = ref.read(movieSearchProvider).isNotEmpty || 
                                     ref.read(movieSortProvider).filter != MovieFilter.all;
                    
                    return SliverFillRemaining(
                      child: EmptyState(
                        icon: isFiltered ? Icons.filter_list_off : Icons.movie_outlined,
                        title: isFiltered ? 'No results found' : 'No movies found',
                        subtitle: isFiltered 
                            ? 'Try parsing your search query or filters.'
                            : 'Add movies to your Radarr library to see them here.',
                      ),
                    );
                  }

                  return SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 120,
                      childAspectRatio: 2 / 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final movie = movies[index];
                        return MovieCard(
                          movie: movie,
                          onTap: () {
                            context.go('/movies/${movie.id}');
                          },
                        );
                      },
                      childCount: movies.length,
                    ),
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
      floatingActionButton: FloatingActionButton(
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
}
