import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../domain/models/instance/instance.dart';
import '../../providers/instances_provider.dart';

class InstanceEditScreen extends ConsumerStatefulWidget {
  final String? instanceId;

  const InstanceEditScreen({super.key, this.instanceId});

  @override
  ConsumerState<InstanceEditScreen> createState() => _InstanceEditScreenState();
}

class _InstanceEditScreenState extends ConsumerState<InstanceEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _apiKeyController;
  InstanceType _type = InstanceType.radarr;
  bool _isTesting = false;
  bool _testSuccess = false;
  String? _testMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _urlController = TextEditingController();
    _apiKeyController = TextEditingController();

    // Load existing if editing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.instanceId != null) {
        final existing = ref
            .read(instancesProvider.notifier)
            .getInstanceById(widget.instanceId!);
        if (existing != null) {
          _nameController.text = existing.label;
          _urlController.text = existing.url;
          _apiKeyController.text = existing.apiKey;
          setState(() {
            _type = existing.type;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTesting = true;
      _testMessage = null;
      _testSuccess = false;
    });

    final url = _urlController.text.trim();
    final apiKey = _apiKeyController.text.trim();

    // Simple test: Try to hit system/status
    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: url,
          connectTimeout: const Duration(seconds: 10),
          headers: {'X-Api-Key': apiKey},
        ),
      );

      // Radarr/Sonarr usually have /api/v3/system/status
      final response = await dio.get('/api/v3/system/status');

      if (response.statusCode == 200) {
        setState(() {
          _testSuccess = true;
          _testMessage =
              'Connection successful! Version: ${response.data['version']}';
        });
      } else {
        setState(() {
          _testSuccess = false;
          _testMessage = 'Failed: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _testSuccess = false;
        _testMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final instance = Instance(
      id: widget.instanceId, // Reuse ID if editing, generated if null
      label: _nameController.text.trim(),
      url: _urlController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      type: _type,
    );

    if (widget.instanceId != null) {
      ref.read(instancesProvider.notifier).updateInstance(instance);
    } else {
      ref.read(instancesProvider.notifier).addInstance(instance);
    }

    context.pop();
  }

  void _delete() {
    if (widget.instanceId != null) {
      ref.read(instancesProvider.notifier).removeInstance(widget.instanceId!);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.instanceId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Instance' : 'Add Instance'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type Selection
              SegmentedButton<InstanceType>(
                segments: const [
                  ButtonSegment(
                    value: InstanceType.radarr,
                    label: Text('Radarr'),
                    icon: Icon(Icons.movie),
                  ),
                  ButtonSegment(
                    value: InstanceType.sonarr,
                    label: Text('Sonarr'),
                    icon: Icon(Icons.tv),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (Set<InstanceType> newSelection) {
                  setState(() {
                    _type = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Home Server',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // URL
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'URL',
                  hintText: 'http://192.168.1.10:7878',
                  border: OutlineInputBorder(),
                  helperText: 'Include http:// or https:// and port',
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (!value.startsWith('http'))
                    return 'Must start with http:// or https://';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // API Key
              TextFormField(
                controller: _apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              // Test Connection
              OutlinedButton.icon(
                onPressed: _isTesting ? null : _testConnection,
                icon: _isTesting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi),
                label: const Text('Test Connection'),
              ),
              if (_testMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _testMessage!,
                  style: TextStyle(
                    color: _testSuccess ? Colors.green : Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 32),

              // Save Button
              FilledButton(
                onPressed: _save,
                child: const Text('Save Instance'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Instance?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.pop(); // Close dialog
              _delete();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
