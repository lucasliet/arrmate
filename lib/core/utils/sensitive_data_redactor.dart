/// Utilities for redacting sensitive data (hosts, IP addresses, tokens) from
/// user-facing and diagnostic strings so instances and credentials never leak
/// into shared reports or logs.
class SensitiveDataRedactor {
  SensitiveDataRedactor._();

  /// IPv4 address pattern, e.g. `192.168.1.10`.
  static final _ipv4 = RegExp(r'\b(?:\d{1,3}\.){3}\d{1,3}(?::\d{1,5})?\b');

  /// IPv6 address pattern, covering common full and mixed forms.
  static final _ipv6 = RegExp(
    r'\b(?:[0-9a-fA-F]{1,4}:){2,7}[0-9a-fA-F]{1,4}\b',
  );

  /// Hostname in a URL context, e.g. `my-server.local` or `radarr.example.com`.
  static final _hostInUrl = RegExp(
    r'https?://([a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+)',
  );

  /// Bare hostnames commonly used for self-hosted servers, matched when they
  /// appear as known service prefixes.
  static final _bareHost = RegExp(
    r'\b(radarr|sonarr|qbittorrent|lidarr|readarr|whisparr|prowlarr)'
    r'(?:[.\-][a-zA-Z0-9.\-]+)?\b',
    caseSensitive: false,
  );

  /// Credential assignments and auth-header values: `apikey=secret`,
  /// `token: value`, or `bearer <value>`.
  static final _token = RegExp(
    r'\b(?:bearer\s+\S+|'
    r'(?:token|apikey|api[_-]?key|password|secret)\s*[:=]\s*\S+)',
    caseSensitive: false,
  );

  /// Returns [input] with every detected sensitive value replaced by a mask.
  static String redact(String input) {
    var result = input;
    result = result.replaceAllMapped(_hostInUrl, (match) {
      final host = match.group(1);
      return match.group(0)!.replaceFirst(host!, '[host]');
    });
    result = result.replaceAll(_ipv4, '[ip]');
    result = result.replaceAll(_ipv6, '[ip]');
    result = result.replaceAll(_bareHost, '[host]');
    result = result.replaceAll(_token, '[token]');
    return result;
  }

  /// Returns [input] when it is non-null, otherwise `null`. Convenience for
  /// optional message fields.
  static String? redactOptional(String? input) {
    if (input == null) return null;
    return redact(input);
  }
}
