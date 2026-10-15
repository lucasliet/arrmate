import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/torrent_query_store.dart';
import '../../../../domain/models/models.dart';
import '../../shared/widgets/batch_action_bar.dart';
import '../../shared/widgets/batch_actions_handler.dart';
import '../../tour/app_tour_keys.dart';
import '../../tour/tour_mock_data.dart';
import '../../tour/tour_mockup_provider.dart';
import '../../tour/widgets/tour_mockup_banner.dart';
import '../../widgets/common_widgets.dart'; // Correct relative path
import '../../widgets/instance_load_failure_banner.dart';
import 'providers/qbittorrent_provider.dart';
import 'providers/torrent_link_provider.dart';
import 'widgets/add_torrent_sheet.dart';
import 'widgets/torrent_details_sheet.dart';
import 'widgets/torrent_filters_sheet.dart';
import 'widgets/torrent_list_item.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../l10n/labels.dart';

class QBittorrentTab extends ConsumerStatefulWidget {
  const QBittorrentTab({super.key});

  @override
  ConsumerState<QBittorrentTab> createState() => _QBittorrentTabState();
}

class _QBittorrentTabState extends ConsumerState<QBittorrentTab> {
  final _searchController = TextEditingController();
  late final TorrentQueryStore _queryStore;
  TorrentQuery _query = const TorrentQuery();
  bool _rememberFilters = false;
  bool _queryModified = false;

  /// Hashes of the torrents picked for a bulk action. Always resolved against
  /// the visible list, so a torrent hidden or gone since it was picked is
  /// never acted on.
  final Set<String> _selectedHashes = {};

  @override
  void initState() {
    super.initState();
    _queryStore = TorrentQueryStore();
    unawaited(_loadQuery());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadQuery() async {
    final savedQuery = await _queryStore.load();
    if (!mounted) return;
    if (_queryModified) {
      setState(() => _rememberFilters = savedQuery.remember);
      if (savedQuery.remember) {
        await _queryStore.save(query: _query, remember: true);
      }
      return;
    }
    _searchController.text = savedQuery.query.search;
    setState(() {
      _query = savedQuery.query;
      _rememberFilters = savedQuery.remember;
    });
  }

  void _updateQuery(TorrentQuery query) {
    _queryModified = true;
    setState(() => _query = query);
    if (_rememberFilters) {
      unawaited(_queryStore.save(query: query, remember: true));
    }
  }

  void _clearQuery() {
    _searchController.clear();
    _updateQuery(_query.clearFilters());
  }

  /// Flips [torrent] in the selection, dropping picks no longer in
  /// [visibleTorrents] so a torrent that left the list and comes back is not
  /// silently selected again.
  void _toggleSelection(Torrent torrent, List<Torrent> visibleTorrents) {
    final visibleHashes = visibleTorrents.map((t) => t.hash).toSet();
    setState(() {
      _selectedHashes.retainWhere(visibleHashes.contains);
      if (!_selectedHashes.remove(torrent.hash)) {
        _selectedHashes.add(torrent.hash);
      }
    });
  }

  void _clearSelection() => setState(_selectedHashes.clear);

  void _selectAll(List<Torrent> torrents) {
    setState(() {
      _selectedHashes
        ..clear()
        ..addAll(torrents.map((torrent) => torrent.hash));
    });
  }

  /// Deletes [torrents] with their files, then reports the outcome and leaves
  /// selection mode.
  Future<void> _deleteSelectedWithFiles(List<Torrent> torrents) async {
    final result = await BatchActionsHandler(
      ref,
    ).deleteTorrentsWithFiles(context, torrents);
    if (!mounted) return;
    if (result != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    }
    _clearSelection();
  }

  /// Header replacing the search and sort controls while torrents are
  /// selected, so the filters that define the selection cannot shift under it.
  Widget _buildSelectionHeader(
    BuildContext context,
    int selectedCount,
    List<Torrent> visibleTorrents,
  ) {
    return Padding(
      key: const Key('torrentSelectionHeader'),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Clear selection',
            onPressed: _clearSelection,
            icon: const Icon(Icons.close),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$selectedCount selected',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            key: const Key('torrentSelectAllButton'),
            tooltip: 'Select all',
            onPressed: () => _selectAll(visibleTorrents),
            icon: const Icon(Icons.select_all),
          ),
        ],
      ),
    );
  }

  /// Tag names carried by the current torrent list, offered as filter chips.
  List<String> _collectAvailableTags() {
    final torrents =
        ref.read(qbittorrentTorrentsProvider).valueOrNull ?? const <Torrent>[];
    final tags = torrents.expand((torrent) => torrent.tags).toSet().toList()
      ..sort();
    return tags;
  }

  /// Category names carried by the current torrent list, offered as filter
  /// chips.
  List<String> _collectAvailableCategories() {
    final torrents =
        ref.read(qbittorrentTorrentsProvider).valueOrNull ?? const <Torrent>[];
    final categories =
        torrents
            .map((torrent) => torrent.category)
            .whereType<String>()
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return categories;
  }

  /// Reloads both the torrent list and the library link index.
  Future<void> _refreshAll() async {
    ref.invalidate(torrentLinkIndexProvider);
    await ref.read(qbittorrentTorrentsProvider.notifier).refresh();
  }

  Future<void> _showFilters({required bool showLinkFilters}) async {
    final availableCategories = _collectAvailableCategories();
    final availableTags = _collectAvailableTags();
    final result = await showModalBottomSheet<TorrentFilterResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => TorrentFiltersSheet(
        query: _query,
        rememberFilters: _rememberFilters,
        showLinkFilters: showLinkFilters,
        availableCategories: availableCategories,
        availableTags: availableTags,
      ),
    );
    if (result == null || !mounted) return;

    _queryModified = true;
    _searchController.text = result.query.search;
    setState(() {
      _query = result.query;
      _rememberFilters = result.rememberFilters;
    });
    await _queryStore.save(
      query: result.query,
      remember: result.rememberFilters,
    );
  }

  void _showAddTorrentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => const AddTorrentSheet(),
    );
  }

  void _showTorrentDetails(
    BuildContext context,
    Torrent torrent,
    TorrentLink? link,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TorrentDetailsSheet(torrent: torrent, link: link),
    );
  }

  /// Builds the sample torrent list shown while the guided tour runs without a
  /// qBittorrent instance, so the torrent step has a visible card.
  ///
  /// The cards are inert and never persisted: they vanish as soon as the tour
  /// is finished or skipped, together with the whole tab.
  Widget _buildTourMockup() {
    final torrents = TourMockData.torrents();
    final tourKeys = ref.watch(appTourKeysProvider);

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: TourMockupBanner(),
        ),
        for (var index = 0; index < torrents.length; index++)
          TourMockup(
            child: TorrentListItem(
              key: index == 0 ? tourKeys.activityTorrentKey : null,
              torrent: torrents[index],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Without a qBittorrent instance the tour still walks through this tab, so
    // sample torrents stand in for the real list and no polling is started.
    final showsTourMockup = ref.watch(
      tourMockupProvider(InstanceType.qbittorrent),
    );
    final torrentsState = showsTourMockup
        ? const AsyncValue<List<Torrent>>.data(<Torrent>[])
        : ref.watch(qbittorrentTorrentsProvider);
    final linkIndex = showsTourMockup
        ? TorrentLinkIndex.empty
        : (ref.watch(torrentLinkIndexProvider).valueOrNull ??
              TorrentLinkIndex.empty);
    final showsLinkFilters = linkIndex.hasInstances;
    final tourKeys = ref.watch(appTourKeysProvider);
    // The library filter only applies while its section is reachable, otherwise
    // a leftover selection would hide every torrent with no way to clear it.
    final effectiveQuery = _query.copyWith(
      linkFilter: showsLinkFilters ? _query.linkFilter : TorrentLinkFilter.all,
    );
    final torrents = torrentsState.valueOrNull ?? const <Torrent>[];
    final visibleTorrents = applyTorrentQuery(
      torrents,
      effectiveQuery,
      linkResolver: showsLinkFilters
          ? (torrent) => linkIndex.resolve(torrent).status
          : null,
    );
    final hiddenCount = torrents.length - visibleTorrents.length;
    final hasVisibleActiveFilters = effectiveQuery.hasActiveFilters;
    final selectedTorrents = showsTourMockup
        ? const <Torrent>[]
        : visibleTorrents
              .where((torrent) => _selectedHashes.contains(torrent.hash))
              .toList();
    final isSelecting = selectedTorrents.isNotEmpty;

    return Scaffold(
      floatingActionButton: isSelecting
          ? null
          : FloatingActionButton(
              onPressed: _showAddTorrentSheet,
              child: const Icon(Icons.add),
            ),
      bottomNavigationBar: isSelecting
          ? BatchActionBar(
              selectedCount: selectedTorrents.length,
              actions: [
                BatchAction(
                  icon: Icons.delete_forever,
                  label: 'Delete with files',
                  isDestructive: true,
                  onPressed: () => _deleteSelectedWithFiles(selectedTorrents),
                ),
              ],
            )
          : null,
      body: Column(
        children: [
          if (isSelecting)
            _buildSelectionHeader(
              context,
              selectedTorrents.length,
              visibleTorrents,
            ),
          // While the guided tour mockup stands in for the real list, the
          // search and sort controls stay hidden so they never answer with the
          // empty state the mockup replaces.
          if (!showsTourMockup && !isSelecting) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                key: const Key('torrentSearchField'),
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search torrents',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.search.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            _updateQuery(_query.copyWith(search: ''));
                          },
                          icon: const Icon(Icons.clear),
                        ),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) =>
                    _updateQuery(_query.copyWith(search: value)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  PopupMenuButton<TorrentSortOption>(
                    key: const Key('torrentSortButton'),
                    icon: const Icon(Icons.sort),
                    initialValue: _query.sortOption,
                    tooltip: 'Sort by',
                    onSelected: (value) =>
                        _updateQuery(_query.copyWith(sortOption: value)),
                    itemBuilder: (context) => TorrentSortOption.values
                        .map(
                          (option) => PopupMenuItem(
                            value: option,
                            child: Text(option.localizedLabel(context.l10n)),
                          ),
                        )
                        .toList(),
                  ),
                  IconButton(
                    key: const Key('torrentSortDirectionButton'),
                    icon: Icon(
                      _query.sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                    ),
                    tooltip: _query.sortAscending ? 'Ascending' : 'Descending',
                    onPressed: () => _updateQuery(
                      _query.copyWith(sortAscending: !_query.sortAscending),
                    ),
                  ),
                  IconButton(
                    key: const Key('torrentFilterButton'),
                    tooltip: 'Filter torrents',
                    onPressed: () =>
                        _showFilters(showLinkFilters: showsLinkFilters),
                    icon: Badge(
                      isLabelVisible: hasVisibleActiveFilters,
                      child: const Icon(Icons.filter_list),
                    ),
                  ),
                  if (hasVisibleActiveFilters)
                    TextButton(
                      key: const Key('clearTorrentFiltersButton'),
                      onPressed: _clearQuery,
                      child: const Text('Clear'),
                    ),
                  const Spacer(),
                  Text(
                    hiddenCount == 0
                        ? '${visibleTorrents.length} torrents'
                        : '${visibleTorrents.length} torrents · $hiddenCount hidden',
                    key: const Key('torrentResultCount'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
          if (!showsTourMockup) const Divider(height: 1),

          if (linkIndex.failures.isNotEmpty)
            InstanceLoadFailureBanner(
              failures: linkIndex.failures,
              onRetry: () => ref.invalidate(torrentLinkIndexProvider),
            ),

          Expanded(
            child: torrentsState.when(
              data: (torrents) {
                if (showsTourMockup) return _buildTourMockup();

                if (torrents.isEmpty) {
                  return EmptyState(
                    icon: Icons.cloud_download_outlined,
                    title: 'No Torrents',
                    subtitle: 'Add a new torrent to start downloading',
                    action: FilledButton(
                      onPressed: _showAddTorrentSheet,
                      child: const Text('Add Torrent'),
                    ),
                  );
                }

                if (visibleTorrents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('No torrents match the current filters'),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _clearQuery,
                          child: const Text('Clear filters'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshAll,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: visibleTorrents.length,
                    itemBuilder: (context, index) {
                      final torrent = visibleTorrents[index];
                      final link = linkIndex.resolve(torrent);
                      return TorrentListItem(
                        key: index == 0 ? tourKeys.activityTorrentKey : null,
                        torrent: torrent,
                        link: link,
                        isSelected: _selectedHashes.contains(torrent.hash),
                        onTap: isSelecting
                            ? () => _toggleSelection(torrent, visibleTorrents)
                            : () => _showTorrentDetails(context, torrent, link),
                        onLongPress: () =>
                            _toggleSelection(torrent, visibleTorrents),
                      );
                    },
                  ),
                );
              },
              error: (error, stack) => Center(
                child: ErrorDisplay(
                  message: 'Failed to load torrents',
                  onRetry: _refreshAll,
                ),
              ),
              loading: () => const Center(
                child: LoadingIndicator(message: 'Loading torrents...'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
