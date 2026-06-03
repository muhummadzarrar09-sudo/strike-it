import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak_it/presentation/widgets/progress_ring.dart';

void main() {
  // Basic widget pump helper.
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('ProgressRing widget', () {
    testWidgets('renders without error at progress=0', (tester) async {
      await tester.pumpWidget(
        wrap(ProgressRing(
          progress: 0.0,
          color: Colors.blue,
          backgroundColor: Colors.grey,
        )),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without error at progress=1', (tester) async {
      await tester.pumpWidget(
        wrap(ProgressRing(
          progress: 1.0,
          color: Colors.green,
          backgroundColor: Colors.grey,
        )),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders child widget in center', (tester) async {
      await tester.pumpWidget(
        wrap(ProgressRing(
          progress: 0.5,
          color: Colors.purple,
          backgroundColor: Colors.grey,
          child: const Text('50'),
        )),
      );
      expect(find.text('50'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('clamps progress > 1.0 without error', (tester) async {
      await tester.pumpWidget(
        wrap(ProgressRing(
          progress: 2.5, // should clamp to 1.0
          color: Colors.orange,
          backgroundColor: Colors.grey,
        )),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('clamps progress < 0.0 without error', (tester) async {
      await tester.pumpWidget(
        wrap(ProgressRing(
          progress: -0.5, // should clamp to 0.0
          color: Colors.red,
          backgroundColor: Colors.grey,
        )),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('respects custom size', (tester) async {
      await tester.pumpWidget(
        wrap(ProgressRing(
          progress: 0.5,
          size: 120,
          strokeWidth: 10,
          color: Colors.teal,
          backgroundColor: Colors.grey,
        )),
      );
      final box = tester.getSize(find.byType(ProgressRing));
      expect(box.width, closeTo(120, 1));
      expect(box.height, closeTo(120, 1));
    });
  });
}
