import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/logger_service.dart';
import '../../../data/api/api.dart';
import '../../../domain/models/models.dart';
import '../../providers/instances_provider.dart';
import '../../tour/app_tour_keys.dart';

/// Screen for creating, editing, and deleting Radarr/Sonarr/qBittorrent instances.
class InstanceEditScreen extends ConsumerStatefulWidget {
  final String? instanceId;

  /// Optional type to pre-select when adding a new instance.
  ///
  /// Ignored when [instanceId] is provided (edit mode).
  final InstanceType? initialType;

  const InstanceEditScreen({super.key, this.instanceId, this.initialType});

  @override
  ConsumerState<InstanceEditScreen> createState() => _InstanceEditScreenState();
}

class _InstanceEditScreenState extends ConsumerState<InstanceEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _alternativeUrlController;
  late TextEditingController _apiKeyController;
  InstanceType _type = InstanceType.radarr;
  bool _slowMode = false;
  bool _isTesting = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _testSuccess = false;
  int _operationGeneration = 0;
  String? _testMessage;
  List<InstanceHeader> _headers = [];

  /// Whether the form fields have already been populated from an existing
  /// instance. Guards against overwriting user edits when the provider emits
  /// again after the initial load (e.g. resolved URL refresh).
  bool _initialized = false;

  /// Set when the provider finished loading but the requested [instanceId]
  /// was not present, so the UI can show an explicit error instead of a
  /// silently empty edit form.
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _urlController = TextEditingController();
    _alternativeUrlController = TextEditingController();
    _apiKeyController = TextEditingController();

    if (widget.instanceId == null && widget.initialType != null) {
      _type = widget.initialType!;
    }
  }

  @override
  void didUpdateWidget(covariant InstanceEditScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.instanceId == widget.instanceId &&
        oldWidget.initialType == widget.initialType) {
      return;
    }

    _operationGeneration++;
    _resetForm();
  }

  @override
  void dispose() {
    _operationGeneration++;
    _nameController.dispose();
    _urlController.dispose();
    _alternativeUrlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _populateFromInstance(Instance existing) {
    _nameController.text = existing.label;
    _urlController.text = existing.url;
    _alternativeUrlController.text = existing.alternativeUrl ?? '';
    _apiKeyController.text = existing.apiKey;
    _type = existing.type;
    _slowMode = existing.mode == InstanceMode.slow;
    _headers = List.from(existing.headers);
    _initialized = true;
    _notFound = false;
  }

  void _resetForm() {
    _nameController.clear();
    _urlController.clear();
    _alternativeUrlController.clear();
    _apiKeyController.clear();
    _type = widget.instanceId == null && widget.initialType != null
        ? widget.initialType!
        : InstanceType.radarr;
    _slowMode = false;
    _isTesting = false;
    _isSaving = false;
    _isDeleting = false;
    _testSuccess = false;
    _testMessage = null;
    _headers = [];
    _initialized = false;
    _notFound = false;
  }

  Future<void> _testConnection() async {
    if (_isBusy || !_formKey.currentState!.validate()) return;
    final operationGeneration = ++_operationGeneration;

    setState(() {
      _isTesting = true;
      _testMessage = null;
      _testSuccess = false;
    });

    final tempInstance = Instance(
      label: _nameController.text.trim(),
      url: _urlController.text.trim(),
      alternativeUrl: _alternativeUrl,
      apiKey: _apiKeyController.text.trim(),
      type: _type,
      mode: _slowMode ? InstanceMode.slow : InstanceMode.normal,
      headers: _headers,
    );

    try {
      if (_type == InstanceType.qbittorrent) {
        final testService = QBittorrentService(tempInstance);
        await testService.authenticate();
        final torrents = await testService.getTorrents();

        final authLabel = _authModeLabel(tempInstance);
        if (!mounted || operationGeneration != _operationGeneration) return;

        setState(() {
          _testSuccess = true;
          _testMessage =
              'Connection successful!\nAuth: $authLabel\nTorrents: ${torrents.length}';
        });
      } else {
        final validatedInstance = await ref
            .read(instancesProvider.notifier)
            .validateInstance(tempInstance);
        if (!mounted || operationGeneration != _operationGeneration) return;

        setState(() {
          _testSuccess = true;
          _testMessage =
              'Connection successful!\nVersion: ${validatedInstance.version}\nInstance: ${validatedInstance.name}\nTags: ${validatedInstance.tags.length} available';
        });
      }
    } catch (e) {
      if (!mounted || operationGeneration != _operationGeneration) return;
      setState(() {
        _testSuccess = false;
        _testMessage = 'Error: ${e.toString()}';
      });
    } finally {
      if (mounted && operationGeneration == _operationGeneration) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  /// Returns a short human-readable label describing the active qBittorrent
  /// auth mode, used in the test-connection feedback message.
  String _authModeLabel(Instance instance) {
    if (instance.apiKey.isEmpty) return 'Custom Header';
    if (instance.apiKey.contains(':')) return 'Username & Password';
    return 'API Key';
  }

  /// Checks whether the [InstanceHeader] list already carries an
  /// `Authorization` entry — typically added via "Add Basic Auth" in
  /// Advanced Settings.
  bool get _hasAuthorizationHeader => _headers.any(
    (h) => h.name.toLowerCase() == 'authorization' && h.value.trim().isNotEmpty,
  );

  Future<void> _save() async {
    if (_isBusy || !_formKey.currentState!.validate()) return;
    final operationGeneration = ++_operationGeneration;

    setState(() {
      _isSaving = true;
      _testMessage = null;
      _testSuccess = false;
    });

    final instance = Instance(
      id: widget.instanceId,
      label: _nameController.text.trim(),
      url: _urlController.text.trim(),
      alternativeUrl: _alternativeUrl,
      apiKey: _apiKeyController.text.trim(),
      type: _type,
      mode: _slowMode ? InstanceMode.slow : InstanceMode.normal,
      headers: _headers,
    );

    try {
      await ref
          .read(instancesProvider.notifier)
          .validateAndSaveInstance(instance);
      if (!mounted || operationGeneration != _operationGeneration) return;
      context.pop();
    } catch (e, stackTrace) {
      logger.warning(
        '[InstanceEditScreen] Instance validation failed',
        e,
        stackTrace,
      );
      if (mounted && operationGeneration == _operationGeneration) {
        setState(() {
          _testMessage = 'Validation failed: $e';
          _testSuccess = false;
        });
      }
    } finally {
      if (mounted && operationGeneration == _operationGeneration) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String? get _alternativeUrl {
    final value = _alternativeUrlController.text.trim();
    if (_type == InstanceType.qbittorrent || value.isEmpty) {
      return null;
    }
    return value;
  }

  Future<void> _delete() async {
    final instanceId = widget.instanceId;
    if (instanceId == null || _isBusy) return;
    final operationGeneration = ++_operationGeneration;
    setState(() => _isDeleting = true);

    try {
      await ref.read(instancesProvider.notifier).removeInstance(instanceId);
      if (!mounted || operationGeneration != _operationGeneration) return;
      context.pop();
    } catch (error, stackTrace) {
      logger.error(
        '[InstanceEditScreen] Failed to delete instance',
        error,
        stackTrace,
      );
      if (mounted && operationGeneration == _operationGeneration) {
        setState(() {
          _testSuccess = false;
          _testMessage = 'Delete failed: $error';
        });
      }
    } finally {
      if (mounted && operationGeneration == _operationGeneration) {
        setState(() => _isDeleting = false);
      }
    }
  }

  bool get _isBusy => _isTesting || _isSaving || _isDeleting;

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.instanceId != null;
    final tourKeys = ref.watch(appTourKeysProvider);

    final instancesState = ref.watch(instancesProvider);
    if (isEditing && !_initialized) {
      final existing = widget.instanceId == null
          ? null
          : instancesState.instances
                .where((i) => i.id == widget.instanceId)
                .firstOrNull;
      if (existing != null) {
        _populateFromInstance(existing);
      } else if (!instancesState.isLoading) {
        _notFound = true;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Instance' : 'Add Instance'),
        actions: [
          if (isEditing && _initialized)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isBusy ? null : _confirmDelete,
            ),
        ],
      ),
      body: _buildBody(context, isEditing, tourKeys),
    );
  }

  Widget _buildBody(
    BuildContext context,
    bool isEditing,
    AppTourKeys tourKeys,
  ) {
    if (isEditing && !_initialized) {
      if (_notFound) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Instance not found',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'The requested instance no longer exists or could not be loaded.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.canPop() ? context.pop() : null,
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<InstanceType>(
              key: tourKeys.instanceTypeSelectorKey,
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
              key: tourKeys.instanceNameFieldKey,
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
              key: tourKeys.instanceUrlFieldKey,
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'http://192.168.1.10:7878',
                border: OutlineInputBorder(),
                helperText: 'Include http:// or https:// and port',
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                final url = value?.trim() ?? '';
                if (url.isEmpty) {
                  return 'Required';
                }
                final uri = Uri.tryParse(url);
                if (uri == null ||
                    uri.host.isEmpty ||
                    (!uri.isScheme('http') && !uri.isScheme('https'))) {
                  return 'Must be a valid HTTP or HTTPS URL';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            if (_type != InstanceType.qbittorrent) ...[
              TextFormField(
                controller: _alternativeUrlController,
                decoration: const InputDecoration(
                  labelText: 'Alternative URL',
                  hintText: 'https://media.example.com',
                  border: OutlineInputBorder(),
                  helperText: 'Optional URL used outside your local network',
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  final alternativeUrl = value?.trim() ?? '';
                  if (alternativeUrl.isEmpty) {
                    return null;
                  }
                  final uri = Uri.tryParse(alternativeUrl);
                  if (uri == null ||
                      uri.host.isEmpty ||
                      (!uri.isScheme('http') && !uri.isScheme('https'))) {
                    return 'Must be a valid HTTP or HTTPS URL';
                  }
                  if (alternativeUrl == _urlController.text.trim()) {
                    return 'Must differ from the primary URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            TextFormField(
              key: tourKeys.instanceApiKeyFieldKey,
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: 'API Key',
                border: const OutlineInputBorder(),
                helperText: _type == InstanceType.qbittorrent
                    ? 'Bearer token (qBittorrent ≥ v5.2.0). Leave empty if using '
                          '"Add Basic Auth" below for older versions.'
                    : null,
              ),
              validator: (value) {
                final isEmpty = value == null || value.isEmpty;
                if (_type == InstanceType.qbittorrent) {
                  if (isEmpty && !_hasAuthorizationHeader) {
                    return 'Provide an API key or add Basic Auth below';
                  }
                  return null;
                }
                return isEmpty ? 'Required' : null;
              },
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
              key: tourKeys.instanceTestConnectionKey,
              onPressed: _isBusy ? null : _testConnection,
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
              key: tourKeys.instanceSaveKey,
              onPressed: _isBusy ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Instance'),
            ),
          ],
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
            onPressed: () async {
              context.pop();
              await _delete();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
