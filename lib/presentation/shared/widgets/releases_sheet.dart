import 'dart:async';

import 'package:arrmate/core/extensions/context_extensions.dart';
import 'package:arrmate/core/l10n/app_locale.dart';
import 'package:arrmate/core/services/release_query_store.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/l10n/error_messages.dart';
import 'package:arrmate/presentation/shared/providers/releases_provider.dart';
import 'package:arrmate/presentation/shared/widgets/filter_sections.dart';
import 'package:arrmate/presentation/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A modal sheet that searches for and displays available releases.
class ReleasesSheet extends ConsumerStatefulWidget {
  final int id;
  final bool isMovie;
  final String title;
  final String? episodeCode;
  final int? seriesId;
  final int? seasonNumber;
  final String? originalLanguage;

  /// Optional persistence store used to load and save release filters.
  final ReleaseQueryStore? queryStore;

  const ReleasesSheet({
    super.key,
    required this.id,
    required this.isMovie,
    required this.title,
    this.episodeCode,
    this.seriesId,
    this.seasonNumber,
    this.originalLanguage,
    this.queryStore,
  });

  bool get _isSeason => !isMovie && seriesId != null && seasonNumber != null;

  @override
  ConsumerState<ReleasesSheet> createState() => _ReleasesSheetState();
}

class _ReleasesSheetState extends ConsumerState<ReleasesSheet> {
  final _searchController = TextEditingController();
  late final ReleaseQueryStore _queryStore;
  ReleaseQuery _query = const ReleaseQuery();
  bool _rememberFilters = false;
  bool _queryModified = false;

  /// GUID of the release currently being sent to the download client, or null
  /// when no grab is in flight. A listenable so the details sheet, which lives
  /// in the navigator overlay and is not rebuilt by [setState], follows it.
  final ValueNotifier<String?> _grabbingGuid = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _queryStore = widget.queryStore ?? ReleaseQueryStore();
    unawaited(_loadQuery());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _grabbingGuid.dispose();
    super.dispose();
  }

  Future<void> _loadQuery() async {
    final savedQuery = await _queryStore.load(isMovie: widget.isMovie);
    if (!mounted) return;
    if (_queryModified) {
      setState(() => _rememberFilters = savedQuery.remember);
      if (savedQuery.remember) {
        await _queryStore.save(
          isMovie: widget.isMovie,
          query: _query,
          remember: true,
        );
      }
      return;
    }
    _searchController.text = savedQuery.query.search;
    setState(() {
      _query = savedQuery.query;
      _rememberFilters = savedQuery.remember;
    });
  }

  void _updateQuery(ReleaseQuery query) {
    _queryModified = true;
    setState(() => _query = query);
    if (_rememberFilters) {
      unawaited(
        _queryStore.save(isMovie: widget.isMovie, query: query, remember: true),
      );
    }
  }

  Future<void> _onDownload(Release release) async {
    if (release.rejected || _grabbingGuid.value != null) return;

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(dialogContext.l10n.releasesDownloadTitle),
          content: Text(dialogContext.l10n.releasesGrabConfirm(release.title)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(dialogContext.l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(dialogContext.l10n.releasesDownload),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      _grabbingGuid.value = release.guid;
      await ref
          .read(releaseActionsProvider.notifier)
          .downloadRelease(
            guid: release.guid,
            indexerId: release.indexerId,
            isMovie: widget.isMovie,
          );
      if (!mounted) return;

      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.releasesGrabSuccess)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.releasesGrabError(describeError(error, context.l10n)),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) _grabbingGuid.value = null;
    }
  }

  void _showDetails(Release release) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (detailsContext) => ValueListenableBuilder<String?>(
        valueListenable: _grabbingGuid,
        builder: (context, grabbingGuid, child) => _ReleaseDetailsSheet(
          release: release,
          onDownload: release.rejected || grabbingGuid != null
              ? null
              : () {
                  Navigator.of(detailsContext).pop();
                  unawaited(_onDownload(release));
                },
        ),
      ),
    );
  }

  Future<void> _showFilters(List<Release> releases) async {
    final result = await showModalBottomSheet<_ReleaseFilterResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _ReleaseFiltersSheet(
        query: _query,
        rememberFilters: _rememberFilters,
        releases: releases,
        showReleaseType: !widget.isMovie,
        originalLanguage: widget.originalLanguage,
      ),
    );
    if (result == null || !mounted) return;

    _queryModified = true;
    _searchController.text = result.query.search;
    setState(() {
      _query = result.query;
      _rememberFilters = result.rememberFilters;
    });
    await _queryStore.save(
      isMovie: widget.isMovie,
      query: result.query,
      remember: result.rememberFilters,
    );
  }

  @override
  Widget build(BuildContext context) {
    final releaseListAsync = widget._isSeason
        ? ref.watch(
            seasonReleasesProvider(widget.seriesId!, widget.seasonNumber!),
          )
        : widget.isMovie
        ? ref.watch(movieReleasesProvider(widget.id))
        : ref.watch(episodeReleasesProvider(widget.id));
    final releases = releaseListAsync.valueOrNull ?? const <Release>[];
    final visibleReleases = applyReleaseQuery(
      releases,
      _query,
      originalLanguage: widget.originalLanguage,
    );
    final hiddenCount = releases.length - visibleReleases.length;
    final l10n = context.l10n;
    final hasOriginalLanguage =
        widget.originalLanguage?.trim().isNotEmpty ?? false;
    final hasVisibleActiveFilters = _query
        .copyWith(
          originalLanguageOnly:
              hasOriginalLanguage && _query.originalLanguageOnly,
        )
        .hasActiveFilters;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            AppBar(
              title: Column(
                children: [
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.episodeCode != null)
                    Text(
                      widget.episodeCode!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
              centerTitle: true,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                key: const Key('releaseSearchField'),
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.releasesSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.search.isEmpty
                      ? null
                      : IconButton(
                          tooltip: l10n.releasesClearSearch,
                          onPressed: () {
                            _searchController.clear();
                            _updateQuery(_query.copyWith(search: ''));
                          },
                          icon: const Icon(Icons.clear),
                        ),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) =>
                    _updateQuery(_query.copyWith(search: value)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  PopupMenuButton<ReleaseSortOption>(
                    key: const Key('releaseSortButton'),
                    icon: const Icon(Icons.sort),
                    initialValue: _query.sortOption,
                    tooltip: l10n.commonSortBy,
                    onSelected: (value) =>
                        _updateQuery(_query.copyWith(sortOption: value)),
                    itemBuilder: (context) => ReleaseSortOption.values
                        .map(
                          (option) => PopupMenuItem(
                            value: option,
                            child: Text(_sortLabel(option, l10n)),
                          ),
                        )
                        .toList(),
                  ),
                  IconButton(
                    icon: Icon(
                      _query.sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                    ),
                    tooltip: _query.sortAscending
                        ? l10n.sharedAscending
                        : l10n.sharedDescending,
                    onPressed: () => _updateQuery(
                      _query.copyWith(sortAscending: !_query.sortAscending),
                    ),
                  ),
                  IconButton(
                    key: const Key('releaseFilterButton'),
                    tooltip: l10n.releasesFilterTooltip,
                    onPressed: () => _showFilters(releases),
                    icon: Badge(
                      isLabelVisible: hasVisibleActiveFilters,
                      child: const Icon(Icons.filter_list),
                    ),
                  ),
                  if (hasVisibleActiveFilters)
                    TextButton(
                      key: const Key('clearReleaseFiltersButton'),
                      onPressed: () {
                        _searchController.clear();
                        _updateQuery(_query.clearFilters());
                      },
                      child: Text(l10n.commonClear),
                    ),
                  const Spacer(),
                  Text(
                    hiddenCount == 0
                        ? l10n.releasesResultCount(visibleReleases.length)
                        : l10n.releasesResultCountHidden(
                            visibleReleases.length,
                            hiddenCount,
                          ),
                    key: const Key('releaseResultCount'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ValueListenableBuilder<String?>(
                valueListenable: _grabbingGuid,
                builder: (context, grabbingGuid, child) =>
                    releaseListAsync.when(
                      data: (items) {
                        if (items.isEmpty) {
                          return Center(child: Text(l10n.releasesNoneFound));
                        }
                        if (visibleReleases.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(l10n.releasesNoMatch),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    _updateQuery(_query.clearFilters());
                                  },
                                  child: Text(l10n.commonClearFilters),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: scrollController,
                          itemCount: visibleReleases.length,
                          itemBuilder: (context, index) {
                            final release = visibleReleases[index];
                            return _ReleaseTile(
                              release: release,
                              isGrabbing: grabbingGuid == release.guid,
                              isAnotherGrabRunning:
                                  grabbingGuid != null &&
                                  grabbingGuid != release.guid,
                              onDetails: () => _showDetails(release),
                              onDownload: () => _onDownload(release),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: LoadingIndicator()),
                      error: (error, stackTrace) => Center(
                        child: Text(
                          l10n.commonErrorWithDetails(
                            describeError(error, l10n),
                          ),
                        ),
                      ),
                    ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReleaseFiltersSheet extends StatefulWidget {
  final ReleaseQuery query;
  final bool rememberFilters;
  final List<Release> releases;
  final bool showReleaseType;
  final String? originalLanguage;

  const _ReleaseFiltersSheet({
    required this.query,
    required this.rememberFilters,
    required this.releases,
    required this.showReleaseType,
    required this.originalLanguage,
  });

  @override
  State<_ReleaseFiltersSheet> createState() => _ReleaseFiltersSheetState();
}

class _ReleaseFiltersSheetState extends State<_ReleaseFiltersSheet> {
  late ReleaseQuery _query;
  late bool _rememberFilters;

  @override
  void initState() {
    super.initState();
    _query = widget.query;
    _rememberFilters = widget.rememberFilters;
  }

  @override
  Widget build(BuildContext context) {
    final protocols = _distinct(
      widget.releases.map((release) => release.protocol),
    );
    final indexers = _distinct(
      widget.releases.map((release) => release.indexer),
    );
    final qualities = _distinct(
      widget.releases.map((release) => release.quality.quality.name),
    );
    final languages = _distinct(
      widget.releases.expand(
        (release) => release.languages.map((language) => language.name ?? ''),
      ),
    );
    final customFormats = _distinct(
      widget.releases.expand(
        (release) => release.customFormats.map((format) => format.name),
      ),
    );
    final l10n = context.l10n;

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: Column(
          children: [
            ListTile(
              title: Text(l10n.releasesFiltersTitle),
              subtitle: Text(l10n.releasesFiltersSubtitle),
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
                    ChoiceSection<ReleaseApprovalFilter>(
                      title: l10n.releasesApproval,
                      values: ReleaseApprovalFilter.values,
                      selected: _query.approval,
                      labelBuilder: (value) => _approvalLabel(value, l10n),
                      onSelected: (value) => setState(
                        () => _query = _query.copyWith(approval: value),
                      ),
                    ),
                    ChoiceSection<ReleaseFreeleechFilter>(
                      title: l10n.releasesFreeleech,
                      values: ReleaseFreeleechFilter.values,
                      selected: _query.freeleech,
                      labelBuilder: (value) => _freeleechLabel(value, l10n),
                      onSelected: (value) => setState(
                        () => _query = _query.copyWith(freeleech: value),
                      ),
                    ),
                    if (widget.showReleaseType)
                      ChoiceSection<ReleaseTypeFilter>(
                        title: l10n.releasesReleaseType,
                        values: ReleaseTypeFilter.values,
                        selected: _query.releaseType,
                        labelBuilder: (value) => _releaseTypeLabel(value, l10n),
                        onSelected: (value) => setState(
                          () => _query = _query.copyWith(releaseType: value),
                        ),
                      ),
                    FilterSection(
                      title: l10n.commonProtocol,
                      values: protocols,
                      selected: _query.protocols,
                      onChanged: (selected) => setState(
                        () => _query = _query.copyWith(protocols: selected),
                      ),
                    ),
                    FilterSection(
                      title: l10n.commonIndexer,
                      values: indexers,
                      selected: _query.indexers,
                      onChanged: (selected) => setState(
                        () => _query = _query.copyWith(indexers: selected),
                      ),
                    ),
                    FilterSection(
                      title: l10n.commonQuality,
                      values: qualities,
                      selected: _query.qualities,
                      onChanged: (selected) => setState(
                        () => _query = _query.copyWith(qualities: selected),
                      ),
                    ),
                    FilterSection(
                      title: l10n.commonLanguage,
                      values: languages,
                      selected: _query.languages,
                      onChanged: (selected) => setState(
                        () => _query = _query.copyWith(languages: selected),
                      ),
                    ),
                    FilterSection(
                      title: l10n.releasesCustomFormat,
                      values: customFormats,
                      selected: _query.customFormats,
                      onChanged: (selected) => setState(
                        () => _query = _query.copyWith(customFormats: selected),
                      ),
                    ),
                    if (widget.originalLanguage?.trim().isNotEmpty ?? false)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.releasesOriginalLanguageOnly),
                        subtitle: Text(widget.originalLanguage!),
                        value: _query.originalLanguageOnly,
                        onChanged: (value) => setState(
                          () => _query = _query.copyWith(
                            originalLanguageOnly: value,
                          ),
                        ),
                      ),
                    const Divider(),
                    SwitchListTile(
                      key: const Key('rememberReleaseFiltersSwitch'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.releasesRememberFilters),
                      subtitle: Text(l10n.releasesRememberFiltersSubtitle),
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
                    child: Text(l10n.commonClearFilters),
                  ),
                  const Spacer(),
                  FilledButton(
                    key: const Key('applyReleaseFiltersButton'),
                    onPressed: () => Navigator.of(context).pop(
                      _ReleaseFilterResult(
                        query: _query,
                        rememberFilters: _rememberFilters,
                      ),
                    ),
                    child: Text(l10n.commonApply),
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

class _ReleaseTile extends StatelessWidget {
  final Release release;

  /// Whether this release is the one currently being sent to the download
  /// client.
  final bool isGrabbing;

  /// Whether a different release is being sent to the download client, which
  /// keeps this tile from starting a second grab at the same time.
  final bool isAnotherGrabRunning;

  final VoidCallback onDetails;
  final VoidCallback onDownload;

  const _ReleaseTile({
    required this.release,
    required this.onDetails,
    required this.onDownload,
    this.isGrabbing = false,
    this.isAnotherGrabRunning = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRejected = release.rejected;
    final canDownload = !isRejected && !isGrabbing && !isAnotherGrabRunning;
    final languageLabel = release.languages
        .map((language) => language.name)
        .whereType<String>()
        .join(', ');
    final l10n = context.l10n;

    return Opacity(
      opacity: isRejected ? 0.55 : 1,
      child: ListTile(
        title: Text(
          release.title,
          style: theme.textTheme.bodyMedium?.copyWith(
            decoration: isRejected ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _Badge(
                  label: release.quality.quality.name,
                  color: Colors.blueAccent,
                ),
                _Badge(label: _formatSize(release.size), color: Colors.grey),
                _Badge(
                  label: l10n.releasesAgeShort(release.age),
                  color: Colors.orange,
                ),
                _Badge(
                  label: release.protocol.toUpperCase(),
                  color: Colors.teal,
                ),
                if (release.fullSeason)
                  _Badge(label: l10n.releasesSeasonPack, color: Colors.purple),
                if (release.isFreeleech)
                  _Badge(label: l10n.releasesFreeleech, color: Colors.green),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    release.indexer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_upward, size: 14, color: Colors.green),
                Text('${release.seeders}'),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_downward, size: 14, color: Colors.red),
                Text('${release.leechers}'),
              ],
            ),
            if (languageLabel.isNotEmpty)
              Text(
                languageLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            if (isRejected && release.rejections.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  release.rejections.first,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
        onTap: isRejected ? null : onDetails,
        enabled: !isRejected,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l10n.releasesDetailsTitle,
              onPressed: onDetails,
              icon: const Icon(Icons.info_outline),
            ),
            IconButton(
              key: isGrabbing ? const Key('releaseGrabProgress') : null,
              tooltip: isGrabbing
                  ? l10n.releasesSendingTooltip
                  : isRejected
                  ? l10n.releasesRejectedTooltip
                  : l10n.releasesDownloadRelease,
              onPressed: canDownload ? onDownload : null,
              icon: isGrabbing
                  ? SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : const Icon(Icons.download),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReleaseDetailsSheet extends StatelessWidget {
  final Release release;
  final VoidCallback? onDownload;

  const _ReleaseDetailsSheet({required this.release, this.onDownload});

  @override
  Widget build(BuildContext context) {
    final languages = release.languages
        .map((language) => language.name)
        .whereType<String>()
        .join(', ');
    final customFormats = release.customFormats
        .map((format) => format.name)
        .join(', ');
    final mappedEpisodes = release.mappedEpisodeNumbers.join(', ');
    final l10n = context.l10n;

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: Column(
          children: [
            ListTile(
              title: Text(l10n.releasesDetailsTitle),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SelectableText(
                    release.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    label: l10n.commonStatus,
                    value: release.rejected
                        ? l10n.releasesRejected
                        : l10n.releasesApproved,
                  ),
                  _DetailRow(
                    label: l10n.commonQuality,
                    value: release.quality.name.trim(),
                  ),
                  _DetailRow(
                    label: l10n.commonSize,
                    value: _formatSize(release.size),
                  ),
                  _DetailRow(
                    label: l10n.releasesAge,
                    value: l10n.releasesAgeDays(release.age),
                  ),
                  _DetailRow(label: l10n.commonIndexer, value: release.indexer),
                  _DetailRow(
                    label: l10n.commonProtocol,
                    value: release.protocol,
                  ),
                  _DetailRow(
                    label: l10n.releasesSeedsPeers,
                    value: '${release.seeders} / ${release.leechers}',
                  ),
                  _DetailRow(
                    label: l10n.releasesReleaseWeight,
                    value: '${release.releaseWeight}',
                  ),
                  _DetailRow(
                    label: l10n.releasesQualityWeight,
                    value: '${release.qualityWeight}',
                  ),
                  _DetailRow(
                    label: l10n.releasesCustomFormatScore,
                    value: '${release.customFormatScore}',
                  ),
                  _DetailRow(
                    label: l10n.releasesLanguages,
                    value: languages.isEmpty ? l10n.commonUnknown : languages,
                  ),
                  _DetailRow(
                    label: l10n.releasesCustomFormats,
                    value: customFormats.isEmpty
                        ? l10n.labelNone
                        : customFormats,
                  ),
                  _DetailRow(
                    label: l10n.releasesReleaseType,
                    value: release.fullSeason
                        ? l10n.releasesSeasonPack
                        : release.episodeRequested
                        ? l10n.releasesRequestedEpisode
                        : l10n.releasesEpisodeOrMovie,
                  ),
                  if (mappedEpisodes.isNotEmpty)
                    _DetailRow(
                      label: l10n.releasesMappedEpisodes,
                      value: mappedEpisodes,
                    ),
                  if (release.indexerFlags.isNotEmpty)
                    _DetailRow(
                      label: l10n.releasesIndexerFlags,
                      value: release.indexerFlags.join(', '),
                    ),
                  if (release.rejections.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      l10n.releasesRejectionReasons,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    ...release.rejections.map(
                      (reason) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: Icon(
                          Icons.block,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        title: Text(reason),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('releaseDetailsDownloadButton'),
                  onPressed: onDownload,
                  icon: const Icon(Icons.download),
                  label: Text(
                    release.rejected
                        ? l10n.releasesReleaseRejected
                        : l10n.releasesDownloadRelease,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ReleaseFilterResult {
  final ReleaseQuery query;
  final bool rememberFilters;

  const _ReleaseFilterResult({
    required this.query,
    required this.rememberFilters,
  });
}

String _formatSize(int bytes) {
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

List<String> _distinct(Iterable<String> values) {
  final result = values
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList();
  result.sort(
    (first, second) => first.toLowerCase().compareTo(second.toLowerCase()),
  );
  return result;
}

String _sortLabel(ReleaseSortOption option, AppLocalizations l10n) {
  return switch (option) {
    ReleaseSortOption.releaseWeight => l10n.releasesReleaseWeight,
    ReleaseSortOption.qualityWeight => l10n.releasesQualityWeight,
    ReleaseSortOption.customFormatScore => l10n.releasesCustomFormatScore,
    ReleaseSortOption.seeders => l10n.releasesSeeders,
    ReleaseSortOption.age => l10n.releasesAge,
    ReleaseSortOption.size => l10n.commonSize,
    ReleaseSortOption.indexer => l10n.commonIndexer,
  };
}

String _approvalLabel(ReleaseApprovalFilter filter, AppLocalizations l10n) {
  return switch (filter) {
    ReleaseApprovalFilter.all => l10n.labelAll,
    ReleaseApprovalFilter.approved => l10n.releasesApproved,
    ReleaseApprovalFilter.rejected => l10n.releasesRejected,
  };
}

String _freeleechLabel(ReleaseFreeleechFilter filter, AppLocalizations l10n) {
  return switch (filter) {
    ReleaseFreeleechFilter.all => l10n.labelAll,
    ReleaseFreeleechFilter.only => l10n.releasesFreeleechOnly,
    ReleaseFreeleechFilter.excluded => l10n.releasesExcludeFreeleech,
  };
}

String _releaseTypeLabel(ReleaseTypeFilter filter, AppLocalizations l10n) {
  return switch (filter) {
    ReleaseTypeFilter.all => l10n.labelAll,
    ReleaseTypeFilter.seasonPacks => l10n.releasesSeasonPacks,
    ReleaseTypeFilter.episodes => l10n.releasesEpisodes,
  };
}
