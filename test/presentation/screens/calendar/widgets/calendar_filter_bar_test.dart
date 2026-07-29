import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/screens/calendar/providers/calendar_provider.dart';
import 'package:arrmate/presentation/screens/calendar/widgets/calendar_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('should expose and dispatch every calendar filter', (
    tester,
  ) async {
    // Given
    await tester.binding.setSurfaceSize(const Size(1400, 300));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final selectedInstances = <String?>[];
    CalendarMediaType? selectedMediaType;
    bool? onlyMonitored;
    bool? onlyPremieres;
    bool? hideSpecials;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarFilterBar(
            instances: [_instance()],
            filters: const CalendarFilters(),
            onInstanceChanged: selectedInstances.add,
            onMediaTypeChanged: (value) => selectedMediaType = value,
            onOnlyMonitoredChanged: (value) => onlyMonitored = value,
            onOnlyPremieresChanged: (value) => onlyPremieres = value,
            onHideSpecialsChanged: (value) => hideSpecials = value,
            onReset: () {},
          ),
        ),
      ),
    );

    // When
    await tester.tap(find.byKey(const ValueKey('calendar-instance-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remote').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('calendar-instance-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Any instance').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('calendar-media-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Series').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('calendar-monitored-filter')));
    await tester.tap(find.byKey(const ValueKey('calendar-premieres-filter')));
    await tester.tap(find.byKey(const ValueKey('calendar-specials-filter')));
    await tester.pump();

    // Then
    expect(selectedInstances, ['remote', null]);
    expect(selectedMediaType, CalendarMediaType.series);
    expect(onlyMonitored, isTrue);
    expect(onlyPremieres, isTrue);
    expect(hideSpecials, isTrue);
  });

  testWidgets('should display reset when any filter is active', (tester) async {
    // Given
    await tester.binding.setSurfaceSize(const Size(1400, 300));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var reset = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarFilterBar(
            instances: [_instance()],
            filters: const CalendarFilters(onlyMonitored: true),
            onInstanceChanged: (_) {},
            onMediaTypeChanged: (_) {},
            onOnlyMonitoredChanged: (_) {},
            onOnlyPremieresChanged: (_) {},
            onHideSpecialsChanged: (_) {},
            onReset: () => reset = true,
          ),
        ),
      ),
    );

    // When
    await tester.tap(find.byKey(const ValueKey('calendar-reset-filters')));

    // Then
    expect(reset, isTrue);
  });
}

Instance _instance() {
  return Instance(
    id: 'remote',
    type: InstanceType.sonarr,
    label: 'Remote',
    url: 'https://remote.example.com',
    apiKey: 'key',
  );
}
