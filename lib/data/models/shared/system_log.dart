import 'package:equatable/equatable.dart';

class LogEntry extends Equatable {
  final DateTime time;
  final String level;
  final String logger;
  final String message;
  final String? exception;
  final String? exceptionType;

  const LogEntry({
    required this.time,
    required this.level,
    required this.logger,
    required this.message,
    this.exception,
    this.exceptionType,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      time: DateTime.parse(json['time'] as String),
      level: json['level'] as String,
      logger: json['logger'] as String,
      message: json['message'] as String,
      exception: json['exception'] as String?,
      exceptionType: json['exceptionType'] as String?,
    );
  }

  @override
  List<Object?> get props => [time, level, logger, message, exception, exceptionType];
}

class LogPage extends Equatable {
  final int page;
  final int pageSize;
  final int totalRecords;
  final List<LogEntry> records;

  const LogPage({
    required this.page,
    required this.pageSize,
    required this.totalRecords,
    required this.records,
  });

  factory LogPage.fromJson(Map<String, dynamic> json) {
    return LogPage(
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      totalRecords: json['totalRecords'] as int,
      records: (json['records'] as List)
          .map((e) => LogEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [page, pageSize, totalRecords, records];
}
