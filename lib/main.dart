import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait — deliberate UX decision.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Edge-to-edge rendering.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Everything else (notifications, XP load, DB init) is done
  // lazily inside providers and SplashScreen — keeps startup fast.
  runApp(
    const ProviderScope(
      child: StreakItApp(),
    ),
  );
}
