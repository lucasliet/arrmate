import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

class LoggerService {
  late final Logger _logger;

  LoggerService() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      level: kDebugMode ? Level.debug : Level.info,
    );
  }

  void debug(String message) => _logger.d(message);
  void info(String message) => _logger.i(message);
  void warning(String message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.w(message, error: error, stackTrace: stackTrace);
  void error(String message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}

final logger = LoggerService();
