# SESSION MEMORY — Streak It
> CAD-RAG context file. Load THIS first, every session. Never scan the full codebase.
> Updated: 2026-06-03

---

## 🗺️ WHAT THIS PROJECT IS
Flutter Android habit tracker. Production APK built and installed on real device.
User: M. Zarrar (Karachi, Pakistan). Real user tester: Lazybizbabe (ADHD, 20+ apps experience).
Stack: Flutter 3.44 · Dart 3.12 · Drift SQLite · Riverpod 2.x · Go Router · Java 17 (Temurin, NOT system Java 25)

---

## 🏗️ FILE MAP (load ONLY what you need)
```
lib/
  core/
    theme/        → app_colors.dart · app_theme.dart · app_typography.dart
    constants/    → app_constants.dart · habit_icons.dart
    router/       → app_router.dart
    utils/        → date_utils.dart · extensions.dart · streak_calculator.dart
  data/
    database/     → app_database.dart + app_database.g.dart  ← NEVER delete .g.dart
      tables/     → habits · completions · tasks · moods
      daos/       → habits · completions · tasks · moods (each has .dart + .g.dart)
    repositories/ → habit_repository.dart · completion_repository.dart
  domain/         → notification_service.dart · xp_service.dart · achievement_service.dart · export_service.dart
  presentation/
    providers/    → database_providers.dart · habit_providers.dart · theme_provider.dart
    screens/      → home · habit_detail · add_edit_habit · analytics · achievements · settings · onboarding · splash
    widgets/      → habit_card · progress_ring · task_checklist · celebration_overlay
docs/             → SESSION_MEMORY.md ← YOU ARE HERE
                  → MISTAKE_LOG.md · USER_FEEDBACK.md · SPRINT_ROADMAP_V2.md
```

---

## ⚡ CAD-RAG PROTOCOL
Before each sprint:
1. Read **SESSION_MEMORY.md** (this file) — 2 min context load
2. Read **MISTAKE_LOG.md** — what NOT to do
3. Read **USER_FEEDBACK.md** — what the user actually needs
4. Load ONLY the specific `.dart` files the sprint touches
5. Never load all 47 dart files. Never.

After each sprint: append new mistakes to MISTAKE_LOG.md, update STATUS below.

---

## 🔴 HARD RULES — NEVER BREAK THESE

### Build rules
| Rule | Why |
|---|---|
| Write `.g.dart` files AND zip in ONE bash command, no gap | Workspace auto-deletes `*.g.dart` (BUILD-006) |
| Java = `~/.jdks/jdk-17`, NOT system Java 25 | Java 25 → Gradle fails (BUILD-007) |
| Always check major version jumps in `pub get` output | 1.x→4.x = broken Android API (BUILD-011) |
| Every DAO needs `import '../tables/xxx_table.dart'` directly | Circular import kills annotation processor (BUILD-005) |
| `drift/drift.dart show Value` needed in every file using `Value()` | Drift doesn't re-export it (BUILD-004) |

### Design rules (from Impeccable SKILL.md)
| Rule | Why |
|---|---|
| NO `border: Border.all()` + shadow on same element | Ghost card — absolute ban |
| NO gradient text (`background-clip: text`) | Decorative, never meaningful |
| NO cream/sand/beige backgrounds | AI default 2026 — instant tell |
| NO `border-radius > 16px` on cards | Over-rounding — AI tell |
| NO uppercase tracked eyebrow on EVERY section | AI grammar (one is voice, many is grammar) |
| Card elevation = background color contrast ONLY | No borders needed if bg contrast is right |
| Accent color = primary actions + state ONLY | Not decoration |
| 150–250ms transitions | Product rhythm — users in task flow |

### Flutter 3.44 / Dart 3.12 specific
| Rule | Why |
|---|---|
| `CardThemeData` not `CardTheme` | Renamed in 3.44 |
| `DialogThemeData` not `DialogTheme` | Renamed in 3.44 |
| `Icons.*` not `PhosphorIcons*` | phosphor_flutter extends `IconData` which is now `final` |
| `flutter_timezone: ^5.1.0` not `^4.1.0` | v5 returns `TimezoneInfo`, use `.identifier` |
| `local_auth: ^3.0.1` — no `const` on `AuthenticationOptions` | 3.x made constructor non-const |
| `local_auth: ^3.0.1` — no `options:` param on `authenticate()` | 3.x removed `options` parameter entirely |
| `go_router: ^17.3.0` — no `initialLocationIfNeeded` on `goBranch()` | 17.x removed the param |
| `flutter_local_notifications: ^21.0.0` — named params only | 21.x removed all positional overloads |
| `org.jetbrains.kotlin.android` version `2.3.21` in settings.gradle | share_plus-13.x needs Kotlin 2.2+; set explicitly to avoid compiler/stdlib mismatch |

---

## ✅ WHAT'S DONE (build passes, APK on device)

### Sprints 0–2 (original build)
- Full Drift DB schema: Habits, Completions, Tasks, Moods
- All DAOs, repositories, providers
- Home screen, habit detail, add/edit, analytics, achievements, settings
- Streak calculator (exponential smoothing), XP system, 20 achievements

### Sprint A — Notifications
- **Fixed:** hardcoded `tz.UTC` → now uses `FlutterTimezone.getLocalTimezone()`
- **Fixed:** missing `uiLocalNotificationDateInterpretation` in `zonedSchedule()`
- **Added:** "Test Notification" button in Settings (fires in 5 seconds)
- **Added:** 3 notification channels: reminders · alerts · celebrations

### Sprint B — Home screen redesign
- Streak number is the HERO (72px SpaceGrotesk Bold, violet)
- Layout: Greeting → 🔥 Streak number → slim progress bar → habits list
- Rationale: ADHD user — seeing progress first = motivation, seeing tasks first = overwhelm

### Sprint C — Typography
- `statHero` = 72px (was never this size before)
- `labelSmall` = 11px, 0.6 letter-spacing (section labels guide, don't shout)
- Full range: 11px captions ↔ 72px hero numbers = personality, not AI flatness

### Sprint D — Onboarding (full rewrite)
- Replaced: 3-page gradient carousel with animations
- Built: 3-step plain form → name → habit → reminder
- No gradients, no marketing copy, no entrance animations
- Suggestion chips for quick habit picks

### Redesign pass (Impeccable/shadcn/julianoczkowski inspired)
- Color system rebuilt: `#0C0C12` dark bg (blue-black), `#F7F7FA` light (cool white)
- Cards: background elevation only, no borders, no ghost cards
- Check button: solid fill circle, no border decoration
- Section label: "Habits" (not "TODAY'S HABITS" all-caps eyebrow)
- Full `AccentPalette` system: 6 colors, each with primary/light/fill variants

### Dependency Upgrade Pass — 2026-06-03 (Fixes batch)
- **local_auth 3.0.1** — removed `const` from AuthenticationOptions, removed `options:` param from `authenticate()`
- **GoRouter 17.3.0** — removed `initialLocationIfNeeded` from `goBranch()`
- **flutter_timezone 5.1.0** — `getLocalTimezone()` returns `TimezoneInfo` object; use `.identifier`
- **flutter_local_notifications 21.0.0** — all `show()`, `zonedSchedule()`, `initialize()` params changed from positional to named; removed `uiLocalNotificationDateInterpretation`
- **syntax fix** — habit_card.dart missing `)` on GestureDetector in nested ScaleTransition
- **import fix** — app.dart missing `database_providers.dart` import for `notificationServiceProvider`
- **Kotlin** — re-added `org.jetbrains.kotlin.android` version 2.3.21 to settings.gradle (share_plus-13 needs Kotlin 2.2+). Added `android.suppressKotlinVersionCompatibilityCheck=true` to gradle.properties

---

## 🔶 CURRENT STATUS

### APK
- **Build:** 🟡 IN PROGRESS (Kotlin 2.3.21 KGP added for share_plus compatibility)
- **Size:** ~64.7 MB (est.)
- **Location:** `build\app\outputs\flutter-apk\app-release.apk`

### Known issues to address next
| Issue | Priority | Sprint |
|---|---|---|
| Verify APK compiles after Kotlin KGP 2.3.21 fix | HIGH | F |
| Notifications: user needs to verify they fire correctly (test button exists) | HIGH | F |
| Onboarding: name entered during onboarding not yet displayed in home greeting | MEDIUM | F |
| Analytics screen: habit type cast is `dynamic` in one place | LOW | F |

---

## 🔧 BUILD ENVIRONMENT (M. Zarrar's machine)
```
OS:           Windows 11, project on D:\Streak it Mobile App
Flutter:      3.44.0 at C:\Users\M.Zarrar\flutter
Java:         Temurin 17 at C:\Users\M.Zarrar\.jdks\jdk-17
Android SDK:  C:\Users\M.Zarrar\AppData\Local\Android\Sdk
Gradle:       8.10.2
AGP:          8.7.3
Kotlin:       2.3.21   (org.jetbrains.kotlin.android in settings.gradle)
Min SDK:      21 (Android 5.0)
Target SDK:   36
App ID:       com.streakitapp.streak_it
```

### PowerShell build block (copy-paste ready)
```powershell
$env:PATH = "C:\Windows\System32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0;$env:PATH"
$env:JAVA_HOME = "$env:USERPROFILE\.jdks\jdk-17"
$env:PATH = "$env:JAVA_HOME\bin;$env:USERPROFILE\flutter\bin;$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest\bin;$env:LOCALAPPDATA\Android\Sdk\platform-tools;$env:PATH"
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
& "$env:USERPROFILE\flutter\bin\flutter.bat" config --jdk-dir "$env:USERPROFILE\.jdks\jdk-17" 2>&1 | Out-Null
$sdk = $env:ANDROID_HOME -replace "\\","\\"; $fl = "$env:USERPROFILE\flutter" -replace "\\","\\"
"sdk.dir=$sdk`nflutter.sdk=$fl`nflutter.buildMode=release`nflutter.versionName=1.0.0`nflutter.versionCode=1" | Set-Content "D:\Streak it Mobile App\android\local.properties"
Set-Location "D:\Streak it Mobile App"
flutter pub get
flutter build apk --release
$apk = "D:\Streak it Mobile App\build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apk) { Write-Host "SUCCESS! $apk" -ForegroundColor Green; Start-Process explorer.exe (Split-Path $apk) } else { Write-Host "Paste error here" -ForegroundColor Red }
```

---

## 📦 ZIP PROTOCOL (CRITICAL — BUILD-006)
```bash
# Write ALL .g.dart files AND zip in ONE command — never split them
cat > lib/data/database/daos/habits_dao.g.dart << 'EOF'
// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'habits_dao.dart';
mixin _$HabitsDaoMixin on DatabaseAccessor<AppDatabase> {
  $HabitsTable get habits => attachedDatabase.habits;
}
EOF
# ... (same for completions, tasks, moods)
# Then immediately:
rm -f streak_it.zip && zip -r streak_it.zip streak_it/ --exclude "streak_it/.dart_tool/*" --exclude "streak_it/build/*"
```

---

## 🎨 DESIGN SYSTEM SNAPSHOT
```
Aesthetic:    Dieter Rams (Functionalist) + Scandinavian warmth
Philosophy:   "Less but better. Every element earns its place."
Register:     Product (design SERVES the task, disappears into it)

Dark bg:      #0C0C12  (blue-black, intentional)
Dark surface: #16161F  (elevation via contrast, no border)
Dark border:  #252533  (structural dividers only)

Light bg:     #F7F7FA  (cool white, no warmth tint)
Light surface:#FFFFFF  (pure white)

Accent:       Violet #7C5CFC (default, user-selectable)
Success:      #10B981
Warning:      #F59E0B
Destructive:  #F43F5E

Type hero:    SpaceGrotesk 72px Bold  ← streak number
Type title:   Inter 16–17px SemiBold  ← habit names
Type body:    Inter 14px Regular      ← descriptions
Type label:   Inter 11px SemiBold     ← section markers
Type caption: Inter 11px Regular      ← timestamps, hints
```

---

## 🗂️ KEY DEPENDENCY VERSIONS (locked, tested working)
```yaml
flutter_riverpod: ^2.6.1
drift: ^2.20.2
drift_flutter: ^0.2.2
go_router: ^17.3.0
fl_chart: ^0.68.0
flutter_animate: ^4.5.0
flutter_local_notifications: ^21.0.0
timezone: ^0.9.4
flutter_timezone: ^5.1.0      ← 1.0.8 caused BUILD-011
local_auth: ^3.0.1
uuid: ^4.4.2
share_plus: ^10.0.2
shared_preferences: ^2.3.2
permission_handler: ^11.3.1
```

---

## 📋 NEXT SESSION CHECKLIST
Before writing any code next session:
- [ ] Read SESSION_MEMORY.md (this file) ✓
- [ ] Read MISTAKE_LOG.md
- [ ] Read USER_FEEDBACK.md
- [ ] Identify WHICH files the next sprint touches
- [ ] Load ONLY those files
- [ ] After changes: run `dart run build_runner build --delete-conflicting-outputs`
- [ ] Append new mistakes to MISTAKE_LOG.md
- [ ] Update STATUS section above
