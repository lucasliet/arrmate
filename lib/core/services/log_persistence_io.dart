import 'dart:async';
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
  final List<_PendingWrite> _pendingWrites = [];
  bool _available = true;
  bool _writing = false;

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
  Future<void> append(String entry) {
    if (!_available) return Future.value();
    final file = _file;
    if (file == null) {
      if (_pendingEntries.length == _maxPendingEntries) {
        _pendingEntries.removeAt(0);
      }
      _pendingEntries.add(entry);
      return Future.value();
    }
    final completer = Completer<void>();
    if (_pendingWrites.length == _maxPendingEntries) {
      _pendingWrites.removeAt(0).completer.complete();
    }
    _pendingWrites.add(_PendingWrite(entry, completer));
    unawaited(_drainWrites(file));
    return completer.future;
  }

  Future<void> _drainWrites(File file) async {
    if (_writing) return;
    _writing = true;
    try {
      while (_pendingWrites.isNotEmpty) {
        final pending = _pendingWrites.removeAt(0);
        try {
          await file.writeAsString('${pending.entry}\n', mode: FileMode.append);
          pending.completer.complete();
        } catch (error, stackTrace) {
          _available = false;
          pending.completer.completeError(error, stackTrace);
          for (final remaining in _pendingWrites) {
            remaining.completer.complete();
          }
          _pendingWrites.clear();
          return;
        }
      }
    } finally {
      _writing = false;
    }
  }
}

class _PendingWrite {
  _PendingWrite(this.entry, this.completer);

  final String entry;
  final Completer<void> completer;
}
