import 'dart:async';
import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/network/request_diagnostics.dart';
import '../../core/network/secure_log_interceptor.dart';
import '../../core/services/logger_service.dart';
import '../../domain/models/models.dart';

/// Interval between catalog polls while waiting for Jellyfin to index a file.
const Duration defaultJellyfinPollInterval = Duration(milliseconds: 1500);

/// Total time spent polling before giving up on the catalog scan.
const Duration defaultJellyfinPollTimeout = Duration(seconds: 20);

/// Bitrate cap applied to the HLS master playlist when the caller does not
/// pass a `maxBitrate` to [JellyfinService.getPlaybackSession].
const int defaultJellyfinHlsMaxBitrate = 4000000;

/// Service for interacting with the Jellyfin media server REST API.
///
/// Supports three authentication modes, mirroring `QBittorrentService`:
/// - **User mode**: `username:password` in [Instance.apiKey], or decoded
///   from a custom `Authorization: Basic ...` header when the field is
///   empty → `POST /Users/AuthenticateByName`; the returned access token
///   and user id are kept in memory only.
/// - **API key mode**: any non-empty value without `:` (the admin-generated
///   key) → sent as `Token` in the `Authorization: MediaBrowser ...`
///   header. An admin API key has no user scope, so playback progress is
///   never reported in this mode (see [supportsProgressSync]) — watch-state
///   writes must not be attributed to an arbitrary account.
/// - **Custom header only**: empty value without usable headers → relies
///   solely on [Instance.headers].
class JellyfinService {
  final Instance instance;
  final Dio _dio;

  /// Delay between catalog polls while waiting for Jellyfin to index a file.
  final Duration pollInterval;

  /// Total time spent polling before giving up on the catalog scan.
  final Duration pollTimeout;

  /// Resolves the per-installation device id used in the MediaBrowser
  /// authorization header. Production resolves it from the platform (see
  /// [_defaultDeviceId]); tests inject fixed values.
  final Future<String> Function()? deviceIdResolver;

  /// Access token from user mode. In-memory only, never persisted.
  String? _accessToken;

  /// Authenticated user id (user mode only).
  String? _userId;

  /// Resolved per-installation device id, or null until it resolves (the
  /// authorization header then falls back to the [Instance.id]-derived
  /// value).
  String? _deviceId;

  /// Per-service resolution of an injected [deviceIdResolver], memoized so
  /// the resolver runs once per service.
  Future<String>? _injectedDeviceIdResolution;

  /// Default-resolver result cached process-wide: the id identifies this
  /// installation, not a configured instance.
  static String? _sharedDeviceId;

  /// In-flight default resolution, coalescing concurrent authentications.
  static Future<String>? _sharedDeviceIdResolution;

  /// Whether the authenticated user is a server administrator (user mode).
  bool _isAdministrator = false;

  /// Whether authentication uses `username:password` credentials.
  bool _isUserMode = false;

  /// Whether authentication uses a plain API key (sent as `Token`).
  bool _isApiKeyMode = false;

  /// Whether watch-state writes (playback progress, resume points) may be
  /// reported to the server.
  ///
  /// Only user mode qualifies: progress is per-user data, and an admin API
  /// key has no legitimate user to attribute it to. Guessing an account via
  /// `GET /Users` would silently write another person's watch state.
  bool get supportsProgressSync => _isUserMode;

  Completer<void>? _reauthCompleter;

  /// Every candidate base URL that may be tried when the active one fails.
  final List<String> _candidateUrls;

  /// Base URL currently considered active. Promoted to a fallback only after
  /// that fallback answers successfully, mirroring `QBittorrentService`.
  String _activeUrl;

  /// Creates a Jellyfin client for [instance].
  ///
  /// [pollInterval] and [pollTimeout] control the catalog polling loop used
  /// by [resolvePlayableItem]; the defaults suit interactive use, and tests
  /// inject tiny values to keep the loop fast and deterministic.
  JellyfinService(
    this.instance, {
    Dio? dio,
    this.pollInterval = defaultJellyfinPollInterval,
    this.pollTimeout = defaultJellyfinPollTimeout,
    this.deviceIdResolver,
  }) : _candidateUrls = instance.connectionUrls,
       _activeUrl = instance.connectionUrls.first,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: instance.effectiveUrl,
               connectTimeout: instance.timeout(InstanceTimeout.normal),
               receiveTimeout: instance.timeout(InstanceTimeout.normal),
               validateStatus: (status) => status != null && status < 500,
               headers: effectiveCustomHeaders(instance),
             ),
           ) {
    _dio.interceptors.add(SecureLogInterceptor());
    _dio.interceptors.add(RequestDiagnosticsInterceptor(source: instance.id));
    // Normalise baseUrl to match the active candidate URL so the
    // relative-path shortcut in [_resolvePath] works.
    _dio.options.baseUrl = _activeUrl;
    _resolveAuthMode();
  }

  /// Custom instance headers applicable to Jellyfin requests.
  ///
  /// In managed modes (user or API key credentials) a custom `Authorization`
  /// header is dropped: Jellyfin honors a single Authorization scheme and
  /// rejects requests carrying a foreign one (e.g. a reverse-proxy `Basic`
  /// value) with 401 even when a valid token travels alongside. The login
  /// request already overrides Authorization with the MediaBrowser value,
  /// which is why authentication alone succeeded while every later call
  /// failed. Custom-header-only mode keeps every header untouched.
  Map<String, String> get _effectiveCustomHeaders =>
      effectiveCustomHeaders(instance);

  /// Filters [instance]'s custom headers for Jellyfin requests (see
  /// [_effectiveCustomHeaders]). Static so the constructor can apply it
  /// before the instance is fully built.
  static Map<String, String> effectiveCustomHeaders(Instance instance) {
    final managed =
        instance.apiKey.isNotEmpty ||
        decodeBasicCredentials(instance.headers) != null;
    return {
      for (final h in instance.headers)
        if (!managed || h.name.toLowerCase() != 'authorization')
          h.name: h.value,
    };
  }

  /// Credentials (`username:password`) for user mode.
  ///
  /// From [Instance.apiKey] when it contains `:`, otherwise decoded from a
  /// custom `Authorization: Basic ...` header (the qBittorrent-style flow:
  /// empty key plus "Add Basic Auth"). Jellyfin never accepts HTTP Basic
  /// itself, so the decoded pair is only ever sent to `AuthenticateByName`.
  String? _loginCredentials;

  /// Decodes `username:password` from a custom Basic authorization header.
  ///
  /// Returns null when there is no Basic header, it is malformed, or it
  /// carries no `:` separator. The decoded value is never logged.
  String? _decodedBasicCredentials() =>
      decodeBasicCredentials(instance.headers);

  /// Decodes `username:password` from a Basic authorization header in
  /// [headers]. Static so the constructor can apply it before the instance
  /// is fully built.
  static String? decodeBasicCredentials(List<InstanceHeader> headers) {
    for (final header in headers) {
      if (header.name.toLowerCase() != 'authorization') continue;
      final value = header.value.trim();
      if (!value.toLowerCase().startsWith('basic ')) return null;
      try {
        final decoded = utf8.decode(
          base64.decode(value.substring('basic '.length).trim()),
        );
        return decoded.contains(':') ? decoded : null;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Resolves the authentication mode from [Instance.apiKey] without any
  /// network call, so request headers are correct from the first request.
  ///
  /// Mirrors `QBittorrentService`: the API key field carries either a plain
  /// key or `username:password`, and an empty field falls back to the
  /// custom headers — including Basic credentials for the login.
  ///
  /// - Plain key → API key mode (no login request).
  /// - `username:password` (field or Basic header) → user mode (credentials
  ///   via AuthenticateByName).
  /// - Empty without usable headers → custom headers only.
  void _resolveAuthMode() {
    _loginCredentials = null;
    if (instance.apiKey.isEmpty) {
      _loginCredentials = _decodedBasicCredentials();
      _isUserMode = _loginCredentials != null;
      _isApiKeyMode = false;
    } else if (!instance.apiKey.contains(':')) {
      _isApiKeyMode = true;
      _isUserMode = false;
    } else {
      _isUserMode = true;
      _isApiKeyMode = false;
      _loginCredentials = instance.apiKey;
    }
    if ((_isUserMode || _isApiKeyMode) &&
        instance.headers.any((h) => h.name.toLowerCase() == 'authorization')) {
      logger.debug(
        '[JellyfinService] Ignoring the custom Authorization header: a '
        'foreign scheme makes Jellyfin reject even valid tokens with 401',
      );
    }
  }

  /// Authenticates with the Jellyfin server.
  ///
  /// Selection of mode based on [Instance.apiKey], mirroring
  /// `QBittorrentService`:
  /// - Empty → decoded Basic header credentials when present, otherwise
  ///   requests fall back to [Instance.headers] only.
  /// - Plain key → API key; no login request.
  /// - `username:password` (field or Basic header) → `POST
  ///   /Users/AuthenticateByName`, storing the returned access token and
  ///   user id in memory.
  Future<void> authenticate({String? baseUrl}) async {
    _resolveAuthMode();
    if (!_isUserMode) {
      logger.debug(
        _isApiKeyMode
            ? '[JellyfinService] Using API key authentication'
            : '[JellyfinService] No apiKey set; relying on custom headers only',
      );
      return;
    }

    final credentials = _loginCredentials ?? instance.apiKey;
    final separatorIndex = credentials.indexOf(':');
    final username = credentials.substring(0, separatorIndex);
    final password = credentials.substring(separatorIndex + 1);

    // The device id travels in the authorization header below. Resolve it
    // before logging in: devices restored from the same cloud backup would
    // otherwise share one id, and Jellyfin invalidates the sibling's session
    // on every login, killing stream tokens mid-play.
    await _resolveDeviceId();

    logger.debug('[JellyfinService] Authenticating as $username...');

    try {
      final loginPath = baseUrl != null
          ? _resolvePath('/Users/AuthenticateByName', baseUrl)
          : '/Users/AuthenticateByName';
      final response = await _dio.post<dynamic>(
        loginPath,
        data: {'Username': username, 'Pw': password},
        options: Options(
          headers: {'Authorization': mediaBrowserAuthorization},
          validateStatus: (status) => true,
        ),
      );

      final data = response.data;
      if (response.statusCode == 200 && data is Map) {
        final token = data['AccessToken']?.toString();
        final user = data['User'];
        _accessToken = (token != null && token.isNotEmpty) ? token : null;
        _userId = user is Map ? user['Id']?.toString() : null;
        _isAdministrator =
            user is Map &&
            user['Policy'] is Map &&
            (user['Policy'] as Map)['IsAdministrator'] == true;
        if (_accessToken != null) {
          logger.debug('[JellyfinService] Authentication successful');
          return;
        }
      }

      throw Exception('Jellyfin authentication failed: ${response.statusCode}');
    } catch (e) {
      logger.error('[JellyfinService] Auth error', e);
      rethrow;
    }
  }

  /// MediaBrowser authorization header required by the auth endpoint.
  ///
  /// The device id is per-installation — not derived from the cloud-synced
  /// [Instance.id] — so Jellyfin keeps sibling devices' sessions separate;
  /// the instance-derived value is used until resolution completes.
  String get mediaBrowserAuthorization {
    final deviceId = _deviceId ?? 'arrmate-${instance.id}';
    return 'MediaBrowser Client="Arrmate", Device="Arrmate", '
        'DeviceId="$deviceId", Version="1.0"';
  }

  /// Resolves the per-installation device id once, storing it in
  /// [_deviceId]. Failures keep the instance-derived fallback so
  /// authentication is never blocked by device-id lookup problems.
  Future<void> _resolveDeviceId() async {
    try {
      _deviceId = await _currentDeviceId();
    } catch (e, stackTrace) {
      logger.warning(
        '[JellyfinService] Device id resolution failed; falling back to the '
        'instance id',
        e,
        stackTrace,
      );
    }
  }

  /// Returns the per-installation device id, resolving it once.
  ///
  /// An injected [deviceIdResolver] (tests) is honored per service; the
  /// default platform resolver is cached process-wide because the id
  /// identifies the installation itself.
  Future<String> _currentDeviceId() {
    final resolver = deviceIdResolver;
    if (resolver != null) {
      return _injectedDeviceIdResolution ??= resolver();
    }
    final cached = _sharedDeviceId;
    if (cached != null) return Future<String>.value(cached);
    return _sharedDeviceIdResolution ??= _defaultDeviceId().then((id) {
      _sharedDeviceId = id;
      return id;
    });
  }

  /// Preference key holding the generated device id.
  ///
  /// Deliberately absent from `BackupService`'s allowlist: cloud backup
  /// syncs only allowlisted SharedPreferences keys, so a restore can never
  /// copy this device's id onto another device (a shared id would make
  /// Jellyfin invalidate the sibling's session on every login).
  static const _deviceIdPreferenceKey = 'jellyfin_device_id';

  /// Default per-installation device id resolver.
  ///
  /// Uses the platform installation id where device_info_plus still exposes
  /// one (iOS `identifierForVendor`); everywhere else — and on any lookup
  /// failure — a random UUID is generated once and persisted under
  /// [_deviceIdPreferenceKey]. Android's `androidId` was removed from
  /// device_info_plus 12 and `Build.ID` is shared across devices, so the
  /// persisted UUID is the only per-install id available there.
  static Future<String> _defaultDeviceId() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final ios = await DeviceInfoPlugin().iosInfo;
        final vendorId = ios.identifierForVendor;
        if (vendorId != null && vendorId.isNotEmpty) return vendorId;
      } catch (e, stackTrace) {
        logger.warning(
          '[JellyfinService] iOS vendor id unavailable; persisting a random '
          'device id instead',
          e,
          stackTrace,
        );
      }
    }
    return _persistedDeviceId();
  }

  /// Reads or creates the persisted random device id.
  static Future<String> _persistedDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString(_deviceIdPreferenceKey);
      if (existing != null && existing.isNotEmpty) return existing;
      final generated = const Uuid().v4();
      await prefs.setString(_deviceIdPreferenceKey, generated);
      return generated;
    } catch (e, stackTrace) {
      logger.warning(
        '[JellyfinService] Could not persist the device id; using an '
        'ephemeral one for this session',
        e,
        stackTrace,
      );
      return const Uuid().v4();
    }
  }

  /// Token sent to the server when a managed one exists: the user access
  /// token in user mode, the configured key in API key mode.
  String? get _authToken {
    if (_isUserMode) return _accessToken;
    if (_isApiKeyMode) return instance.apiKey;
    return null;
  }

  /// Full `Authorization` header value for authenticated requests.
  ///
  /// Jellyfin 12 no longer accepts the legacy `X-Emby-Token` header or the
  /// lowercase `api_key` query parameter (legacy authorization is disabled
  /// by default upstream); the only accepted methods are this `MediaBrowser`
  /// scheme and the `ApiKey` query parameter. The same header shape is also
  /// honored by 10.8+, so one code path serves old and new servers.
  String? get _authorizationValue {
    final token = _authToken;
    if (token == null) return null;
    return '$mediaBrowserAuthorization, Token="$token"';
  }

  /// Ensures the client is ready to make authenticated requests.
  ///
  /// User mode acquires an access token when none is held. API key mode and
  /// custom-header-only mode need no setup (no user id is guessed — an API
  /// key has no user scope).
  /// [currentUrl] is forwarded so the auth request reaches the correct
  /// candidate when the service has failed over.
  Future<void> _ensureAuthenticated({String? currentUrl}) async {
    if (_isUserMode) {
      if (_accessToken != null) return;
      if (_reauthCompleter != null && !_reauthCompleter!.isCompleted) {
        await _reauthCompleter!.future;
      } else {
        await authenticate(baseUrl: currentUrl);
      }
    }
  }

  /// Makes an authenticated request with auto-retry on 401.
  ///
  /// Safe read requests (GET) additionally fail over to the next candidate
  /// URL on a connection-level failure, mirroring `QBittorrentService`.
  /// Mutating requests never fail over: a refresh or playback report retried
  /// against an alternative host could run twice on distinct servers.
  Future<Response<T>> _request<T>(
    String path, {
    String method = 'GET',
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final allowFailover = method.toUpperCase() == 'GET';
    final attemptedUrls = <String>{};
    var currentUrl = _activeUrl;

    while (true) {
      attemptedUrls.add(currentUrl);
      try {
        final response = await _requestOnce<T>(
          _resolvePath(path, currentUrl),
          method: method,
          data: data,
          queryParameters: queryParameters,
          options: options,
          currentUrl: currentUrl,
        );
        final statusCode = response.statusCode;
        if (statusCode != null && statusCode >= 200 && statusCode < 300) {
          _activeUrl = currentUrl;
        }
        return response;
      } on DioException catch (error) {
        final nextUrl = _nextCandidateUrl(attemptedUrls);
        if (!allowFailover || !_canFailOver(error) || nextUrl == null) {
          rethrow;
        }
        logger.warning(
          '[JellyfinService] Connection failed, retrying with an '
          'alternative instance URL',
        );
        currentUrl = nextUrl;
      }
    }
  }

  /// Runs a single authenticated attempt against a resolved path, handling
  /// the 401 re-authentication flow. The token/user state is shared across
  /// candidate URLs because each candidate points to the same logical server.
  Future<Response<T>> _requestOnce<T>(
    String resolvedPath, {
    String method = 'GET',
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? currentUrl,
  }) async {
    await _ensureAuthenticated(currentUrl: currentUrl);

    options ??= Options();
    final authValue = _authorizationValue;
    if (authValue != null) {
      options.headers = {
        ...(options.headers ?? {}),
        'Authorization': authValue,
      };
    }
    options.method = method;

    final response = await _dio.request<T>(
      resolvedPath,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );

    // Only user-mode tokens can be renewed; a 401 under an API key or custom
    // headers is final, so the response is returned as-is.
    if (response.statusCode == 401 && _isUserMode) {
      await _reauthenticate(currentUrl: currentUrl);
      final retryAuthValue = _authorizationValue;
      final retryOptions = Options(
        method: method,
        headers: {
          ...(options.headers ?? {}),
          if (retryAuthValue != null) 'Authorization': retryAuthValue,
        },
      );
      return _dio.request<T>(
        resolvedPath,
        data: data,
        queryParameters: queryParameters,
        options: retryOptions,
      );
    }

    return response;
  }

  /// Re-authenticates once, coalescing concurrent 401 handling through a
  /// single in-flight [Completer].
  Future<void> _reauthenticate({String? currentUrl}) async {
    if (_reauthCompleter != null && !_reauthCompleter!.isCompleted) {
      logger.debug(
        '[JellyfinService] 401 encountered, waiting for existing re-auth...',
      );
      await _reauthCompleter!.future;
      return;
    }
    final completer = Completer<void>();
    _reauthCompleter = completer;
    try {
      logger.warning(
        '[JellyfinService] Access token rejected, re-authenticating...',
      );
      _accessToken = null;
      await authenticate(baseUrl: currentUrl);
      completer.complete();
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _reauthCompleter = null;
    }
  }

  /// Resolves [path] against [baseUrl]. When the candidate differs from the
  /// shared Dio base URL, an absolute URL is returned so the request runs
  /// against the fallback without mutating [_dio.options.baseUrl].
  String _resolvePath(String path, String baseUrl) {
    if (baseUrl == _dio.options.baseUrl) return path;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final separator = baseUrl.endsWith('/') || path.startsWith('/') ? '' : '/';
    return '$baseUrl$separator$path';
  }

  /// Returns the first candidate URL not yet attempted, if any.
  String? _nextCandidateUrl(Set<String> attemptedUrls) {
    return _candidateUrls
        .where((candidate) => !attemptedUrls.contains(candidate))
        .firstOrNull;
  }

  /// Whether a [DioException] justifies trying an alternative URL.
  bool _canFailOver(DioException error) {
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout;
  }

  /// Reads the system status, reporting the fixed `Jellyfin` app name so the
  /// instance validation label check passes.
  ///
  /// Prefers the authenticated `GET /System/Info` and falls back to the
  /// public endpoint when auth is unavailable or restricted for a non-admin
  /// user.
  Future<InstanceStatus> getSystemStatus() async {
    // Authenticate eagerly so credential problems surface as the auth error
    // instead of being swallowed into the public-info fallback.
    await authenticate();
    var info = await _getSystemInfo('/System/Info', rejectOnAuthFailure: true);
    info ??= await _getSystemInfo('/System/Info/Public');
    if (info == null) {
      throw Exception(
        '[JellyfinService] Could not read the Jellyfin system status',
      );
    }
    return InstanceStatus(
      appName: 'Jellyfin',
      instanceName: info['ServerName']?.toString() ?? instance.label,
      version: info['Version']?.toString() ?? 'Unknown',
      authentication: _isUserMode
          ? 'Credentials'
          : _isApiKeyMode
          ? 'MediaBrowser Token'
          : null,
    );
  }

  /// Fetches one of the `/System/Info*` endpoints, returning null on failure.
  ///
  /// When [rejectOnAuthFailure] is true and credentials are managed, a 401
  /// (or 403 in API-key mode, where keys are always admin-scoped) throws
  /// instead of falling back to the public endpoint.
  Future<Map<String, dynamic>?> _getSystemInfo(
    String path, {
    bool rejectOnAuthFailure = false,
  }) async {
    final Response<dynamic> response;
    try {
      response = await _request<dynamic>(path);
    } catch (e, stackTrace) {
      logger.warning(
        '[JellyfinService] $path failed, trying the next source',
        e,
        stackTrace,
      );
      return null;
    }
    final statusCode = response.statusCode;
    final data = response.data;
    if (statusCode == 200 && data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (rejectOnAuthFailure &&
        ((statusCode == 401 && (_isApiKeyMode || _isUserMode)) ||
            (statusCode == 403 && _isApiKeyMode))) {
      throw Exception(
        '[JellyfinService] Jellyfin rejected the configured credentials '
        '($statusCode)',
      );
    }
    logger.debug(
      '[JellyfinService] $path returned $statusCode; '
      'trying the next source',
    );
    return null;
  }

  /// Locates the Jellyfin item backing a Radarr/Sonarr media file.
  ///
  /// Jellyfin's server-side filters are treated as hints only:
  /// `AnyProviderIdEquals` is ignored by current `/Items` builds,
  /// `SearchTerm` matches names rather than file paths, and
  /// `/Shows/{id}/Episodes` has no episode-number filter — so every
  /// candidate is validated client-side before it is returned. Three
  /// stages, each short-circuiting on success:
  ///
  /// 1. **Title search** — searches by movie [title] / episode [seriesName]
  ///    (falling back to the file basename) and accepts a candidate only by
  ///    path match, movie tmdb/imdb match, or episode tvdb match.
  /// 2. **Episode via series** — resolves the series by name (validated by
  ///    [seriesTvdbId] when available, otherwise a unique name match), then
  ///    lists `/Shows/{id}/Episodes?season=...` and filters the
  ///    season/episode numbers client-side.
  /// 3. **Scan + poll** — `POST /Library/Media/Updated` with the file path,
  ///    then re-runs stages 1–2 until [pollTimeout]. A 403 (a non-admin
  ///    Jellyfin user may not scan) aborts immediately.
  ///
  /// Returns null when no playable item is found; an item is only
  /// considered playable when it carries at least one media source.
  Future<JellyfinItem?> resolvePlayableItem({
    required String filePath,
    String? fileName,
    String? title,
    int? productionYear,
    int? tmdbId,
    String? imdbId,
    int? seriesTvdbId,
    int? episodeTvdbId,
    int? seasonNumber,
    int? episodeNumber,
    String? seriesName,
    required bool isEpisode,
    void Function(String status)? onProgress,
  }) async {
    // Resolves the user id for API key mode before the first query so the
    // userId filter is present from the start.
    await _ensureAuthenticated();
    final normalizedFilePath = _normalizePath(filePath);

    final trimmedSeriesName = seriesName?.trim();
    final titleTerm = isEpisode ? trimmedSeriesName : title?.trim();
    final hasTitle = titleTerm != null && titleTerm.isNotEmpty;
    // The production year narrows only movie title searches; a file
    // basename fallback already carries the year in its release name.
    final years = hasTitle && !isEpisode ? productionYear : null;
    // *arr titles may carry a year suffix ("Dark Matter (2024)") while
    // Jellyfin catalogues the bare name ("Dark Matter"): search the
    // stripped variant first, then the raw one. Validation stays
    // client-side, so a looser term can never cause a wrong hit.
    final searchTerms = <String>{
      if (hasTitle)
        ..._titleVariants(titleTerm)
      else ...[
        p.basenameWithoutExtension(filePath),
        if (fileName != null && fileName.trim().isNotEmpty) fileName.trim(),
      ],
    }.toList();

    // Runs stages 1–2 against the live catalog; reused by the poll loop
    // after the scan request.
    Future<JellyfinItem?> searchLibrary() async {
      // Stage 1 — title (or basename) search, validated client-side.
      for (final term in searchTerms) {
        final match = await _findFirstValidatedItem(
          searchTerm: term,
          years: years?.toString(),
          normalizedFilePath: normalizedFilePath,
          isEpisode: isEpisode,
          tmdbId: tmdbId,
          imdbId: imdbId,
          episodeTvdbId: episodeTvdbId,
        );
        if (match != null) return match;
      }

      // Stage 2 — episodes resolve through their series item.
      if (isEpisode) {
        final episode = await _findEpisodeViaSeries(
          seriesName: trimmedSeriesName,
          seriesTvdbId: seriesTvdbId,
          seasonNumber: seasonNumber,
          episodeNumber: episodeNumber,
          episodeTvdbId: episodeTvdbId,
        );
        if (episode != null) return episode;
      }
      return null;
    }

    onProgress?.call('Searching the Jellyfin library...');
    final found = await searchLibrary();
    if (found != null) return found;

    // Stage 3 — the file is not indexed yet: trigger a scan, then poll.
    onProgress?.call('Asking Jellyfin to scan the new file...');
    if (!await _notifyLibraryUpdated(filePath)) {
      onProgress?.call('Jellyfin user cannot trigger a library scan');
      return null;
    }

    onProgress?.call('Waiting for Jellyfin to index the file...');
    final deadline = DateTime.now().add(pollTimeout);
    while (DateTime.now().isBefore(deadline)) {
      final match = await searchLibrary();
      if (match != null) return match;
      await Future<void>.delayed(pollInterval);
    }
    logger.warning(
      '[JellyfinService] File was not indexed within '
      '${pollTimeout.inSeconds}s: $filePath',
    );
    return null;
  }

  /// Search variants for an *arr title: the year-suffixed raw form plus the
  /// bare name (`"Dark Matter (2024)"` → `"Dark Matter"`), deduplicated.
  /// Jellyfin usually catalogues the bare name, while Sonarr titles often
  /// carry the year — searching both keeps pairing working either way.
  static List<String> _titleVariants(String title) {
    final raw = title.trim();
    final stripped = raw.replaceFirst(RegExp(r'\s+\(\d{4}\)$'), '').trim();
    return <String>{
      if (stripped.isNotEmpty) stripped,
      if (raw.isNotEmpty) raw,
    }.toList(growable: false);
  }

  /// Stage 1 — searches by [searchTerm] and returns the first candidate
  /// proven to be the requested content by [_candidateRefersToSameContent].
  /// [years] is a server-side narrowing hint only; the client-side
  /// validation stays the authority.
  Future<JellyfinItem?> _findFirstValidatedItem({
    required String searchTerm,
    required String? years,
    required String normalizedFilePath,
    required bool isEpisode,
    required int? tmdbId,
    required String? imdbId,
    required int? episodeTvdbId,
  }) async {
    final items = await _searchItems(
      includeItemTypes: 'Movie,Episode,Video',
      searchTerm: searchTerm,
      years: years,
    );
    logger.debug(
      '[JellyfinService] Search "$searchTerm" returned ${items.length} '
      'candidate(s)',
    );
    for (final item in items) {
      if (item.mediaSources.isEmpty) continue;
      if (_candidateRefersToSameContent(
        item,
        normalizedFilePath: normalizedFilePath,
        isEpisode: isEpisode,
        tmdbId: tmdbId,
        imdbId: imdbId,
        episodeTvdbId: episodeTvdbId,
      )) {
        logger.debug(
          '[JellyfinService] Matched "${item.name}" (${item.id}) with '
          '${item.playbackPositionTicks ?? 0} resume ticks',
        );
        return item;
      }
    }
    return null;
  }

  /// Whether a server-side search candidate is genuinely the requested
  /// content. Jellyfin's `/Items` filters are unreliable (provider-id
  /// filters are ignored, `SearchTerm` matches names rather than paths), so
  /// a candidate must prove itself by file path or external provider ids
  /// before it may be played.
  bool _candidateRefersToSameContent(
    JellyfinItem item, {
    required String normalizedFilePath,
    required bool isEpisode,
    required int? tmdbId,
    required String? imdbId,
    required int? episodeTvdbId,
  }) {
    // (a) The candidate's file path is the requested file, possibly mounted
    // under a different container root.
    final itemPath = item.path;
    if (itemPath != null &&
        _pathsReferToSameFile(_normalizePath(itemPath), normalizedFilePath)) {
      return true;
    }
    // (d) Same file name under the same parent folder, regardless of the
    // container root (`/data/tvshows/Show/Season 2/E07.mkv` vs
    // `/data/tvseries/sonarr/Show/Season 2/E07.mkv`). Library roots are
    // never hardcodable — every user maps them differently — so only the
    // tail proves anything. This also matches freshly scanned items that
    // carry no provider ids yet.
    if (itemPath != null &&
        _sharesParentAndName(_normalizePath(itemPath), normalizedFilePath)) {
      return true;
    }
    if (isEpisode) {
      // (c) The episode carries the requested tvdb id.
      return episodeTvdbId != null &&
          item.providerIds['tvdb'] == '$episodeTvdbId';
    }
    // (b) The movie carries the requested tmdb/imdb id.
    if (tmdbId != null && item.providerIds['tmdb'] == '$tmdbId') {
      return true;
    }
    final candidateImdb = item.providerIds['imdb'];
    if (imdbId != null &&
        imdbId.isNotEmpty &&
        candidateImdb != null &&
        candidateImdb.toLowerCase() == imdbId.toLowerCase()) {
      return true;
    }
    return false;
  }

  /// Whether an item path and a Radarr/Sonarr path point at the same file.
  ///
  /// Both paths are expected normalized (lowercase, forward slashes). Either
  /// they are equal, or the item path is the same file mounted under a
  /// different container root (`/media/data/x` vs `/data/x`): a tail match on
  /// the full file path. The suffix must be slash-delimited, so
  /// `/data/foo.mkv` can never match `/mydata/foo.mkv`.
  bool _pathsReferToSameFile(String itemPath, String filePath) {
    if (itemPath == filePath) return true;
    final suffix = filePath.startsWith('/') ? filePath : '/$filePath';
    return itemPath.endsWith(suffix);
  }

  /// Whether two normalized paths share file name and parent folder.
  ///
  /// A weaker signal than [_pathsReferToSameFile], used as one acceptance
  /// rule among others: identical file + parent under different roots is
  /// overwhelmingly the same release, and it is the only signal available
  /// for freshly scanned items without provider ids.
  bool _sharesParentAndName(String itemPath, String filePath) {
    List<String> tail(String path) {
      final segments = path.split('/').where((s) => s.isNotEmpty).toList();
      if (segments.length < 2) return const [];
      return segments.sublist(segments.length - 2);
    }

    final a = tail(itemPath);
    final b = tail(filePath);
    return a.length == 2 && b.length == 2 && a[0] == b[0] && a[1] == b[1];
  }

  /// Stage 2 — resolves an episode through its series item: finds the series
  /// by name, then lists its episodes and validates the season/episode
  /// numbers client-side.
  Future<JellyfinItem?> _findEpisodeViaSeries({
    required String? seriesName,
    required int? seriesTvdbId,
    required int? seasonNumber,
    required int? episodeNumber,
    required int? episodeTvdbId,
  }) async {
    final name = seriesName?.trim();
    if (name == null || name.isEmpty) return null;
    for (final variant in _titleVariants(name)) {
      final seriesItems = await _searchItems(
        includeItemTypes: 'Series',
        searchTerm: variant,
      );
      logger.debug(
        '[JellyfinService] Series search "$variant" returned '
        '${seriesItems.length} candidate(s)',
      );
      final series = _selectSeries(
        seriesItems,
        seriesName: variant,
        seriesTvdbId: seriesTvdbId,
      );
      if (series == null) continue;
      logger.debug(
        '[JellyfinService] Matched series "${series.name}" (${series.id})',
      );
      final episode = await _findSeriesEpisode(
        series.id,
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
        episodeTvdbId: episodeTvdbId,
      );
      if (episode != null) {
        logger.debug(
          '[JellyfinService] Matched "${episode.name}" (${episode.id}) with '
          '${episode.playbackPositionTicks ?? 0} resume ticks',
        );
        return episode;
      }
    }
    return null;
  }

  /// Picks the catalogued series matching [seriesName]: by tvdb id when
  /// known, otherwise the unique name match — never a guess among
  /// duplicates.
  JellyfinItem? _selectSeries(
    List<JellyfinItem> candidates, {
    required String seriesName,
    required int? seriesTvdbId,
  }) {
    if (seriesTvdbId != null) {
      return candidates
          .where((item) => item.providerIds['tvdb'] == '$seriesTvdbId')
          .firstOrNull;
    }
    final nameMatches = candidates
        .where(
          (item) =>
              (item.name ?? '').trim().toLowerCase() ==
              seriesName.toLowerCase(),
        )
        .toList(growable: false);
    return nameMatches.length == 1 ? nameMatches.first : null;
  }

  /// Fetches the episodes of [seriesId] through the `/Shows/{id}/Episodes`
  /// `season` filter and returns the first playable episode whose
  /// season/episode numbers (or tvdb id) match client-side. There is no
  /// server-side episode-number filter to lean on.
  Future<JellyfinItem?> _findSeriesEpisode(
    String seriesId, {
    required int? seasonNumber,
    required int? episodeNumber,
    required int? episodeTvdbId,
  }) async {
    final query = <String, dynamic>{
      'Fields': 'Path,MediaSources,ProviderIds',
      if (seasonNumber != null) 'season': '$seasonNumber',
      if (_userId != null) 'userId': _userId,
    };
    try {
      final response = await _request<Map<String, dynamic>>(
        '/Shows/$seriesId/Episodes',
        queryParameters: query,
      );
      final data = response.data;
      if (response.statusCode != 200 || data == null) return null;
      final items = data['Items'];
      if (items is! List) return null;
      for (final entry in items) {
        if (entry is! Map) continue;
        final item = JellyfinItem.fromJson(Map<String, dynamic>.from(entry));
        if (item.mediaSources.isEmpty) continue;
        if (_episodeMatchesNumbers(
          item,
          seasonNumber: seasonNumber,
          episodeNumber: episodeNumber,
          episodeTvdbId: episodeTvdbId,
        )) {
          return item;
        }
      }
      return null;
    } catch (e, stackTrace) {
      logger.warning(
        '[JellyfinService] Could not list episodes for series $seriesId',
        e,
        stackTrace,
      );
      return null;
    }
  }

  /// Whether an episode from the series listing sits in the requested
  /// season and slot, or carries the requested tvdb id. Without any of
  /// those there is nothing to validate against, so nothing is accepted.
  bool _episodeMatchesNumbers(
    JellyfinItem item, {
    required int? seasonNumber,
    required int? episodeNumber,
    required int? episodeTvdbId,
  }) {
    if (episodeTvdbId != null && item.providerIds['tvdb'] == '$episodeTvdbId') {
      return true;
    }
    if (seasonNumber != null && item.parentIndexNumber != seasonNumber) {
      return false;
    }
    if (episodeNumber != null && item.indexNumber != episodeNumber) {
      return false;
    }
    return seasonNumber != null || episodeNumber != null;
  }

  /// Queries `/Items` with the given filters, returning an empty list on any
  /// non-200 answer so the pipeline can move on to the next stage.
  ///
  /// The result is only a hint pool: callers must validate candidates
  /// client-side, because `AnyProviderIdEquals` is ignored by current
  /// Jellyfin builds and `SearchTerm` matches names rather than paths.
  Future<List<JellyfinItem>> _searchItems({
    required String includeItemTypes,
    String? searchTerm,
    String? years,
  }) async {
    final query = <String, dynamic>{
      'Recursive': 'true',
      'IncludeItemTypes': includeItemTypes,
      'Fields': 'Path,MediaSources,ProviderIds',
      'Limit': '100',
      if (searchTerm != null) 'SearchTerm': searchTerm,
      if (years != null) 'years': years,
    };
    final userId = _userId;
    if (userId != null) {
      query['userId'] = userId;
    }
    try {
      final response = await _request<Map<String, dynamic>>(
        '/Items',
        queryParameters: query,
      );
      final data = response.data;
      if (response.statusCode != 200 || data == null) return const [];
      final items = data['Items'];
      if (items is! List) return const [];
      return [
        for (final entry in items)
          if (entry is Map)
            JellyfinItem.fromJson(Map<String, dynamic>.from(entry)),
      ];
    } catch (e, stackTrace) {
      logger.warning(
        '[JellyfinService] Item search failed (SearchTerm: $searchTerm, '
        'years: $years)',
        e,
        stackTrace,
      );
      return const [];
    }
  }

  /// Stage 3 entry point — tells Jellyfin a new file appeared at [filePath].
  ///
  /// Only the targeted `POST /Library/Media/Updated` is used: the virtual
  /// folder lookup, per-folder refresh, and `/Library/Refresh` full scan are
  /// admin-only routes that a regular user can only answer with a 403 — and
  /// an expensive scan for an admin.
  ///
  /// Returns whether polling for the indexed file makes sense: true on a
  /// successful scan request, false when the server refused or failed it.
  Future<bool> _notifyLibraryUpdated(String filePath) async {
    try {
      final response = await _request(
        '/Library/Media/Updated',
        method: 'POST',
        data: {
          'Updates': [
            {'Path': filePath, 'UpdateType': 'Created'},
          ],
        },
      );
      final status = response.statusCode;
      if (status != null && status >= 200 && status < 300) return true;
      if (status == 403) {
        logger.warning(
          '[JellyfinService] /Library/Media/Updated returned 403: this '
          'Jellyfin user cannot trigger a library scan',
        );
        return false;
      }
      logger.warning(
        '[JellyfinService] /Library/Media/Updated returned $status; '
        'skipping the index wait',
      );
      return false;
    } catch (e, stackTrace) {
      logger.warning(
        '[JellyfinService] /Library/Media/Updated failed; skipping the '
        'index wait',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// Lowercases, converts backslashes to forward slashes, and strips
  /// trailing slashes so paths from different mounts compare equal.
  String _normalizePath(String path) {
    var normalized = path.toLowerCase().replaceAll('\\', '/');
    while (normalized.length > 1 && normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  /// Builds a playback session for [item].
  ///
  /// Both URLs point at the first media source and carry `ApiKey` (capital A:
  /// Jellyfin 12 only honors this casing alongside the `Authorization`
  /// header): [JellyfinPlaybackSession.streamUrl] is always Direct Play
  /// (`static=true`), while [JellyfinPlaybackSession.hlsUrl] is the HLS
  /// master playlist capped at [maxBitrate] (default
  /// [defaultJellyfinHlsMaxBitrate]) so the player can fall back or switch
  /// quality when Direct Play fails.
  Future<JellyfinPlaybackSession> getPlaybackSession(
    JellyfinItem item, {
    int? maxBitrate,
  }) async {
    // Resolves the user access token (user mode) before PlaybackInfo.
    await _ensureAuthenticated();
    final userId = _userId;
    final playbackInfo = await _requestPlaybackInfo(item, userId: userId);

    JellyfinMediaSource? source;
    final responseSources = playbackInfo?['MediaSources'];
    if (responseSources is List && responseSources.isNotEmpty) {
      final first = responseSources.first;
      if (first is Map) {
        source = JellyfinMediaSource.fromJson(Map<String, dynamic>.from(first));
      }
    }
    source ??= item.mediaSources.firstOrNull;
    if (source == null) {
      throw StateError('Jellyfin item ${item.id} has no media sources to play');
    }

    final token = _authToken;
    final streamQuery = <String, String>{
      'MediaSourceId': source.id,
      if (token != null) 'ApiKey': token,
    };

    final streamUrl = _buildUri('/Videos/${item.id}/stream', {
      'static': 'true',
      ...streamQuery,
    });
    final hlsUrl = _buildUri('/Videos/${item.id}/master.m3u8', {
      ...streamQuery,
      'VideoBitrate': '${maxBitrate ?? defaultJellyfinHlsMaxBitrate}',
      'VideoCodec': 'h264',
      'AudioCodec': 'aac,mp3',
    });

    return JellyfinPlaybackSession(
      itemId: item.id,
      mediaSourceId: source.id,
      streamUrl: streamUrl,
      hlsUrl: hlsUrl,
      httpHeaders: {
        // Custom instance headers first (minus any custom Authorization in
        // managed modes — see [_effectiveCustomHeaders]), then the managed
        // MediaBrowser authorization (with Token) so it wins on conflicts.
        ..._effectiveCustomHeaders,
        if (_authorizationValue != null) 'Authorization': _authorizationValue!,
      },
      // Resume position is per-user data: only report it when the session
      // belongs to an authenticated user, never for a scope-less admin key.
      // Jellyfin ticks are 100 ns, hence `microseconds ~/ 10`.
      playbackPosition: supportsProgressSync
          ? Duration(microseconds: (item.playbackPositionTicks ?? 0) ~/ 10)
          : Duration.zero,
      audioStreams: source.mediaStreams
          .where((stream) => stream.type == 'Audio')
          .toList(growable: false),
      subtitleStreams: source.mediaStreams
          .where((stream) => stream.type == 'Subtitle')
          .toList(growable: false),
    );
  }

  /// Minimal device profile for the PlaybackInfo handshake: without a
  /// `DeviceProfile` Jellyfin never returns `DeliveryUrl` for external
  /// subtitle streams, leaving them unfetchable by the player.
  static const _playbackDeviceProfile = <String, dynamic>{
    'SubtitleProfiles': [
      {'Format': 'vtt', 'Method': 'External'},
      {'Format': 'srt', 'Method': 'External'},
      {'Format': 'ass', 'Method': 'External'},
      {'Format': 'ssa', 'Method': 'External'},
    ],
  };

  /// POSTs the PlaybackInfo handshake for [item], returning null on failure.
  Future<Map<String, dynamic>?> _requestPlaybackInfo(
    JellyfinItem item, {
    required String? userId,
  }) async {
    try {
      final response = await _request<Map<String, dynamic>>(
        '/Items/${item.id}/PlaybackInfo',
        method: 'POST',
        queryParameters: {if (userId != null) 'userId': userId},
        data: {
          if (userId != null) 'UserId': userId,
          'IsPlayback': true,
          'AutoOpenLiveStream': true,
          'DeviceProfile': _playbackDeviceProfile,
          if (item.mediaSources.length > 1)
            'MediaSourceId': item.mediaSources.first.id,
        },
      );
      final data = response.data;
      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        return data;
      }
    } catch (e, stackTrace) {
      logger.warning(
        '[JellyfinService] PlaybackInfo failed for item ${item.id}',
        e,
        stackTrace,
      );
    }
    return null;
  }

  /// Builds an absolute URL against the active candidate base URL.
  Uri _buildUri(String path, Map<String, String> queryParameters) {
    final base = Uri.parse(_activeUrl);
    final basePath = base.path.endsWith('/') && base.path.length > 1
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    return base.replace(
      path: '$basePath$path',
      queryParameters: queryParameters,
    );
  }

  /// Returns a server-scoped API key named [appName], minting one when the
  /// authenticated user is an administrator.
  ///
  /// Server-to-server integrations (e.g. the Radarr/Sonarr library-update
  /// connector) outlive a user session, so they need a real API key instead
  /// of the in-memory access token. Reuses an existing [appName] key before
  /// creating a new one. Jellyfin exposes key management under `/Auth/Keys`
  /// (mint via the `app=` query parameter) and lists them as an
  /// `AuthenticationInfoQueryResult` (`Items` array).
  ///
  /// Returns null outside user mode, for non-admin users, or when the server
  /// refuses key management — callers must then ask the user for a key.
  Future<String?> ensureApiKey({String appName = 'Arrmate'}) async {
    await _ensureAuthenticated();
    if (!_isUserMode || !_isAdministrator) {
      logger.debug(
        '[JellyfinService] API key management requires an administrator '
        'login (username:password)',
      );
      return null;
    }
    try {
      final existing = await _findApiKey(appName);
      if (existing != null) {
        logger.debug(
          '[JellyfinService] Reusing the existing "$appName" API key',
        );
        return existing;
      }
      await _request<void>(
        '/Auth/Keys',
        method: 'POST',
        queryParameters: {'app': appName},
      );
      logger.info('[JellyfinService] Created the "$appName" API key');
      return await _findApiKey(appName);
    } catch (e, st) {
      logger.warning('[JellyfinService] Could not ensure an API key', e, st);
      return null;
    }
  }

  /// Looks up an existing [appName] API key, or null when none exists.
  Future<String?> _findApiKey(String appName) async {
    final response = await _request<Map<String, dynamic>>('/Auth/Keys');
    final keys = response.data?['Items'];
    if (keys is! List) {
      return null;
    }
    for (final entry in keys) {
      if (entry is! Map) {
        continue;
      }
      final name = entry['AppName']?.toString();
      if (name != null && name.toLowerCase() == appName.toLowerCase()) {
        final token = entry['AccessToken']?.toString();
        if (token != null && token.isNotEmpty) {
          return token;
        }
      }
    }
    return null;
  }

  /// Reports playback progress (position and pause state) to Jellyfin.
  ///
  /// Fire-and-forget: failures are logged and never thrown to the caller.
  Future<void> reportPlaybackProgress({
    required String itemId,
    required String mediaSourceId,
    required Duration position,
    required bool isPaused,
  }) {
    return _reportPlayback(
      '/Sessions/Playing/Progress',
      itemId: itemId,
      mediaSourceId: mediaSourceId,
      position: position,
      isPaused: isPaused,
    );
  }

  /// Reports playback stopped at [position] to Jellyfin so resume points are
  /// kept in sync.
  ///
  /// Fire-and-forget: failures are logged and never thrown to the caller.
  Future<void> reportPlaybackStopped({
    required String itemId,
    required String mediaSourceId,
    required Duration position,
  }) {
    return _reportPlayback(
      '/Sessions/Playing/Stopped',
      itemId: itemId,
      mediaSourceId: mediaSourceId,
      position: position,
    );
  }

  /// POSTs one of the `/Sessions/Playing/*` events. Jellyfin ticks are
  /// 100 ns, hence `milliseconds * 10000`.
  ///
  /// No-op without [supportsProgressSync]: API-key sessions have no user
  /// scope, so watch-state writes would be attributed to an arbitrary
  /// account.
  Future<void> _reportPlayback(
    String path, {
    required String itemId,
    required String mediaSourceId,
    Duration? position,
    bool? isPaused,
  }) async {
    if (!supportsProgressSync) {
      logger.debug(
        '[JellyfinService] Skipping $path: API-key mode has no user scope '
        'for progress sync',
      );
      return;
    }
    try {
      // Acquires the access token + user id on the first report (no-op once
      // authenticated, and in modes without user scope).
      await _ensureAuthenticated();
      final userId = _userId;
      if (position != null) {
        // Durations are safe to log (no media content or credentials); the
        // reported seconds are what a later session resumes from.
        logger.debug(
          '[JellyfinService] Reporting $path at '
          '${position.inSeconds}s for item $itemId',
        );
      }
      await _request(
        path,
        method: 'POST',
        queryParameters: {if (userId != null) 'userId': userId},
        data: {
          'ItemId': itemId,
          'MediaSourceId': mediaSourceId,
          if (position != null)
            'PositionTicks': position.inMilliseconds * 10000,
          if (isPaused != null) 'IsPaused': isPaused,
        },
      );
    } catch (e, stackTrace) {
      logger.warning(
        '[JellyfinService] Playback report to $path failed',
        e,
        stackTrace,
      );
    }
  }
}
