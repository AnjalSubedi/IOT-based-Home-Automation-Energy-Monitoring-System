// Widget tests for Home Energy Monitor app.

import 'package:flutter_test/flutter_test.dart';
import 'package:home_energy_monitor/main.dart';

void main() {
  testWidgets('App smoke test — app starts without crashing',
      (WidgetTester tester) async {
    // Build our app and verify it starts without crashing
    await tester.pumpWidget(const HomeEnergyApp());
    // Just verify it pumps without throwing
    await tester.pump();
    // App should render at least one widget
    expect(find.byType(HomeEnergyApp), findsOneWidget);
  });
}
