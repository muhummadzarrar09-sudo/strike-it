import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak_it/common/widgets/empty_state.dart';
import 'package:streak_it/core/theme/app_theme.dart';

/// ═══════════════════════════════════════════════════════════════════
/// Shared Widget Smoke Tests
/// ═══════════════════════════════════════════════════════════════════

void main() {
  group('EmptyState', () {
    Widget buildEmptyState({Widget? action}) {
      return ProviderScope(
        child: MaterialApp(
          theme: StreakItTheme.darkTheme,
          home: Scaffold(
            body: EmptyState(
              icon: Icons.bolt,
              title: 'TEST TITLE',
              subtitle: 'Test subtitle text',
              action: action,
            ),
          ),
        ),
      );
    }

    testWidgets('renders title and subtitle', (tester) async {
      await tester.pumpWidget(buildEmptyState());
      expect(find.text('TEST TITLE'), findsOneWidget);
      expect(find.text('Test subtitle text'), findsOneWidget);
    });

    testWidgets('renders action button when provided', (tester) async {
      await tester.pumpWidget(
        buildEmptyState(action: ElevatedButton(onPressed: () {}, child: const Text('ACTION'))),
      );
      expect(find.text('ACTION'), findsOneWidget);
    });

    testWidgets('does not render action when not provided', (tester) async {
      await tester.pumpWidget(buildEmptyState());
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('renders icon', (tester) async {
      await tester.pumpWidget(buildEmptyState());
      expect(find.byIcon(Icons.bolt), findsOneWidget);
    });
  });

  group('SectionHeader', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: StreakItTheme.darkTheme,
            home: Scaffold(
              body: Column(
                children: const [
                  SectionHeader(title: 'SECTION'),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.text('SECTION'), findsOneWidget);
    });
  });
}
