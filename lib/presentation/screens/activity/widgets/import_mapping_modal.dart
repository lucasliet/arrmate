import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../domain/models/models.dart';
import '../../../widgets/common_widgets.dart';
import '../../series/providers/season_episodes_provider.dart';
import '../../series/providers/series_lookup_provider.dart';

class ImportMappingModal extends ConsumerStatefulWidget {
  final ImportableFile file;
  final void Function(ImportableFile updatedFile) onApply;
  final VoidCallback? onApplyToSimilar;

  const ImportMappingModal({
    super.key,
    required this.file,
    required this.onApply,
    this.onApplyToSimilar,
  });

  @override
  ConsumerState<ImportMappingModal> createState() => _ImportMappingModalState();
}

class _ImportMappingModalState extends ConsumerState<ImportMappingModal> {
  final _searchController = TextEditingController();
  Series? _selectedSeries;
  int? _selectedSeasonNumber;
  final Set<int> _selectedEpisodeIds = {};

  @override
  void initState() {
    super.initState();
    _selectedSeries = widget.file.series;
    if (widget.file.episodes != null && widget.file.episodes!.isNotEmpty) {
      _selectedSeasonNumber = widget.file.episodes!.first.seasonNumber;
      _selectedEpisodeIds.addAll(widget.file.episodes!.map((e) => e.id));
    }
    _searchController.addListener(_onSearchTextChanged);
  }

  void _onSearchTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            AppBar(
              title: const Text('Map File'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(paddingMd),
                children: [
                  _buildFileInfo(theme),
                  const SizedBox(height: paddingMd),
                  _buildSeriesSearch(theme),
                  if (_selectedSeries != null) ...[
                    const SizedBox(height: paddingMd),
                    _buildSeasonSelector(theme),
                    if (_selectedSeasonNumber != null) ...[
                      const SizedBox(height: paddingMd),
                      _buildEpisodeSelector(theme),
                    ],
                  ],
                  const SizedBox(height: paddingLg),
                  _buildPreview(theme),
                  const SizedBox(height: paddingLg),
                  _buildActions(theme),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFileInfo(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'File',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: paddingXs),
            Text(
              widget.file.name ?? widget.file.relativePath ?? 'Unknown',
              style: theme.textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeriesSearch(ThemeData theme) {
    final lookupState = ref.watch(seriesLookupProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Series', style: theme.textTheme.titleMedium),
        const SizedBox(height: paddingSm),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search for series...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(seriesLookupProvider.notifier).reset();
                    },
                  )
                : null,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (query) {
            if (query.isNotEmpty) {
              ref.read(seriesLookupProvider.notifier).search(query);
            }
          },
        ),
        if (_selectedSeries != null) ...[
          const SizedBox(height: paddingSm),
          Chip(
            avatar: const Icon(Icons.tv, size: 18),
            label: Text(_selectedSeries!.title),
            onDeleted: () {
              setState(() {
                _selectedSeries = null;
                _selectedSeasonNumber = null;
                _selectedEpisodeIds.clear();
              });
            },
          ),
        ],
        lookupState.when(
          data: (series) {
            if (series.isEmpty) return const SizedBox.shrink();
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(top: paddingSm),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: series.length,
                itemBuilder: (context, index) {
                  final item = series[index];
                  return ListTile(
                    leading: const Icon(Icons.tv),
                    title: Text(item.title),
                    subtitle: Text('${item.yearLabel} • ${item.network ?? ''}'),
                    onTap: () {
                      setState(() {
                        _selectedSeries = item;
                        _selectedSeasonNumber = null;
                        _selectedEpisodeIds.clear();
                      });
                      _searchController.clear();
                      ref.read(seriesLookupProvider.notifier).reset();
                    },
                  );
                },
              ),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(paddingMd),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(paddingMd),
            child: Text(
              'Error: $e',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeasonSelector(ThemeData theme) {
    final seasons = _selectedSeries!.seasons;
    if (seasons.isEmpty) {
      return Text(
        'No seasons available',
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Season', style: theme.textTheme.titleMedium),
        const SizedBox(height: paddingSm),
        DropdownButtonFormField<int>(
          initialValue: _selectedSeasonNumber,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Select season',
          ),
          items: seasons.map((season) {
            return DropdownMenuItem(
              value: season.seasonNumber,
              child: Text(season.label),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedSeasonNumber = value;
              _selectedEpisodeIds.clear();
            });
          },
        ),
      ],
    );
  }

  Widget _buildEpisodeSelector(ThemeData theme) {
    final episodesAsync = ref.watch(
      seasonEpisodesProvider(_selectedSeries!.id, _selectedSeasonNumber!),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Episodes', style: theme.textTheme.titleMedium),
            if (_selectedEpisodeIds.isNotEmpty)
              TextButton(
                onPressed: () => setState(() => _selectedEpisodeIds.clear()),
                child: const Text('Clear'),
              ),
          ],
        ),
        const SizedBox(height: paddingSm),
        episodesAsync.when(
          data: (episodes) {
            if (episodes.isEmpty) {
              return Text(
                'No episodes found',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              );
            }
            return Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainer,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: episodes.length,
                itemBuilder: (context, index) {
                  final episode = episodes[index];
                  final isSelected = _selectedEpisodeIds.contains(episode.id);
                  return CheckboxListTile(
                    value: isSelected,
                    title: Text(episode.episodeLabel),
                    subtitle: Text(episode.title ?? 'TBA'),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedEpisodeIds.add(episode.id);
                        } else {
                          _selectedEpisodeIds.remove(episode.id);
                        }
                      });
                    },
                  );
                },
              ),
            );
          },
          loading: () => const LoadingIndicator(message: 'Loading episodes...'),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }

  Widget _buildPreview(ThemeData theme) {
    if (_selectedSeries == null) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mapping Preview',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: paddingSm),
            Text(
              'Series: ${_selectedSeries!.title}',
              style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
            ),
            if (_selectedSeasonNumber != null)
              Text(
                'Season: $_selectedSeasonNumber',
                style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
              ),
            if (_selectedEpisodeIds.isNotEmpty)
              Text(
                'Episodes: ${_selectedEpisodeIds.length} selected',
                style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: _selectedSeries != null ? _handleApply : null,
          child: const Text('Apply'),
        ),
        if (widget.onApplyToSimilar != null) ...[
          const SizedBox(height: paddingSm),
          OutlinedButton(
            onPressed: _selectedSeries != null
                ? () async {
                    await _handleApply();
                    widget.onApplyToSimilar?.call();
                  }
                : null,
            child: const Text('Apply to Similar Files'),
          ),
        ],
      ],
    );
  }

  Future<void> _handleApply() async {
    if (_selectedSeries == null) return;

    try {
      List<Episode>? selectedEpisodes;
      if (_selectedSeasonNumber != null && _selectedEpisodeIds.isNotEmpty) {
        final episodes = await ref.read(
          seasonEpisodesProvider(
            _selectedSeries!.id,
            _selectedSeasonNumber!,
          ).future,
        );
        selectedEpisodes = episodes
            .where((e) => _selectedEpisodeIds.contains(e.id))
            .toList();
      }

      final updatedFile = widget.file.copyWith(
        series: _selectedSeries,
        episodes: selectedEpisodes ?? [],
      );

      widget.onApply(updatedFile);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to apply mapping: $e')));
      }
    }
  }
}
