/// Utilities for redacting sensitive data (hosts, IP addresses, tokens) from
/// user-facing and diagnostic strings so instances and credentials never leak
/// into shared reports or logs.
class SensitiveDataRedactor {
  SensitiveDataRedactor._();

  /// HTTP or HTTPS URL, including optional user info, IPv6 authorities, paths,
  /// queries, and fragments.
  static final _url = RegExp(r'https?://[^\s<>"()]+', caseSensitive: false);

  /// IPv4 address pattern, e.g. `192.168.1.10`.
  static final _ipv4 = RegExp(r'\b(?:\d{1,3}\.){3}\d{1,3}(?::\d{1,5})?\b');

  /// Potential IPv6 value. Candidates are validated as URI hosts before being
  /// redacted so timestamps and other colon-separated text remain.
  static final _ipv6Candidate = RegExp(
    r'(^|[^0-9a-fA-F:])'
    r'(\[?(?:[0-9a-fA-F]{0,4}:){2,}[0-9a-fA-F]{0,4}\]?)'
    r'(?=$|[^0-9a-fA-F:])',
  );

  /// Bare fully qualified hostname, including local and internal domains.
  static final _bareDomain = RegExp(
    r'\b(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+'
    r'[a-z][a-z0-9-]{1,62}\b',
    caseSensitive: false,
  );

  /// Single-label hostname following common network-error context.
  static final _hostInMessage = RegExp(
    r'''(\b(?:host(?:name)?\s+lookup\s*[:=]?\s*|'''
    r'''host(?:name)?\s*[:=]\s*|host(?:name)?\s+(?!lookup\b)|'''
    r'''endpoint\s*[:=]\s*|connect(?:ing)?\s+to\s+|'''
    r'''connection\s+(?:refused|failed)\s+(?:to|for)\s+|'''
    r'''reaching\s+)['"]?)([a-zA-Z0-9][a-zA-Z0-9.-]*)'''
    r'''(?=['"]?(?::\d{1,5})?(?:\b|$))''',
    caseSensitive: false,
  );

  /// Common self-hosted service names and localhost when they appear bare.
  static final _knownBareHost = RegExp(
    r'\b(localhost|radarr|sonarr|qbittorrent|lidarr|readarr|whisparr|prowlarr)'
    r'(?:[.\-][a-zA-Z0-9.\-]+)?\b',
    caseSensitive: false,
  );

  /// Credential assignments, authentication headers, and bearer/basic values.
  static final _token = RegExp(
    r'\b(?:bearer|basic)\s+\S+|'
    r'\b(?:authorization|x-api-key|api[-_]?key|apikey|token|password|'
    r'passkey|secret|cookie|set-cookie|sid|auth)'
    r'\s*[:=]\s*(?:(?:bearer|basic)\s+)?[^&,\s}\]]+',
    caseSensitive: false,
  );

  /// Returns [input] with every detected sensitive value replaced by a mask.
  static String redact(String input) {
    var result = input;
    result = result.replaceAllMapped(
      _url,
      (match) => _redactUrl(match.group(0)!),
    );
    result = result.replaceAll(_ipv4, '[ip]');
    result = result.replaceAllMapped(_ipv6Candidate, _redactIpv6Candidate);
    result = result.replaceAll(_bareDomain, '[host]');
    result = result.replaceAllMapped(
      _hostInMessage,
      (match) => '${match.group(1)}[host]',
    );
    result = result.replaceAll(_knownBareHost, '[host]');
    result = result.replaceAll(_token, '[token]');
    return result;
  }

  /// Returns [input] when it is non-null, otherwise `null`. Convenience for
  /// optional message fields.
  static String? redactOptional(String? input) {
    if (input == null) return null;
    return redact(input);
  }

  static String _redactUrl(String value) {
    try {
      final uri = Uri.tryParse(value);
      if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
        return '[url]';
      }

      final port = uri.hasPort ? ':${uri.port}' : '';
      final query = uri.hasQuery ? '?[redacted]' : '';
      final fragment = uri.hasFragment ? '#[redacted]' : '';
      return '${uri.scheme}://[host]$port${uri.path}$query$fragment';
    } on FormatException {
      return '[url]';
    }
  }

  static String _redactIpv6Candidate(Match match) {
    final prefix = match.group(1) ?? '';
    final candidate = match.group(2)!;
    final address = candidate.startsWith('[') && candidate.endsWith(']')
        ? candidate.substring(1, candidate.length - 1)
        : candidate;
    if (!_isIpv6Address(address)) {
      return match.group(0)!;
    }
    return '$prefix[ip]';
  }

  static bool _isIpv6Address(String address) {
    try {
      Uri.parse('http://[$address]');
      return true;
    } on FormatException {
      return false;
    }
  }
}
