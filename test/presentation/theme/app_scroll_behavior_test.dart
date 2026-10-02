import 'package:arrmate/presentation/theme/app_scroll_behavior.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('should drag scrollables with a mouse', () {
    const behavior = AppScrollBehavior();

    expect(behavior.dragDevices, contains(PointerDeviceKind.mouse));
    expect(behavior.dragDevices, contains(PointerDeviceKind.touch));
  });

  testWidgets('should refresh a short list from a mouse drag', (tester) async {
    var refreshes = 0;

    await tester.pumpWidget(
      const MaterialApp(
        scrollBehavior: AppScrollBehavior(),
        home: _ShortRefreshList(),
      ),
    );
    await tester.pump();

    final state = tester.state<_ShortRefreshListState>(
      find.byType(_ShortRefreshList),
    );
    state.onRefresh = () async {
      refreshes++;
    };

    final gesture = await tester.startGesture(
      const Offset(200, 120),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveBy(const Offset(0, 300));
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(refreshes, 1);
  });
}

class _ShortRefreshList extends StatefulWidget {
  const _ShortRefreshList();

  @override
  State<_ShortRefreshList> createState() => _ShortRefreshListState();
}

class _ShortRefreshListState extends State<_ShortRefreshList> {
  /// Completes when the indicator finishes a pull.
  Future<void> Function() onRefresh = () async {};

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => onRefresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [SizedBox(height: 80, child: Text('one row'))],
      ),
    );
  }
}
