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
      time: DateTime.tryParse(json['time']?.toString() ?? '') ?? DateTime.now(),
      level: json['level']?.toString() ?? '',
      logger: json['logger']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      exception: json['exception']?.toString(),
      exceptionType: json['exceptionType']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
    time,
    level,
    logger,
    message,
    exception,
    exceptionType,
  ];
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
    final recordsJson = json['records'];
    return LogPage(
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 50,
      totalRecords: json['totalRecords'] as int? ?? 0,
      records: recordsJson is List
          ? recordsJson
                .whereType<Map<String, dynamic>>()
                .map((e) => LogEntry.fromJson(e))
                .toList()
          : [],
    );
  }

  @override
  List<Object?> get props => [page, pageSize, totalRecords, records];
}
