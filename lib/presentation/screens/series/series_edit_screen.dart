import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/models.dart';
import '../../providers/data_providers.dart';
import 'providers/series_provider.dart';

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
  late int? _qualityProfileId;
  late String? _rootFolderPath;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _monitored = widget.series.monitored;
    _seasonFolder = widget.series.seasonFolder;
    _seriesType = widget.series.seriesType;
    _qualityProfileId = widget.series.qualityProfileId;
    _rootFolderPath = widget.series.rootFolderPath ?? widget.series.path;
    // Map tags if available in future
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
            title: const Text('Move Files?'),
            content: const Text(
              'You verifyed the root folder. Do you want to move existing files to the new location?',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, false), // No, just update DB
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, true), // Yes, move files
                child: const Text('Yes, Move Files'),
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
            content: Text('Error updating series: $e'),
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
      seasonFolder: _seasonFolder,
      seriesType: _seriesType,
      qualityProfileId: _qualityProfileId,
      rootFolderPath: _rootFolderPath,
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

    if (repository == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Series'),
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
            TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: FutureBuilder<(List<QualityProfile>, List<RootFolder>)>(
        future:
            Future.wait([
              repository.getQualityProfiles(),
              repository.getRootFolders(),
            ]).then(
              (value) => (
                value[0] as List<QualityProfile>,
                value[1] as List<RootFolder>,
              ),
            ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final profiles = snapshot.data!.$1;
          final rootFolders = snapshot.data!.$2;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Monitored
              SwitchListTile(
                title: const Text('Monitored'),
                subtitle: const Text('Monitor episodes for this series'),
                value: _monitored,
                onChanged: (value) => setState(() => _monitored = value),
              ),
              const Divider(),

              // Season Folder
              SwitchListTile(
                title: const Text('Season Folders'),
                subtitle: const Text('Use Season folders (e.g. Season 01/...)'),
                value: _seasonFolder,
                onChanged: (value) => setState(() => _seasonFolder = value),
              ),
              const Divider(),

              // Series Type
              ListTile(
                title: const Text('Series Type'),
                subtitle: Text(_seriesType.label),
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
                        child: Text(type.label),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const Divider(),

              // Quality Profile
              ListTile(
                title: const Text('Quality Profile'),
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

              // Root Folder
              ListTile(
                title: const Text('Root Folder'),
                subtitle: Text(_rootFolderPath ?? 'Select Path'),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: rootFolders.any((f) => f.path == _rootFolderPath)
                        ? _rootFolderPath
                        : null, // Handle case where current path isn't in available root folders
                    hint: const Text('Select'),
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
            ],
          );
        },
      ),
    );
  }
}
