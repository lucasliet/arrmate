import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/models.dart';
import '../providers/instances_provider.dart';

/// Displays the service and configured instance that owns a remote record.
class InstanceOriginBadge extends ConsumerWidget {
  /// Identifier of the configured instance.
  final String? instanceId;

  /// Service type of the configured instance.
  final InstanceType? instanceType;

  /// Creates a badge describing a remote record origin.
  const InstanceOriginBadge({
    super.key,
    required this.instanceId,
    this.instanceType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = instanceId;
    if (id == null) {
      return const SizedBox.shrink();
    }

    final instance = ref.watch(
      instancesProvider.select(
        (state) => state.instances
            .where((candidate) => candidate.id == id)
            .firstOrNull,
      ),
    );
    final type = instanceType ?? instance?.type;
    final label = instance?.label ?? id;
    final text = type == null ? label : '${type.label} · $label';
    final color = Theme.of(context).colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
