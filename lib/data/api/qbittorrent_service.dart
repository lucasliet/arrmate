import 'dart:async';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import '../../core/services/logger_service.dart';
import '../../domain/models/models.dart';

/// Service for interacting with qBittorrent API v2.
///
/// Handles authentication (cookie-based), torrent management, and adding torrents.
class QBittorrentService {
  final Instance instance;
  final Dio _dio;

  // Cookie for session management. Not persisted in MVP.
  String? _sessionCookie;
  Completer<void>? _reauthCompleter;

  QBittorrentService(this.instance)
    : _dio = Dio(
        BaseOptions(
          baseUrl: instance.url,
          connectTimeout: instance.timeout(InstanceTimeout.normal),
          receiveTimeout: instance.timeout(InstanceTimeout.normal),
          validateStatus: (status) => status != null && status < 500,
        ),
      );

  /// Authenticates with the qBittorrent API.
  ///
  /// Uses Basic Auth parameters from [Instance.apiKey] (format: username:password).
  /// Stores the returned SID cookie for subsequent requests.
  Future<void> authenticate() async {
    // If a re-auth is already in progress via the completer triggered by a 403,
    // wait for it instead of starting a new one, unless we are the ones who started it.
    // However, for explicit calls to authenticate(), we usually want to force it.
    // For safety, let's just proceed with the logic but careful with the completer.
    // The completer is mainly for _request to coordinate retries.

    final separatorIndex = instance.apiKey.indexOf(':');
    if (separatorIndex == -1) {
      throw Exception('Invalid credentials format. Expected username:password');
    }

    final username = instance.apiKey.substring(0, separatorIndex);
    final password = instance.apiKey.substring(separatorIndex + 1);

    logger.debug('[QBittorrentService] Authenticating as $username...');

    try {
      final response = await _dio.post(
        '/api/v2/auth/login',
        data: FormData.fromMap({'username': username, 'password': password}),
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == 200) {
        // Extract SID cookie
        final cookies = response.headers['set-cookie'];
        if (cookies != null && cookies.isNotEmpty) {
          final sidCookie = cookies.firstWhere(
            (c) => c.startsWith('SID='),
            orElse: () => '',
          );
          if (sidCookie.isNotEmpty) {
            _sessionCookie = sidCookie.split(';')[0];
            logger.debug('[QBittorrentService] Authentication successful');
            return;
          }
        }
        // Even if no cookie returned, 200 "Ok." might mean already auth or no auth needed
        if (response.data.toString().contains('Ok.')) {
          logger.debug('[QBittorrentService] Auth Ok (No cookie returned)');
          return;
        }
      }

      if (response.statusCode == 403) {
        throw Exception('Invalid credentials (403)');
      }

      throw Exception(
        'Authentication failed: ${response.statusCode} - ${response.data}',
      );
    } catch (e) {
      logger.error('[QBittorrentService] Auth error', e);
      rethrow;
    }
  }

  /// Ensures user is authenticated before making a request.
  Future<void> _ensureAuthenticated() async {
    if (_sessionCookie == null) {
      // If re-auth is in progress, wait for it
      if (_reauthCompleter != null && !_reauthCompleter!.isCompleted) {
        await _reauthCompleter!.future;
      } else {
        await authenticate();
      }
    }
  }

  /// Helper to make authenticated requests with auto-retry on 401/403.
  Future<Response<T>> _request<T>(
    String path, {
    String method = 'GET',
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await _ensureAuthenticated();

    options ??= Options();
    if (_sessionCookie != null) {
      options.headers = {...(options.headers ?? {}), 'Cookie': _sessionCookie};
    }
    options.method = method;

    try {
      final response = await _dio.request<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      // Re-authenticate on 403 (Session expired)
      if (response.statusCode == 403) {
        // Check if re-auth is already happening
        if (_reauthCompleter != null) {
          logger.debug(
            '[QBittorrentService] 403 encountered, waiting for existing re-auth...',
          );
          await _reauthCompleter!.future;
          // Retry with new cookie
          if (_sessionCookie != null) {
            options.headers?['Cookie'] = _sessionCookie;
          }
          return await _dio.request<T>(
            path,
            data: data,
            queryParameters: queryParameters,
            options: options,
          );
        }

        _reauthCompleter = Completer();
        try {
          logger.warning(
            '[QBittorrentService] Session expired, re-authenticating...',
          );
          _sessionCookie = null;
          await authenticate();
          _reauthCompleter!.complete();

          // Retry
          if (_sessionCookie != null) {
            options.headers?['Cookie'] = _sessionCookie;
          }
          return await _dio.request<T>(
            path,
            data: data,
            queryParameters: queryParameters,
            options: options,
          );
        } catch (e) {
          _reauthCompleter!.completeError(e);
          rethrow;
        } finally {
          _reauthCompleter = null;
        }
      }

      return response;
    } catch (e) {
      // If error is 403 from DioException, logic is similar
      if (e is DioException && e.response?.statusCode == 403) {
        if (_reauthCompleter != null) {
          logger.debug(
            '[QBittorrentService] 403 (exception), waiting for existing re-auth...',
          );
          await _reauthCompleter!.future;
          if (_sessionCookie != null) {
            options.headers?['Cookie'] = _sessionCookie;
          }
          return await _dio.request<T>(
            path,
            data: data,
            queryParameters: queryParameters,
            options: options,
          );
        }

        _reauthCompleter = Completer();
        try {
          logger.warning(
            '[QBittorrentService] Session expired (DioException), re-authenticating...',
          );
          _sessionCookie = null;
          await authenticate();
          _reauthCompleter!.complete();

          if (_sessionCookie != null) {
            options.headers?['Cookie'] = _sessionCookie;
          }
          return await _dio.request<T>(
            path,
            data: data,
            queryParameters: queryParameters,
            options: options,
          );
        } catch (authError) {
          _reauthCompleter!.completeError(authError);
          rethrow;
        } finally {
          _reauthCompleter = null;
        }
      }
      rethrow;
    }
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

      // qBittorrent expects 'torrent_files' (API v2) or 'torrents' depending on version,
      // but 'torrent_files' is widely standard for multipart.
      final formData = FormData.fromMap({
        'torrent_files': await MultipartFile.fromFile(
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
  Future<void> pauseTorrents(List<String> hashes) async {
    await _request(
      '/api/v2/torrents/pause',
      method: 'POST',
      data: {'hashes': hashes.join('|')},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  /// Resumes the specified torrents.
  ///
  /// [hashes] List of torrent hashes to resume.
  /// Throws if the API request fails.
  /// Returns a Future that completes when the action is acknowledged by the server.
  Future<void> resumeTorrents(List<String> hashes) async {
    await _request(
      '/api/v2/torrents/resume',
      method: 'POST',
      data: {'hashes': hashes.join('|')},
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
    await authenticate();

    // Get version
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
    await _ensureAuthenticated();

    final versionResp = await _request<String>('/api/v2/app/version');

    return InstanceStatus(
      appName: 'qBittorrent',
      instanceName: instance.label,
      version: versionResp.data ?? 'Unknown',
      authentication: 'Basic',
    );
  }
}
