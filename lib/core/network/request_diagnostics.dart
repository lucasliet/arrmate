import 'dart:async';
import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

/// Sanitized metadata for one HTTP request made by Arrmate.
class RequestDiagnosticEntry extends Equatable {
  /// Identifier of the instance or service that originated the request.
  final String source;

  /// HTTP method used by the request.
  final String method;

  /// Request path without host, query parameters, headers, or body data.
  final String path;

  /// HTTP response status code when a response was received.
  final int? statusCode;

  /// Time when the request started.
  final DateTime startedAt;

  /// Total request duration.
  final Duration duration;

  /// Dio error category when the request failed.
  final String? errorType;

  const RequestDiagnosticEntry({
    required this.source,
    required this.method,
    required this.path,
    required this.startedAt,
    required this.duration,
    this.statusCode,
    this.errorType,
  });

  /// Whether the request completed with an HTTP success status.
  bool get isSuccessful =>
      statusCode != null && statusCode! >= 200 && statusCode! < 400;

  @override
  List<Object?> get props => [
    source,
    method,
    path,
    statusCode,
    startedAt,
    duration,
    errorType,
  ];
}

/// Stores a bounded stream of sanitized request diagnostics.
class RequestDiagnosticsRecorder {
  static const int _maximumEntries = 100;

  /// Shared recorder used by application HTTP clients.
  static final RequestDiagnosticsRecorder instance =
      RequestDiagnosticsRecorder();

  final ListQueue<RequestDiagnosticEntry> _entries = ListQueue();
  final StreamController<List<RequestDiagnosticEntry>> _controller =
      StreamController<List<RequestDiagnosticEntry>>.broadcast();

  /// Current entries ordered from newest to oldest.
  List<RequestDiagnosticEntry> get entries =>
      List.unmodifiable(_entries.toList());

  /// Emits whenever the diagnostics list changes.
  Stream<List<RequestDiagnosticEntry>> get stream => _controller.stream;

  /// Adds one sanitized request diagnostic.
  void record(RequestDiagnosticEntry entry) {
    _entries.addFirst(entry);
    while (_entries.length > _maximumEntries) {
      _entries.removeLast();
    }
    _controller.add(entries);
  }

  /// Removes all recorded request diagnostics.
  void clear() {
    _entries.clear();
    _controller.add(entries);
  }
}

/// Dio interceptor that records request timing and response metadata.
class RequestDiagnosticsInterceptor extends Interceptor {
  static const _startedAtKey = 'arrmate_request_started_at';

  final String source;
  final RequestDiagnosticsRecorder recorder;

  /// Creates an interceptor for the given diagnostic [source].
  RequestDiagnosticsInterceptor({
    required this.source,
    RequestDiagnosticsRecorder? recorder,
  }) : recorder = recorder ?? RequestDiagnosticsRecorder.instance;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedAtKey] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _record(response.requestOptions, statusCode: response.statusCode);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _record(
      err.requestOptions,
      statusCode: err.response?.statusCode,
      errorType: err.type.name,
    );
    handler.next(err);
  }

  void _record(RequestOptions options, {int? statusCode, String? errorType}) {
    final startedAt =
        options.extra[_startedAtKey] as DateTime? ?? DateTime.now();
    recorder.record(
      RequestDiagnosticEntry(
        source: source,
        method: options.method,
        path: _pathOnly(options.path),
        statusCode: statusCode,
        startedAt: startedAt,
        duration: DateTime.now().difference(startedAt),
        errorType: errorType,
      ),
    );
  }

  String _pathOnly(String path) {
    final uri = Uri.tryParse(path);
    if (uri == null || !uri.hasScheme) {
      return path.split('?').first;
    }
    return uri.path;
  }
}
