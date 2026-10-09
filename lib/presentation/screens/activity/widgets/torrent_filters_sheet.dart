import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/shared/widgets/filter_sections.dart';
import 'package:flutter/material.dart';

/// Outcome of the torrent filters sheet: the configured query and whether it
/// should be persisted for future sessions.
class TorrentFilterResult {
  final TorrentQuery query;
  final bool rememberFilters;

  const TorrentFilterResult({
    required this.query,
    required this.rememberFilters,
  });
}

/// A modal sheet exposing the search filters for the Activity torrents tab.
class TorrentFiltersSheet extends StatefulWidget {
  final TorrentQuery query;
  final bool rememberFilters;

  /// Whether the library link section is offered, which requires at least one
  /// Radarr/Sonarr instance to be configured.
  final bool showLinkFilters;

  /// Category names available on the current torrent list, offered as filter
  /// chips.
  final List<String> availableCategories;

  /// Tag names available on the current torrent list, offered as filter chips.
  final List<String> availableTags;

  const TorrentFiltersSheet({
    super.key,
    required this.query,
    required this.rememberFilters,
    required this.showLinkFilters,
    this.availableCategories = const [],
    this.availableTags = const [],
  });

  @override
  State<TorrentFiltersSheet> createState() => _TorrentFiltersSheetState();
}

class _TorrentFiltersSheetState extends State<TorrentFiltersSheet> {
  late TorrentQuery _query;
  late bool _rememberFilters;

  @override
  void initState() {
    super.initState();
    _query = _dropSelectionsWithoutChips(widget.query);
    _rememberFilters = widget.rememberFilters;
  }

  /// Drops persisted category/tag selections that no longer exist on the
  /// current torrent list, so every active selection keeps a visible chip to
  /// untap instead of silently hiding the whole list.
  TorrentQuery _dropSelectionsWithoutChips(TorrentQuery query) {
    return query.copyWith(
      categories: query.categories.intersection(
        widget.availableCategories.toSet(),
      ),
      tags: query.tags.intersection(widget.availableTags.toSet()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: Column(
          children: [
            ListTile(
              title: const Text('Torrent filters'),
              subtitle: const Text('Combine any number of filters'),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ChoiceSection<TorrentStatusFilter>(
                      title: 'Status',
                      values: TorrentStatusFilter.values,
                      selected: _query.status,
                      labelBuilder: (value) => value.label,
                      onSelected: (value) => setState(
                        () => _query = _query.copyWith(status: value),
                      ),
                    ),
                    if (widget.showLinkFilters)
                      ChoiceSection<TorrentLinkFilter>(
                        title: 'Library link',
                        values: TorrentLinkFilter.values,
                        selected: _query.linkFilter,
                        labelBuilder: (value) => value.label,
                        onSelected: (value) => setState(
                          () => _query = _query.copyWith(linkFilter: value),
                        ),
                      ),
                    FilterSection(
                      title: 'Category',
                      values: widget.availableCategories,
                      selected: _query.categories,
                      onChanged: (value) => setState(
                        () => _query = _query.copyWith(categories: value),
                      ),
                    ),
                    FilterSection(
                      title: 'Tags',
                      values: widget.availableTags,
                      selected: _query.tags,
                      onChanged: (value) =>
                          setState(() => _query = _query.copyWith(tags: value)),
                    ),
                    const Divider(),
                    SwitchListTile(
                      key: const Key('rememberTorrentFiltersSwitch'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Remember filters'),
                      subtitle: const Text(
                        'Keep this configuration for future sessions',
                      ),
                      value: _rememberFilters,
                      onChanged: (value) =>
                          setState(() => _rememberFilters = value),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () =>
                        setState(() => _query = _query.clearFilters()),
                    child: const Text('Clear filters'),
                  ),
                  const Spacer(),
                  FilledButton(
                    key: const Key('applyTorrentFiltersButton'),
                    onPressed: () => Navigator.of(context).pop(
                      TorrentFilterResult(
                        query: _query,
                        rememberFilters: _rememberFilters,
                      ),
                    ),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
