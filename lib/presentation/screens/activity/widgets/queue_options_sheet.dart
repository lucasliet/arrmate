import 'package:flutter/material.dart';

import '../../../../domain/models/models.dart';

const _allQueueValues = '';

/// Displays filtering and sorting controls for the activity queue.
class QueueOptionsSheet extends StatefulWidget {
  /// Queue items used to derive available filter values.
  final List<QueueItem> items;

  /// Configured instances used to label instance filters.
  final List<Instance> instances;

  /// Current queue query.
  final QueueQuery query;

  /// Called when the user applies new queue options.
  final ValueChanged<QueueQuery> onApply;

  /// Creates queue filtering and sorting controls.
  const QueueOptionsSheet({
    super.key,
    required this.items,
    required this.instances,
    required this.query,
    required this.onApply,
  });

  @override
  State<QueueOptionsSheet> createState() => _QueueOptionsSheetState();
}

class _QueueOptionsSheetState extends State<QueueOptionsSheet> {
  String? _instanceId;
  String? _protocol;
  String? _downloadClient;
  late bool _issuesOnly;
  late QueueSortField _sortField;
  late bool _ascending;

  @override
  void initState() {
    super.initState();
    _setQuery(widget.query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Queue options',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  TextButton(onPressed: _reset, child: const Text('Reset')),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _SectionTitle(label: 'Filter'),
                  const SizedBox(height: 8),
                  _buildInstanceField(),
                  const SizedBox(height: 12),
                  _buildTextFilter(
                    label: 'Protocol',
                    value: _protocol,
                    values: _protocols,
                    onChanged: (value) => setState(() => _protocol = value),
                  ),
                  const SizedBox(height: 12),
                  _buildTextFilter(
                    label: 'Client',
                    value: _downloadClient,
                    values: _downloadClients,
                    onChanged: (value) =>
                        setState(() => _downloadClient = value),
                  ),
                  SwitchListTile(
                    title: const Text('Problems only'),
                    subtitle: const Text(
                      'Show tasks that need attention or manual import',
                    ),
                    value: _issuesOnly,
                    onChanged: (value) => setState(() => _issuesOnly = value),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(height: 32),
                  _SectionTitle(label: 'Sort by'),
                  RadioGroup<QueueSortField>(
                    groupValue: _sortField,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _sortField = value);
                      }
                    },
                    child: const Column(
                      children: [
                        RadioListTile<QueueSortField>(
                          title: Text('Title'),
                          value: QueueSortField.title,
                          contentPadding: EdgeInsets.zero,
                        ),
                        RadioListTile<QueueSortField>(
                          title: Text('Added'),
                          value: QueueSortField.added,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 32),
                  _SectionTitle(label: 'Direction'),
                  RadioGroup<bool>(
                    groupValue: _ascending,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _ascending = value);
                      }
                    },
                    child: const Column(
                      children: [
                        RadioListTile<bool>(
                          title: Text('Ascending'),
                          value: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        RadioListTile<bool>(
                          title: Text('Descending'),
                          value: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _apply,
                  child: const Text('Apply'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInstanceField() {
    final availableIds = widget.items
        .map((item) => item.instanceId)
        .whereType<String>()
        .toSet()
        .toList();
    availableIds.sort((left, right) {
      return _instanceLabel(left).compareTo(_instanceLabel(right));
    });
    final selected = availableIds.contains(_instanceId)
        ? _instanceId
        : _allQueueValues;

    return DropdownButtonFormField<String>(
      key: ValueKey('queue-instance-$selected'),
      initialValue: selected,
      decoration: const InputDecoration(
        labelText: 'Instance',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(
          value: _allQueueValues,
          child: Text('Any instance'),
        ),
        ...availableIds.map(
          (id) => DropdownMenuItem(value: id, child: Text(_instanceLabel(id))),
        ),
      ],
      onChanged: (value) => setState(() {
        _instanceId = value == _allQueueValues ? null : value;
      }),
    );
  }

  Widget _buildTextFilter({
    required String label,
    required String? value,
    required List<String> values,
    required ValueChanged<String?> onChanged,
  }) {
    final selected = values.contains(value) ? value : _allQueueValues;

    return DropdownButtonFormField<String>(
      key: ValueKey('queue-$label-$selected'),
      initialValue: selected,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem(
          value: _allQueueValues,
          child: Text('Any ${label.toLowerCase()}'),
        ),
        ...values.map(
          (option) => DropdownMenuItem(value: option, child: Text(option)),
        ),
      ],
      onChanged: (selectedValue) {
        onChanged(selectedValue == _allQueueValues ? null : selectedValue);
      },
    );
  }

  List<String> get _protocols {
    return _uniqueValues(widget.items.map((item) => item.protocol));
  }

  List<String> get _downloadClients {
    return _uniqueValues(
      widget.items.map((item) => item.downloadClient).whereType<String>(),
    );
  }

  String _instanceLabel(String id) {
    final instance = widget.instances
        .where((candidate) => candidate.id == id)
        .firstOrNull;
    if (instance == null) return id;
    final label = instance.label.trim().isEmpty ? id : instance.label;
    return '${instance.type.label} · $label';
  }

  void _setQuery(QueueQuery query) {
    _instanceId = query.instanceId;
    _protocol = query.protocol;
    _downloadClient = query.downloadClient;
    _issuesOnly = query.issuesOnly;
    _sortField = query.sortField;
    _ascending = query.ascending;
  }

  void _reset() {
    setState(() => _setQuery(const QueueQuery()));
  }

  void _apply() {
    final availableInstanceIds = widget.items
        .map((item) => item.instanceId)
        .whereType<String>()
        .toSet();
    final instanceId = availableInstanceIds.contains(_instanceId)
        ? _instanceId
        : null;
    final protocol = _protocols.contains(_protocol) ? _protocol : null;
    final downloadClient = _downloadClients.contains(_downloadClient)
        ? _downloadClient
        : null;

    widget.onApply(
      QueueQuery(
        instanceId: instanceId,
        protocol: protocol,
        downloadClient: downloadClient,
        issuesOnly: _issuesOnly,
        sortField: _sortField,
        ascending: _ascending,
      ),
    );
    Navigator.of(context).pop();
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;

  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

List<String> _uniqueValues(Iterable<String> values) {
  final unique = <String, String>{};
  for (final value in values) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isNotEmpty) {
      unique.putIfAbsent(normalized, () => value.trim());
    }
  }
  final result = unique.values.toList();
  result.sort(
    (left, right) => left.toLowerCase().compareTo(right.toLowerCase()),
  );
  return result;
}
