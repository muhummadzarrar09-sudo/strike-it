# ═══════════════════════════════════════════════════════════
# STREAK IT — PROGUARD / R8 RULES
# ═══════════════════════════════════════════════════════════

# ━━━ FLUTTER ━━━
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ━━━ FIREBASE ━━━
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firebase Auth
-keepattributes Signature
-keepattributes *Annotation*

# ━━━ ISAR (Native bindings) ━━━
-keep class io.isar.** { *; }
-keep class com.isar.** { *; }
-dontwarn io.isar.**

# ━━━ BIOMETRIC (local_auth) ━━━
-keep class androidx.biometric.** { *; }
-dontwarn androidx.biometric.**

# ━━━ WORKMANAGER ━━━
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

# ━━━ TFLITE / LiteRT ━━━
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# ━━━ GENERAL ━━━
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-dontwarn javax.annotation.**
-dontwarn kotlin.Unit
-dontwarn retrofit2.KotlinExtensions
-dontwarn retrofit2.KotlinExtensions$*

# Keep data classes (models)
-keepclassmembers class * {
    <init>(...);
}

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
}