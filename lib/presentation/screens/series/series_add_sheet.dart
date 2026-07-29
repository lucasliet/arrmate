import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/media_add_defaults_store.dart';
import '../../../core/utils/discovery_results.dart';
import '../../../domain/models/models.dart';
import '../../providers/data_providers.dart';
import '../../providers/instances_provider.dart';
import '../../shared/providers/formatted_options_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/tags/tag_list.dart';
import 'providers/series_lookup_provider.dart';
import 'providers/series_provider.dart';

/// A modal sheet for searching and adding new series to Sonarr.
class SeriesAddSheet extends ConsumerStatefulWidget {
  final Series? initialSeries;
  final bool embedded;
  final String? initialQuery;

  const SeriesAddSheet({
    super.key,
    this.initialSeries,
    this.embedded = false,
    this.initialQuery,
  });

  @override
  ConsumerState<SeriesAddSheet> createState() => _SeriesAddSheetState();
}

class _SeriesAddSheetState extends ConsumerState<SeriesAddSheet> {
  final _searchController = TextEditingController();
  final _embeddedScrollController = ScrollController();
  final _defaultsStore = MediaAddDefaultsStore();
  Series? _selectedSeries;
  bool _isConfiguring = false;

  SeriesMonitorType _monitor = SeriesMonitorType.none;
  SeriesMonitorNewItems _monitorNewItems = SeriesMonitorNewItems.none;
  SeriesType _seriesType = SeriesType.standard;
  int? _qualityProfileId;
  String? _rootFolderPath;
  bool _seasonFolder = true;
  Set<int> _selectedTagIds = {};
  DiscoverySortOption _sort = DiscoverySortOption.relevance;
  bool _hideExisting = true;
  bool _isSubmitting = false;
  String? _loadedDefaultsInstanceId;

  @override
  void initState() {
    super.initState();
    _selectedSeries = widget.initialSeries;
    final query = widget.initialQuery?.trim();
    if (query != null && query.isNotEmpty) {
      _searchController.text = query;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(seriesLookupProvider.notifier).search(query);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _embeddedScrollController.dispose();
    super.dispose();
  }

  void _onSeriesSelected(Series series) {
    setState(() {
      _selectedSeries = series;
      _isConfiguring = false;
    });
  }

  void _loadDefaults(Instance? instance) {
    if (instance == null || _loadedDefaultsInstanceId == instance.id) return;
    _loadedDefaultsInstanceId = instance.id;
    _defaultsStore.loadSeries(instance.id).then((defaults) {
      if (!mounted || _loadedDefaultsInstanceId != instance.id) return;
      setState(() {
        _monitor = defaults.monitor;
        _monitorNewItems = defaults.monitorNewItems;
        _seriesType = defaults.seriesType;
        _seasonFolder = defaults.seasonFolder;
        _qualityProfileId = defaults.qualityProfileId;
        _rootFolderPath = defaults.rootFolderPath;
        _selectedTagIds = defaults.tags.toSet();
      });
    });
  }

  Future<void> _submit() async {
    if (_selectedSeries == null ||
        _qualityProfileId == null ||
        _rootFolderPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a series, quality profile, and root folder',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final api = ref.read(sonarrApiProvider);
      if (api == null) throw Exception('API not available');
      final instance = ref.read(currentSonarrInstanceProvider);
      if (instance == null) throw Exception('Sonarr instance not available');

      final seriesToAdd = _selectedSeries!.copyWith(
        monitored: _monitor != SeriesMonitorType.none,
        monitorNewItems: _monitorNewItems,
        qualityProfileId: _qualityProfileId,
        rootFolderPath: _rootFolderPath,
        seasonFolder: _seasonFolder,
        seriesType: _seriesType,
        tags: _selectedTagIds.toList(),
        addOptions: SeriesAddOptions(monitor: _monitor),
        added: DateTime.now(),
      );

      await api.addSeries(seriesToAdd);
      await _defaultsStore.saveSeries(
        instance.id,
        SeriesAddDefaults(
          monitor: _monitor,
          monitorNewItems: _monitorNewItems,
          seriesType: _seriesType,
          seasonFolder: _seasonFolder,
          qualityProfileId: _qualityProfileId,
          rootFolderPath: _rootFolderPath,
          tags: _selectedTagIds.toList(),
        ),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Series added successfully')),
        );
        ref.invalidate(seriesProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding series: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _loadDefaults(ref.watch(currentSonarrInstanceProvider));
    if (_selectedSeries != null && _isConfiguring) {
      return _buildConfigForm();
    }
    if (_selectedSeries != null) {
      return _buildPreview();
    }
    return _buildSearch();
  }

  Widget _buildSearch() {
    final searchResult = ref.watch(seriesLookupProvider);

    return _buildSurface(
      (scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      hintText: 'Breaking Bad, tvdb:81189, imdb:tt0903747',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      ref
                          .read(seriesLookupProvider.notifier)
                          .searchDebounced(value);
                    },
                    onSubmitted: (value) {
                      ref.read(seriesLookupProvider.notifier).search(value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<DiscoverySortOption>(
                    initialValue: _sort,
                    decoration: const InputDecoration(
                      labelText: 'Sort',
                      isDense: true,
                    ),
                    items: DiscoverySortOption.values
                        .map(
                          (option) => DropdownMenuItem(
                            value: option,
                            child: Text(option.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _sort = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                FilterChip(
                  selected: _hideExisting,
                  label: const Text('Hide in library'),
                  onSelected: (value) {
                    setState(() => _hideExisting = value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: searchResult.when(
              data: (seriesList) {
                final results = prepareSeriesDiscoveryResults(
                  seriesList,
                  sort: _sort,
                  hideExisting: _hideExisting,
                );
                if (results.isEmpty && _searchController.text.isNotEmpty) {
                  return const Center(child: Text('No results found'));
                }
                if (results.isEmpty) {
                  return const Center(
                    child: Text('Search by title, provider ID, or URL'),
                  );
                }
                return ListView.builder(
                  controller: scrollController,
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final series = results[index];
                    return ListTile(
                      leading: series.remotePoster != null
                          ? Image.network(
                              series.remotePoster!,
                              width: 40,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.tv),
                      title: Text(series.title),
                      subtitle: Text(
                        '${series.yearLabel} · '
                        '${series.ratings?.value.toStringAsFixed(1) ?? 'No rating'}',
                      ),
                      trailing: series.exists
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.chevron_right),
                      onTap: () {
                        if (series.exists) {
                          context.go('/series/${series.id}');
                        } else {
                          _onSeriesSelected(series);
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: LoadingIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final series = _selectedSeries!;
    return _buildSurface(
      (scrollController) => Column(
        children: [
          AppBar(
            title: const Text('Series Preview'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _selectedSeries = null),
            ),
            automaticallyImplyLeading: false,
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                if (series.remotePoster != null)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        series.remotePoster!,
                        width: 180,
                        height: 270,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  '${series.title} (${series.yearLabel})',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    if (series.certification != null) series.certification!,
                    if (series.network != null) series.network!,
                    ...series.genres.take(3),
                  ].join(' · '),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(series.overview ?? 'No overview available.'),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => setState(() => _isConfiguring = true),
                  icon: const Icon(Icons.tune),
                  label: const Text('Configure Addition'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurface(
    Widget Function(ScrollController scrollController) builder,
  ) {
    if (widget.embedded) {
      return builder(_embeddedScrollController);
    }
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => builder(scrollController),
    );
  }

  Widget _buildConfigForm() {
    final qualityProfiles = ref.watch(seriesQualityProfilesProvider);
    final rootFolders = ref.watch(seriesRootFoldersProvider);
    final tags =
        ref.watch(currentSonarrInstanceProvider)?.tags ?? const <Tag>[];

    return _buildSurface(
      (scrollController) => Column(
        children: [
          AppBar(
            title: Text(_selectedSeries?.title ?? 'Add Series'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _isConfiguring = false),
            ),
            actions: [
              TextButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Add',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
            automaticallyImplyLeading: false,
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<SeriesMonitorType>(
                  decoration: const InputDecoration(labelText: 'Monitor'),
                  initialValue: _monitor,
                  items: SeriesMonitorType.values
                      .where(
                        (monitor) =>
                            monitor != SeriesMonitorType.unknown &&
                            monitor != SeriesMonitorType.skip,
                      )
                      .map(
                        (monitor) => DropdownMenuItem(
                          value: monitor,
                          child: Text(monitor.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _monitor = value);
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Monitor New Seasons'),
                  value: _monitorNewItems == SeriesMonitorNewItems.all,
                  onChanged: (value) {
                    setState(
                      () => _monitorNewItems = value
                          ? SeriesMonitorNewItems.all
                          : SeriesMonitorNewItems.none,
                    );
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<SeriesType>(
                  decoration: const InputDecoration(labelText: 'Series Type'),
                  initialValue: _seriesType,
                  items: SeriesType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.label),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _seriesType = val!),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Season Folder'),
                  value: _seasonFolder,
                  onChanged: (val) => setState(() => _seasonFolder = val),
                ),
                const SizedBox(height: 16),
                qualityProfiles.when(
                  data: (profiles) {
                    final effectiveProfileId =
                        profiles.any(
                          (profile) => profile.id == _qualityProfileId,
                        )
                        ? _qualityProfileId
                        : profiles.firstOrNull?.id;
                    if (_qualityProfileId != effectiveProfileId) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(
                            () => _qualityProfileId = effectiveProfileId,
                          );
                        }
                      });
                    }
                    return DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Quality Profile',
                      ),
                      initialValue: effectiveProfileId,
                      items: profiles
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.name),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _qualityProfileId = val),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading profiles: $e'),
                ),
                const SizedBox(height: 16),
                rootFolders.when(
                  data: (folders) {
                    final rootFolderList = List<RootFolder>.from(folders);
                    final effectiveRootFolder =
                        rootFolderList.any(
                          (folder) => folder.path == _rootFolderPath,
                        )
                        ? _rootFolderPath
                        : rootFolderList.firstOrNull?.path;
                    if (_rootFolderPath != effectiveRootFolder) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() => _rootFolderPath = effectiveRootFolder);
                        }
                      });
                    }
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Root Folder',
                      ),
                      initialValue: effectiveRootFolder,
                      items: rootFolderList.map((f) {
                        final freeSpaceGb =
                            (f.freeSpace ?? 0) / 1024 / 1024 / 1024;
                        return DropdownMenuItem(
                          value: f.path,
                          child: Text(
                            '${f.path} (${freeSpaceGb.toStringAsFixed(1)} GB Free)',
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _rootFolderPath = val),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading folders: $e'),
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Tags', style: Theme.of(context).textTheme.titleMedium),
                  TagList(
                    tags: tags,
                    selectedTagIds: _selectedTagIds,
                    onSelectionChanged: (value) {
                      setState(() => _selectedTagIds = value);
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
