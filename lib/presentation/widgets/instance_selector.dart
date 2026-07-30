import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/models.dart';
import '../providers/instances_provider.dart';

/// Lets the user choose the active configured instance for a service type.
class InstanceSelector extends ConsumerWidget {
  /// Service type whose active instance will be changed.
  final InstanceType type;

  /// Creates an instance selector for [type].
  const InstanceSelector({super.key, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instances = ref.watch(instancesByTypeProvider(type));
    final selectedInstance = ref.watch(currentInstanceProvider(type));

    if (instances.length <= 1) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      initialValue: selectedInstance?.id,
      tooltip: 'Select ${type.label} instance',
      icon: const Icon(Icons.dns_outlined),
      onSelected: (id) async {
        await ref.read(instancesProvider.notifier).selectInstance(type, id);
      },
      itemBuilder: (context) {
        return instances.map((instance) {
          final isSelected = instance.id == selectedInstance?.id;
          return PopupMenuItem(
            value: instance.id,
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check : Icons.dns_outlined,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(instance.label)),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}
