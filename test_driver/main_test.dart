import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('Arrmate App', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver.close();
    });

    test('starts and connects', () async {
      // Check if driver is properly connected
      final health = await driver.checkHealth();
      expect(health.status, HealthStatus.ok);
    });
  });
}
