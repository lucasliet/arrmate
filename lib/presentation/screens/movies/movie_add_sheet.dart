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
import 'providers/movie_lookup_provider.dart';
import 'providers/movies_provider.dart';

/// A modal sheet for searching and adding new movies to Radarr.
class MovieAddSheet extends ConsumerStatefulWidget {
  final Movie? initialMovie;
  final bool embedded;
  final String? initialQuery;

  const MovieAddSheet({
    super.key,
    this.initialMovie,
    this.embedded = false,
    this.initialQuery,
  });

  @override
  ConsumerState<MovieAddSheet> createState() => _MovieAddSheetState();
}

class _MovieAddSheetState extends ConsumerState<MovieAddSheet> {
  final _searchController = TextEditingController();
  final _embeddedScrollController = ScrollController();
  final _defaultsStore = MediaAddDefaultsStore();
  Movie? _selectedMovie;
  bool _isConfiguring = false;

  MovieMonitorType _monitor = MovieMonitorType.movieOnly;
  MovieStatus _minimumAvailability = MovieStatus.announced;
  int? _qualityProfileId;
  String? _rootFolderPath;
  Set<int> _selectedTagIds = {};
  DiscoverySortOption _sort = DiscoverySortOption.relevance;
  bool _hideExisting = true;
  bool _isSubmitting = false;
  String? _loadedDefaultsInstanceId;

  @override
  void initState() {
    super.initState();
    _selectedMovie = widget.initialMovie;
    final query = widget.initialQuery?.trim();
    if (query != null && query.isNotEmpty) {
      _searchController.text = query;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(movieLookupProvider.notifier).search(query);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _embeddedScrollController.dispose();
    super.dispose();
  }

  void _onMovieSelected(Movie movie) {
    setState(() {
      _selectedMovie = movie;
      _isConfiguring = false;
    });
  }

  void _loadDefaults(Instance? instance) {
    if (instance == null || _loadedDefaultsInstanceId == instance.id) return;
    _loadedDefaultsInstanceId = instance.id;
    _defaultsStore.loadMovie(instance.id).then((defaults) {
      if (!mounted || _loadedDefaultsInstanceId != instance.id) return;
      setState(() {
        _monitor = defaults.monitor;
        _minimumAvailability = defaults.minimumAvailability;
        _qualityProfileId = defaults.qualityProfileId;
        _rootFolderPath = defaults.rootFolderPath;
        _selectedTagIds = defaults.tags.toSet();
      });
    });
  }

  Future<void> _submit() async {
    if (_selectedMovie == null ||
        _qualityProfileId == null ||
        _rootFolderPath == null) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final api = ref.read(radarrApiProvider);
      if (api == null) throw Exception('API not available');

      final instance = ref.read(currentRadarrInstanceProvider);
      if (instance == null) throw Exception('Radarr instance not available');

      final movieToAdd = _selectedMovie!.copyWith(
        monitored: _monitor != MovieMonitorType.none,
        minimumAvailability: _minimumAvailability,
        qualityProfileId: _qualityProfileId,
        rootFolderPath: _rootFolderPath,
        tags: _selectedTagIds.toList(),
        addOptions: MovieAddOptions(monitor: _monitor),
        added: DateTime.now(),
      );

      await api.addMovie(movieToAdd);
      await _defaultsStore.saveMovie(
        instance.id,
        MovieAddDefaults(
          monitor: _monitor,
          minimumAvailability: _minimumAvailability,
          qualityProfileId: _qualityProfileId,
          rootFolderPath: _rootFolderPath,
          tags: _selectedTagIds.toList(),
        ),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Movie added successfully')),
        );
        ref.invalidate(moviesProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding movie: $e'),
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
    _loadDefaults(ref.watch(currentRadarrInstanceProvider));
    if (_selectedMovie != null && _isConfiguring) {
      return _buildConfigForm();
    }
    if (_selectedMovie != null) {
      return _buildPreview();
    }
    return _buildSearch();
  }

  Widget _buildSearch() {
    final searchResult = ref.watch(movieLookupProvider);

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
                      hintText: 'Interstellar, tmdb:157336, imdb:tt0816692',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      ref
                          .read(movieLookupProvider.notifier)
                          .searchDebounced(value);
                    },
                    onSubmitted: (value) {
                      ref.read(movieLookupProvider.notifier).search(value);
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
              data: (movies) {
                final results = prepareMovieDiscoveryResults(
                  movies,
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
                    final movie = results[index];
                    return ListTile(
                      leading: movie.remotePoster != null
                          ? Image.network(
                              movie.remotePoster!,
                              width: 40,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.movie),
                      title: Text(movie.title),
                      subtitle: Text(
                        '${movie.yearLabel} · '
                        '${movie.ratings?.tmdb?.value.toStringAsFixed(1) ?? 'No rating'}',
                      ),
                      trailing: movie.exists
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.chevron_right),
                      onTap: () {
                        if (movie.exists) {
                          context.go('/movies/${movie.id}');
                        } else {
                          _onMovieSelected(movie);
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
    final movie = _selectedMovie!;
    return _buildSurface(
      (scrollController) => Column(
        children: [
          AppBar(
            title: const Text('Movie Preview'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _selectedMovie = null),
            ),
            automaticallyImplyLeading: false,
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                if (movie.remotePoster != null)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        movie.remotePoster!,
                        width: 180,
                        height: 270,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  '${movie.title} (${movie.yearLabel})',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    if (movie.certification != null) movie.certification!,
                    if (movie.runtime > 0) '${movie.runtime} min',
                    ...movie.genres.take(3),
                  ].join(' · '),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(movie.overview ?? 'No overview available.'),
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
    final qualityProfiles = ref.watch(movieQualityProfilesProvider);
    final rootFolders = ref.watch(movieRootFoldersProvider);
    final tags =
        ref.watch(currentRadarrInstanceProvider)?.tags ?? const <Tag>[];

    return _buildSurface(
      (scrollController) => Column(
        children: [
          AppBar(
            title: Text(_selectedMovie?.title ?? 'Add Movie'),
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
                DropdownButtonFormField<MovieMonitorType>(
                  decoration: const InputDecoration(labelText: 'Monitor'),
                  initialValue: _monitor,
                  items: MovieMonitorType.values
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
                DropdownButtonFormField<MovieStatus>(
                  decoration: const InputDecoration(
                    labelText: 'Minimum Availability',
                  ),
                  initialValue: _minimumAvailability,
                  items:
                      [
                        MovieStatus.announced,
                        MovieStatus.inCinemas,
                        MovieStatus.released,
                      ].map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        );
                      }).toList(),
                  onChanged: (val) =>
                      setState(() => _minimumAvailability = val!),
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
