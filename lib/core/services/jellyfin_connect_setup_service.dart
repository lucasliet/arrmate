import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/jellyfin_service.dart';
import '../../data/api/radarr_api.dart';
import '../../data/api/sonarr_api.dart';
import '../../domain/models/models.dart';
import '../../presentation/providers/instances_provider.dart';
import 'logger_service.dart';
import 'remote_notification_setup_service.dart' show NotificationSetupResult;

/// Provider for the [JellyfinConnectSetupService].
final jellyfinConnectSetupServiceProvider = Provider(
  (ref) => JellyfinConnectSetupService(ref),
);

/// Service responsible for automatically keeping Jellyfin libraries in sync
/// with *arr activity.
///
/// It uses the MediaBrowser (preferred) or Emby notification implementation
/// shipped with Radarr/Sonarr — both speak the Emby protocol that Jellyfin
/// implements — to create or update an "Update Library" connector named
/// `Arrmate Jellyfin`. The connector makes Jellyfin refresh its library
/// whenever media is imported, upgraded, renamed or deleted.
class JellyfinConnectSetupService {
  static const _logPrefix = 'JellyfinConnectSetupService';

  /// Fixed display name of the connector managed by this service.
  static const _connectorName = 'Arrmate Jellyfin';

  final RadarrApi Function(Instance instance) _radarrApiFactory;
  final SonarrApi Function(Instance instance) _sonarrApiFactory;
  final List<Instance> Function() _instancesSource;
  final JellyfinService Function(Instance instance) _jellyfinServiceFactory;

  /// Creates the service.
  ///
  /// [radarrApiFactory], [sonarrApiFactory], [jellyfinServiceFactory] and
  /// [instancesSource] are injection points for tests; production uses the
  /// real API clients and [instancesProvider].
  JellyfinConnectSetupService(
    Ref ref, {
    RadarrApi Function(Instance instance)? radarrApiFactory,
    SonarrApi Function(Instance instance)? sonarrApiFactory,
    JellyfinService Function(Instance instance)? jellyfinServiceFactory,
    List<Instance> Function()? instancesSource,
  }) : _radarrApiFactory = radarrApiFactory ?? _defaultRadarrApi,
       _sonarrApiFactory = sonarrApiFactory ?? _defaultSonarrApi,
       _jellyfinServiceFactory =
           jellyfinServiceFactory ?? ((instance) => JellyfinService(instance)),
       _instancesSource =
           instancesSource ?? (() => ref.read(instancesProvider).instances);

  static RadarrApi _defaultRadarrApi(Instance instance) => RadarrApi(instance);

  static SonarrApi _defaultSonarrApi(Instance instance) => SonarrApi(instance);

  /// Configures the Jellyfin connector on every configured Radarr and Sonarr
  /// instance.
  ///
  /// [jellyfinInstance] is the Jellyfin server the connectors should notify;
  /// when omitted, the first configured instance of type [InstanceType.jellyfin]
  /// is used. [instances] overrides the configured instance list (used by
  /// tests). One failing *arr instance never aborts the others.
  Future<List<NotificationSetupResult>> configureForAllArrInstances({
    Instance? jellyfinInstance,
    List<Instance>? instances,
  }) async {
    final source = instances ?? _instancesSource();
    jellyfinInstance ??= source
        .where((instance) => instance.type == InstanceType.jellyfin)
        .firstOrNull;
    if (jellyfinInstance == null) {
      logger.warning(
        '[$_logPrefix] No Jellyfin connection configured; skipping connector setup.',
      );
      return [
        NotificationSetupResult.failure(
          'No Jellyfin connection configured in Arrmate.',
        ),
      ];
    }

    final arrInstances = source
        .where(
          (instance) =>
              instance.type == InstanceType.radarr ||
              instance.type == InstanceType.sonarr,
        )
        .toList();

    if (arrInstances.isEmpty) {
      logger.info('[$_logPrefix] No Radarr or Sonarr instances to configure.');
      return const [];
    }

    final serverApiKey = await _resolveServerApiKey(jellyfinInstance);
    final results = <NotificationSetupResult>[];
    for (final arrInstance in arrInstances) {
      results.add(
        await _configureArrInstance(
          arrInstance,
          jellyfinInstance: jellyfinInstance,
          resolvedServerApiKey: serverApiKey,
        ),
      );
    }
    return results;
  }

  /// Configures (creates or updates) the Jellyfin connector on [arrInstance].
  ///
  /// Returns a [NotificationSetupResult] describing success or the failure
  /// reason; this method never throws.
  Future<NotificationSetupResult> configureArrInstance(
    Instance arrInstance, {
    required Instance jellyfinInstance,
  }) => _configureArrInstance(arrInstance, jellyfinInstance: jellyfinInstance);

  Future<NotificationSetupResult> _configureArrInstance(
    Instance arrInstance, {
    required Instance jellyfinInstance,
    _ApiKeyResolution? resolvedServerApiKey,
  }) async {
    try {
      if (arrInstance.type != InstanceType.radarr &&
          arrInstance.type != InstanceType.sonarr) {
        return NotificationSetupResult.failure(
          '${_describe(arrInstance)} is not a Radarr or Sonarr instance.',
        );
      }

      final serverApiKey =
          resolvedServerApiKey ?? await _resolveServerApiKey(jellyfinInstance);
      if (serverApiKey.failure != null) {
        logger.warning(
          '[$_logPrefix] ${_describe(arrInstance)}: ${serverApiKey.failure}',
        );
        return NotificationSetupResult.failure(serverApiKey.failure!);
      }

      // The connector must reach Jellyfin from the *arr server's network, so
      // it is configured with the primary configured URL (`instance.url`) —
      // never `effectiveUrl`/`activeUrl`, which may have picked the
      // alternative URL that suits the phone's current network (e.g. a
      // WAN/tunnel address the *arr server cannot reach).
      final endpoint = _JellyfinEndpoint.fromUrl(jellyfinInstance.url);
      logger.info(
        '[$_logPrefix] Configuring ${_describe(arrInstance)} with Jellyfin at ${endpoint.url}',
      );

      final existing = _findExisting(await _getNotifications(arrInstance));

      if (existing == null) {
        final schemas = await _getSchemas(arrInstance);
        final schema = _pickSchema(schemas, arrInstance);

        final created = schema.copyWith(
          name: _connectorName,
          onGrab: false,
          onDownload: true,
          onUpgrade: true,
          onMovieDelete: true,
          onMovieFileDelete: true,
          onEpisodeFileDelete: true,
          fields: _buildFields(
            schema.fields,
            endpoint: endpoint,
            apiKey: serverApiKey.apiKey!,
          ),
        );
        await _createNotification(arrInstance, _withRenameTrigger(created));
        logger.info(
          '[$_logPrefix] Created "$_connectorName" on ${_describe(arrInstance)}.',
        );
        return NotificationSetupResult.success(
          '${_describe(arrInstance)} configured successfully.',
        );
      }

      final updated = existing.copyWith(
        name: _connectorName,
        onGrab: false,
        onDownload: true,
        onUpgrade: true,
        onMovieDelete: true,
        onMovieFileDelete: true,
        onEpisodeFileDelete: true,
        fields: _buildFields(
          existing.fields,
          endpoint: endpoint,
          apiKey: serverApiKey.apiKey!,
        ),
      );
      await _updateNotification(arrInstance, _withRenameTrigger(updated));
      logger.info(
        '[$_logPrefix] Updated "$_connectorName" on ${_describe(arrInstance)}.',
      );
      return NotificationSetupResult.success(
        '${_describe(arrInstance)} updated successfully.',
      );
    } catch (e, st) {
      logger.error(
        '[$_logPrefix] Failed to configure ${_describe(arrInstance)}',
        e,
        st,
      );
      return NotificationSetupResult.failure(
        'Failed to configure ${_describe(arrInstance)}: $e',
      );
    }
  }

  /// Resolves a server-scoped API key for the connector.
  ///
  /// A plain API key is used as-is. `username:password` credentials log in
  /// as the user and mint (or reuse) an `Arrmate` API key when the account
  /// is an administrator — the connector outlives a user session, so it
  /// cannot rely on the in-memory access token.
  Future<_ApiKeyResolution> _resolveServerApiKey(
    Instance jellyfinInstance,
  ) async {
    final credential = jellyfinInstance.apiKey.trim();
    // A plain key is used as-is. Anything else (user login in the field or
    // in a Basic header, or nothing at all) goes through the login flow,
    // which mints a key for admins and yields null otherwise.
    if (credential.isNotEmpty && !credential.contains(':')) {
      return _ApiKeyResolution(apiKey: credential);
    }
    final service = _jellyfinServiceFactory(jellyfinInstance);
    final minted = await service.ensureApiKey();
    if (minted != null) {
      return _ApiKeyResolution(apiKey: minted);
    }
    return _ApiKeyResolution(
      failure:
          'Jellyfin API key required for automatic library updates: set an '
          'API key in the field, or log in with an administrator account '
          '(API Key field as username:password, or Add Basic Auth)',
    );
  }

  /// Enables `onRename` when the implementation ships it.
  ///
  /// Triggers missing from [NotificationResource] survive in [NotificationResource.extra]
  /// and are only present in the JSON when the schema actually defines them,
  /// so enabling here never invents fields an implementation does not know.
  NotificationResource _withRenameTrigger(NotificationResource notification) {
    final json = notification.toJson();
    if (json.containsKey('onRename')) {
      json['onRename'] = true;
    }
    return NotificationResource.fromJson(json);
  }

  /// Fetches already configured notifications from the instance.
  Future<List<NotificationResource>> _getNotifications(
    Instance instance,
  ) async {
    if (instance.type == InstanceType.radarr) {
      return _radarrApiFactory(instance).getNotifications();
    }
    return _sonarrApiFactory(instance).getNotifications();
  }

  /// Fetches available notification schemas from the instance.
  Future<List<NotificationResource>> _getSchemas(Instance instance) async {
    if (instance.type == InstanceType.radarr) {
      return _radarrApiFactory(instance).getNotificationSchemas();
    }
    return _sonarrApiFactory(instance).getNotificationSchemas();
  }

  /// Sends a request to create a new notification in the instance.
  Future<void> _createNotification(
    Instance instance,
    NotificationResource notification,
  ) async {
    if (instance.type == InstanceType.radarr) {
      await _radarrApiFactory(instance).createNotification(notification);
    } else {
      await _sonarrApiFactory(instance).createNotification(notification);
    }
  }

  /// Sends a request to update an existing notification in the instance.
  Future<void> _updateNotification(
    Instance instance,
    NotificationResource notification,
  ) async {
    if (instance.type == InstanceType.radarr) {
      await _radarrApiFactory(instance).updateNotification(notification);
    } else {
      await _sonarrApiFactory(instance).updateNotification(notification);
    }
  }

  /// Picks the notification schema that works against Jellyfin.
  ///
  /// Radarr and Sonarr ship a `MediaBrowser` implementation that speaks the
  /// Emby protocol (which Jellyfin implements); prefer it and fall back to the
  /// legacy `Emby` implementation.
  NotificationResource _pickSchema(
    List<NotificationResource> schemas,
    Instance arrInstance,
  ) {
    for (final implementation in const ['mediabrowser', 'emby']) {
      for (final schema in schemas) {
        if (schema.implementation?.toLowerCase() == implementation) {
          return schema;
        }
      }
    }
    throw StateError(
      '${_describe(arrInstance)} ships neither a MediaBrowser nor an Emby '
      'notification implementation',
    );
  }

  /// Finds an existing connector created by this service.
  ///
  /// Matching is name-only: `Arrmate Jellyfin` is the name this service
  /// manages, so only such connectors are adopted and updated. A connector
  /// the user created manually — even a MediaBrowser/Emby one pointing at
  /// the same Jellyfin server — is never adopted or renamed; a separate
  /// `Arrmate Jellyfin` connector is created alongside it instead.
  NotificationResource? _findExisting(
    List<NotificationResource> notifications,
  ) {
    for (final notification in notifications) {
      if (notification.name == _connectorName) {
        return notification;
      }
    }
    return null;
  }

  /// Populates configuration fields with the Jellyfin server address and API
  /// key, and turns "Update Library" on.
  ///
  /// Field names differ between implementations and firmware versions, so
  /// matching is case-insensitive and only fields the schema actually defines
  /// are written (unknown fields pass through untouched). Current Radarr
  /// (`MediaBrowserSettings`) and Sonarr (`EmbySettings`) ship the split
  /// `Host`/`Port`/`UseSsl`/`UrlBase`/`ApiKey` fields; very old builds shipped
  /// a single `Url` field, which is still populated as a fallback.
  List<NotificationField> _buildFields(
    List<NotificationField> baseFields, {
    required _JellyfinEndpoint endpoint,
    required String apiKey,
  }) {
    return baseFields.map((field) {
      switch (field.name.toLowerCase()) {
        case 'host':
          return NotificationField(name: field.name, value: endpoint.host);
        case 'port':
          final port = endpoint.portFor(field.value);
          return port == null
              ? field
              : NotificationField(name: field.name, value: port);
        case 'usessl':
          return NotificationField(name: field.name, value: endpoint.useSsl);
        case 'urlbase':
          // Path-less URL: leave the schema default (usually '/') untouched.
          return endpoint.urlBase.isEmpty
              ? field
              : NotificationField(name: field.name, value: endpoint.urlBase);
        case 'url':
          // Legacy implementations with a single scheme+host+port field.
          return NotificationField(name: field.name, value: endpoint.url);
        case 'apikey':
          return NotificationField(name: field.name, value: apiKey);
        case 'updatelibrary':
          return NotificationField(name: field.name, value: true);
        default:
          return field;
      }
    }).toList();
  }

  /// A short, log-safe label for the instance (never contains API keys).
  String _describe(Instance instance) => instance.name ?? instance.id;
}

/// The Jellyfin server address parsed from the instance's configured URL.
///
/// Real `MediaBrowserSettings` (Radarr) and `EmbySettings` (Sonarr) schemas
/// store the address as separate fields, so the URL is decomposed once here.
class _JellyfinEndpoint {
  /// Normalized full URL (`scheme://host[:port][/path]`), no trailing slash.
  final String url;

  /// Hostname without scheme or port.
  final String host;

  /// Explicit port from the URL; `null` when the URL carries none.
  final int? explicitPort;

  /// Whether the URL uses HTTPS.
  final bool useSsl;

  /// Path portion of the URL (e.g. `/jellyfin`); empty when the URL has none.
  final String urlBase;

  const _JellyfinEndpoint({
    required this.url,
    required this.host,
    required this.explicitPort,
    required this.useSsl,
    required this.urlBase,
  });

  /// Parses [rawUrl] after trimming trailing slashes.
  factory _JellyfinEndpoint.fromUrl(String rawUrl) {
    final url = rawUrl.trim().replaceAll(RegExp(r'/+$'), '');
    var parsed = Uri.parse(url);
    if (parsed.scheme.isEmpty) {
      // Scheme-less input parses the hostname as the scheme; assume http.
      parsed = Uri.parse('http://$url');
    }
    final path = parsed.path;
    return _JellyfinEndpoint(
      url: url,
      host: parsed.host,
      explicitPort: parsed.hasPort ? parsed.port : null,
      useSsl: parsed.scheme.toLowerCase() == 'https',
      urlBase: path == '/' ? '' : path,
    );
  }

  /// Port to store in the connector's `Port` field, or `null` to keep the
  /// current field value untouched.
  ///
  /// An explicit port in the URL always wins. Without one, only an *unset*
  /// field (0/empty — the real schemas ship a default of 0) is filled with
  /// the scheme default (8096 http / 443 https); a non-zero stored value is
  /// kept, because a working configured port beats a guess.
  int? portFor(dynamic currentValue) {
    final explicit = explicitPort;
    if (explicit != null) {
      return explicit;
    }
    final stored = currentValue is int
        ? currentValue
        : int.tryParse('$currentValue');
    if (stored != null && stored > 0) {
      return null;
    }
    return useSsl ? 443 : 8096;
  }
}

/// Outcome of the connector credential resolution: either a server API key
/// or the reason none could be obtained.
class _ApiKeyResolution {
  final String? apiKey;
  final String? failure;

  const _ApiKeyResolution({this.apiKey, this.failure});
}
