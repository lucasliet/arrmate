import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arrmate/data/models/models.dart';
import 'package:arrmate/presentation/shared/widgets/common_widgets.dart';
import 'providers/series_lookup_provider.dart';
import 'providers/series_provider.dart';
import '../../../../presentation/shared/providers/formatted_options_provider.dart';
import '../../../../presentation/shared/providers/instances_provider.dart';

class SeriesAddSheet extends ConsumerStatefulWidget {
  const SeriesAddSheet({super.key});

  @override
  ConsumerState<SeriesAddSheet> createState() => _SeriesAddSheetState();
}

class _SeriesAddSheetState extends ConsumerState<SeriesAddSheet> {
  final _searchController = TextEditingController();
  Series? _selectedSeries;
  
  // Form State
  bool _monitored = true;
  String _seriesType = 'standard'; // Default to standard
  int? _qualityProfileId;
  String? _rootFolderPath;
  bool _seasonFolder = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSeriesSelected(Series series) {
    setState(() {
      _selectedSeries = series;
      _monitored = true;
      _seasonFolder = true;
      _seriesType = 'standard'; 
    });
  }

  Future<void> _submit() async {
    if (_selectedSeries == null || _qualityProfileId == null || _rootFolderPath == null) return;

    setState(() => _isSubmitting = true);

    try {
      final api = ref.read(sonarrApiProvider);
      if (api == null) throw Exception('API not available');

      final seriesToAdd = _selectedSeries!.copyWith(
        monitored: _monitored,
        qualityProfileId: _qualityProfileId,
        rootFolderPath: _rootFolderPath,
        seasonFolder: _seasonFolder,
        seriesType: _seriesType, // Add to model if missing, or handle map usage
        added: DateTime.now(),
      );

      await api.addSeries(seriesToAdd);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Series added successfully')),
        );
        ref.refresh(seriesProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding series: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedSeries != null) {
      return _buildConfigForm();
    }
    return _buildSearch();
  }

  Widget _buildSearch() {
    final searchResult = ref.watch(seriesLookupProvider);

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
                        hintText: 'Search for series...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (value) {
                         ref.read(seriesLookupProvider.notifier).search(value);
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
                data: (seriesList) {
                  if (seriesList.isEmpty && _searchController.text.isNotEmpty) {
                    return const Center(child: Text('No results found'));
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: seriesList.length,
                    itemBuilder: (context, index) {
                      final series = seriesList[index];
                      // Use a safe check for 'added' or similar property
                      final isAdded = series.added.year > 2000; 
                      
                      return ListTile(
                        leading: series.remotePoster != null
                            ? Image.network(series.remotePoster!, width: 40, fit: BoxFit.cover)
                            : const Icon(Icons.tv),
                        title: Text(series.title),
                        subtitle: Text('${series.year}'),
                        trailing: isAdded
                            ? const Icon(Icons.check, color: Colors.green)
                            : const Icon(Icons.add),
                        onTap: () {
                             if (!isAdded) {
                                  _onSeriesSelected(series);
                             } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                       const SnackBar(content: Text('Series already in library')),
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
    final qualityProfiles = ref.watch(seriesQualityProfilesProvider);
    final rootFolders = ref.watch(seriesRootFoldersProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            AppBar(
              title: Text(_selectedSeries?.title ?? 'Add Series'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedSeries = null),
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
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Series Type'),
                    value: _seriesType,
                    items: const [
                      DropdownMenuItem(value: 'standard', child: Text('Standard')),
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'anime', child: Text('Anime')),
                    ],
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
                      if (_qualityProfileId == null && profiles.isNotEmpty) {
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
