import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Stores application logs outside the in-memory diagnostic buffer.
abstract interface class LogPersistence {
  /// Prepares the persistence implementation.
  Future<void> initialize();

  /// Appends one already-redacted log [entry].
  Future<void> append(String entry);
}

/// Creates the native file-backed persistence implementation.
LogPersistence createLogPersistence() => _FileLogPersistence();

class _FileLogPersistence implements LogPersistence {
  static const _maxPendingEntries = 100;

  File? _file;
  final List<String> _pendingEntries = [];
  bool _available = true;

  @override
  Future<void> initialize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/app_logs.txt');
      await file.writeAsString(
        '\n--- SESSION STARTED AT ${DateTime.now()} ---\n',
        mode: FileMode.append,
      );
      while (_pendingEntries.isNotEmpty) {
        final entry = _pendingEntries.removeAt(0);
        await file.writeAsString('$entry\n', mode: FileMode.append);
      }
      _file = file;
    } catch (_) {
      _pendingEntries.clear();
      _available = false;
      rethrow;
    }
  }

  @override
  Future<void> append(String entry) async {
    if (!_available) return;
    final file = _file;
    if (file == null) {
      if (_pendingEntries.length == _maxPendingEntries) {
        _pendingEntries.removeAt(0);
      }
      _pendingEntries.add(entry);
      return;
    }
    await file.writeAsString('$entry\n', mode: FileMode.append);
  }
}
