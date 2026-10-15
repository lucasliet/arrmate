import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/network/api_error.dart';
import '../../../core/services/jellyfin_connect_setup_service.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/services/remote_notification_setup_service.dart';
import '../../../data/api/api.dart';
import '../../../domain/models/models.dart';
import '../../l10n/labels.dart';
import '../../providers/instances_provider.dart';
import '../../providers/jellyfin_session_state_provider.dart';
import '../../tour/app_tour_keys.dart';

/// Screen for creating, editing, and deleting Radarr/Sonarr/qBittorrent/
/// Jellyfin instances.
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
  bool _isConfiguringConnect = false;
  bool _obscureApiKey = true;
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

  /// Stored Jellyfin session of the instance being edited, kept so saving
  /// without new credentials preserves the sign-in.
  InstanceUserSession? _existingSession;

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
    _existingSession = existing.userSession;
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
    _isConfiguringConnect = false;
    _testSuccess = false;
    _testMessage = null;
    _headers = [];
    _existingSession = null;
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

    final tempInstance = _formInstance;

    try {
      if (_type == InstanceType.qbittorrent) {
        final testService = QBittorrentService(tempInstance);
        await testService.authenticate();
        final torrents = await testService.getTorrents();

        final authLabel = _authModeLabel(tempInstance);
        if (!mounted || operationGeneration != _operationGeneration) return;

        setState(() {
          _testSuccess = true;
          _testMessage = context.l10n.instanceTestSuccessQbittorrent(
            authLabel,
            torrents.length,
          );
        });
      } else {
        final validatedInstance = await ref
            .read(instancesProvider.notifier)
            .validateInstance(tempInstance);
        if (!mounted || operationGeneration != _operationGeneration) return;

        setState(() {
          _testSuccess = true;
          _testMessage = context.l10n.instanceTestSuccessArr(
            '${validatedInstance.version}',
            '${validatedInstance.name}',
            validatedInstance.tags.length,
          );
        });
      }
    } catch (e) {
      _markSessionExpiredIfRejected(e);
      if (!mounted || operationGeneration != _operationGeneration) return;
      setState(() {
        _testSuccess = false;
        _testMessage = context.l10n.commonErrorWithDetails(_describeError(e));
      });
    } finally {
      if (mounted && operationGeneration == _operationGeneration) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  /// Turns a connection failure into a message fit for the screen.
  ///
  /// Typed API errors already carry one (translated by [describeError]); a
  /// raw [DioException] (whose text dumps request internals such as browser
  /// CORS notes) is reduced to what the user can act on.
  String _describeError(Object error) {
    final l10n = context.l10n;
    if (error is ApiError) return describeError(error, l10n);
    if (error is DioException) {
      return switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => l10n.instanceErrorTimeout,
        DioExceptionType.badResponse => l10n.instanceErrorHttpStatus(
          '${error.response?.statusCode}',
        ),
        _ => l10n.instanceErrorUnreachable,
      };
    }
    if (error is StateError) return error.message;
    return error.toString();
  }

  /// Returns a short human-readable label describing the active qBittorrent
  /// auth mode, used in the test-connection feedback message.
  String _authModeLabel(Instance instance) {
    if (instance.apiKey.isEmpty) return context.l10n.instanceAuthCustomHeader;
    if (instance.apiKey.contains(':')) {
      return context.l10n.instanceAuthUsernamePassword;
    }
    return 'API Key';
  }

  /// Flags the edited Jellyfin instance when [error] reports that its stored
  /// session was rejected, so the settings list asks for a new sign-in.
  void _markSessionExpiredIfRejected(Object error) {
    final instanceId = widget.instanceId;
    if (instanceId == null ||
        error is! UnauthorizedError ||
        !error.message.contains('session has expired')) {
      return;
    }
    ref.read(jellyfinSessionExpiredProvider.notifier).markExpired(instanceId);
  }

  /// Whether the edited Jellyfin instance was flagged as having an expired
  /// session.
  bool get _sessionExpired {
    final instanceId = widget.instanceId;
    return instanceId != null &&
        ref.read(jellyfinSessionExpiredProvider).contains(instanceId);
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

    final instance = _formInstance.copyWith(id: widget.instanceId);

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
      _markSessionExpiredIfRejected(e);
      if (mounted && operationGeneration == _operationGeneration) {
        setState(() {
          _testMessage = context.l10n.instanceValidationFailed(
            _describeError(e),
          );
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
    if (value.isEmpty) {
      return null;
    }
    return value;
  }

  /// Builds an [Instance] from the current form values, without an id.
  Instance get _formInstance => Instance(
    label: _nameController.text.trim(),
    url: _urlController.text.trim(),
    alternativeUrl: _alternativeUrl,
    apiKey: _apiKeyController.text.trim(),
    type: _type,
    mode: _slowMode ? InstanceMode.slow : InstanceMode.normal,
    headers: _headers,
    userSession: _existingSession,
  );

  Future<void> _delete() async {
    final instanceId = widget.instanceId;
    if (instanceId == null || _isBusy) return;
    final operationGeneration = ++_operationGeneration;
    setState(() => _isDeleting = true);

    final l10n = context.l10n;
    try {
      final notifier = ref.read(instancesProvider.notifier);
      final existing = notifier.getInstanceById(instanceId);
      // Undo the remote setup first: it needs the stored session, which the
      // local removal discards. Failures are reported, never blocking.
      final cleanupFailures = existing?.type == InstanceType.jellyfin
          ? await ref
                .read(jellyfinConnectSetupServiceProvider)
                .disconnect(existing!)
          : const <String>[];
      await notifier.removeInstance(instanceId);
      if (!mounted || operationGeneration != _operationGeneration) return;
      final messenger = ScaffoldMessenger.of(context);
      context.pop();
      if (cleanupFailures.isNotEmpty) {
        messenger.showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 8),
            content: Text(
              l10n.instanceRemovedCleanupFailed(cleanupFailures.join('\n')),
            ),
          ),
        );
      }
    } catch (error, stackTrace) {
      logger.error(
        '[InstanceEditScreen] Failed to delete instance',
        error,
        stackTrace,
      );
      if (mounted && operationGeneration == _operationGeneration) {
        setState(() {
          _testSuccess = false;
          _testMessage = l10n.instanceDeleteFailed(_describeError(error));
        });
      }
    } finally {
      if (mounted && operationGeneration == _operationGeneration) {
        setState(() => _isDeleting = false);
      }
    }
  }

  /// Helper text of the API Key field for Jellyfin, naming the signed-in
  /// user when a session is stored.
  String get _jellyfinApiKeyHelperText {
    final l10n = context.l10n;
    if (_sessionExpired) {
      return l10n.instanceJellyfinHelperSessionExpired;
    }
    final session = _existingSession;
    if (session != null) {
      final user = session.userName ?? l10n.instanceJellyfinFallbackUser;
      return l10n.instanceJellyfinHelperSignedIn(user);
    }
    return l10n.instanceJellyfinHelperDefault;
  }

  bool get _isBusy =>
      _isTesting || _isSaving || _isDeleting || _isConfiguringConnect;

  /// Runs the Radarr/Sonarr → Jellyfin connector setup for the saved
  /// Jellyfin instance, then shows one result line per *arr instance.
  ///
  /// Pairing only ever runs from this explicit action, never on save, and
  /// uses the saved instance so it signs in with the stored session rather
  /// than unsaved form values.
  Future<void> _configureJellyfinConnect() async {
    final instanceId = widget.instanceId;
    if (instanceId == null || _isBusy) return;
    final saved = ref
        .read(instancesProvider.notifier)
        .getInstanceById(instanceId);
    if (saved == null) return;
    final operationGeneration = ++_operationGeneration;

    setState(() => _isConfiguringConnect = true);

    try {
      final results = await ref
          .read(jellyfinConnectSetupServiceProvider)
          .configureForAllArrInstances(jellyfinInstance: saved);
      if (!mounted || operationGeneration != _operationGeneration) return;
      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.settingsNoRadarrSonarrInstances)),
        );
        return;
      }
      _showJellyfinConnectResults(results);
    } catch (e, stackTrace) {
      logger.error(
        '[InstanceEditScreen] Jellyfin connector setup failed',
        e,
        stackTrace,
      );
      if (!mounted || operationGeneration != _operationGeneration) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.instanceSetupFailed(_describeError(e))),
        ),
      );
    } finally {
      if (mounted && operationGeneration == _operationGeneration) {
        setState(() => _isConfiguringConnect = false);
      }
    }
  }

  /// Shows one dialog line per Radarr/Sonarr instance result, mirroring the
  /// report dialog of the notification auto-config screen.
  void _showJellyfinConnectResults(List<NotificationSetupResult> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.instanceLibraryAutoUpdateSetupTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: results
              .map(
                (result) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    result.isSuccess ? Icons.check_circle : Icons.error,
                    color: result.isSuccess ? Colors.green : Colors.red,
                  ),
                  title: Text(
                    result.message,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(context.l10n.commonOk),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.instanceId != null;
    final tourKeys = ref.watch(appTourKeysProvider);

    final instancesState = ref.watch(instancesProvider);
    ref.watch(jellyfinSessionExpiredProvider);
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
        title: Text(
          isEditing
              ? context.l10n.instanceEditTitle
              : context.l10n.settingsAddInstance,
        ),
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
                  context.l10n.instanceNotFoundTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.instanceNotFoundMessage,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.canPop() ? context.pop() : null,
                  child: Text(context.l10n.instanceGoBack),
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
                ButtonSegment(
                  value: InstanceType.jellyfin,
                  label: Text('Jellyfin'),
                  icon: Icon(Icons.dns),
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
              decoration: InputDecoration(
                labelText: context.l10n.instanceNameLabel,
                hintText: context.l10n.instanceNameHint,
                border: const OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? context.l10n.instanceRequired
                  : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              key: tourKeys.instanceUrlFieldKey,
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'URL',
                hintText: 'http://192.168.1.10:7878',
                border: const OutlineInputBorder(),
                helperText: context.l10n.instanceUrlHelper,
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                final url = value?.trim() ?? '';
                if (url.isEmpty) {
                  return context.l10n.instanceRequired;
                }
                final uri = Uri.tryParse(url);
                if (uri == null ||
                    uri.host.isEmpty ||
                    (!uri.isScheme('http') && !uri.isScheme('https'))) {
                  return context.l10n.instanceUrlInvalid;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _alternativeUrlController,
              decoration: InputDecoration(
                labelText: context.l10n.instanceAlternativeUrl,
                hintText: 'https://media.example.com',
                border: const OutlineInputBorder(),
                helperText: context.l10n.instanceAlternativeUrlHelper,
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
                  return context.l10n.instanceUrlInvalid;
                }
                if (alternativeUrl == _urlController.text.trim()) {
                  return context.l10n.instanceAlternativeUrlSameAsPrimary;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            if (_type == InstanceType.jellyfin && _sessionExpired) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.l10n.instanceJellyfinSessionExpiredBanner,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            TextFormField(
              key: tourKeys.instanceApiKeyFieldKey,
              controller: _apiKeyController,
              obscureText: _obscureApiKey,
              decoration: InputDecoration(
                labelText: 'API Key',
                border: const OutlineInputBorder(),
                helperText: _type == InstanceType.qbittorrent
                    ? context.l10n.instanceQbittorrentApiKeyHelper
                    : _type == InstanceType.jellyfin
                    ? _jellyfinApiKeyHelperText
                    : null,
                helperMaxLines: 4,
                suffixIcon: IconButton(
                  tooltip: _obscureApiKey
                      ? context.l10n.instanceShowApiKey
                      : context.l10n.instanceHideApiKey,
                  icon: Icon(
                    _obscureApiKey
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscureApiKey = !_obscureApiKey),
                ),
              ),
              validator: (value) {
                final isEmpty = value == null || value.isEmpty;
                if (_type == InstanceType.qbittorrent ||
                    _type == InstanceType.jellyfin) {
                  final hasSession =
                      _type == InstanceType.jellyfin &&
                      _existingSession != null &&
                      !_sessionExpired;
                  if (isEmpty && !_hasAuthorizationHeader && !hasSession) {
                    return _sessionExpired
                        ? context.l10n.instanceApiKeySessionExpiredValidation
                        : context.l10n.instanceApiKeyOrBasicAuthRequired;
                  }
                  return null;
                }
                return isEmpty ? context.l10n.instanceRequired : null;
              },
            ),
            const SizedBox(height: 16),

            ExpansionTile(
              title: Text(context.l10n.instanceAdvancedSettings),
              subtitle: Text(context.l10n.instanceAdvancedSettingsSubtitle),
              children: [
                SwitchListTile(
                  title: Text(context.l10n.instanceSlowMode),
                  subtitle: Text(context.l10n.instanceSlowModeSubtitle),
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
                        label: Text(context.l10n.instanceAddHeader),
                      ),
                      TextButton.icon(
                        onPressed: _addBasicAuthDialog,
                        icon: const Icon(Icons.lock),
                        label: Text(context.l10n.instanceAddBasicAuth),
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
              label: Text(context.l10n.instanceTestConnection),
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

            if (_type == InstanceType.jellyfin && isEditing) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _isBusy ? null : _configureJellyfinConnect,
                icon: _isConfiguringConnect
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: Text(context.l10n.instanceSetUpLibraryAutoUpdate),
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
                  : Text(context.l10n.instanceSave),
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
        title: Text(context.l10n.instanceAddHeader),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: context.l10n.instanceHeaderName,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: valueCtrl,
              decoration: InputDecoration(
                labelText: context.l10n.instanceHeaderValue,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonCancel),
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
            child: Text(context.l10n.commonAdd),
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
        title: Text(context.l10n.instanceBasicAuthTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.instanceBasicAuthBase64Note),
            const SizedBox(height: 8),
            TextField(
              controller: userCtrl,
              decoration: InputDecoration(
                labelText: context.l10n.instanceUsername,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passCtrl,
              decoration: InputDecoration(
                labelText: context.l10n.instancePassword,
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonCancel),
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
            child: Text(context.l10n.commonAdd),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.instanceDeleteTitle),
        content: Text(
          _type == InstanceType.jellyfin
              ? context.l10n.instanceDeleteJellyfinWarning
              : context.l10n.instanceDeleteWarning,
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () async {
              context.pop();
              await _delete();
            },
            child: Text(
              context.l10n.commonDelete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
