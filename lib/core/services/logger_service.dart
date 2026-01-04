import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AppLogEntry {
  final DateTime time;
  final Level level;
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;

  AppLogEntry({
    required this.time,
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
  });

  String toLogString() {
    final errStr = error != null ? '\nError: $error' : '';
    final stackStr = stackTrace != null ? '\nStackTrace: $stackTrace' : '';
    return '[${time.toIso8601String()}] ${level.name}: $message$errStr$stackStr';
  }
}

class LoggerService {
  late final Logger _logger;
  final List<AppLogEntry> _buffer = [];
  final _logController = StreamController<List<AppLogEntry>>.broadcast();
  File? _logFile;

  static const int _maxBufferSize = 100;

  LoggerService() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 0, // Simplified for brevity in file
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      level: kDebugMode ? Level.debug : Level.info,
    );
    _initFileLogger();
  }

  Future<void> _initFileLogger() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _logFile = File('${dir.path}/app_logs.txt');
      // Append a separator for new session
      await _logFile?.writeAsString(
        '\n--- SESSION STARTED AT ${DateTime.now()} ---\n',
        mode: FileMode.append,
      );
    } catch (e) {
      debugPrint('Error initializing file logger: $e');
    }
  }

  Stream<List<AppLogEntry>> get logStream => _logController.stream;
  List<AppLogEntry> get logs => List.unmodifiable(_buffer);

  void _addToBuffer(Level level, String message, [dynamic error, StackTrace? stackTrace]) {
    final entry = AppLogEntry(
      time: DateTime.now(),
      level: level,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
    
    _buffer.insert(0, entry);
    if (_buffer.length > _maxBufferSize) {
      _buffer.removeLast();
    }
    _logController.add(List.unmodifiable(_buffer));

    // Async write to file
    _logFile?.writeAsString(
      '${entry.toLogString()}\n',
      mode: FileMode.append,
    ).catchError((e) => debugPrint('Error writing to log file: $e'));
  }

  void debug(String message) {
    _logger.d(message);
    _addToBuffer(Level.debug, message);
  }

  void info(String message) {
    _logger.i(message);
    _addToBuffer(Level.info, message);
  }

  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
    _addToBuffer(Level.warning, message, error, stackTrace);
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
    _addToBuffer(Level.error, message, error, stackTrace);
  }
}

final logger = LoggerService();
