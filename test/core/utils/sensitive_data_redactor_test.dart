import 'package:arrmate/core/utils/sensitive_data_redactor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SensitiveDataRedactor', () {
    test('should redact an IPv4 address', () {
      final redacted = SensitiveDataRedactor.redact(
        'Failed to connect to 192.168.1.10:7878',
      );
      expect(redacted, contains('[ip]'));
      expect(redacted, isNot(contains('192.168.1.10')));
    });

    test('should redact an IPv6 address', () {
      final redacted = SensitiveDataRedactor.redact(
        'Host fe80::1a2b:3c4d:5e6f reachable',
      );
      expect(redacted, contains('[ip]'));
      expect(redacted, isNot(contains('fe80::1a2b')));
    });

    test('should redact a host in a full URL', () {
      final redacted = SensitiveDataRedactor.redact(
        'GET https://radarr.example.com/api/v3/movie',
      );
      expect(redacted, isNot(contains('radarr.example.com')));
    });

    test('should redact a bare self-hosted service host', () {
      final redacted = SensitiveDataRedactor.redact(
        'Connection refused to sonarr.local',
      );
      expect(redacted, isNot(contains('sonarr.local')));
    });

    test('should redact a bearer token assignment', () {
      final redacted = SensitiveDataRedactor.redact(
        'Authorization: bearer abc123def456',
      );
      expect(redacted, contains('[token]'));
      expect(redacted, isNot(contains('abc123def456')));
    });

    test('should redact an api key assignment', () {
      final redacted = SensitiveDataRedactor.redact('apikey=supersecret123');
      expect(redacted, contains('[token]'));
      expect(redacted, isNot(contains('supersecret123')));
    });

    test('should leave non-sensitive text intact', () {
      const input = 'Resource not found.';
      expect(SensitiveDataRedactor.redact(input), input);
    });

    test('redactOptional should return null for null input', () {
      expect(SensitiveDataRedactor.redactOptional(null), isNull);
    });

    test('redactOptional should redact a non-null input', () {
      final redacted = SensitiveDataRedactor.redactOptional(
        'Timeout reaching 10.0.0.5',
      );
      expect(redacted, contains('[ip]'));
    });
  });
}
