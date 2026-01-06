import 'package:equatable/equatable.dart';

/// Represents a system health check warning or error.
class HealthCheck extends Equatable {
  final String source;
  final String type;
  final String message;
  final String wikiUrl;

  const HealthCheck({
    required this.source,
    required this.type,
    required this.message,
    required this.wikiUrl,
  });

  factory HealthCheck.fromJson(Map<String, dynamic> json) {
    return HealthCheck(
      source: json['source'] as String,
      type: json['type'] as String,
      message: json['message'] as String,
      wikiUrl: json['wikiUrl'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [source, type, message, wikiUrl];
}
