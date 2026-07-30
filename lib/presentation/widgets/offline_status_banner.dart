import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/extensions/date_extensions.dart';
import '../../core/network/custom_cache_manager.dart';
import '../providers/network_status_provider.dart';

/// Displays an explicit offline state above the current application screen.
class OfflineStatusBanner extends ConsumerWidget {
  const OfflineStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availability = ref.watch(networkAvailabilityProvider);
    return availability.maybeWhen(
      data: (status) {
        if (!status.isOffline) {
          return const SizedBox.shrink();
        }
        final lastOnline = status.lastOnlineAt;
        final lastOnlineText = lastOnline == null
            ? 'No previous online connection recorded'
            : 'Last online ${lastOnline.relativeDate}';
        return Material(
          color: Theme.of(context).colorScheme.errorContainer,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Offline',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '$lastOnlineText · Cached images may be up to '
                          '${CustomCacheManager.stalePeriod.inDays} days old',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
