import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../domain/models/models.dart';
import '../../widgets/common_widgets.dart'; // Correct relative path
import 'providers/qbittorrent_provider.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _showTorrentDetails(BuildContext context, Torrent torrent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TorrentDetailsSheet(torrent: torrent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final torrentsState = ref.watch(qbittorrentTorrentsProvider);

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
                          final isSelected = _selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(
                                filter[0].toUpperCase() + filter.substring(1),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedFilter = filter;
                                });
                              },
                              showCheckmark: false,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? context.colorScheme.onPrimary
                                    : null,
                              ),
                              backgroundColor:
                                  context.colorScheme.surfaceContainerHighest,
                              selectedColor: context.colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isSelected
                                      ? Colors.transparent
                                      : context.colorScheme.outline.withValues(
                                          alpha: 0.2,
                                        ),
                                ),
                              ),
                            ),
                          );
                        }),
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
                          if (_selectedFilter == 'paused')
                            return t.status.isPaused;
                          if (_selectedFilter == 'error')
                            return t.status.hasError;
                          return true;
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
                  onRefresh: () =>
                      ref.read(qbittorrentTorrentsProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: filteredTorrents.length,
                    itemBuilder: (context, index) {
                      final torrent = filteredTorrents[index];
                      return TorrentListItem(
                        torrent: torrent,
                        onTap: () => _showTorrentDetails(context, torrent),
                      );
                    },
                  ),
                );
              },
              error: (error, stack) => Center(
                child: ErrorDisplay(
                  message: 'Failed to load torrents',
                  onRetry: () =>
                      ref.read(qbittorrentTorrentsProvider.notifier).refresh(),
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
