import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/l10n/app_locale.dart';
import '../../../domain/models/shared/media_credits.dart';
import '../../widgets/poster_network_image.dart';

/// Returns the labelled titles worth showing next to a localized [title].
///
/// The original and the English titles are listed only when they differ from
/// [title], and the English one only when it also differs from the original.
List<String> previewExtraTitles(
  AppLocalizations l10n, {
  required String title,
  String? originalTitle,
  String? englishTitle,
}) {
  String normalize(String value) => value.trim().toLowerCase();
  bool differs(String? candidate, String? other) =>
      candidate != null &&
      candidate.trim().isNotEmpty &&
      (other == null || normalize(candidate) != normalize(other));

  final showOriginal = differs(originalTitle, title);
  final showEnglish =
      differs(englishTitle, title) && differs(englishTitle, originalTitle);
  return [
    if (showOriginal) l10n.discoveryOriginalTitle(originalTitle!.trim()),
    if (showEnglish) l10n.discoveryEnglishTitle(englishTitle!.trim()),
  ];
}

/// Extra titles of a looked-up item, shown under its localized title.
///
/// Renders nothing when there is no title to add.
class MediaPreviewTitles extends StatelessWidget {
  /// Localized title already on screen.
  final String title;

  /// Title in the original language, when known.
  final String? originalTitle;

  /// English title, when known.
  final String? englishTitle;

  /// Creates a [MediaPreviewTitles].
  const MediaPreviewTitles({
    super.key,
    required this.title,
    this.originalTitle,
    this.englishTitle,
  });

  @override
  Widget build(BuildContext context) {
    final lines = previewExtraTitles(
      context.l10n,
      title: title,
      originalTitle: originalTitle,
      englishTitle: englishTitle,
    );
    if (lines.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        children: [
          for (final line in lines)
            Text(
              line,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

/// Cast and crew of a looked-up item, from an async [details] load.
///
/// Shows a slim progress bar while loading and nothing when the load fails
/// or brings no credits: the data only helps identifying the title.
class MediaPreviewCredits extends StatelessWidget {
  /// Load state of the preview details.
  final AsyncValue<MediaPreviewDetails> details;

  /// Creates a [MediaPreviewCredits].
  const MediaPreviewCredits({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return details.when(
      skipLoadingOnReload: true,
      data: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (data.cast.isNotEmpty)
            MediaCreditsSection(
              key: const ValueKey('preview-cast-section'),
              title: context.l10n.discoveryCast,
              credits: data.cast,
            ),
          if (data.crew.isNotEmpty)
            MediaCreditsSection(
              key: const ValueKey('preview-crew-section'),
              title: context.l10n.discoveryCrew,
              credits: data.crew,
            ),
        ],
      ),
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 16),
        child: LinearProgressIndicator(minHeight: 2),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

/// A titled, horizontally scrollable row of credited people.
class MediaCreditsSection extends StatelessWidget {
  static const double _cardWidth = 88;

  /// Section header.
  final String title;

  /// People listed in the row.
  final List<MediaCredit> credits;

  /// Creates a [MediaCreditsSection].
  const MediaCreditsSection({
    super.key,
    required this.title,
    required this.credits,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (index, credit) in credits.indexed)
                Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 0 : 12),
                  child: _CreditCard(credit: credit, width: _cardWidth),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CreditCard extends StatelessWidget {
  final MediaCredit credit;
  final double width;

  const _CreditCard({required this.credit, required this.width});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = credit.imageUrl;
    final role = credit.role;
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: width,
              height: width * 1.5,
              child: imageUrl == null
                  ? _buildFallback(context)
                  : PosterNetworkImage(
                      imageUrl: imageUrl,
                      errorBuilder: _buildFallback,
                      placeholderBuilder: (context) => ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            credit.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium,
          ),
          if (role != null)
            Text(
              role,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(Icons.person_outline, size: 32, color: colorScheme.outline),
    );
  }
}
