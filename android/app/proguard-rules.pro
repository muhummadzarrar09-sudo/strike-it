# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Drift (moor) rules
-keep class androidx.sqlite.** { *; }
-keep class org.sqlite.** { *; }

# Local auth (biometric)
-keep class androidx.biometric.** { *; }

# flutter_local_notifications
-keep class com.dexterous.** { *; }
-keep class android.app.** { *; }

# Gson (used by some packages)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**

# General Android safety
-dontwarn com.google.errorprone.annotations.**
