import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'google_token_store_io.dart';
import 'logger_service.dart';

/// Resolves the directory that holds the token file.
typedef TokenDirectoryResolver = Future<Directory> Function();

/// [GoogleTokenStore] that keeps the tokens in a JSON file readable only by
/// the current user, inside the app support directory.
///
/// Used on macOS instead of the keychain: the release build is ad-hoc signed,
/// so its designated requirement is the binary's cdhash. Every update changes
/// it, which voids the "Always Allow" granted to each keychain item and makes
/// macOS ask for the login password again on every read and write.
class FileGoogleTokenStore implements GoogleTokenStore {
  /// Name of the file that holds the tokens.
  static const String fileName = 'google_tokens.json';

  final TokenDirectoryResolver _resolveDirectory;
  Future<void> _pendingWrite = Future.value();

  /// Creates the store, optionally injecting the [resolveDirectory] used to
  /// locate the token file for tests.
  FileGoogleTokenStore({TokenDirectoryResolver? resolveDirectory})
    : _resolveDirectory = resolveDirectory ?? getApplicationSupportDirectory;

  @override
  Future<Map<String, String>> readAll() async {
    await _pendingWrite;
    return _readFile();
  }

  @override
  Future<void> save(Map<String, String> values) {
    return _enqueueWrite(() async {
      final merged = {...await _readFile(), ...values};
      await _writeFile(merged);
    });
  }

  @override
  Future<void> clear() {
    return _enqueueWrite(() async {
      final file = await _tokenFile();
      if (await file.exists()) {
        await file.delete();
      }
    });
  }

  /// Runs [write] after every write already queued, so concurrent saves never
  /// overwrite each other's keys.
  Future<void> _enqueueWrite(Future<void> Function() write) {
    final next = _pendingWrite.then((_) => write());
    _pendingWrite = next.catchError((_) {});
    return next;
  }

  Future<File> _tokenFile() async {
    final directory = await _resolveDirectory();
    return File(path.join(directory.path, fileName));
  }

  Future<Map<String, String>> _readFile() async {
    final file = await _tokenFile();
    if (!await file.exists()) {
      return {};
    }
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        throw FormatException('Expected a JSON object', decoded.toString());
      }
      return {
        for (final entry in decoded.entries)
          if (entry.value is String) entry.key: entry.value as String,
      };
    } on FormatException catch (error, stackTrace) {
      logger.error(
        '[FileGoogleTokenStore] Token file is not a JSON object, '
        'ignoring it: ${file.path}',
        error,
        stackTrace,
      );
      return {};
    }
  }

  /// Writes [values] to a private temporary file and renames it over the
  /// token file, so a crash never leaves a half-written file behind.
  Future<void> _writeFile(Map<String, String> values) async {
    final file = await _tokenFile();
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString('');
    await _restrictToOwner(temporary);
    await temporary.writeAsString(jsonEncode(values), flush: true);
    await temporary.rename(file.path);
  }

  Future<void> _restrictToOwner(File file) async {
    final result = await Process.run('chmod', ['600', file.path]);
    if (result.exitCode != 0) {
      logger.warning(
        '[FileGoogleTokenStore] chmod 600 failed '
        '(exit ${result.exitCode}): ${result.stderr}',
      );
    }
  }
}
