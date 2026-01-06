import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/models/models.dart';
import '../../providers/data_providers.dart';
import 'providers/movie_details_provider.dart';

/// Screen for editing an existing movie's configuration (monitor status, profile, path).
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
  Future<(List<QualityProfile>, List<RootFolder>)>? _dataFuture;
  bool _hasSyncedRootFolder = false;

  @override
  void initState() {
    super.initState();
    _monitored = widget.movie.monitored;
    _qualityProfileId = widget.movie.qualityProfileId;
    _rootFolderPath = widget.movie.rootFolderPath ?? widget.movie.path ?? '';
    _minimumAvailability = widget.movie.minimumAvailability;
  }

  void _initDataFuture() {
    if (_dataFuture != null) return;
    final repository = ref.read(movieRepositoryProvider);
    if (repository == null) return;

    _dataFuture =
        Future.wait([
          repository.getQualityProfiles(),
          repository.getRootFolders(),
        ]).then((value) {
          final rootFolders = value[1] as List<RootFolder>;
          _syncRootFolderIfNeeded(rootFolders);
          return (value[0] as List<QualityProfile>, rootFolders);
        });
  }

  void _syncRootFolderIfNeeded(List<RootFolder> rootFolders) {
    if (_hasSyncedRootFolder) return;
    _hasSyncedRootFolder = true;

    if (!rootFolders.any((f) => f.path == _rootFolderPath) &&
        rootFolders.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _rootFolderPath = rootFolders.first.path;
          });
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      bool rootFolderChanged = false;
      if (widget.movie.rootFolderPath != _rootFolderPath) {
        rootFolderChanged = true;
      }

      bool moveFiles = false;
      if (rootFolderChanged && widget.movie.isDownloaded) {
        final confirmMove = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Move Files?'),
            content: Text(
              'Do you want to move the files to "$_rootFolderPath"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
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

      await ref
          .read(movieControllerProvider(widget.movie.id))
          .updateMovie(updatedMovie, moveFiles: moveFiles);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Movie updated')));
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
    final repository = ref.watch(movieRepositoryProvider);

    if (repository != null) {
      _initDataFuture();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Movie'),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
      body: repository == null || _dataFuture == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<(List<QualityProfile>, List<RootFolder>)>(
              future: _dataFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final qualityProfiles = snapshot.data!.$1;
                final rootFolders = snapshot.data!.$2;

                final effectiveRootFolder =
                    rootFolders.any((f) => f.path == _rootFolderPath)
                    ? _rootFolderPath
                    : rootFolders.isNotEmpty
                    ? rootFolders.first.path
                    : null;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          title: const Text('Monitored'),
                          value: _monitored,
                          onChanged: (val) => setState(() => _monitored = val),
                        ),
                        const Divider(),

                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Quality Profile',
                            border: OutlineInputBorder(),
                          ),
                          initialValue: _qualityProfileId,
                          items: qualityProfiles
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text(p.name),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _qualityProfileId = val!),
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<MovieStatus>(
                          decoration: const InputDecoration(
                            labelText: 'Minimum Availability',
                            border: OutlineInputBorder(),
                          ),
                          initialValue: _minimumAvailability,
                          items:
                              [
                                    MovieStatus.announced,
                                    MovieStatus.inCinemas,
                                    MovieStatus.released,
                                  ]
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s.label),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) =>
                              setState(() => _minimumAvailability = val!),
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Root Folder',
                            border: OutlineInputBorder(),
                            helperText:
                                'Changing this will move files if confirmed',
                          ),
                          initialValue: effectiveRootFolder,
                          items: rootFolders
                              .map(
                                (f) => DropdownMenuItem(
                                  value: f.path,
                                  child: Text(f.path),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _rootFolderPath = val!),
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
