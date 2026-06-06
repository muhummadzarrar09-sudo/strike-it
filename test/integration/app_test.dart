import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:streak_it/main.dart' as app;

/// ═══════════════════════════════════════════════════════════════════
/// Integration Test — Full App Launch
///
/// Run: flutter test integration_test/app_test.dart
/// ═══════════════════════════════════════════════════════════════════

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Streak It Integration', () {
    testWidgets('app launches and shows initial screen', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      // Should show either onboarding or the app shell — both contain the brand
      expect(
        find.textContaining('STREAK'),
        findsWidgets,
      );
    });
  });
}
