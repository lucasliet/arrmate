import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import '../../../core/services/logger_service.dart';
import '../../../data/api/api.dart'; // Add this import
import '../../../domain/models/models.dart';
import '../../providers/instances_provider.dart';
import '../../providers/data_providers.dart';

/// Screen for creating, editing, and deleting Radarr/Sonarr instances.
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
  bool _slowMode = false;
  bool _isTesting = false;
  bool _testSuccess = false;
  String? _testMessage;
  List<InstanceHeader> _headers = [];

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
            _slowMode = existing.mode == InstanceMode.slow;
            _headers = List.from(existing.headers);
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

    final tempInstance = Instance(
      label: _nameController.text.trim(),
      url: _urlController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      type: _type,
      mode: _slowMode ? InstanceMode.slow : InstanceMode.normal,
      headers: _headers,
    );

    try {
      if (_type == InstanceType.qbittorrent) {
        // We need to create a temporary service/instance for testing
        // But for now, let's just use the repo if possible (but repo throws Unimplemented)
        // OR we can't easily test without a dedicated service instance.
        // Actually, the qbittorrentServiceProvider depends on currentQBittorrentInstanceProvider.
        // We might need to manually create the service here or update repo to handle test.

        // Let's use the QBittorrentService directly with the temp instance
        final testService = QBittorrentService(tempInstance);
        await testService.authenticate();
        // If auth works, we are good? Or fetch torrents as test?
        // Let's try to get torrents (empty list is fine) just to verify auth working
        final torrents = await testService.getTorrents();

        final separatorIndex = tempInstance.apiKey.indexOf(':');
        final username = separatorIndex != -1
            ? tempInstance.apiKey.substring(0, separatorIndex)
            : 'User';

        setState(() {
          _testSuccess = true;
          _testMessage =
              'Connection successful!\nAuthenticated as $username\nTorrents: ${torrents.length}';
        });
      } else {
        final instanceRepo = ref.read(instanceRepositoryProvider);

        final results = await Future.wait([
          instanceRepo.getSystemStatus(tempInstance),
          instanceRepo.getTags(tempInstance),
        ]);

        final status = results[0] as InstanceStatus;
        final tags = results[1] as List<Tag>;

        setState(() {
          _testSuccess = true;
          _testMessage =
              'Connection successful!\nVersion: ${status.version}\nInstance: ${status.instanceName}\nTags: ${tags.length} available';
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final instance = Instance(
      id: widget.instanceId,
      label: _nameController.text.trim(),
      url: _urlController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      type: _type,
      mode: _slowMode ? InstanceMode.slow : InstanceMode.normal,
      headers: _headers,
    );

    if (widget.instanceId != null) {
      await ref.read(instancesProvider.notifier).updateInstance(instance);
    } else {
      await ref.read(instancesProvider.notifier).addInstance(instance);
    }

    try {
      await ref
          .read(instancesProvider.notifier)
          .validateAndCacheInstanceData(instance, ref);
    } catch (e) {
      logger.warning(
        '[InstanceEditScreen] Failed to validate and cache instance data',
        e,
      );
    }

    if (mounted) {
      context.pop();
    }
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
                  ButtonSegment(
                    value: InstanceType.qbittorrent,
                    label: Text('qBittorrent'),
                    icon: Icon(Icons.download),
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
                  if (!value.startsWith('http')) {
                    return 'Must start with http:// or https://';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  labelText: _type == InstanceType.qbittorrent
                      ? 'Username:Password'
                      : 'API Key',
                  hintText: _type == InstanceType.qbittorrent
                      ? 'admin:adminadmin'
                      : null,
                  border: const OutlineInputBorder(),
                  helperText: _type == InstanceType.qbittorrent
                      ? 'Format: username:password'
                      : null,
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              ExpansionTile(
                title: const Text('Advanced Settings'),
                subtitle: const Text('Custom Headers & Authentication'),
                children: [
                  SwitchListTile(
                    title: const Text('Slow Instance Mode'),
                    subtitle: const Text(
                      'Increase timeouts for slower connections',
                    ),
                    value: _slowMode,
                    onChanged: (value) => setState(() => _slowMode = value),
                  ),
                  const Divider(),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _headers.length,
                    itemBuilder: (context, index) {
                      final header = _headers[index];
                      return ListTile(
                        title: Text(header.name),
                        subtitle: Text(header.value),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              _headers.removeAt(index);
                            });
                          },
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton.icon(
                          onPressed: _addHeaderDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Header'),
                        ),
                        TextButton.icon(
                          onPressed: _addBasicAuthDialog,
                          icon: const Icon(Icons.lock),
                          label: const Text('Add Basic Auth'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

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

  Future<void> _addHeaderDialog() async {
    final nameCtrl = TextEditingController();
    final valueCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Header'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Header Name'),
            ),
            TextField(
              controller: valueCtrl,
              decoration: const InputDecoration(labelText: 'Header Value'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && valueCtrl.text.isNotEmpty) {
                setState(() {
                  _headers.add(
                    InstanceHeader(name: nameCtrl.text, value: valueCtrl.text),
                  );
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addBasicAuthDialog() async {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Basic Authentication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Credentials will be encoded to Base64.'),
            const SizedBox(height: 8),
            TextField(
              controller: userCtrl,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (userCtrl.text.isNotEmpty && passCtrl.text.isNotEmpty) {
                final raw = '${userCtrl.text}:${passCtrl.text}';
                final encoded = base64Encode(utf8.encode(raw));
                setState(() {
                  _headers.add(
                    InstanceHeader(
                      name: 'Authorization',
                      value: 'Basic $encoded',
                    ),
                  );
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
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
