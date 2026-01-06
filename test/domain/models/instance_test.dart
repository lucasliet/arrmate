import 'package:flutter_test/flutter_test.dart';
import 'package:arrmate/domain/models/instance/instance.dart';

void main() {
  group('Instance', () {
    test('authHeaders includes API key', () {
      final instance = Instance(apiKey: '12345');
      expect(instance.authHeaders, containsPair('X-Api-Key', '12345'));
    });

    test('authHeaders includes custom headers', () {
      final instance = Instance(
        apiKey: '12345',
        headers: [
          InstanceHeader(name: 'X-Custom-Auth', value: 'secret'),
          InstanceHeader(name: 'Authorization', value: 'Basic abc'),
        ],
      );

      final headers = instance.authHeaders;

      expect(headers, containsPair('X-Api-Key', '12345'));
      expect(headers, containsPair('X-Custom-Auth', 'secret'));
      expect(headers, containsPair('Authorization', 'Basic abc'));
    });

    test('InstanceHeader trims values', () {
      final header = InstanceHeader(name: ' Name ', value: ' Value ');
      expect(header.name, 'Name');
      expect(header.value, 'Value');
    });

    test('InstanceHeader removes colons from name', () {
      final header = InstanceHeader(name: 'X-Auth:', value: '123');
      expect(header.name, 'X-Auth');
    });

    group('Timeouts', () {
      test('Normal mode returns default timeouts', () {
        final instance = Instance(mode: InstanceMode.normal);

        expect(instance.timeout(InstanceTimeout.normal).inSeconds, 10);
        expect(instance.timeout(InstanceTimeout.slow).inSeconds, 10);
        expect(instance.timeout(InstanceTimeout.releaseSearch).inSeconds, 90);
      });

      test('Slow mode returns increased timeouts', () {
        final instance = Instance(mode: InstanceMode.slow);

        expect(instance.timeout(InstanceTimeout.normal).inSeconds, 10);
        // Should be 300s (5 mins) for slow operations
        expect(instance.timeout(InstanceTimeout.slow).inSeconds, 300);
        // Should be 180s (3 mins) for release search
        expect(instance.timeout(InstanceTimeout.releaseSearch).inSeconds, 180);
      });
    });
  });
}
