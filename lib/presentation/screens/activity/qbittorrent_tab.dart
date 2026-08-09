import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../domain/models/models.dart';
import '../../widgets/common_widgets.dart'; // Correct relative path
import '../../widgets/instance_load_failure_banner.dart';
import 'providers/qbittorrent_provider.dart';
import 'providers/torrent_link_provider.dart';
import 'widgets/add_torrent_sheet.dart';
import 'widgets/torrent_details_sheet.dart';
import 'widgets/torrent_list_item.dart';

class QBittorrentTab extends ConsumerStatefulWidget {
  const QBittorrentTab({super.key});

  @override
  ConsumerState<QBittorrentTab> createState() => _QBittorrentTabState();
}

class _QBittorrentTabState extends ConsumerState<QBittorrentTab> {
  String _selectedFilter = 'all';

  /// Active media-library filter, or `null` when no library filter is applied.
  TorrentLinkStatus? _selectedLinkFilter;

  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = [
    'all',
    'downloading',
    'seeding',
    'paused',
    'error',
  ];

  /// Library relations offered as filters, in decreasing order of urgency.
  static const List<TorrentLinkStatus> _linkFilters = [
    TorrentLinkStatus.orphan,
    TorrentLinkStatus.fileMissing,
    TorrentLinkStatus.linked,
    TorrentLinkStatus.external,
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Reloads both the torrent list and the library link index.
  Future<void> _refreshAll() async {
    ref.invalidate(torrentLinkIndexProvider);
    await ref.read(qbittorrentTorrentsProvider.notifier).refresh();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
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

  /// Builds a filter chip following the tab's existing chip styling.
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        showCheckmark: false,
        labelStyle: TextStyle(
          color: isSelected ? context.colorScheme.onPrimary : null,
        ),
        backgroundColor: context.colorScheme.surfaceContainerHighest,
        selectedColor: context.colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected
                ? Colors.transparent
                : context.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final torrentsState = ref.watch(qbittorrentTorrentsProvider);
    final linkIndex =
        ref.watch(torrentLinkIndexProvider).valueOrNull ??
        TorrentLinkIndex.empty;
    final showsLinkFilters = linkIndex.hasInstances;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTorrentSheet,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search torrents...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _clearSearch,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: context.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  isDense: true,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 16),
                    child: Row(
                      children: [
                        ..._filters.map((filter) {
                          return _buildFilterChip(
                            label:
                                filter[0].toUpperCase() + filter.substring(1),
                            isSelected: _selectedFilter == filter,
                            onSelected: () =>
                                setState(() => _selectedFilter = filter),
                          );
                        }),
                        if (showsLinkFilters) ...[
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: SizedBox(
                              height: 24,
                              child: VerticalDivider(
                                width: 1,
                                thickness: 1,
                                color: context.colorScheme.outline.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                          ),
                          ..._linkFilters.map((status) {
                            return _buildFilterChip(
                              label: status.label,
                              isSelected: _selectedLinkFilter == status,
                              onSelected: () => setState(() {
                                _selectedLinkFilter =
                                    _selectedLinkFilter == status
                                    ? null
                                    : status;
                              }),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(_isSearching ? Icons.search_off : Icons.search),
                  onPressed: _toggleSearch,
                  tooltip: _isSearching ? 'Close search' : 'Search torrents',
                ),
              ],
            ),
          ),

          if (linkIndex.failures.isNotEmpty)
            InstanceLoadFailureBanner(
              failures: linkIndex.failures,
              onRetry: () => ref.invalidate(torrentLinkIndexProvider),
            ),

          Expanded(
            child: torrentsState.when(
              data: (torrents) {
                if (torrents.isEmpty && _selectedFilter == 'all') {
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

                final filteredTorrents =
                    torrents
                        .where((t) {
                          if (_selectedFilter == 'all') return true;
                          if (_selectedFilter == 'downloading') {
                            return t.status.isActive && !t.status.isPaused;
                          }
                          if (_selectedFilter == 'seeding') {
                            return t.status == TorrentStatus.uploading ||
                                t.status == TorrentStatus.stalledUP;
                          }
                          if (_selectedFilter == 'paused') {
                            return t.status.isPaused;
                          }
                          if (_selectedFilter == 'error') {
                            return t.status.hasError;
                          }
                          return true;
                        })
                        .where((t) {
                          if (_selectedLinkFilter == null) return true;
                          return linkIndex.resolve(t).status ==
                              _selectedLinkFilter;
                        })
                        .where((t) {
                          if (_searchQuery.isEmpty) return true;
                          return t.name.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          );
                        })
                        .toList()
                      ..sort((a, b) {
                        final aIsActive =
                            a.status.isActive && !a.status.isPaused;
                        final bIsActive =
                            b.status.isActive && !b.status.isPaused;
                        if (aIsActive && !bIsActive) return -1;
                        if (!aIsActive && bIsActive) return 1;
                        return a.name.toLowerCase().compareTo(
                          b.name.toLowerCase(),
                        );
                      });

                if (filteredTorrents.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No torrents found with this filter'
                          : 'No torrents found',
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshAll,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: filteredTorrents.length,
                    itemBuilder: (context, index) {
                      final torrent = filteredTorrents[index];
                      final link = linkIndex.resolve(torrent);
                      return TorrentListItem(
                        torrent: torrent,
                        link: link,
                        onTap: () =>
                            _showTorrentDetails(context, torrent, link),
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
