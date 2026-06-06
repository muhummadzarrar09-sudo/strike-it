import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options_dev.dart' as dev;
import 'firebase_options_prod.dart' as prod;

enum FirebaseEnvironment { dev, prod }

class FirebaseService {
  FirebaseService._();
  static FirebaseEnvironment currentEnv = FirebaseEnvironment.dev;

  static Future<void> init({FirebaseEnvironment env = FirebaseEnvironment.dev}) async {
    currentEnv = env;
    final options = env == FirebaseEnvironment.dev
        ? dev.DefaultFirebaseOptions.currentPlatform
        : prod.DefaultFirebaseOptions.currentPlatform;
    await Firebase.initializeApp(options: options);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    debugPrint('✅ Firebase initialized — ${env.name.toUpperCase()}');
  }

  static FirebaseApp get app => Firebase.app();
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseCrashlytics get crashlytics => FirebaseCrashlytics.instance;
  static User? get currentUser => auth.currentUser;
  static bool get isSignedIn => currentUser != null;
}