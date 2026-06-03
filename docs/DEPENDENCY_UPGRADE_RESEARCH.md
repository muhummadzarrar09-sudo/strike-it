# Dependency Upgrade Research
> Live data pulled: 2026-06-02. Read this before touching pubspec.yaml.

---

## Current vs Latest

| Package | Current | Latest | Bump Type | Risk |
|---|---|---|---|---|
| flutter_riverpod | 2.6.1 | 3.3.1 | 🔴 MAJOR | HIGH — StateProvider moved to legacy.dart |
| riverpod_annotation | 2.3.5 | 4.0.2 | 🔴 MAJOR | HIGH — must match riverpod |
| drift | 2.20.2 | 2.33.0 | 🟡 MINOR | LOW — additive only |
| drift_flutter | 0.2.2 | 0.3.0 | 🟡 MINOR | LOW |
| drift_dev | 2.20.2 | 2.33.0 | 🟡 MINOR | LOW |
| sqlite3_flutter_libs | 0.5.24 | 0.6.0+eol | 🔴 EOL | MEDIUM — package discontinued |
| go_router | 14.2.7 | 17.2.3 | 🔴 MAJOR | LOW — StatefulShellRoute API stable |
| fl_chart | 0.68.0 | 1.2.0 | 🔴 MAJOR | MEDIUM — API changes in 1.x |
| flutter_animate | 4.5.2 | 4.5.2 | ✅ UP TO DATE | — |
| flutter_local_notifications | 17.2.4 | 21.0.0 | 🔴 MAJOR | MEDIUM — minSdk bump, API changes |
| timezone | 0.9.4 | 0.11.0 | 🟡 MINOR | LOW |
| flutter_timezone | 4.1.0 | 5.1.0 | 🔴 MAJOR | LOW |
| local_auth | 2.3.0 | 3.0.1 | 🔴 MAJOR | LOW — minor API cleanup |
| uuid | 4.4.2 | 4.5.3 | 🟡 MINOR | LOW |
| intl | 0.19.0 | 0.20.2 | 🟡 MINOR | LOW |
| shared_preferences | 2.3.2 | 2.5.5 | 🟡 MINOR | LOW |
| share_plus | 10.0.2 | 13.1.0 | 🔴 MAJOR | MEDIUM — API refactor |
| permission_handler | 11.3.1 | 12.0.3 | 🔴 MAJOR | LOW — compileSdk 35 |
| build_runner | 2.4.12 | 2.15.0 | 🟡 MINOR | LOW |
| riverpod_generator | 2.4.3 | 4.0.3 | 🔴 MAJOR | HIGH — must match riverpod |
| flutter_lints | 4.0.0 | 6.0.0 | 🔴 MAJOR | LOW — stricter lint rules |
| mocktail | 1.0.4 | 1.0.5 | 🟡 MINOR | LOW |
| cupertino_icons | 1.0.8 | 1.0.9 | 🟡 MINOR | LOW |
| path_provider | 2.1.4 | 2.1.5 | 🟡 MINOR | LOW |

---

## Breaking Changes — Package by Package

### 🔴 flutter_riverpod 2.6.1 → 3.3.1

**What's breaking in our codebase:**
1. `StateProvider` moved to `package:flutter_riverpod/legacy.dart`
   - We use `StateProvider` in `habit_providers.dart` (`_todayDateProvider`, `onboardingDoneProvider`)
   - **Fix:** add `import 'package:flutter_riverpod/legacy.dart';` OR convert to `Notifier`
2. `AsyncValue.valueOrNull` removed → use `.value` instead
   - Search: `valueOrNull` — not used in our codebase
3. All providers now use `==` to filter updates (was `identical` for some)
   - Our `StreamProvider` usage for completions/habits — watch for silent deduplication bugs
4. `Ref` type parameter removed (e.g., `FutureProviderRef<T>` → just `Ref`)
   - We don't use typed Ref subclasses — safe
5. `riverpod_annotation` must match: 2.x → 4.x together
6. `riverpod_generator` must match: 2.x → 4.x together
   - **We don't use @riverpod codegen** — `riverpod_annotation` and `riverpod_generator` are UNUSED deps (BUILD-ARCH from earlier session). Can drop them entirely.

**Verdict:** Safe to upgrade. Main change: add legacy import for StateProvider.

---

### 🔴 go_router 14.2.7 → 17.2.3

**What's breaking:**
- 14→15: No public API breaks for StatefulShellRoute
- 15→16: Minor internal changes
- 16→17: `initialLocation` param renamed to `initialLocationIfNeeded` in `goBranch()`
  - **Fix:** `shell.goBranch(index, initialLocation: ...)` → `shell.goBranch(index, initialLocationIfNeeded: ...)`
  - We use this in `home_screen.dart` AppShell

**Verdict:** One rename. Easy.

---

### 🔴 fl_chart 0.68.0 → 1.2.0

**What's breaking (0.x → 1.x):**
- `BarChart`, `LineChart`, `PieChart` constructors changed — `data:` param no longer positional
- `FlTitlesData` fields may have renamed
- **Risk:** Our analytics screen uses `BarChart`, `BarChartData`, `BarChartRodData`, `FlTitlesData`
- Must check each widget construction

**Verdict:** Moderate. Need to verify analytics_screen.dart compiles.

---

### 🔴 flutter_local_notifications 17.2.4 → 21.0.0

**What's breaking:**
- `minSdkVersion` raised: our app already targets SDK 21, check if 21 is still OK in v21
- `AndroidScheduleMode.exactAllowWhileIdle` — verify still exists (it does as of 21.0)
- `uiLocalNotificationDateInterpretation` — still required
- No changes needed to our notification_service.dart per changelog review
- The `id` on `ActiveNotification` is now nullable — we don't use `getActiveNotifications()`

**Verdict:** No code changes needed. Just bump version.

---

### 🔴 share_plus 10.0.2 → 13.1.0

**What's breaking (10→13):**
- `Share.shareFiles()` removed → must use `Share.shareXFiles()` (we already use `shareXFiles`)
- `XFile` import path unchanged
- Constructor params unchanged

**Verdict:** We already migrated to `shareXFiles`. No changes needed.

---

### 🔴 local_auth 2.3.0 → 3.0.1

**What's breaking:**
- `AuthenticationOptions` constructor unchanged
- `BiometricType` enum unchanged
- `canCheckBiometrics` still exists
- Minor: some error codes may differ on specific Android OEMs

**Verdict:** No changes needed.

---

### 🔴 permission_handler 11.3.1 → 12.0.3

**What's breaking:**
- Updates `android/app/build.gradle` `compileSdkVersion` requirement to 35
- Our build.gradle uses `flutter.compileSdkVersion` (dynamic) — safe
- API unchanged

**Verdict:** No code changes. Build.gradle already flexible.

---

### sqlite3_flutter_libs 0.5.24 → 0.6.0+eol ⚠️ EOL

**Critical:** This package is **End of Life**. The maintainer has moved to `drift_flutter` 
which bundles SQLite natively. We already use `drift_flutter` — this means we can 
**remove `sqlite3_flutter_libs` entirely** and let `drift_flutter ^0.3.0` handle SQLite.

**Verdict:** Remove from pubspec. drift_flutter handles it.

---

### AGP / Gradle / Kotlin — Your Key Point

**You're right about built-in Kotlin:**
- AGP 8.11+ has built-in Kotlin support
- AGP 9.0 makes it required (removes separate KGP)
- We currently have: AGP 8.7.3, Gradle 8.10.2, Kotlin 2.1.0
- **Migration:** Remove `id "org.jetbrains.kotlin.android"` from `settings.gradle` plugin block
  and from `app/build.gradle` — AGP supplies Kotlin automatically
- **New versions:** AGP 8.11.1, Gradle 8.14, (Kotlin handled by AGP)
- **Java:** Keep Java 17 (our `~/.jdks/jdk-17`) — AGP 8.x still works with Java 17

---

## Migration Decision Matrix

| Package | Action | Effort |
|---|---|---|
| flutter_riverpod | Upgrade + add legacy import for StateProvider | 5 min |
| riverpod_annotation | **DROP** — we don't use codegen | — |
| riverpod_generator | **DROP** — we don't use codegen | — |
| drift + drift_flutter + drift_dev | Upgrade (additive only) | 2 min |
| sqlite3_flutter_libs | **REMOVE** — EOL, drift_flutter handles it | — |
| go_router | Upgrade + rename `initialLocation` → `initialLocationIfNeeded` | 2 min |
| fl_chart | Upgrade — verify analytics compiles | 10 min |
| flutter_local_notifications | Upgrade (no code changes) | 2 min |
| timezone | Upgrade | 1 min |
| flutter_timezone | Upgrade | 1 min |
| share_plus | Upgrade (already using shareXFiles) | 1 min |
| local_auth | Upgrade | 1 min |
| permission_handler | Upgrade | 1 min |
| intl, uuid, shared_prefs, path_provider | Upgrade | 1 min |
| build_runner | Upgrade | 1 min |
| flutter_lints | Upgrade | 1 min |
| mocktail, cupertino_icons | Upgrade | 1 min |
| AGP 8.7.3 → 8.11.1 | Upgrade settings.gradle + remove kotlin plugin | 5 min |
| Gradle 8.10.2 → 8.14 | Update gradle-wrapper.properties | 1 min |

---

## Files That Need Code Changes

1. `pubspec.yaml` — version bumps + remove dead deps
2. `android/settings.gradle` — AGP 8.11.1, remove KGP plugin
3. `android/gradle/wrapper/gradle-wrapper.properties` — Gradle 8.14
4. `android/app/build.gradle` — remove kotlin plugin from plugins block
5. `lib/presentation/providers/habit_providers.dart` — add legacy import for StateProvider
6. `lib/presentation/screens/home/home_screen.dart` — rename `initialLocation` → `initialLocationIfNeeded` in goBranch
7. `lib/presentation/screens/analytics/analytics_screen.dart` — verify fl_chart 1.x API compat

---

## What NOT to Upgrade This Pass

- Do NOT upgrade to go_router 17 `initialLocationIfNeeded` without checking all goBranch calls
- Do NOT upgrade riverpod to 3.x without the legacy import for StateProvider  
- Do NOT remove sqlite3_flutter_libs without confirming drift_flutter 0.3.0 bundles SQLite
- Keep Java 17 — AGP 8.11 supports it, AGP 9.0 will require Java 17+ anyway

---
