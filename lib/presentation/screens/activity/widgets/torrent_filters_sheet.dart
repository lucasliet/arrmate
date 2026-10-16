import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/shared/widgets/filter_sections.dart';
import 'package:flutter/material.dart';
import 'package:arrmate/core/extensions/context_extensions.dart';
import 'package:arrmate/presentation/l10n/labels.dart';

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
              title: Text(context.l10n.torrentFiltersTitle),
              subtitle: Text(context.l10n.torrentFiltersSubtitle),
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
                      title: context.l10n.commonStatus,
                      values: TorrentStatusFilter.values,
                      selected: _query.status,
                      labelBuilder: (value) =>
                          value.localizedLabel(context.l10n),
                      onSelected: (value) => setState(
                        () => _query = _query.copyWith(status: value),
                      ),
                    ),
                    if (widget.showLinkFilters)
                      ChoiceSection<TorrentLinkFilter>(
                        title: context.l10n.torrentFilterLibraryLink,
                        values: TorrentLinkFilter.values,
                        selected: _query.linkFilter,
                        labelBuilder: (value) =>
                            value.localizedLabel(context.l10n),
                        onSelected: (value) => setState(
                          () => _query = _query.copyWith(linkFilter: value),
                        ),
                      ),
                    FilterSection(
                      title: context.l10n.torrentInfoCategory,
                      values: widget.availableCategories,
                      selected: _query.categories,
                      onChanged: (value) => setState(
                        () => _query = _query.copyWith(categories: value),
                      ),
                    ),
                    FilterSection(
                      title: context.l10n.commonTags,
                      values: widget.availableTags,
                      selected: _query.tags,
                      onChanged: (value) =>
                          setState(() => _query = _query.copyWith(tags: value)),
                    ),
                    const Divider(),
                    SwitchListTile(
                      key: const Key('rememberTorrentFiltersSwitch'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.l10n.torrentRememberFilters),
                      subtitle: Text(
                        context.l10n.torrentRememberFiltersSubtitle,
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
                    child: Text(context.l10n.commonClearFilters),
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
                    child: Text(context.l10n.commonApply),
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
