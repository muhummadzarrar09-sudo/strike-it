# Streak It — Setup Guide

## Prerequisites

### 1. Flutter SDK >= 3.35.0
```powershell
flutter --version
# Download: https://docs.flutter.dev/get-started/install/windows
```

### 2. Android Studio + SDK
- SDK Platform 35, Build-Tools 35.0.0, Command-line Tools

### 3. JDK 17+
```powershell
java -version
# Download: https://adoptium.net/
```

### 4. Firebase CLI
```powershell
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
```

## Setup

### 1. Firebase Projects
Create TWO projects: `streak-it-dev` and `streak-it-prod`

For each:
```powershell
firebase use <project-id>
flutterfire configure --project=<project-id> --platforms=android --out=lib/core/services/firebase_options_<env>.dart
# Rename google-services.json: google-services-dev.json / google-services-prod.json
```

### 2. Enable Firebase Services
- **Authentication**: Google Sign-In provider + SHA-1 fingerprint
- **Firestore**: Create database
- **FCM**: Auto-enabled

### 3. SHA-1 Fingerprint
```powershell
cd android
.\gradlew signingReport
# Copy SHA-1 → Firebase Console → Project Settings → Add fingerprint
```

### 4. Run
```powershell
.\scripts\streak_it_build.ps1 doctor
.\scripts\streak_it_build.ps1 dev
.\scripts\streak_it_build.ps1 run
```

## Troubleshooting

| Issue | Fix |
|---|---|
| firebase_core not initialized | `flutter clean` + rebuild |
| google-services.json missing | Run `flutterfire configure` |
| Isar version mismatch | `dart run build_runner build --delete-conflicting-outputs` |
| minSdk too low | Set `minSdk = 24` in build.gradle.kts |
| Desugaring required | Enable in build.gradle.kts compileOptions |