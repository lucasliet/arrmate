import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';

import '../../domain/models/models.dart';
import '../network/api_error.dart';
import '../network/request_diagnostics.dart';
import '../utils/sensitive_data_redactor.dart';

/// Loads system status from a specific configured instance.
typedef InstanceStatusLoader =
    Future<InstanceStatus> Function(Instance instance);

/// Loads the network interfaces currently reported by the platform.
typedef ConnectivityLoader = Future<List<ConnectivityResult>> Function();

/// Result of one authenticated instance connectivity check.
class InstanceDiagnosticCheck extends Equatable {
  final String instanceId;
  final String instanceLabel;
  final InstanceType instanceType;
  final String endpointLabel;
  final String endpoint;
  final bool isSuccessful;
  final Duration duration;
  final String? version;
  final String? error;

  const InstanceDiagnosticCheck({
    required this.instanceId,
    required this.instanceLabel,
    required this.instanceType,
    required this.endpointLabel,
    required this.endpoint,
    required this.isSuccessful,
    required this.duration,
    this.version,
    this.error,
  });

  @override
  List<Object?> get props => [
    instanceId,
    instanceLabel,
    instanceType,
    endpointLabel,
    endpoint,
    isSuccessful,
    duration,
    version,
    error,
  ];
}

/// Complete result of a network and instance diagnostics run.
class SystemDiagnosticsSnapshot extends Equatable {
  final DateTime generatedAt;
  final List<String> networkInterfaces;
  final List<InstanceDiagnosticCheck> checks;

  const SystemDiagnosticsSnapshot({
    required this.generatedAt,
    required this.networkInterfaces,
    required this.checks,
  });

  /// Whether the platform reports an available network interface.
  bool get hasNetworkInterface => networkInterfaces.any(
    (interface) =>
        interface.trim().isNotEmpty && interface.toLowerCase() != 'none',
  );

  /// Whether every configured endpoint check failed.
  bool get areAllEndpointsUnavailable =>
      checks.isNotEmpty && checks.every((check) => !check.isSuccessful);

  /// Whether the platform reports no available network interface.
  bool get isOffline => !hasNetworkInterface;

  @override
  List<Object?> get props => [generatedAt, networkInterfaces, checks];
}

/// Runs authenticated connectivity checks against every instance URL.
class SystemDiagnosticsService {
  final ConnectivityLoader _loadConnectivity;
  final InstanceStatusLoader _loadStatus;
  final DateTime Function() _clock;

  SystemDiagnosticsService({
    ConnectivityLoader? loadConnectivity,
    required InstanceStatusLoader loadStatus,
    DateTime Function()? clock,
  }) : _loadConnectivity = loadConnectivity ?? Connectivity().checkConnectivity,
       _loadStatus = loadStatus,
       _clock = clock ?? DateTime.now;

  /// Tests all configured instance endpoints and returns a diagnostic snapshot.
  Future<SystemDiagnosticsSnapshot> run(List<Instance> instances) async {
    final connectivity = await _loadConnectivity();
    final interfaces = connectivity.map((result) => result.name).toList();
    final checks = await Future.wait(instances.expand(_checksForInstance));

    return SystemDiagnosticsSnapshot(
      generatedAt: _clock(),
      networkInterfaces: interfaces,
      checks: checks,
    );
  }

  Iterable<Future<InstanceDiagnosticCheck>> _checksForInstance(
    Instance instance,
  ) {
    return instance.connectionUrls.map(
      (endpoint) => _checkEndpoint(instance, endpoint),
    );
  }

  Future<InstanceDiagnosticCheck> _checkEndpoint(
    Instance instance,
    String endpoint,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final status = await _loadStatus(_isolateEndpoint(instance, endpoint));
      stopwatch.stop();
      return InstanceDiagnosticCheck(
        instanceId: instance.id,
        instanceLabel: instance.label,
        instanceType: instance.type,
        endpointLabel: _endpointLabel(instance, endpoint),
        endpoint: endpoint,
        isSuccessful: true,
        duration: stopwatch.elapsed,
        version: status.version,
      );
    } catch (error) {
      stopwatch.stop();
      return InstanceDiagnosticCheck(
        instanceId: instance.id,
        instanceLabel: instance.label,
        instanceType: instance.type,
        endpointLabel: _endpointLabel(instance, endpoint),
        endpoint: endpoint,
        isSuccessful: false,
        duration: stopwatch.elapsed,
        error: _safeError(error),
      );
    }
  }

  String _endpointLabel(Instance instance, String endpoint) {
    final normalizedEndpoint = _normalizeEndpoint(endpoint);
    final primary = _normalizeEndpoint(instance.url);
    final alternative = instance.alternativeUrl == null
        ? null
        : _normalizeEndpoint(instance.alternativeUrl!);
    final active = _normalizeEndpoint(instance.effectiveUrl);

    if (normalizedEndpoint == active) {
      if (normalizedEndpoint == primary) {
        return 'Primary · Active';
      }
      if (normalizedEndpoint == alternative) {
        return 'Alternative · Active';
      }
      return 'Active';
    }
    if (normalizedEndpoint == primary) {
      return 'Primary';
    }
    return 'Alternative';
  }

  Instance _isolateEndpoint(Instance instance, String endpoint) {
    return Instance(
      id: instance.id,
      type: instance.type,
      mode: instance.mode,
      label: instance.label,
      url: endpoint,
      activeUrl: endpoint,
      apiKey: instance.apiKey,
      headers: instance.headers,
      rootFolders: instance.rootFolders,
      qualityProfiles: instance.qualityProfiles,
      tags: instance.tags,
      name: instance.name,
      version: instance.version,
    );
  }

  String _normalizeEndpoint(String endpoint) {
    return endpoint.trim().replaceFirst(RegExp(r'/+$'), '');
  }

  String _safeError(Object error) {
    if (error is ApiError) {
      return error.message;
    }
    return error.runtimeType.toString();
  }
}

/// Builds sanitized text reports from system diagnostics.
class DiagnosticReportBuilder {
  /// Builds a report that excludes credentials, headers, query values, and
  /// request or response bodies.
  String build({
    required SystemDiagnosticsSnapshot snapshot,
    required List<RequestDiagnosticEntry> requests,
    required String appVersion,
    required String buildNumber,
    required String platform,
    DateTime? imageCacheClearedAt,
  }) {
    final aliases = <String, String>{};
    for (final check in snapshot.checks) {
      aliases.putIfAbsent(
        check.instanceId,
        () => 'Instance ${aliases.length + 1}',
      );
    }

    final buffer = StringBuffer()
      ..writeln('Arrmate Diagnostic Report')
      ..writeln('Generated: ${snapshot.generatedAt.toIso8601String()}')
      ..writeln('App: $appVersion+$buildNumber')
      ..writeln('Platform: ${sanitize(platform)}')
      ..writeln('Network available: ${snapshot.hasNetworkInterface}')
      ..writeln(
        'All endpoints unavailable: ${snapshot.areAllEndpointsUnavailable}',
      )
      ..writeln('Network interfaces: ${snapshot.networkInterfaces.join(', ')}')
      ..writeln(
        'Image cache last cleared: '
        '${imageCacheClearedAt?.toIso8601String() ?? 'never'}',
      )
      ..writeln()
      ..writeln('Instance checks');

    if (snapshot.checks.isEmpty) {
      buffer.writeln('- No instances configured');
    }
    for (final check in snapshot.checks) {
      final alias = aliases[check.instanceId] ?? 'Instance';
      final outcome = check.isSuccessful
          ? 'OK ${check.duration.inMilliseconds}ms v${check.version}'
          : 'FAILED ${check.duration.inMilliseconds}ms ${check.error}';
      buffer.writeln(
        '- $alias ${check.instanceType.label} ${check.endpointLabel}: '
        '${sanitizeUrl(check.endpoint)} · ${sanitize(outcome)}',
      );
    }

    buffer
      ..writeln()
      ..writeln('Recent requests');
    if (requests.isEmpty) {
      buffer.writeln('- No request diagnostics recorded');
    }
    for (final request in requests.take(50)) {
      final source = aliases[request.source] ?? 'App service';
      final outcome =
          request.statusCode?.toString() ?? request.errorType ?? 'unknown';
      buffer.writeln(
        '- ${request.startedAt.toIso8601String()} $source '
        '${request.method} ${sanitize(request.path)} $outcome '
        '${request.duration.inMilliseconds}ms',
      );
    }

    return buffer.toString();
  }

  /// Removes common credential values and URL secrets from arbitrary text.
  String sanitize(String value) {
    var sanitized = value.replaceAllMapped(
      RegExp(
        r'(x-api-key|api[-_ ]?key|authorization|cookie|password|token|sid)'
        r'(\s*[:=]\s*)([^,\s}\]]+)',
        caseSensitive: false,
      ),
      (match) => '${match.group(1)}${match.group(2)}<redacted>',
    );
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'\b(bearer|basic)\s+[a-z0-9+/_=.-]+', caseSensitive: false),
      (match) => '${match.group(1)} <redacted>',
    );
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'https?://[^\s)\]}]+', caseSensitive: false),
      (match) => sanitizeUrl(match.group(0)!),
    );
    return SensitiveDataRedactor.redact(sanitized);
  }

  /// Returns a URL shape without user info, host, query, or fragment values.
  String sanitizeUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) {
      return '<redacted-url>';
    }
    final port = uri.hasPort ? ':${uri.port}' : '';
    final path = uri.path.isEmpty ? '/' : uri.path;
    return '${uri.scheme}://<redacted-host>$port$path';
  }
}
