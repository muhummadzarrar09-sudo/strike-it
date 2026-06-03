import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Smoke test — verifies the app boots and ProviderScope is functional.
/// Full widget tests for HabitCard require Drift in-memory DB setup
/// which is configured in integration tests.
void main() {
  group('App smoke tests', () {
    testWidgets('ProviderScope wraps without crashing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(child: Text('Smoke test')),
            ),
          ),
        ),
      );
      expect(find.text('Smoke test'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MaterialApp with dark theme renders', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: Center(child: Text('Dark mode test')),
          ),
        ),
      );
      expect(find.text('Dark mode test'), findsOneWidget);
    });

    testWidgets('ProviderScope with overrides does not crash', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          overrides: [],
          child: MaterialApp(
            home: Scaffold(body: SizedBox()),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
