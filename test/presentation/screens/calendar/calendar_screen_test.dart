import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/screens/calendar/calendar_screen.dart';
import 'package:arrmate/presentation/screens/calendar/providers/calendar_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('should show visible filters and partial instance failures', (
    tester,
  ) async {
    // Given
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    const failure = CalendarInstanceFailure(
      instanceId: 'remote',
      instanceType: InstanceType.sonarr,
      instanceLabel: 'Remote',
      message: 'Calendar data could not be loaded.',
    );

    // When
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          filteredCalendarProvider.overrideWithValue(
            const AsyncData<List<CalendarEvent>>([]),
          ),
          calendarLoadStatusProvider.overrideWithValue(
            const CalendarLoadStatus(failures: [failure]),
          ),
        ],
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Then
    expect(
      find.byKey(const ValueKey('calendar-partial-failure')),
      findsOneWidget,
    );
    expect(
      find.text('Remote (Sonarr): Calendar data could not be loaded.'),
      findsOneWidget,
    );
    expect(find.text('Instance: Any'), findsOneWidget);
    expect(find.text('All media'), findsOneWidget);
    expect(find.text('Monitored'), findsOneWidget);
    expect(find.text('Premieres'), findsOneWidget);
    expect(find.text('Hide specials'), findsOneWidget);
  });
}
