# ═══════════════════════════════════════════════════════════════════════════════
#   STREAK IT — CI QA VERIFICATION SCRIPT
#   Run this to verify every import chain, test, and path before building.
# ═══════════════════════════════════════════════════════════════════════════════
#
#   USAGE:
#     .\ci_verify.ps1           — Full QA: lint → test → path audit
#     .\ci_verify.ps1 -Quick    — Fast: path audit only
#     .\ci_verify.ps1 -Tests    — Run all tests only
# ═══════════════════════════════════════════════════════════════════════════════

param(
    [switch]$Quick,
    [switch]$Tests
)

$ErrorActionPreference = "Continue"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-H { param($T) Write-Host "`n━━━ $T ━━━" -ForegroundColor Cyan }
function Write-S { param($T) Write-Host "  → $T" -ForegroundColor Gray }
function Write-OK { param($T) Write-Host "  ✅ $T" -ForegroundColor Green }
function Write-W { param($T) Write-Host "  ⚠️  $T" -ForegroundColor Yellow }
function Write-E { param($T) Write-Host "  ❌ $T" -ForegroundColor Red }

$failures = 0

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 1. PATH AUDIT — Every import must resolve
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function Audit-Paths {
    Write-H "PATH AUDIT"

    $mustExist = @(
        "lib/main.dart",
        "lib/core/theme/app_theme.dart",
        "lib/core/constants/app_constants.dart",
        "lib/core/services/isar_service.dart",
        "lib/core/services/firebase_service.dart",
        "lib/core/services/firebase_options_dev.dart",
        "lib/core/services/firebase_options_prod.dart",
        "lib/core/services/notification_service.dart",
        "lib/core/services/biometric_service.dart",
        "lib/core/services/sync_service.dart",
        "lib/common/widgets/app_shell.dart",
        "lib/common/widgets/empty_state.dart",
        "lib/common/widgets/section_header.dart",
        "lib/features/habits/models/habit.dart",
        "lib/features/habits/models/habit.g.dart",
        "lib/features/habits/models/habit_checkin.dart",
        "lib/features/habits/models/habit_checkin.g.dart",
        "lib/features/habits/providers/habit_provider.dart",
        "lib/features/habits/screens/today_screen.dart",
        "lib/features/habits/screens/habits_list_screen.dart",
        "lib/features/habits/widgets/habit_card.dart",
        "lib/features/habits/widgets/add_habit_sheet.dart",
        "lib/features/streaks/providers/streak_engine.dart",
        "lib/features/streaks/providers/streak_provider.dart",
        "lib/features/streaks/widgets/streak_header.dart",
        "lib/features/streaks/widgets/heatmap_widget.dart",
        "lib/features/analytics/screens/analytics_screen.dart",
        "lib/features/journal/models/journal_entry.dart",
        "lib/features/journal/models/journal_entry.g.dart",
        "lib/features/journal/screens/journal_screen.dart",
        "lib/features/gamification/models/badge.dart",
        "lib/features/gamification/models/badge.g.dart",
        "lib/features/gamification/providers/gamification_provider.dart",
        "lib/features/ai_coach/providers/ai_coach_provider.dart",
        "lib/features/onboarding/providers/onboarding_provider.dart",
        "lib/features/onboarding/screens/onboarding_screen.dart",
        "lib/features/onboarding/screens/notification_permission_screen.dart",
        "lib/features/auth/models/user_profile.dart",
        "lib/features/auth/models/user_profile.g.dart",
        "lib/features/auth/screens/auth_screen.dart",
        "lib/features/auth/widgets/biometric_lock_screen.dart",
        "lib/features/widgets/providers/widget_service.dart",
        "android/app/build.gradle.kts",
        "android/settings.gradle.kts",
        "android/gradle/wrapper/gradle-wrapper.properties",
        "android/app/src/main/AndroidManifest.xml",
        "android/app/src/main/java/app/streakit/android/StreakItWidgetProvider.kt",
        "android/app/src/main/res/values/styles.xml",
        "android/app/src/main/res/values/strings.xml",
        "android/app/src/main/res/layout/streak_widget.xml",
        "android/app/src/main/res/layout/quick_check_widget.xml",
        "android/app/src/main/res/layout/progress_widget.xml",
        "android/app/src/main/res/xml/streak_widget_info.xml",
        "android/app/src/main/res/xml/quick_check_widget_info.xml",
        "android/app/src/main/res/xml/progress_widget_info.xml",
        "android/app/src/main/res/drawable/widget_preview_streak.xml",
        "android/app/src/main/res/drawable/widget_preview_quick.xml",
        "android/app/src/main/res/drawable/widget_preview_progress.xml",
        "android/app/proguard-rules.pro",
        "build.ps1",
        "pubspec.yaml",
        "analysis_options.yaml",
        ".gitignore",
        "test/unit/streak_engine_test.dart",
        "test/unit/xp_engine_test.dart",
        "test/unit/biometric_service_test.dart",
        "test/widget/theme_test.dart",
        "test/widget/shared_widgets_test.dart",
        "test/integration/app_test.dart",
        "docs/architecture/README.md",
        "docs/design/DESIGN_SYSTEM.md",
        "docs/setup/SETUP.md",
        "docs/setup/DEPENDENCIES.md"
    )

    foreach ($path in $mustExist) {
        $full = Join-Path $Root $path
        if (Test-Path $full) {
            Write-OK $path
        } else {
            Write-E "MISSING: $path"
            $failures++
        }
    }

    $total = $mustExist.Count
    Write-Host "`n  Path audit: $($total - $failures)/$total passed" -ForegroundColor $(if ($failures -eq 0) { "Green" } else { "Red" })
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 2. IMPORT CHAIN VERIFICATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function Audit-Imports {
    Write-H "IMPORT CHAIN VERIFICATION"

    $dartFiles = Get-ChildItem -Path "$Root/lib" -Filter "*.dart" -Recurse | Where-Object { $_.Name -notlike "*.g.dart" }

    foreach ($file in $dartFiles) {
        $content = Get-Content $file.FullName -Raw
        $imports = [regex]::Matches($content, "import '([^']+)'")

        foreach ($match in $imports) {
            $importPath = $match.Groups[1].Value

            # Skip package: imports (handled by pub get)
            if ($importPath.StartsWith("package:") -or $importPath.StartsWith("dart:")) {
                continue
            }

            # Resolve relative import
            $fileDir = Split-Path $file.FullName -Parent
            $resolved = Join-Path $fileDir $importPath -Resolve

            if (-not (Test-Path $resolved)) {
                Write-E "BROKEN IMPORT: $importPath`n   in: $($file.FullName)"
                $failures++
            }
        }
    }

    if ($failures -eq 0) { Write-OK "All imports resolve" }
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 3. PART DIRECTIVE AUDIT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function Audit-Parts {
    Write-H "PART DIRECTIVE AUDIT"

    $modelFiles = Get-ChildItem -Path "$Root/lib/features" -Recurse -Filter "*.dart" |
        Where-Object { $_.Name -like "*.dart" -and $_.Name -notlike "*.g.dart" }

    foreach ($file in $modelFiles) {
        $content = Get-Content $file.FullName -Raw
        $parts = [regex]::Matches($content, "part '([^']+.g.dart)'")

        foreach ($match in $parts) {
            $partName = $match.Groups[1].Value
            $partFile = Join-Path (Split-Path $file.FullName -Parent) $partName

            if (-not (Test-Path $partFile)) {
                Write-E "MISSING PART: $partName`n   in: $($file.FullName)"
                $failures++
            }
        }
    }

    if ($failures -eq 0) { Write-OK "All part files exist" }
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 4. RUN TESTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function Invoke-AllTests {
    Write-H "RUNNING ALL TESTS"
    Set-Location $Root

    Write-S "Unit tests..."
    $result = flutter test test/unit/ 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-OK "All unit tests passed"
    } else {
        Write-W "Unit test failures — review output above"
        $failures++
    }

    Write-S "Widget tests..."
    $result = flutter test test/widget/ 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-OK "All widget tests passed"
    } else {
        Write-W "Widget test failures — review output above"
        $failures++
    }
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Write-Host ""
Write-Host "  STREAK IT — CI QA VERIFICATION" -ForegroundColor White
Write-Host "  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor DarkGray
Write-Host ""

$sw = [System.Diagnostics.Stopwatch]::StartNew()

# Always audit paths
Audit-Paths
Audit-Parts
Audit-Imports

# Run tests unless -Quick
if (-not $Quick) {
    Invoke-AllTests
}

$sw.Stop()

Write-Host ""
if ($failures -eq 0) {
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "  ALL CHECKS PASSED — $($sw.Elapsed.ToString('mm\:ss'))" -ForegroundColor White
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
} else {
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host "  $failures FAILURES — $($sw.Elapsed.ToString('mm\:ss'))" -ForegroundColor Red
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Red
}
Write-Host ""