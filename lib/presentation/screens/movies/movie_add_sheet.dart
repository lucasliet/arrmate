import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/media_add_defaults_store.dart';
import '../../../core/utils/discovery_results.dart';
import '../../../domain/models/models.dart';
import '../../providers/data_providers.dart';
import '../../providers/instance_tags_provider.dart';
import '../../providers/instances_provider.dart';
import '../../shared/providers/formatted_options_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/tags/tag_list.dart';
import 'providers/movie_lookup_provider.dart';
import 'providers/movies_provider.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../l10n/labels.dart';

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

  /// Closes the sheet, falling back to the library route when the discovery
  /// screen is the root of the navigation stack (direct URL or deep link).
  void _closeSheet() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/movies');
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.moviesAddMissingSelection)),
      );
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
        final messenger = ScaffoldMessenger.of(context);
        final container = ProviderScope.containerOf(context);
        final successMessage = context.l10n.moviesAddedSuccessfully;
        _closeSheet();
        messenger.showSnackBar(SnackBar(content: Text(successMessage)));
        // Reload the library on the next frame, after the pop and the
        // snackbar have been scheduled.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          container.invalidate(moviesProvider);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.moviesAddFailed(describeError(e, context.l10n)),
            ),
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
          AppBar(
            title: Text(context.l10n.moviesAddMovieTitle),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                tooltip: context.l10n.commonClose,
                icon: const Icon(Icons.close),
                onPressed: _closeSheet,
              ),
            ],
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: context.l10n.commonSearch,
                hintText: 'Interstellar, tmdb:157336, imdb:tt0816692',
                isDense: true,
              ),
              onChanged: (value) {
                ref.read(movieLookupProvider.notifier).searchDebounced(value);
              },
              onSubmitted: (value) {
                ref.read(movieLookupProvider.notifier).search(value);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Built inside the callback. A dropdown created outside and
                // reused here is moved during layout and corrupts the parent
                // LayoutBuilder.
                final sortSelector =
                    DropdownButtonFormField<DiscoverySortOption>(
                      initialValue: _sort,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.l10n.commonSort,
                        isDense: true,
                      ),
                      items: DiscoverySortOption.values
                          .map(
                            (option) => DropdownMenuItem(
                              value: option,
                              child: Text(option.localizedLabel(context.l10n)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _sort = value);
                      },
                    );
                final hideExistingFilter = FilterChip(
                  selected: _hideExisting,
                  label: Text(context.l10n.discoveryHideAlreadyAdded),
                  onSelected: (value) {
                    setState(() => _hideExisting = value);
                  },
                );
                if (constraints.maxWidth < 320) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      sortSelector,
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: hideExistingFilter,
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: sortSelector),
                    const SizedBox(width: 12),
                    hideExistingFilter,
                  ],
                );
              },
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
                  return Center(
                    child: Text(context.l10n.discoveryNoResultsFound),
                  );
                }
                if (results.isEmpty) {
                  return Center(
                    child: Text(context.l10n.discoverySearchPrompt),
                  );
                }
                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: 24),
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
                        '${movie.localizedYearLabel(context.l10n)} · '
                        '${movie.ratings?.tmdb?.value.toStringAsFixed(1) ?? context.l10n.discoveryNoRating}',
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
              error: (err, stack) => Center(
                child: Text(
                  context.l10n.commonErrorWithDetails(
                    describeError(err, context.l10n),
                  ),
                ),
              ),
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
            title: Text(context.l10n.moviesPreviewTitle),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _selectedMovie = null),
            ),
            automaticallyImplyLeading: false,
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                  '${movie.title} (${movie.localizedYearLabel(context.l10n)})',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    if (movie.certification != null) movie.certification!,
                    if (movie.runtime > 0)
                      context.l10n.discoveryRuntimeMinutes(movie.runtime),
                    ...movie.genres.take(3),
                  ].join(' · '),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(movie.overview ?? context.l10n.discoveryNoOverview),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => setState(() => _isConfiguring = true),
                  icon: const Icon(Icons.tune),
                  label: Text(context.l10n.discoveryConfigureAddition),
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
    final tags = watchInstanceTags(
      ref,
      ref.watch(currentRadarrInstanceProvider),
    );

    return _buildSurface(
      (scrollController) => Column(
        children: [
          AppBar(
            title: Text(
              _selectedMovie?.title ?? context.l10n.moviesAddMovieTitle,
            ),
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
                    : Text(
                        context.l10n.commonAdd,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
            automaticallyImplyLeading: false,
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                DropdownButtonFormField<MovieMonitorType>(
                  decoration: InputDecoration(
                    labelText: context.l10n.commonMonitor,
                  ),
                  initialValue: _monitor,
                  items: MovieMonitorType.values
                      .map(
                        (monitor) => DropdownMenuItem(
                          value: monitor,
                          child: Text(monitor.localizedLabel(context.l10n)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _monitor = value);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<MovieStatus>(
                  decoration: InputDecoration(
                    labelText: context.l10n.moviesMinimumAvailability,
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
                          child: Text(status.localizedLabel(context.l10n)),
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
                      decoration: InputDecoration(
                        labelText: context.l10n.commonQualityProfile,
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
                  error: (e, _) => Text(
                    context.l10n.discoveryLoadProfilesFailed(
                      describeError(e, context.l10n),
                    ),
                  ),
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
                      decoration: InputDecoration(
                        labelText: context.l10n.commonRootFolder,
                      ),
                      initialValue: effectiveRootFolder,
                      items: rootFolderList.map((f) {
                        final freeSpaceGb =
                            (f.freeSpace ?? 0) / 1024 / 1024 / 1024;
                        return DropdownMenuItem(
                          value: f.path,
                          child: Text(
                            context.l10n.discoveryRootFolderFreeSpace(
                              f.path,
                              freeSpaceGb.toStringAsFixed(1),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _rootFolderPath = val),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text(
                    context.l10n.discoveryLoadFoldersFailed(
                      describeError(e, context.l10n),
                    ),
                  ),
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.commonTags,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
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
