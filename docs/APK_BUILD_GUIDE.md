# StreakIt — APK Build Guide

This guide walks you through building the `.apk` from scratch on your machine.
**No prior Flutter experience required** — follow every step exactly.

---

## Step 1: Install Flutter

1. Go to **https://docs.flutter.dev/get-started/install/windows** (or Mac/Linux).
2. Download the Flutter SDK zip.
3. Extract to `C:\flutter` (Windows) or `~/flutter` (Mac/Linux).
4. Add `C:\flutter\bin` to your system `PATH`.
5. Verify install:
   ```bash
   flutter doctor
   ```
   Fix anything it flags (usually Android SDK + cmdline-tools).

---

## Step 2: Install Android Studio

1. Download from **https://developer.android.com/studio**.
2. During install, include:
   - Android SDK
   - Android SDK Command-line Tools
   - Android Emulator (optional, for testing)
3. Accept all SDK licenses:
   ```bash
   flutter doctor --android-licenses
   ```

---

## Step 3: Install Java 17

Flutter's build system requires Java 17+.
- Windows: Install from **https://adoptium.net/**
- Mac: `brew install openjdk@17`
- Set `JAVA_HOME` to the JDK folder.

---

## Step 4: Set Up the Project

```bash
# Clone or copy the project folder to your machine
cd streak_it

# Get dependencies
flutter pub get

# Run code generation (Drift ORM + Riverpod)
dart run build_runner build --delete-conflicting-outputs
```

> **If you see errors about Drift generated files** — that's expected until
> you run the build_runner command above. It generates the `.g.dart` files.

---

## Step 5: Add Font Files

The app uses **Inter** and **Space Grotesk** fonts.
Download and place them in `assets/fonts/`:

**Inter** (from https://fonts.google.com/specimen/Inter):
- `Inter-Regular.ttf`
- `Inter-Medium.ttf`
- `Inter-SemiBold.ttf`
- `Inter-Bold.ttf`

**Space Grotesk** (from https://fonts.google.com/specimen/Space+Grotesk):
- `SpaceGrotesk-Regular.ttf`
- `SpaceGrotesk-Medium.ttf`
- `SpaceGrotesk-SemiBold.ttf`
- `SpaceGrotesk-Bold.ttf`

---

## Step 6: Run on a Device / Emulator (Testing)

Connect an Android phone via USB with **Developer Mode** and **USB Debugging** on.

```bash
flutter devices        # Check your device shows up
flutter run            # Launch in debug mode
```

---

## Step 7: Build the Release APK

```bash
flutter build apk --release
```

The APK will be at:
```
build/app/outputs/flutter-apk/app-release.apk
```

**Transfer to your phone** via USB, WhatsApp, email, or Google Drive.
On the phone, tap the APK → Enable "Install from Unknown Sources" → Install.

---

## Step 8: (Optional) Build an App Bundle for Play Store

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

---

## Step 9: Signing (for Play Store distribution)

> Skip this for personal use — the debug key works for sideloading.

1. Generate a keystore:
   ```bash
   keytool -genkey -v -keystore streak_it.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias streak_it
   ```
2. Create `android/key.properties`:
   ```
   storePassword=YOUR_STORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=streak_it
   storeFile=../../streak_it.jks
   ```
3. Reference it in `android/app/build.gradle`.
4. Run `flutter build apk --release` again.

---

## Troubleshooting

| Error | Fix |
|---|---|
| `SDK not found` | Open Android Studio → SDK Manager → install SDK 34 |
| `Gradle build failed` | Run `flutter clean` then rebuild |
| `build_runner error` | Delete `.dart_tool/` and run build_runner again |
| `Could not find flutter` | Add Flutter to your system PATH |
| `minSdk too low` | Already set to 21 in our build.gradle |
