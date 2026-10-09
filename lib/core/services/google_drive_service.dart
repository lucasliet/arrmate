import 'dart:convert';

import 'package:dio/dio.dart';

import 'google_auth.dart';
import 'logger_service.dart';

/// Metadata of the backup file stored in the Drive app data folder.
class DriveBackupInfo {
  /// Drive file identifier of the backup file.
  final String id;

  /// Last modification timestamp reported by Drive.
  final DateTime modifiedTime;

  const DriveBackupInfo({required this.id, required this.modifiedTime});
}

/// Talks to the Google Drive v3 REST API for the app's private backup file.
class GoogleDriveService {
  /// Name of the backup file inside the app data folder.
  static const backupFileName = 'arrmate-backup.json';

  static const _baseUrl = 'https://www.googleapis.com';

  final GoogleAccessTokenProvider _tokenProvider;
  final Dio _dio;

  /// Creates the service, obtaining access tokens from [tokenProvider].
  ///
  /// A [dio] instance can be injected for tests; by default a plain [Dio] with
  /// short connect and receive timeouts is created.
  GoogleDriveService({
    required GoogleAccessTokenProvider tokenProvider,
    Dio? dio,
  }) : _tokenProvider = tokenProvider,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 30),
             ),
           );

  /// Looks up the backup file inside the Drive app data folder.
  ///
  /// Returns the newest matching [DriveBackupInfo], or null when no backup has
  /// been uploaded yet.
  Future<DriveBackupInfo?> findBackupFile() async {
    final response = await _send(
      (token) => _dio.get<dynamic>(
        '$_baseUrl/drive/v3/files',
        queryParameters: {
          'spaces': 'appDataFolder',
          'q': "name = '$backupFileName'",
          'fields': 'files(id,modifiedTime)',
          'orderBy': 'modifiedTime desc',
          'pageSize': '1',
        },
        options: _authorizedOptions(token),
      ),
    );
    _ensureOk(response);
    final files = (response.data as Map)['files'] as List? ?? const [];
    if (files.isEmpty) {
      logger.debug(
        '[GoogleDriveService] No backup file found in appDataFolder',
      );
      return null;
    }
    final file = files.first as Map;
    logger.debug('[GoogleDriveService] Found backup file ${file['id']}');
    return DriveBackupInfo(
      id: file['id'] as String,
      modifiedTime: DateTime.parse(file['modifiedTime'] as String),
    );
  }

  /// Uploads [content] as the app backup file, overwriting the stored copy
  /// when it already exists or creating it on the first upload.
  ///
  /// Returns the [DriveBackupInfo] reported by Drive after the upload.
  Future<DriveBackupInfo> uploadBackup(String content) async {
    final existing = await findBackupFile();
    if (existing != null) {
      logger.info(
        '[GoogleDriveService] Updating existing backup file ${existing.id}',
      );
      final response = await _send(
        (token) => _dio.patch<dynamic>(
          '$_baseUrl/upload/drive/v3/files/${existing.id}',
          queryParameters: {'uploadType': 'media'},
          data: content,
          options: _authorizedOptions(token, contentType: 'application/json'),
        ),
      );
      _ensureOk(response);
      return _backupInfoFrom(response);
    }

    logger.info('[GoogleDriveService] Creating backup file in appDataFolder');
    final response = await _send(
      (token) => _dio.post<dynamic>(
        '$_baseUrl/upload/drive/v3/files',
        queryParameters: {'uploadType': 'multipart'},
        data: _multipartUpload(content),
        options: _authorizedOptions(token),
      ),
    );
    _ensureOk(response);
    return _backupInfoFrom(response);
  }

  /// Downloads the raw content of the stored backup file.
  ///
  /// Throws [DriveBackupNotFoundException] when no backup exists yet.
  Future<String> downloadBackup() async {
    final existing = await findBackupFile();
    if (existing == null) {
      logger.warning(
        '[GoogleDriveService] Download requested but no backup file exists',
      );
      throw const DriveBackupNotFoundException();
    }
    final response = await _send(
      (token) => _dio.get<dynamic>(
        '$_baseUrl/drive/v3/files/${existing.id}',
        queryParameters: {'alt': 'media'},
        options: _authorizedOptions(token, responseType: ResponseType.plain),
      ),
    );
    _ensureOk(response);
    return response.data as String;
  }

  FormData _multipartUpload(String content) {
    return FormData.fromMap({
      'metadata': MultipartFile.fromString(
        jsonEncode({
          'name': backupFileName,
          'parents': ['appDataFolder'],
        }),
        contentType: DioMediaType('application', 'json'),
      ),
      'file': MultipartFile.fromString(
        content,
        filename: backupFileName,
        contentType: DioMediaType('application', 'json'),
      ),
    });
  }

  Options _authorizedOptions(
    String token, {
    String? contentType,
    ResponseType? responseType,
  }) {
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
        if (contentType != null) Headers.contentTypeHeader: contentType,
      },
      validateStatus: (status) => status != null && status < 500,
      responseType: responseType,
    );
  }

  Future<Response<dynamic>> _send(
    Future<Response<dynamic>> Function(String token) request,
  ) async {
    try {
      var token = await _tokenProvider.getValidAccessToken();
      var response = token == null ? null : await request(token);

      if (token == null || _isUnauthorized(response)) {
        logger.warning(
          '[GoogleDriveService] Access token missing or rejected, refreshing',
        );
        token = await _tokenProvider.refreshAccessToken();
        if (token == null) {
          logger.error(
            '[GoogleDriveService] Token refresh produced no session',
          );
          throw const DriveAuthException();
        }
        response = await request(token);
      }

      if (response == null || _isUnauthorized(response)) {
        logger.error(
          '[GoogleDriveService] Request still unauthorized after refresh',
        );
        throw const DriveAuthException();
      }

      return response;
    } on DioException catch (error, stackTrace) {
      logger.error(
        '[GoogleDriveService] Request failed with status '
        '${error.response?.statusCode} for ${error.requestOptions.uri}',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  bool _isUnauthorized(Response<dynamic>? response) =>
      response?.statusCode == 401;

  void _ensureOk(Response<dynamic> response) {
    if (response.statusCode != 200) {
      logger.error(
        '[GoogleDriveService] Unexpected status ${response.statusCode} '
        'for ${response.requestOptions.uri}',
      );
      throw StateError(
        'Google Drive returned status ${response.statusCode} '
        'for ${response.requestOptions.uri}',
      );
    }
  }

  DriveBackupInfo _backupInfoFrom(Response<dynamic> response) {
    final data = response.data as Map;
    return DriveBackupInfo(
      id: data['id'] as String,
      modifiedTime: DateTime.parse(data['modifiedTime'] as String),
    );
  }
}

/// Thrown when a download is requested but no backup file exists in Drive.
class DriveBackupNotFoundException implements Exception {
  const DriveBackupNotFoundException();

  @override
  String toString() => 'No backup file found in Google Drive';
}

/// Thrown when Google Drive keeps rejecting the access token even after a
/// refresh, meaning the user has to sign in again.
class DriveAuthException implements Exception {
  const DriveAuthException();

  @override
  String toString() =>
      'Google Drive rejected the authorization; sign in again to restore access';
}
