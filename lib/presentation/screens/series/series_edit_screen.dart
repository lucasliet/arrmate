import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/models.dart';
import '../../../../domain/repositories/series_repository.dart';
import '../../providers/data_providers.dart';
import '../../providers/instance_tags_provider.dart';
import '../../providers/instances_provider.dart';
import '../../widgets/tags/tag_list.dart';
import 'providers/series_provider.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../l10n/labels.dart';

/// Screen for editing an existing series' configuration (monitor status, profile, path).
class SeriesEditScreen extends ConsumerStatefulWidget {
  final Series series;

  const SeriesEditScreen({super.key, required this.series});

  @override
  ConsumerState<SeriesEditScreen> createState() => _SeriesEditScreenState();
}

class _SeriesEditScreenState extends ConsumerState<SeriesEditScreen> {
  late bool _monitored;
  late bool _seasonFolder;
  late SeriesType _seriesType;
  late SeriesMonitorNewItems _monitorNewItems;
  late int? _qualityProfileId;
  late String? _rootFolderPath;
  late Set<int> _selectedTagIds;

  bool _isSaving = false;
  SeriesRepository? _dataRepository;
  Future<(List<QualityProfile>, List<RootFolder>)>? _dataFuture;

  @override
  void initState() {
    super.initState();
    _monitored = widget.series.monitored;
    _seasonFolder = widget.series.seasonFolder;
    _seriesType = widget.series.seriesType;
    _monitorNewItems =
        widget.series.monitorNewItems ?? SeriesMonitorNewItems.none;
    _qualityProfileId = widget.series.qualityProfileId;
    _rootFolderPath = widget.series.rootFolderPath ?? widget.series.path;
    _selectedTagIds = widget.series.tags.toSet();
  }

  Future<void> _save() async {
    final repository = ref.read(seriesRepositoryProvider);
    if (repository == null) return;

    setState(() => _isSaving = true);

    try {
      final moveFiles =
          _rootFolderPath != widget.series.rootFolderPath &&
          _rootFolderPath != widget.series.path;

      if (moveFiles) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.l10n.seriesMoveFilesTitle),
            content: Text(context.l10n.seriesMoveFilesContent),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, false), // No, just update DB
                child: Text(context.l10n.commonNo),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, true), // Yes, move files
                child: Text(context.l10n.seriesYesMoveFiles),
              ),
            ],
          ),
        );

        if (confirm == null) {
          setState(() => _isSaving = false);
          return; // Cancelled
        }

        await _performUpdate(moveFiles: confirm);
      } else {
        await _performUpdate(moveFiles: false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.seriesUpdateFailed(describeError(e, context.l10n)),
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _performUpdate({required bool moveFiles}) async {
    final updatedSeries = widget.series.copyWith(
      monitored: _monitored,
      monitorNewItems: _monitorNewItems,
      seasonFolder: _seasonFolder,
      seriesType: _seriesType,
      qualityProfileId: _qualityProfileId,
      rootFolderPath: _rootFolderPath,
      tags: _selectedTagIds.toList(),
    );

    // Using the controller to update ensures the provider is refreshed
    final controller = ref.read(seriesControllerProvider(widget.series.id));
    // Note: Controller needs an updateSeries method, similar to MovieController
    await controller.updateSeries(updatedSeries, moveFiles: moveFiles);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(seriesRepositoryProvider);
    final tags = watchInstanceTags(
      ref,
      ref.watch(currentSonarrInstanceProvider),
    );

    if (repository == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Live tags and form edits rebuild independently of server configuration.
    if (!identical(repository, _dataRepository)) {
      _dataRepository = repository;
      _dataFuture =
          Future.wait([
            repository.getQualityProfiles(),
            repository.getRootFolders(),
          ]).then(
            (value) => (
              value[0] as List<QualityProfile>,
              value[1] as List<RootFolder>,
            ),
          );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.seriesEditSeries),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(onPressed: _save, child: Text(context.l10n.commonSave)),
        ],
      ),
      body: FutureBuilder<(List<QualityProfile>, List<RootFolder>)>(
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

          final profiles = snapshot.data!.$1;
          final rootFolders = snapshot.data!.$2;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: Text(context.l10n.commonMonitored),
                subtitle: Text(context.l10n.seriesMonitoredSubtitle),
                value: _monitored,
                onChanged: (value) => setState(() => _monitored = value),
              ),
              const Divider(),

              SwitchListTile(
                title: Text(context.l10n.seriesMonitorNewSeasons),
                subtitle: Text(context.l10n.seriesMonitorNewSeasonsSubtitle),
                value: _monitorNewItems == SeriesMonitorNewItems.all,
                onChanged: (value) {
                  setState(
                    () => _monitorNewItems = value
                        ? SeriesMonitorNewItems.all
                        : SeriesMonitorNewItems.none,
                  );
                },
              ),
              const Divider(),

              SwitchListTile(
                title: Text(context.l10n.seriesSeasonFolders),
                subtitle: Text(context.l10n.seriesSeasonFoldersSubtitle),
                value: _seasonFolder,
                onChanged: (value) => setState(() => _seasonFolder = value),
              ),
              const Divider(),

              ListTile(
                title: Text(context.l10n.seriesSeriesType),
                subtitle: Text(_seriesType.localizedLabel(context.l10n)),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<SeriesType>(
                    value: _seriesType,
                    onChanged: (SeriesType? newValue) {
                      if (newValue != null) {
                        setState(() => _seriesType = newValue);
                      }
                    },
                    items: SeriesType.values.map((SeriesType type) {
                      return DropdownMenuItem<SeriesType>(
                        value: type,
                        child: Text(type.localizedLabel(context.l10n)),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const Divider(),

              ListTile(
                title: Text(context.l10n.commonQualityProfile),
                subtitle: Text(
                  profiles
                      .firstWhere(
                        (p) => p.id == _qualityProfileId,
                        orElse: () => profiles.first,
                      )
                      .name,
                ),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _qualityProfileId,
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        setState(() => _qualityProfileId = newValue);
                      }
                    },
                    items: profiles.map((QualityProfile profile) {
                      return DropdownMenuItem<int>(
                        value: profile.id,
                        child: Text(profile.name),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const Divider(),

              ListTile(
                title: Text(context.l10n.commonRootFolder),
                subtitle: Text(
                  _rootFolderPath ?? context.l10n.seriesSelectPath,
                ),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: rootFolders.any((f) => f.path == _rootFolderPath)
                        ? _rootFolderPath
                        : null, // Handle case where current path isn't in available root folders
                    hint: Text(context.l10n.seriesSelect),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => _rootFolderPath = newValue);
                      }
                    },
                    items: rootFolders.map((RootFolder folder) {
                      return DropdownMenuItem<String>(
                        value: folder.path,
                        child: Text(folder.path),
                      );
                    }).toList(),
                  ),
                ),
              ),
              if (tags.isNotEmpty) ...[
                const Divider(),
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
          );
        },
      ),
    );
  }
}
