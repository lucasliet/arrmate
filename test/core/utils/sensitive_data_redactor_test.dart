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

    test('should redact URL user info and a single-label host', () {
      final redacted = SensitiveDataRedactor.redact(
        'GET https://admin:secret@nas:7878/api/v3?auth=query-secret',
      );
      expect(redacted, contains('https://[host]:7878/api/v3?'));
      expect(redacted, isNot(contains('admin')));
      expect(redacted, isNot(contains('secret')));
      expect(redacted, isNot(contains('nas')));
    });

    test('should redact localhost in a URL', () {
      final redacted = SensitiveDataRedactor.redact(
        'GET http://localhost:8989/api/v3/system/status',
      );
      expect(redacted, contains('http://[host]:8989/api/v3/system/status'));
      expect(redacted, isNot(contains('localhost')));
    });

    test('should redact complete URL queries and fragments', () {
      final redacted = SensitiveDataRedactor.redact(
        'https://example.com/callback?auth_token=query-secret'
        '#access_token=fragment-secret',
      );
      expect(redacted, 'https://[host]/callback?[redacted]#[redacted]');
      expect(redacted, isNot(contains('query-secret')));
      expect(redacted, isNot(contains('fragment-secret')));
    });

    test('should redact user info and an IPv6 host in a URL', () {
      final redacted = SensitiveDataRedactor.redact(
        'GET https://admin:secret@[2001:db8::1]:7878/api/v3/status',
      );
      expect(redacted, contains('https://[host]:7878/api/v3/status'));
      expect(redacted, isNot(contains('admin')));
      expect(redacted, isNot(contains('secret')));
      expect(redacted, isNot(contains('2001:db8::1')));
    });

    test('should redact a bare self-hosted service host', () {
      final redacted = SensitiveDataRedactor.redact(
        'Connection refused to sonarr.local',
      );
      expect(redacted, isNot(contains('sonarr.local')));
    });

    test('should redact arbitrary bare and single-label hosts', () {
      final redacted = SensitiveDataRedactor.redact(
        "Failed host lookup: 'media.home.arpa'; connecting to nas",
      );
      expect(redacted, isNot(contains('media.home.arpa')));
      expect(redacted, isNot(contains('nas')));
    });

    test('should redact a mixed-case bare hostname', () {
      final redacted = SensitiveDataRedactor.redact(
        'Connection failed outside context: Media.Example',
      );
      expect(redacted, isNot(contains('Media.Example')));
      expect(redacted, contains('[host]'));
    });

    test(
      'should redact compressed IPv6 addresses without masking timestamps',
      () {
        final redacted = SensitiveDataRedactor.redact(
          'Hosts fe80::1 and [2001:db8::1] failed at 13:53:22',
        );
        expect(redacted, isNot(contains('fe80::1')));
        expect(redacted, isNot(contains('2001:db8::1')));
        expect(redacted, contains('13:53:22'));
      },
    );

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
