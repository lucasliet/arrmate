import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/models.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/sort_bottom_sheet.dart';
import 'series_add_sheet.dart';
import 'providers/series_provider.dart';
import 'widgets/series_card.dart';

class SeriesScreen extends ConsumerStatefulWidget {
  const SeriesScreen({super.key});

  @override
  ConsumerState<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends ConsumerState<SeriesScreen> {
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
        final currentSort = ref.read(seriesSortProvider);
        return SortBottomSheet<SeriesSortOption, SeriesFilter>(
          title: 'Sort & Filter',
          currentSort: currentSort.option,
          isAscending: currentSort.isAscending,
          currentFilter: currentSort.filter,
          sortOptions: SeriesSortOption.values,
          filterOptions: SeriesFilter.values,
          sortLabelBuilder: (option) => option.label,
          filterLabelBuilder: (filter) => filter.label,
          onSortChanged: (option) {
            ref.read(seriesSortProvider.notifier).update(currentSort.copyWith(option: option));
          },
          onAscendingChanged: (ascending) {
            ref.read(seriesSortProvider.notifier).update(currentSort.copyWith(isAscending: ascending));
          },
          onFilterChanged: (filter) {
            ref.read(seriesSortProvider.notifier).update(currentSort.copyWith(filter: filter));
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final seriesAsync = ref.watch(filteredSeriesProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
            ref.read(seriesSearchProvider.notifier).update('');
            _searchController.clear();
            await ref.read(seriesProvider.notifier).refresh();
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar.medium(
              title: _isSearching
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search series...',
                        border: InputBorder.none,
                      ),
                      onChanged: (value) => ref.read(seriesSearchProvider.notifier).update(value),
                    )
                  : const Text('Series'),
              actions: [
                if (_isSearching)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                         _isSearching = false;
                         _searchController.clear();
                      });
                      ref.read(seriesSearchProvider.notifier).update('');
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
              sliver: seriesAsync.when(
                data: (seriesList) {
                  if (seriesList.isEmpty) {
                    final isFiltered = ref.read(seriesSearchProvider).isNotEmpty || 
                                     ref.read(seriesSortProvider).filter != SeriesFilter.all;

                    return SliverFillRemaining(
                      child: EmptyState(
                        icon: isFiltered ? Icons.filter_list_off : Icons.tv,
                        title: isFiltered ? 'No results found' : 'No series found',
                        subtitle: isFiltered
                            ? 'Try parsing your search query or filters.'
                            : 'Add series to your Sonarr library to see them here.',
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
                        final series = seriesList[index];
                        return SeriesCard(
                          series: series,
                          onTap: () {
                            context.go('/series/${series.id}');
                          },
                        );
                      },
                      childCount: seriesList.length,
                    ),
                  );
                },
                error: (error, stack) => SliverFillRemaining(
                  child: ErrorDisplay(
                    message: error.toString(),
                    onRetry: () => ref.read(seriesProvider.notifier).refresh(),
                  ),
                ),
                loading: () => const SliverFillRemaining(
                  child: LoadingIndicator(message: 'Loading series...'),
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
            builder: (context) => const SeriesAddSheet(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
