import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/models/models.dart';
import '../../providers/data_providers.dart';
import '../../providers/instance_tags_provider.dart';
import '../../providers/instances_provider.dart';
import '../../widgets/tags/tag_list.dart';
import 'providers/movie_details_provider.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../l10n/labels.dart';

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
  late Set<int> _selectedTagIds;

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
    _selectedTagIds = widget.movie.tags.toSet();
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
            title: Text(context.l10n.moviesMoveFilesTitle),
            content: Text(context.l10n.moviesMoveFilesConfirm(_rootFolderPath)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.l10n.commonNo),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.l10n.commonYes),
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
        tags: _selectedTagIds.toList(),
      );

      await ref
          .read(movieControllerProvider(widget.movie.id))
          .updateMovie(updatedMovie, moveFiles: moveFiles);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.moviesUpdated)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.moviesUpdateFailed(describeError(e, context.l10n)),
            ),
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
    final tags = watchInstanceTags(
      ref,
      ref.watch(currentRadarrInstanceProvider),
    );

    if (repository != null) {
      _initDataFuture();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.moviesEditTitle),
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
                  return Center(
                    child: Text(
                      context.l10n.commonErrorWithDetails(
                        describeError(snapshot.error!, context.l10n),
                      ),
                    ),
                  );
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
                          title: Text(context.l10n.commonMonitored),
                          value: _monitored,
                          onChanged: (val) => setState(() => _monitored = val),
                        ),
                        const Divider(),

                        DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            labelText: context.l10n.commonQualityProfile,
                            border: const OutlineInputBorder(),
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
                          decoration: InputDecoration(
                            labelText: context.l10n.moviesMinimumAvailability,
                            border: const OutlineInputBorder(),
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
                                      child: Text(
                                        s.localizedLabel(context.l10n),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) =>
                              setState(() => _minimumAvailability = val!),
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: context.l10n.commonRootFolder,
                            border: const OutlineInputBorder(),
                            helperText: context.l10n.moviesRootFolderHelper,
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
                );
              },
            ),
    );
  }
}
