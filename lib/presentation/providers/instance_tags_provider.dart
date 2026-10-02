import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/models.dart';
import 'data_providers.dart';

/// Loads the tags currently defined on [instance].
///
/// [Instance.tags] is only the snapshot taken the last time the connection
/// was tested. Tags created on the server after that stay hidden until this
/// provider reads them again.
final instanceTagsProvider = FutureProvider.autoDispose
    .family<List<Tag>, Instance>((ref, instance) {
      return ref.watch(instanceRepositoryProvider).getTags(instance);
    });

/// Tags to offer while editing or adding media on [instance].
///
/// Prefers the live list. Until that read finishes, or if it fails, the last
/// snapshot on [Instance.tags] is used so the form is not empty.
List<Tag> watchInstanceTags(WidgetRef ref, Instance? instance) {
  if (instance == null) return const <Tag>[];
  final live = ref.watch(instanceTagsProvider(instance)).valueOrNull;
  return live ?? instance.tags;
}
