import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/queue_lookup_provider.dart';

/// A compact badge shown on media cards when the item is currently queued.
class QueueStatusIndicator extends ConsumerWidget {
  final int? movieId;
  final int? seriesId;

  const QueueStatusIndicator({super.key, this.movieId, this.seriesId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lookupAsync = ref.watch(queueMediaLookupProvider);
    final lookup = lookupAsync.valueOrNull;
    if (lookup == null) return const SizedBox.shrink();

    final isQueued = lookup.hasMovie(movieId) || lookup.hasSeries(seriesId);
    if (!isQueued) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(Icons.downloading, size: 12, color: Colors.white)],
      ),
    );
  }
}
