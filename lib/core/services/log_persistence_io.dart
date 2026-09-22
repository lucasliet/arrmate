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
  File? _file;
  final List<String> _pendingEntries = [];

  @override
  Future<void> initialize() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/app_logs.txt');
    await file.writeAsString(
      '\n--- SESSION STARTED AT ${DateTime.now()} ---\n',
      mode: FileMode.append,
    );
    _file = file;
    for (final entry in _pendingEntries) {
      await file.writeAsString('$entry\n', mode: FileMode.append);
    }
    _pendingEntries.clear();
  }

  @override
  Future<void> append(String entry) async {
    final file = _file;
    if (file == null) {
      _pendingEntries.add(entry);
      return;
    }
    await file.writeAsString('$entry\n', mode: FileMode.append);
  }
}
