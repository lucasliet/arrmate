import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../domain/models/models.dart';

/// Describes a request failure for one configured instance, surfaced alongside
/// successful data from other origins so partial failures are never mistaken
/// for an empty result.
class InstanceLoadFailure extends Equatable {
  /// Identifier of the failed instance.
  final String instanceId;

  /// Type of the failed instance.
  final InstanceType instanceType;

  /// User-facing instance label.
  final String instanceLabel;

  /// Safe user-facing failure description.
  final String message;

  const InstanceLoadFailure({
    required this.instanceId,
    required this.instanceType,
    required this.instanceLabel,
    required this.message,
  });

  @override
  List<Object?> get props => [instanceId, instanceType, instanceLabel, message];
}

/// A banner shown when some instances fail to load while others succeed,
/// listing the failed origins and offering a retry action.
class InstanceLoadFailureBanner extends StatelessWidget {
  final List<InstanceLoadFailure> failures;
  final VoidCallback onRetry;

  const InstanceLoadFailureBanner({
    super.key,
    required this.failures,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('instance-partial-failure'),
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: colorScheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Some instances could not be loaded',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
          ...failures.map(
            (failure) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${failure.instanceLabel} (${failure.instanceType.label}): ${failure.message}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onErrorContainer,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
