import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/models/models.dart';
import '../../providers/data_providers.dart';
import 'providers/movie_details_provider.dart';

class MovieEditScreen extends ConsumerStatefulWidget {
  final Movie movie;

  const MovieEditScreen({super.key, required this.movie});

  @override
  ConsumerState<MovieEditScreen> createState() => _MovieEditScreenState();
}

class _MovieEditScreenState extends ConsumerState<MovieEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late bool _monitored;
  late int _qualityProfileId;
  late String _rootFolderPath;
  late MovieStatus _minimumAvailability;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _monitored = widget.movie.monitored;
    _qualityProfileId = widget.movie.qualityProfileId;
    _rootFolderPath = widget.movie.rootFolderPath ?? widget.movie.path ?? '';
    _minimumAvailability = widget.movie.minimumAvailability;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {

      // Rudarr logic: detects if root folder changed. In Radarr API, if you change 'rootFolderPath' 
      // AND 'moveFiles=true', it moves. But Movie object usually has 'path' (full path) and 'rootFolderPath' (prefix).
      // Wait, the API usually expects 'rootFolderPath' to be updated if we are moving?
      // Actually, looking at Radarr API docs/behavior:
      // To move, we update 'rootFolderPath' property in the JSON to the new parent folder.
      // The 'path' property is usually read-only or derived.
      
      bool rootFolderChanged = false;
      // We need to compare specific logic or just trust the user selection.
      // Let's check if the current path starts with the selected root folder.
      // Or just check if _rootFolderPath is different from initial.
      
      // Simplification: We check if the user selected a different root folder than what was implied.
      // However, `movie.rootFolderPath` comes from API.
      
      if (widget.movie.rootFolderPath != _rootFolderPath) {
        rootFolderChanged = true;
      }

      bool moveFiles = false;
      if (rootFolderChanged && widget.movie.isDownloaded) {
        // Ask usage
        final confirmMove = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Move Files?'),
            content: Text(
              'Do you want to move the files to "$_rootFolderPath"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false), // No, just update DB
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true), // Yes, move files
                child: const Text('Yes'),
              ),
            ],
          ),
        );
        moveFiles = confirmMove ?? false;
      }

      final updatedMovie = widget.movie.copyWith(
        monitored: _monitored,
        qualityProfileId: _qualityProfileId,
        rootFolderPath: _rootFolderPath,
        minimumAvailability: _minimumAvailability,
      );

      await ref.read(movieControllerProvider(widget.movie.id))
          .updateMovie(updatedMovie, moveFiles: moveFiles);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Movie updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating movie: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // We need to fetch profiles and root folders
    final repository = ref.watch(movieRepositoryProvider);
    
    // We can use FutureBuilder or define a provider.
    // For simplicity in this edit screen, let's use FutureBuilder inside the build or just assume loading state.
    // Better: Helper provider.
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Movie'),
        actions: [
          IconButton(
            icon: _isSaving 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save),
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
      body: repository == null 
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<(List<QualityProfile>, List<RootFolder>)>(
              future: Future.wait([
                repository.getQualityProfiles(),
                repository.getRootFolders(),
              ]).then((value) => (value[0] as List<QualityProfile>, value[1] as List<RootFolder>)),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final qualityProfiles = snapshot.data!.$1;
                final rootFolders = snapshot.data!.$2;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Monitored Toggle
                        SwitchListTile(
                          title: const Text('Monitored'),
                          value: _monitored,
                          onChanged: (val) => setState(() => _monitored = val),
                        ),
                        const Divider(),
                        
                        // Quality Profile
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Quality Profile',
                            border: OutlineInputBorder(),
                          ),
                          value: _qualityProfileId,
                          items: qualityProfiles.map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.name),
                          )).toList(),
                          onChanged: (val) => setState(() => _qualityProfileId = val!),
                        ),
                        const SizedBox(height: 16),

                        // Minimum Availability
                        DropdownButtonFormField<MovieStatus>(
                          decoration: const InputDecoration(
                            labelText: 'Minimum Availability',
                            border: OutlineInputBorder(),
                          ),
                          value: _minimumAvailability,
                          items: [
                            MovieStatus.announced,
                            MovieStatus.inCinemas,
                            MovieStatus.released,
                          ].map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.label),
                          )).toList(),
                          onChanged: (val) => setState(() => _minimumAvailability = val!),
                        ),
                        const SizedBox(height: 16),

                        // Root Folder
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Root Folder',
                            border: OutlineInputBorder(),
                            helperText: 'Changing this will move files if confirmed',
                          ),
                          value: rootFolders.any((f) => f.path == _rootFolderPath) 
                              ? _rootFolderPath 
                              : (rootFolders.firstOrNull?.path ?? _rootFolderPath),
                              // Fallback if current path is not in list (strange but possible)
                          items: rootFolders.map((f) => DropdownMenuItem(
                            value: f.path,
                            child: Text(f.path ?? 'Unknown'),
                          )).toList(),
                          onChanged: (val) => setState(() => _rootFolderPath = val!),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
