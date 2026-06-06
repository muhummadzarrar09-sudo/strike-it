# ═══════════════════════════════════════════════════════════════════════════════
#   STREAK IT — MASTER BUILD SCRIPT
#   Runs everything: setup → code gen → tests → APK → on your phone
# ═══════════════════════════════════════════════════════════════════════════════
#
#   USAGE:
#     .\build.ps1 setup    — First-time: downloads fonts, creates assets, checks env
#     .\build.ps1 dev      — Full pipeline: clean → deps → gen → analyze → test → APK
#     .\build.ps1 prod     — Same as dev but with production Firebase config
#     .\build.ps1 quick    — Fast build: just pub get + gen + APK (skip tests)
#     .\build.ps1 run      — Build & install on connected Android device
#     .\build.ps1 install  — Install last built APK to connected device
#     .\build.ps1 clean    — Nuclear clean
#     .\build.ps1 doctor   — Check environment
#     .\build.ps1 help     — Show this help
# ═══════════════════════════════════════════════════════════════════════════════

param(
    [Parameter(Position = 0)]
    [ValidateSet("setup", "dev", "prod", "quick", "run", "install", "clean", "doctor", "help")]
    [string]$Target = "help"
)

$ErrorActionPreference = "Continue"
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path "$ScriptRoot\.."
$BuildDir = "$ProjectRoot\build"
$ApkDir = "$BuildDir\app\outputs\flutter-apk"
$AabDir = "$BuildDir\app\outputs\bundle\release"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# COLORS & LOGGING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function Write-H { param($T) Write-Host "`n━━━ $T ━━━" -ForegroundColor Cyan }
function Write-S { param($T) Write-Host "  → $T" -ForegroundColor Gray }
function Write-OK { param($T) Write-Host "  ✅ $T" -ForegroundColor Green }
function Write-W { param($T) Write-Host "  ⚠️  $T" -ForegroundColor Yellow }
function Write-E { param($T) Write-Host "  ❌ $T" -ForegroundColor Red }
function Write-B { param($T) Write-Host "  🔥 $T" -ForegroundColor DarkRed }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# BANNER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function Show-Banner {
    Write-Host @"

     ███████╗████████╗██████╗ ███████╗ █████╗ ██╗  ██╗
     ██╔════╝╚══██╔══╝██╔══██╗██╔════╝██╔══██╗██║ ██╔╝
     ███████╗   ██║   ██████╔╝█████╗  ███████║█████╔╝
     ╚════██║   ██║   ██╔══██╗██╔══╝  ██╔══██║██╔═██╗
     ███████║   ██║   ██║  ██║███████╗██║  ██║██║  ██╗
     ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝

              DON'T BREAK THE CHAIN.
"@ -ForegroundColor Red
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# HELP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function Show-Help {
    Show-Banner
    Write-Host "USAGE: .\build.ps1 <command>`n" -ForegroundColor White
    Write-Host "COMMANDS:" -ForegroundColor Gray
    Write-Host "  setup    First-time setup (fonts, assets, env check, Firebase stub)"
    Write-Host "  dev      Full dev build (clean → deps → gen → test → APK + AAB)"
    Write-Host "  prod     Full prod build (same but switches to prod Firebase)"
    Write-Host "  quick    Fast build: skip tests, just APK"
    Write-Host "  run      Build + install on USB-connected Android device"
    Write-Host "  install  Install last APK to connected device"
    Write-Host "  clean    Nuclear clean (everything)"
    Write-Host "  doctor   Check environment (Flutter, Java, Android SDK)"
    Write-Host "  help     Show this help"
    Write-Host ""
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 0: ENVIRONMENT CHECK
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function Check-Env {
    Write-H "CHECKING ENVIRONMENT"

    # Flutter
    $flutterOut = flutter --version 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        Write-E "Flutter SDK not found. Install: https://docs.flutter.dev/get-started/install"
        Write-E "Then add Flutter to your PATH."
        exit 1
    }
    $flutterVer = ($flutterOut -split "`n")[0].Trim()
    Write-OK "Flutter: $flutterVer"

    # Java / JDK
    $javaOut = java -version 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        Write-E "Java/JDK not found. Install JDK 17+: https://adoptium.net/"
        exit 1
    }
    Write-OK "Java found"

    # Android SDK
    $androidHome = $env:ANDROID_HOME
    if (-not $androidHome) { $androidHome = $env:ANDROID_SDK_ROOT }
    $defaults = @("$env:LOCALAPPDATA\Android\Sdk", "$env:HOMEDRIVE\Android\Sdk", "C:\Android\Sdk")
    foreach ($d in $defaults) { if (Test-Path $d) { $androidHome = $d; break } }
    if ($androidHome) {
        Write-OK "Android SDK: $androidHome"
        $env:ANDROID_HOME = $androidHome
    } else {
        Write-W "ANDROID_HOME not set. APK build may fail."
    }

    Write-OK "Environment check passed."
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 1: CLEAN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function Invoke-Clean {
    Write-H "CLEANING"
    Set-Location $ProjectRoot
    flutter clean
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $BuildDir
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$ProjectRoot\.dart_tool"
    Write-OK "Clean complete."
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 2: SETUP (first-time)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function Invoke-Setup {
    Write-H "FIRST-TIME SETUP"
    Set-Location $ProjectRoot

    # Create asset directories
    $dirs = @(
        "assets\icons",
        "assets\images",
        "assets\fonts",
        "test\unit",
        "test\widget",
        "test\integration"
    )
    foreach ($d in $dirs) {
        $path = "$ProjectRoot\$d"
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
            Write-OK "Created: $d"
        }
    }

    # Create .gitkeep files so git tracks empty dirs
    foreach ($d in $dirs) {
        $gitkeep = "$ProjectRoot\$d\.gitkeep"
        if (-not (Test-Path $gitkeep)) {
            "" | Out-File -FilePath $gitkeep -Encoding UTF8
        }
    }

    # Create test files
    $testFiles = @{
        "test\unit\streak_engine_test.dart" = @'
import 'package:flutter_test/flutter_test.dart';
import 'package:streak_it/features/streaks/providers/streak_engine.dart';

void main() {
  group('StreakEngine', () {
    test('calculates current streak correctly', () {
      final today = DateTime.now();
      final dates = [
        today,
        today.subtract(const Duration(days: 1)),
        today.subtract(const Duration(days: 2)),
      ];
      expect(StreakEngine.calculateCurrentStreak(dates), 3);
    });

    test('broken streak returns 0', () {
      final today = DateTime.now();
      final dates = [
        today.subtract(const Duration(days: 2)),
      ];
      expect(StreakEngine.calculateCurrentStreak(dates), 0);
    });

    test('longest streak works', () {
      final today = DateTime.now();
      final dates = [
        today, today.subtract(const Duration(days: 1)),
        today.subtract(const Duration(days: 3)), today.subtract(const Duration(days: 4)),
      ];
      expect(StreakEngine.calculateLongestStreak(dates), 2);
    });

    test('isPendingToday works', () {
      expect(StreakEngine.isPendingToday(null), true);
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      expect(StreakEngine.isPendingToday(todayDate), false);
    });
  });
}
'@;
        "test\integration\app_test.dart" = @'
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:streak_it/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches successfully', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('STREAK IT'), findsOneWidget);
  });
}
'@;
    }

    foreach ($kv in $testFiles.GetEnumerator()) {
        $path = "$ProjectRoot\$($kv.Key)"
        if (-not (Test-Path $path)) {
            $kv.Value | Out-File -FilePath $path -Encoding UTF8
            Write-OK "Created: $($kv.Key)"
        }
    }

    Write-H "DOWNLOADING FONTS (Space Grotesk)"
    Write-S "Fonts will be downloaded by google_fonts at first launch."
    Write-S "You can also manually place .ttf files in assets/fonts/"
    Write-OK "Setup complete. Run: .\build.ps1 dev"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 3: DEPENDENCIES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function Install-Deps {
    Write-H "INSTALLING DEPENDENCIES"
    Set-Location $ProjectRoot
    flutter pub get
    if ($LASTEXITCODE -ne 0) { Write-E "flutter pub get failed"; exit 1 }
    Write-OK "Dependencies installed."
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 4: CODE GENERATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function Invoke-Gen {
    Write-H "CODE GENERATION"
    Set-Location $ProjectRoot

    # build_runner for Isar, Riverpod, Freezed, JSON
    Write-S "build_runner (Isar schemas, Riverpod, Freezed, JSON)..."
    dart run build_runner build --delete-conflicting-outputs 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-W "build_runner had issues. Retrying once more..."
        dart run build_runner build --delete-conflicting-outputs 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-W "Some code generation failed. This is OK for first build."
            Write-W "Run manually: dart run build_runner build --delete-conflicting-outputs"
        } else {
            Write-OK "Code generation complete (retry succeeded)."
        }
    } else {
        Write-OK "Code generation complete."
    }
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 5: ANALYZE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function Invoke-Analyze {
    Write-H "STATIC ANALYSIS"
    Set-Location $ProjectRoot
    flutter analyze 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-W "Analysis found issues. Review them. Continuing with build..."
    } else {
        Write-OK "No analysis issues."
    }
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 6: TESTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function Invoke-Tests {
    Write-H "RUNNING TESTS"
    Set-Location $ProjectRoot
    Write-S "Unit + widget tests..."
    flutter test 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-W "Some tests failed. Review before deploying."
    } else {
        Write-OK "All tests passed."
    }
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 7: FIREBASE SWITCH
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function Switch-Firebase {
    param([string]$Env)
    Write-H "FIREBASE CONFIG → $Env"
    Set-Location $ProjectRoot
    $src = "$ProjectRoot\android\app\google-services-$Env.json"
    $dest = "$ProjectRoot\android\app\google-services.json"

    if (Test-Path $src) {
        Copy-Item -Path $src -Destination $dest -Force
        Write-OK "Switched to $Env config."
    } else {
        Write-W "$src not found."
        Write-S "Run: flutterfire configure --project=streak-it-$Env --platforms=android"
        Write-S "Then rename google-services.json → google-services-$Env.json"
        Write-W "Continuing without Firebase config switch..."
    }
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 8: BUILD APK
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function Build-APK {
    Write-H "BUILDING APK"
    Set-Location $ProjectRoot

    Write-S "Building release APK (split per ABI)..."
    flutter build apk --release --split-per-abi 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-E "APK build failed!"
        Write-S "Common fixes:"
        Write-S "  1. Check Android SDK: flutter doctor --android-licenses"
        Write-S "  2. Isar code gen: dart run build_runner build --delete-conflicting-outputs"
        Write-S "  3. minSdk: Ensure android/app/build.gradle.kts has minSdk = 24"
        Write-S "  4. Desugaring: Ensure compileOptions has isCoreLibraryDesugaringEnabled = true"
        exit 1
    }

    Write-OK "APK built successfully."
    Write-B ""
    Write-B "APK FILES:"
    if (Test-Path $ApkDir) {
        Get-ChildItem $ApkDir -Filter "*.apk" | ForEach-Object {
            $sizeMB = [math]::Round($_.Length / 1MB, 1)
            Write-B "  $($_.Name)  ($sizeMB MB)"
        }
    }
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 9: BUILD AAB (Play Store)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function Build-AAB {
    Write-H "BUILDING APP BUNDLE"
    Set-Location $ProjectRoot
    Write-S "Building release AAB..."
    flutter build appbundle --release 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-W "AAB build failed. APK is still available."
    } else {
        Write-OK "AAB built."
        if (Test-Path $AabDir) {
            Get-ChildItem $AabDir -Filter "*.aab" | ForEach-Object {
                $sizeMB = [math]::Round($_.Length / 1MB, 1)
                Write-B "  $($_.Name)  ($sizeMB MB)"
            }
        }
    }
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 10: INSTALL ON DEVICE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function Install-OnDevice {
    Write-H "INSTALLING ON DEVICE"
    Set-Location $ProjectRoot

    # Find the arm64 APK (most common)
    $arm64Apk = "$ApkDir\app-arm64-v8a-release.apk"
    $armeabiApk = "$ApkDir\app-armeabi-v7a-release.apk"
    $allApk = "$ApkDir\app-release.apk"

    $apk = if (Test-Path $arm64Apk) { $arm64Apk }
           elseif (Test-Path $allApk) { $allApk }
           elseif (Test-Path $armeabiApk) { $armeabiApk }
           else { $null }

    if ($apk) {
        Write-S "Installing: $apk"
        adb install -r $apk 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-OK "Installed! Launching Streak It on your phone..."
            adb shell am start -n app.streakit.android/.MainActivity 2>&1
        } else {
            Write-W "Install failed. Is your phone connected via USB with debugging enabled?"
            Write-S "Try: adb devices"
        }
    } else {
        Write-W "No APK found. Run '.\build.ps1 dev' first."
        Write-S "Then run '.\build.ps1 install' to install."
    }
}

function Run-OnDevice {
    Write-H "BUILDING & RUNNING ON DEVICE"
    Set-Location $ProjectRoot
    Write-S "Building and installing..."
    flutter run --release 2>&1
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if ($Target -eq "help") { Show-Help; exit 0 }

Show-Banner
$sw = [System.Diagnostics.Stopwatch]::StartNew()
Write-Host "TARGET: $Target" -ForegroundColor DarkGray
Write-Host ""

switch ($Target) {
    "doctor"  { Check-Env }
    "clean"   { Invoke-Clean }
    "setup"   { Check-Env; Invoke-Setup }
    "install" { Install-OnDevice }
    "run"     { Check-Env; Install-Deps; Invoke-Gen; Run-OnDevice }
    "quick"   { Check-Env; Install-Deps; Invoke-Gen; Invoke-Analyze; Build-APK }

    "dev" {
        Check-Env; Invoke-Clean; Install-Deps; Invoke-Gen
        Invoke-Analyze; Invoke-Tests
        Switch-Firebase -Env "dev"
        Build-APK; Build-AAB
    }

    "prod" {
        Check-Env; Invoke-Clean; Install-Deps; Invoke-Gen
        Invoke-Analyze; Invoke-Tests
        Switch-Firebase -Env "prod"
        Build-APK; Build-AAB
    }
}

$sw.Stop()
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  DONE in $($sw.Elapsed.ToString('mm\:ss'))  —  DON'T BREAK THE CHAIN." -ForegroundColor White
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
