import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // User cancelled

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseService.auth.signInWithCredential(credential);

      if (context.mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: ${e.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: StreakItTheme.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Brand mark
              Text('STREAK IT', style: StreakItTheme.textTheme.displaySmall?.copyWith(color: StreakItTheme.accent)),
              const SizedBox(height: 8),
              Text('DON\'T BREAK THE CHAIN.', style: StreakItTheme.textTheme.labelMedium?.copyWith(color: StreakItTheme.mutedGray, letterSpacing: 3)),
              const SizedBox(height: 64),

              // Google Sign In
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _signInWithGoogle(context),
                  icon: const Icon(Icons.login),
                  label: const Text('CONTINUE WITH GOOGLE'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: StreakItTheme.darkGray, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Guest mode
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OR USE OFFLINE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: StreakItTheme.mutedGray)),
                ),
              ),

              const Spacer(),
              Text(
                'Your data stays on your device.\nSign in only if you want cloud backup.',
                style: StreakItTheme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}