import 'dart:async';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import '../../core/network/api_error.dart';
import '../../core/network/request_diagnostics.dart';
import '../../core/network/secure_log_interceptor.dart';
import '../../core/services/logger_service.dart';
import '../../domain/models/models.dart';

/// Service for interacting with qBittorrent API v2.
///
/// Supports three authentication modes, resolved from [Instance.apiKey]:
/// - **Cookie-based**: `username:password` format → form-based login + SID cookie.
/// - **API Key (≥v5.2.0)**: any non-empty value without `:` → `Authorization: Bearer`.
/// - **Custom header only**: empty value → relies solely on [Instance.headers]
///   (e.g. an `Authorization: Basic …` entry added via "Add Basic Auth" in
///   Advanced Settings) for both reverse proxies and direct WebUI access.
class QBittorrentService {
  final Instance instance;
  final Dio _dio;

  /// Cookie for session management. Not persisted in MVP.
  String? _sessionCookie;

  /// Whether authentication uses API key (Bearer token) instead of cookies.
  bool _isApiKey = false;

  /// Login currently in flight, shared by every request that needs a session.
  ///
  /// Parallel requests wait for the same login instead of each starting one:
  /// qBittorrent bans an IP after a few failed logins in a row.
  Future<void>? _loginInFlight;

  /// Set once the server refused the credentials.
  ///
  /// From then on every request fails with [UnauthorizedError] without logging
  /// in, so something that keeps retrying (a poll, several open screens) cannot
  /// pile up failed logins and get the IP banned. Only [allowAuthenticationRetry]
  /// clears it.
  bool _credentialsRefused = false;

  /// Lets the next request try to log in again after the credentials were
  /// refused.
  ///
  /// Meant for something the user did on purpose — opening the list, pressing
  /// retry or refresh. Editing the instance creates a new service, which starts
  /// clean.
  void allowAuthenticationRetry() => _credentialsRefused = false;

  /// Every candidate base URL that may be tried when the active one fails.
  final List<String> _candidateUrls;

  /// Base URL currently considered active. Promoted to a fallback only after
  /// that fallback answers successfully, so a fallback returning 401/500 never
  /// traps the client on it. Mirrors [ApiClient._activeBaseUrl].
  String _activeUrl;

  /// Set once the server answers the 5.0 start/stop endpoints with a 404, so
  /// a pre-5.0 instance is not probed on every action.
  bool _usesLegacyStartStop = false;

  QBittorrentService(this.instance, {Dio? dio})
    : _candidateUrls = instance.connectionUrls,
      _activeUrl = instance.connectionUrls.first,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: instance.effectiveUrl,
              connectTimeout: instance.timeout(InstanceTimeout.normal),
              receiveTimeout: instance.timeout(InstanceTimeout.normal),
              headers: {for (final h in instance.headers) h.name: h.value},
            ),
          ) {
    _dio.interceptors.add(SecureLogInterceptor());
    _dio.interceptors.add(RequestDiagnosticsInterceptor(source: instance.id));
    // Normalise baseUrl to match the active candidate URL so the
    // relative-path shortcut in [_resolvePath] works.
    _dio.options.baseUrl = _activeUrl;
  }

  /// Authenticates with the qBittorrent API.
  ///
  /// When [baseUrl] is provided the login POST targets that URL (via
  /// [_resolvePath]) instead of the default Dio base URL, which enables
  /// cookie-mode auth to follow the active failover candidate.
  ///
  /// Selection of mode based on [Instance.apiKey]:
  /// - Empty → no managed auth; requests fall back to [Instance.headers] only.
  /// - No `:` → Bearer API key (qBittorrent ≥v5.2.0), no login request.
  /// - `username:password` → form-based login, stores returned SID cookie.
  Future<void> authenticate({String? baseUrl}) async {
    if (instance.apiKey.isEmpty) {
      _isApiKey = false;
      logger.debug(
        '[QBittorrentService] No apiKey set; relying on custom headers only',
      );
      return;
    }
    if (!instance.apiKey.contains(':')) {
      _isApiKey = true;
      logger.debug('[QBittorrentService] Using API key authentication');
      return;
    }
    _isApiKey = false;

    final separatorIndex = instance.apiKey.indexOf(':');
    final username = instance.apiKey.substring(0, separatorIndex);
    final password = instance.apiKey.substring(separatorIndex + 1);

    logger.debug('[QBittorrentService] Authenticating as $username...');

    try {
      final loginPath = baseUrl != null
          ? _resolvePath('/api/v2/auth/login', baseUrl)
          : '/api/v2/auth/login';
      final response = await _dio.post(
        loginPath,
        data: FormData.fromMap({'username': username, 'password': password}),
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        final cookies = response.headers['set-cookie'];
        if (cookies != null && cookies.isNotEmpty) {
          final sidCookie = cookies.firstWhere(
            (c) => c.startsWith('SID=') || c.startsWith('QBT_SID'),
            orElse: () => '',
          );
          if (sidCookie.isNotEmpty) {
            _sessionCookie = sidCookie.split(';')[0];
            logger.debug('[QBittorrentService] Authentication successful');
            return;
          }
        }
        if (response.statusCode == 204 ||
            response.data.toString().contains('Ok.')) {
          logger.debug('[QBittorrentService] Auth Ok (No cookie returned)');
          return;
        }
      }

      // A rejected login comes back as `200 Fails.`, or as 401/403 once the IP
      // is banned. None of those carry anything worth showing, and the error
      // must never repeat the username or the URL.
      final status = response.statusCode;
      if (status == 200 || status == 204 || status == 401 || status == 403) {
        throw const UnauthorizedError();
      }
      throw DioException.badResponse(
        statusCode: status ?? 0,
        requestOptions: response.requestOptions,
        response: response,
      );
    } catch (e) {
      logger.error('[QBittorrentService] Auth error', e);
      rethrow;
    }
  }

  /// Ensures the client is ready to make authenticated requests.
  ///
  /// Stateless modes (API key or custom-header-only) require no preparation —
  /// this is a no-op for them. Cookie mode acquires a session if none is held.
  /// [currentUrl] is forwarded to [authenticate] so the login POST reaches the
  /// correct candidate when the service has failed over to an alternative URL.
  Future<void> _ensureAuthenticated({String? currentUrl}) async {
    if (_isApiKey) return;
    if (instance.apiKey.isEmpty) return;
    if (_sessionCookie == null) await _login(baseUrl: currentUrl);
  }

  /// Logs in, sharing one attempt between every caller that arrives while it
  /// runs, so they all see the same outcome.
  Future<void> _login({String? baseUrl}) async {
    final running = _loginInFlight;
    if (running != null) return running;
    if (_credentialsRefused) throw const UnauthorizedError();
    final login = authenticate(baseUrl: baseUrl);
    _loginInFlight = login;
    try {
      await login;
    } on UnauthorizedError {
      _credentialsRefused = true;
      rethrow;
    } finally {
      _loginInFlight = null;
    }
  }

  /// Replaces the session the server just rejected, at most once per
  /// rejection.
  ///
  /// Requests that were rejected together share a single login. A request that
  /// only now sees its 401/403, after another one already replaced the
  /// [rejectedCookie], simply reuses the new session.
  Future<void> _renewSession({
    required String? rejectedCookie,
    String? baseUrl,
  }) async {
    final running = _loginInFlight;
    if (running != null) return running;
    if (_sessionCookie != rejectedCookie) return;
    logger.warning('[QBittorrentService] Session expired, logging in again');
    _sessionCookie = null;
    await _login(baseUrl: baseUrl);
  }

  /// Whether this instance signs in with a username and password, the only
  /// mode in which a rejected request can be fixed by logging in again.
  bool get _usesCookieSession => instance.apiKey.contains(':');

  /// Whether [status] means the server refused the credentials.
  bool _isAuthRejected(int? status) => status == 401 || status == 403;

  /// Makes an authenticated request.
  ///
  /// Only a 2xx answer is a success. A rejected session (401/403) is renewed
  /// and the request retried once; if it is rejected again the call fails with
  /// [UnauthorizedError] and does not log in any further. Any other status
  /// throws a [DioException], so an action the server refused is never taken
  /// for one it performed.
  ///
  /// Safe read requests (GET) additionally fail over to the next candidate URL
  /// on a connection-level failure, mirroring [ApiClient]. Mutating requests
  /// never fail over: an add/pause/delete retried against an alternative host
  /// could duplicate side effects across distinct qBittorrent servers.
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
          '[QBittorrentService] Connection failed, retrying with an '
          'alternative instance URL',
        );
        currentUrl = nextUrl;
      }
    }
  }

  /// Runs a single authenticated attempt against a resolved path.
  ///
  /// The cookie/API-key state is shared across candidate URLs because each
  /// candidate points to the same logical server. The status of every answer
  /// is judged here rather than by the HTTP client, so the outcome does not
  /// depend on how that client was configured. The body is read untyped
  /// because a rejection comes as plain text (`Forbidden`), which cannot be
  /// cast to [T]; only a successful answer is converted.
  Future<Response<T>> _requestOnce<T>(
    String resolvedPath, {
    String method = 'GET',
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? currentUrl,
  }) async {
    await _ensureAuthenticated(currentUrl: currentUrl);

    Future<Response<dynamic>> send() {
      final base = options ?? Options();
      final headers = <String, dynamic>{...?base.headers};
      if (_isApiKey) {
        headers['Authorization'] = 'Bearer ${instance.apiKey}';
      } else if (_sessionCookie != null) {
        headers['Cookie'] = _sessionCookie;
      }
      return _dio.request<dynamic>(
        resolvedPath,
        // A form that was already sent cannot be sent again.
        data: data is FormData ? data.clone() : data,
        queryParameters: queryParameters,
        options: base.copyWith(
          method: method,
          headers: headers,
          validateStatus: (_) => true,
          responseType: _responseTypeFor<T>(base.responseType),
        ),
      );
    }

    final usedCookie = _sessionCookie;
    var response = await send();
    if (_isAuthRejected(response.statusCode)) {
      if (!_usesCookieSession) throw const UnauthorizedError();
      await _renewSession(rejectedCookie: usedCookie, baseUrl: currentUrl);
      response = await send();
      if (_isAuthRejected(response.statusCode)) {
        throw const UnauthorizedError();
      }
    }

    final status = response.statusCode;
    if (status != null && status >= 200 && status < 300) {
      return Response<T>(
        data: response.data as T?,
        requestOptions: response.requestOptions,
        headers: response.headers,
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
        isRedirect: response.isRedirect,
        redirects: response.redirects,
        extra: response.extra,
      );
    }
    throw DioException.badResponse(
      statusCode: status ?? 0,
      requestOptions: response.requestOptions,
      response: response,
    );
  }

  /// The response type Dio would pick for a request typed as [T].
  ///
  /// Requests are sent untyped, so this repeats Dio's own choice: plain text
  /// for [String], JSON otherwise, unless bytes or a stream were asked for.
  ResponseType? _responseTypeFor<T>(ResponseType? requested) {
    if (requested == ResponseType.bytes || requested == ResponseType.stream) {
      return requested;
    }
    return T == String ? ResponseType.plain : ResponseType.json;
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

  /// Gets the list of torrents.
  ///
  /// [filter] can be 'all', 'downloading', 'seeding', 'completed', 'paused', 'active', 'inactive', 'resumed', 'stalled', 'stalled_uploading', 'stalled_downloading', 'errored'.
  /// [sort] defaults to 'priority' to match qBittorrent's default queue order.
  Future<List<Torrent>> getTorrents({
    String filter = 'all',
    String sort = 'priority',
    bool reverse = true,
  }) async {
    try {
      final response = await _request<List>(
        '/api/v2/torrents/info',
        queryParameters: {
          'filter': filter,
          'sort': sort,
          'reverse': reverse.toString(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data!
            .map((json) => Torrent.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      logger.error('[QBittorrentService] Failed to get torrents', e);
      rethrow;
    }
  }

  /// Adds torrents via URLs (Magnet or HTTP).
  Future<void> addTorrentUrl(AddTorrentRequest request) async {
    if (request.urls == null) {
      throw Exception('URLs are required for addTorrentUrl');
    }

    try {
      final formData = FormData.fromMap(request.toFormFields());

      await _request('/api/v2/torrents/add', method: 'POST', data: formData);

      logger.info('[QBittorrentService] Added torrent via URL');
    } catch (e) {
      logger.error('[QBittorrentService] Failed to add torrent (URL)', e);
      rethrow;
    }
  }

  /// Adds torrent via .torrent file.
  Future<void> addTorrentFile(AddTorrentRequest request) async {
    if (request.torrentFilePath == null) {
      throw Exception('File path is required for addTorrentFile');
    }

    try {
      final formMap = request.toFormFields();

      // qBittorrent expects 'torrents' for file upload in API v2
      final formData = FormData.fromMap({
        'torrents': await MultipartFile.fromFile(
          request.torrentFilePath!,
          filename: p.basename(request.torrentFilePath!),
        ),
        ...formMap,
      });

      await _request('/api/v2/torrents/add', method: 'POST', data: formData);

      logger.info('[QBittorrentService] Added torrent via File');
    } catch (e) {
      logger.error('[QBittorrentService] Failed to add torrent (File)', e);
      rethrow;
    }
  }

  /// Pauses the specified torrents.
  ///
  /// [hashes] List of torrent hashes to pause.
  /// Throws if the API request fails.
  /// Returns a Future that completes when the action is acknowledged by the server.
  Future<void> pauseTorrents(List<String> hashes) {
    return _halt(
      hashes,
      path: '/api/v2/torrents/stop',
      legacyPath: '/api/v2/torrents/pause',
    );
  }

  /// Resumes the specified torrents.
  ///
  /// [hashes] List of torrent hashes to resume.
  /// Throws if the API request fails.
  /// Returns a Future that completes when the action is acknowledged by the server.
  Future<void> resumeTorrents(List<String> hashes) {
    return _halt(
      hashes,
      path: '/api/v2/torrents/start',
      legacyPath: '/api/v2/torrents/resume',
    );
  }

  /// Posts [hashes] to [path], retrying on [legacyPath] when the server does
  /// not serve it.
  ///
  /// qBittorrent 5 renamed `pause`/`resume` to `stop`/`start` and dropped the
  /// old names, while 4.x only ever had the old ones. A 404 or 405 means the
  /// request had no effect, so trying the other name cannot act twice.
  Future<void> _halt(
    List<String> hashes, {
    required String path,
    required String legacyPath,
  }) async {
    final data = {'hashes': hashes.join('|')};
    if (!_usesLegacyStartStop) {
      try {
        await _request(
          path,
          method: 'POST',
          data: data,
          options: Options(contentType: Headers.formUrlEncodedContentType),
        );
        return;
      } on DioException catch (error) {
        final status = error.response?.statusCode;
        if (status != 404 && status != 405) rethrow;
      }
      logger.info(
        '[QBittorrentService] $path is unavailable, falling back to the '
        'pre-5.0 endpoints',
      );
      _usesLegacyStartStop = true;
    }

    await _request(
      legacyPath,
      method: 'POST',
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  /// Deletes the specified torrents.
  ///
  /// [hashes] List of torrent hashes to delete.
  /// [deleteFiles] If true, also deletes the downloaded files on disk.
  /// Throws if the API request fails.
  /// Returns a Future that completes when the action is acknowledged by the server.
  Future<void> deleteTorrents(
    List<String> hashes, {
    bool deleteFiles = false,
  }) async {
    await _request(
      '/api/v2/torrents/delete',
      method: 'POST',
      data: {'hashes': hashes.join('|'), 'deleteFiles': deleteFiles.toString()},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  /// Rechecks the specified torrents.
  ///
  /// [hashes] List of torrent hashes to recheck.
  /// Throws if the API request fails.
  /// Returns a Future that completes when the action is acknowledged by the server.
  Future<void> recheckTorrents(List<String> hashes) async {
    await _request(
      '/api/v2/torrents/recheck',
      method: 'POST',
      data: {'hashes': hashes.join('|')},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  /// Tests connection and returns app version info.
  Future<Map<String, dynamic>> testConnection() async {
    // Get version — _request authenticates against the active candidate URL.
    final versionResp = await _request<String>('/api/v2/app/version');
    final apiVersionResp = await _request<String>('/api/v2/app/webapiVersion');

    return {
      'version': versionResp.data,
      'apiVersion': apiVersionResp.data,
      'status': 'Connected',
    };
  }

  /// Gets the list of files for a specific torrent.
  Future<List<TorrentFile>> getTorrentFiles(String hash) async {
    try {
      final response = await _request<List>(
        '/api/v2/torrents/files',
        queryParameters: {'hash': hash},
      );

      if (response.statusCode == 200 && response.data != null) {
        // The API returns a list of files without explicit indices, so we use the list index.
        return response.data!.asMap().entries.map((entry) {
          return TorrentFile.fromJson(
            entry.value as Map<String, dynamic>,
            entry.key,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      logger.error('[QBittorrentService] Failed to get torrent files', e);
      rethrow;
    }
  }

  /// Gets the announce trackers for a specific torrent.
  ///
  /// Calls `GET /api/v2/torrents/trackers`. The list also includes the DHT,
  /// PeX, and LSD rows qBittorrent reports alongside real announce URLs.
  /// Tracker URLs are not logged: private announce links can embed a passkey.
  Future<List<TorrentTracker>> getTorrentTrackers(String hash) async {
    try {
      final response = await _request<List>(
        '/api/v2/torrents/trackers',
        queryParameters: {'hash': hash},
      );

      if (response.statusCode == 200 && response.data != null) {
        return [
          for (final entry in response.data!)
            if (entry is Map<String, dynamic>)
              TorrentTracker.fromJson(entry)
            else if (entry is Map)
              TorrentTracker.fromJson(Map<String, dynamic>.from(entry)),
        ];
      }
      return [];
    } catch (e) {
      logger.error('[QBittorrentService] Failed to get torrent trackers', e);
      rethrow;
    }
  }

  /// Gets the list of peers connected to a specific torrent.
  ///
  /// Calls `GET /api/v2/sync/torrentPeers`, whose response nests a `peers` map
  /// keyed by "ip:port".
  Future<List<TorrentPeer>> getTorrentPeers(String hash) async {
    try {
      final response = await _request<Map<String, dynamic>>(
        '/api/v2/sync/torrentPeers',
        queryParameters: {'hash': hash},
      );

      if (response.statusCode == 200 && response.data != null) {
        final peersMap = response.data!['peers'];
        if (peersMap is! Map<String, dynamic>) return [];
        return peersMap.entries
            .map(
              (entry) => TorrentPeer.fromJson(
                entry.value as Map<String, dynamic>,
                entry.key,
              ),
            )
            .toList();
      }
      return [];
    } catch (e) {
      logger.error('[QBittorrentService] Failed to get torrent peers', e);
      rethrow;
    }
  }

  /// Sets the priority of files within a torrent.
  ///
  /// [hash] The torrent hash.
  /// [fileIndices] List of file indices to update.
  /// [priority] The new priority value (e.g., 0 for skip, 1 for normal, 6 for high).
  Future<void> setFilePriority(
    String hash,
    List<int> fileIndices,
    int priority,
  ) async {
    try {
      if (fileIndices.isEmpty) return;

      await _request(
        '/api/v2/torrents/filePrio',
        method: 'POST',
        data: {
          'hash': hash,
          'id': fileIndices.join('|'),
          'priority': priority.toString(),
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
    } catch (e) {
      logger.error('[QBittorrentService] Failed to set file priority', e);
      rethrow;
    }
  }

  /// Sets the download location for torrents.
  ///
  /// [hashes] List of torrent hashes.
  /// [location] The new absolute path.
  Future<void> setTorrentLocation(List<String> hashes, String location) async {
    if (location.trim().isEmpty) {
      throw Exception('Location path cannot be empty');
    }

    try {
      await _request(
        '/api/v2/torrents/setLocation',
        method: 'POST',
        data: {'hashes': hashes.join('|'), 'location': location},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
    } catch (e) {
      logger.error('[QBittorrentService] Failed to set torrent location', e);
      rethrow;
    }
  }

  /// Gets the system status including version information.
  Future<InstanceStatus> getSystemStatus() async {
    // _request authenticates against the active candidate URL, so this keeps
    // working after a failover instead of hitting the dead primary.
    final versionResp = await _request<String>('/api/v2/app/version');

    return InstanceStatus(
      appName: 'qBittorrent',
      instanceName: instance.label,
      version: versionResp.data ?? 'Unknown',
      authentication: 'Basic',
    );
  }

  /// Gets the list of categories.
  ///
  /// Returns a list of category names available in qBittorrent.
  Future<List<String>> getCategories() async {
    try {
      final response = await _request<Map<String, dynamic>>(
        '/api/v2/torrents/categories',
      );

      if (response.statusCode == 200 && response.data != null) {
        // API returns a map where keys are category names
        return response.data!.keys.toList();
      }
      return [];
    } catch (e, stackTrace) {
      logger.error(
        '[QBittorrentService] Failed to get categories',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Gets the list of tags.
  ///
  /// Returns a list of tag names available in qBittorrent.
  Future<List<String>> getTags() async {
    try {
      final response = await _request<List>('/api/v2/torrents/tags');

      if (response.statusCode == 200 && response.data != null) {
        // API returns a list of tag names
        return response.data!.map((tag) => tag.toString()).toList();
      }
      return [];
    } catch (e, stackTrace) {
      logger.error('[QBittorrentService] Failed to get tags', e, stackTrace);
      rethrow;
    }
  }
}
