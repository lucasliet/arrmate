import 'package:arrmate/presentation/adaptive/window_class.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WindowClass', () {
    test('uses centralized boundary values', () {
      expect(WindowClass.fromWidth(599), WindowClass.compact);
      expect(WindowClass.fromWidth(600), WindowClass.medium);
      expect(WindowClass.fromWidth(899), WindowClass.medium);
      expect(WindowClass.fromWidth(900), WindowClass.expanded);
      expect(WindowClass.fromWidth(1439), WindowClass.expanded);
      expect(WindowClass.fromWidth(1440), WindowClass.large);
    });

    test('exposes navigation presentation', () {
      expect(WindowClass.compact.hasNavigationRail, isFalse);
      expect(WindowClass.medium.hasNavigationRail, isTrue);
      expect(WindowClass.medium.hasExtendedNavigation, isFalse);
      expect(WindowClass.expanded.hasExtendedNavigation, isTrue);
      expect(WindowClass.large.hasExtendedNavigation, isTrue);
    });
  });
}
