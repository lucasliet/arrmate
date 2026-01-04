import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arrmate/data/models/models.dart';
import 'package:arrmate/presentation/shared/widgets/common_widgets.dart';
import 'providers/movie_lookup_provider.dart';
import 'providers/movies_provider.dart';
import '../../../../presentation/shared/providers/formatted_options_provider.dart';
import '../../../../presentation/shared/providers/instances_provider.dart';

class MovieAddSheet extends ConsumerStatefulWidget {
  const MovieAddSheet({super.key});

  @override
  ConsumerState<MovieAddSheet> createState() => _MovieAddSheetState();
}

class _MovieAddSheetState extends ConsumerState<MovieAddSheet> {
  final _searchController = TextEditingController();
  Movie? _selectedMovie;
  
  // Form State
  bool _monitored = true;
  MovieStatus _minimumAvailability = MovieStatus.announced;
  int? _qualityProfileId;
  String? _rootFolderPath;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onMovieSelected(Movie movie) {
    setState(() {
      _selectedMovie = movie;
      // Reset form defaults if needed, or fetch defaults from API if implemented
      _monitored = true;
      _minimumAvailability = MovieStatus.announced;
      // Quality/Folder selection will default to first available in dropdowns
    });
  }

  Future<void> _submit() async {
    if (_selectedMovie == null || _qualityProfileId == null || _rootFolderPath == null) return;

    setState(() => _isSubmitting = true);

    try {
      final api = ref.read(radarrApiProvider);
      if (api == null) throw Exception('API not available');

      final movieToAdd = _selectedMovie!.copyWith(
        monitored: _monitored,
        minimumAvailability: _minimumAvailability,
        qualityProfileId: _qualityProfileId,
        rootFolderPath: _rootFolderPath,
        // Ensure added is set correctly, though API usually handles this
        added: DateTime.now(), 
      );

      await api.addMovie(movieToAdd);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Movie added successfully')),
        );
        ref.refresh(moviesProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding movie: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedMovie != null) {
      return _buildConfigForm();
    }
    return _buildSearch();
  }

  Widget _buildSearch() {
    final searchResult = ref.watch(movieLookupProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search for a movie...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (value) {
                         ref.read(movieLookupProvider.notifier).search(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: searchResult.when(
                data: (movies) {
                  if (movies.isEmpty && _searchController.text.isNotEmpty) {
                    return const Center(child: Text('No results found'));
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: movies.length,
                    itemBuilder: (context, index) {
                      final movie = movies[index];
                      return ListTile(
                        leading: movie.remotePoster != null
                            ? Image.network(movie.remotePoster!, width: 40, fit: BoxFit.cover)
                            : const Icon(Icons.movie),
                        title: Text(movie.title),
                        subtitle: Text('${movie.year}'),
                        trailing: movie.added.year > 2000 // Simple check if already added - usually API returns fully populated obj if exists
                            ? const Icon(Icons.check, color: Colors.green)
                            : const Icon(Icons.add),
                        onTap: () {
                             if (movie.added.year <= 2000) { // Check if 'added' is default (not in library)
                                  _onMovieSelected(movie);
                             } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                       const SnackBar(content: Text('Movie already in library')),
                                  );
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
        );
      },
    );
  }

  Widget _buildConfigForm() {
    final qualityProfiles = ref.watch(movieQualityProfilesProvider);
    final rootFolders = ref.watch(movieRootFoldersProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            AppBar(
              title: Text(_selectedMovie?.title ?? 'Add Movie'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedMovie = null),
              ),
              actions: [
                TextButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting 
                     ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                     : const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
              automaticallyImplyLeading: false, 
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  SwitchListTile(
                    title: const Text('Monitored'),
                    value: _monitored,
                    onChanged: (val) => setState(() => _monitored = val),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<MovieStatus>(
                    decoration: const InputDecoration(labelText: 'Minimum Availability'),
                    value: _minimumAvailability,
                    items: [
                      MovieStatus.announced,
                      MovieStatus.inCinemas,
                      MovieStatus.released
                    ].map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status.label),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _minimumAvailability = val!),
                  ),
                  const SizedBox(height: 16),
                  qualityProfiles.when(
                    data: (profiles) {
                      if (_qualityProfileId == null && profiles.isNotEmpty) {
                         // Defer state update to next frame to avoid build error
                         WidgetsBinding.instance.addPostFrameCallback((_) {
                           if(mounted) setState(() => _qualityProfileId = profiles.first.id);
                         });
                      }
                      return DropdownButtonFormField<int>(
                        decoration: const InputDecoration(labelText: 'Quality Profile'),
                        value: _qualityProfileId,
                        items: profiles.map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(p.name),
                        )).toList(),
                        onChanged: (val) => setState(() => _qualityProfileId = val),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Error loading profiles: $e'),
                  ),
                  const SizedBox(height: 16),
                  rootFolders.when(
                    data: (folders) {
                       if (_rootFolderPath == null && folders.isNotEmpty) {
                         WidgetsBinding.instance.addPostFrameCallback((_) {
                           if(mounted) setState(() => _rootFolderPath = folders.first.path);
                         });
                      }
                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Root Folder'),
                        value: _rootFolderPath,
                        items: folders.map((f) => DropdownMenuItem(
                          value: f.path,
                          child: Text('${f.path} (${f.freeSpaceGb.toStringAsFixed(1)} GB Free)'),
                        )).toList(),
                        onChanged: (val) => setState(() => _rootFolderPath = val),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Error loading folders: $e'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
