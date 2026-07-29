import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../domain/models/models.dart';
import '../../providers/data_providers.dart';
import '../../providers/instances_provider.dart';
import '../../providers/settings_provider.dart';
import '../../shared/widgets/batch_action_bar.dart';
import '../../shared/widgets/batch_actions_handler.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/instance_selector.dart';
import '../../widgets/notification_icon_button.dart';
import '../../widgets/sort_bottom_sheet.dart';
import 'providers/series_provider.dart';
import 'widgets/series_card.dart';
import 'widgets/series_list_tile.dart';

/// The main screen displaying the list of series in the library, with sorting and filtering.
class SeriesScreen extends ConsumerStatefulWidget {
  const SeriesScreen({super.key});

  @override
  ConsumerState<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends ConsumerState<SeriesScreen> {
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

  void _selectAll(List<Series> seriesList) {
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(seriesList.map((s) => s.id));
    });
  }

  List<Series> _resolveSelected(List<Series> seriesList) {
    return seriesList.where((s) => _selectedIds.contains(s.id)).toList();
  }

  Future<void> _runAutomaticSearch(Series series) async {
    try {
      final instanceId = series.instanceId;
      if (instanceId == null) {
        final repository = ref.read(seriesRepositoryProvider);
        if (repository == null) {
          throw StateError('Sonarr instance is unavailable');
        }
        await repository.searchSeries(series.id);
      } else {
        final instance = ref
            .read(instancesByTypeProvider(InstanceType.sonarr))
            .where((candidate) => candidate.id == instanceId)
            .firstOrNull;
        if (instance == null) {
          throw StateError('Series instance is no longer configured');
        }
        await ref
            .read(seriesRepositoryForInstanceProvider(instance))
            .searchSeries(series.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Automatic search started for ${series.title}')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to start automatic search: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _openExternalUri(Uri uri) async {
    try {
      if (uri.scheme != 'https') {
        throw const FormatException('Only HTTPS links are supported');
      }
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw StateError('Unable to open link');
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to open link: $error')));
    }
  }

  void _showSortSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        final currentSort = ref.read(seriesSortProvider);
        final rootFolders =
            (ref.read(seriesProvider).valueOrNull ?? const <Series>[])
                .map((series) => series.rootFolderPath)
                .whereType<String>()
                .toSet()
                .toList()
              ..sort();
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
            ref
                .read(seriesSortProvider.notifier)
                .update(currentSort.copyWith(option: option));
          },
          onAscendingChanged: (ascending) {
            ref
                .read(seriesSortProvider.notifier)
                .update(currentSort.copyWith(isAscending: ascending));
          },
          onFilterChanged: (filter) {
            ref
                .read(seriesSortProvider.notifier)
                .update(currentSort.copyWith(filter: filter));
          },
          additionalFilters: rootFolders.isEmpty
              ? null
              : Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ROOT FOLDER',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('All folders'),
                            selected: currentSort.rootFolderPath == null,
                            onSelected: (selected) {
                              if (!selected) return;
                              ref
                                  .read(seriesSortProvider.notifier)
                                  .update(
                                    currentSort.copyWith(
                                      clearRootFolderPath: true,
                                    ),
                                  );
                              Navigator.pop(context);
                            },
                          ),
                          for (final path in rootFolders)
                            FilterChip(
                              label: Text(path),
                              selected: currentSort.rootFolderPath == path,
                              onSelected: (selected) {
                                if (!selected) return;
                                ref
                                    .read(seriesSortProvider.notifier)
                                    .update(
                                      currentSort.copyWith(
                                        rootFolderPath: path,
                                      ),
                                    );
                                Navigator.pop(context);
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
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
    final seriesAsync = ref.watch(filteredSeriesProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(seriesSearchProvider.notifier).update('');
          _searchController.clear();
          await ref.read(seriesProvider.notifier).refresh();
        },
        child: CustomScrollView(
          slivers: [
            _isSelecting
                ? _buildSelectionAppBar(context, seriesAsync)
                : _isSearching
                ? _buildSearchAppBar(context)
                : _buildNormalAppBar(context, settings),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: seriesAsync.when(
                data: (seriesList) {
                  if (seriesList.isEmpty) {
                    final isFiltered =
                        ref.read(seriesSearchProvider).isNotEmpty ||
                        ref.read(seriesSortProvider).filter != SeriesFilter.all;

                    return SliverFillRemaining(
                      child: EmptyState(
                        icon: isFiltered
                            ? Icons.filter_list_off
                            : Icons.tv_outlined,
                        title: isFiltered
                            ? 'No results found'
                            : 'No series found',
                        subtitle: isFiltered
                            ? 'Try clearing or adjusting your search query or filters.'
                            : 'Add series to your Sonarr library to see them here.',
                      ),
                    );
                  }

                  if (settings.viewMode == ViewMode.list) {
                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final series = seriesList[index];
                        return SeriesListTile(
                          series: series,
                          isSelected: _selectedIds.contains(series.id),
                          onTap: _isSelecting
                              ? () => _toggleSelection(series.id)
                              : () => context.go('/series/${series.id}'),
                          onLongPress: () => _toggleSelection(series.id),
                          onAutomaticSearch: _isSelecting
                              ? null
                              : () => _runAutomaticSearch(series),
                          onOpenExternal: _isSelecting
                              ? null
                              : _openExternalUri,
                        );
                      }, childCount: seriesList.length),
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
                      final series = seriesList[index];
                      return SeriesCard(
                        series: series,
                        isSelected: _selectedIds.contains(series.id),
                        onTap: _isSelecting
                            ? () => _toggleSelection(series.id)
                            : () => context.go('/series/${series.id}'),
                        onLongPress: () => _toggleSelection(series.id),
                        onAutomaticSearch: _isSelecting
                            ? null
                            : () => _runAutomaticSearch(series),
                        onOpenExternal: _isSelecting ? null : _openExternalUri,
                      );
                    }, childCount: seriesList.length),
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
      bottomNavigationBar: _isSelecting
          ? BatchActionBar(
              selectedCount: _selectedIds.length,
              actions: [
                BatchAction(
                  icon: Icons.bookmark,
                  label: 'Monitor',
                  onPressed: () => _runBatchAction(
                    context,
                    (h) => h.setSeriesMonitored(
                      context,
                      _resolveSelected(
                        seriesAsync.valueOrNull ?? const <Series>[],
                      ),
                      monitored: true,
                    ),
                  ),
                ),
                BatchAction(
                  icon: Icons.bookmark_border,
                  label: 'Unmonitor',
                  onPressed: () => _runBatchAction(
                    context,
                    (h) => h.setSeriesMonitored(
                      context,
                      _resolveSelected(
                        seriesAsync.valueOrNull ?? const <Series>[],
                      ),
                      monitored: false,
                    ),
                  ),
                ),
                BatchAction(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  isDestructive: true,
                  submenu: [
                    BatchAction(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      isDestructive: true,
                      onPressed: () => _runBatchAction(
                        context,
                        (h) => h.deleteSeriesList(
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
                        (h) =>
                            h.deleteSeriesFiles(context, _selectedIds.toList()),
                      ),
                    ),
                    BatchAction(
                      icon: Icons.delete_forever,
                      label: 'Purge',
                      isDestructive: true,
                      onPressed: () => _runBatchAction(
                        context,
                        (h) =>
                            h.purgeSeriesList(context, _selectedIds.toList()),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : null,
      floatingActionButton: _isSelecting
          ? null
          : FloatingActionButton(
              onPressed: () => context.push('/discover?type=series'),
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildNormalAppBar(BuildContext context, SettingsState settings) {
    return SliverAppBar.medium(
      pinned: false,
      floating: false,
      title: const Text('Series'),
      actions: [
        const InstanceSelector(type: InstanceType.sonarr),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => setState(() => _isSearching = true),
        ),
        IconButton(
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
            hintText: 'Search series...',
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) =>
              ref.read(seriesSearchProvider.notifier).update(value),
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
            ref.read(seriesSearchProvider.notifier).update('');
          },
        ),
      ],
    );
  }

  Widget _buildSelectionAppBar(
    BuildContext context,
    AsyncValue<List<Series>> seriesAsync,
  ) {
    final allSeries = seriesAsync.valueOrNull ?? const <Series>[];
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
          onPressed: () => _selectAll(allSeries),
        ),
      ],
    );
  }
}
