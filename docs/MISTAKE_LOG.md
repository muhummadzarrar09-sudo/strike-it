# Streak It — Mistake Log
> Every bug we hit, what caused it, how we fixed it. Use this to avoid repeating.

---

## [BUILD-001] `phosphor_flutter` incompatible with Flutter 3.44 / Dart 3.12
- **Error:** `The class 'IconData' can't be extended outside of its library because it's a final class`
- **Cause:** Flutter 3.44 made `IconData` a `final class`. phosphor_flutter 2.1.0 extended it — illegal.
- **Fix:** Dropped phosphor_flutter entirely. Replaced all 76 icon refs with Flutter's built-in `Icons.*`

---

## [BUILD-002] Bad Python sed concatenation on icon names
- **Error:** `Icons.person_outlinedRun`, `Icons.edit_outlinedLine` — invalid icon names
- **Cause:** Sed replaced `PhosphorIconsRegular.personSimpleRun` → `Icons.person_outlined` + appended `Run` instead of replacing the whole thing
- **Fix:** Explicit string-by-string replacement in Python dict covering every icon

---

## [BUILD-003] `CardTheme` / `DialogTheme` → `CardThemeData` / `DialogThemeData`
- **Error:** `The argument type 'CardTheme' can't be assigned to the parameter type 'CardThemeData?'`
- **Cause:** Flutter 3.44 renamed these theme classes
- **Fix:** `sed -i 's/cardTheme: CardTheme(/cardTheme: CardThemeData(/g'`

---

## [BUILD-004] Missing `import 'package:drift/drift.dart' show Value'` in task_checklist.dart
- **Error:** `The method 'Value' isn't defined for the type '_TaskChecklistState'`
- **Cause:** Drift's `Value()` wrapper requires explicit import in every file that uses it
- **Fix:** Added `import 'package:drift/drift.dart' show Value;` at top of file

---

## [BUILD-005] DAOs missing direct table imports — `Undefined name 'Habits'`
- **Error:** `@DriftAccessor(tables: [Habits])` — `Habits` undefined
- **Cause:** Circular import chain: `app_database → habits_dao → app_database`. Annotation processor can't resolve `Habits` through the circle at compile time.
- **Fix:** Added direct table file imports to each DAO:
  ```dart
  import '../tables/habits_table.dart'; // in habits_dao.dart
  import '../tables/completions_table.dart'; // in completions_dao.dart
  // etc.
  ```

---

## [BUILD-006] `.g.dart` files excluded by workspace snapshot system
- **Error:** Files exist after writing, then disappear before next session
- **Cause:** Arena workspace auto-excludes files matching `*.g.dart` (generated file pattern)
- **Fix:** Write all `.g.dart` files AND zip immediately in the same bash command, no gap

---

## [BUILD-007] Java 25 incompatible with Gradle 8.x
- **Error:** `Unsupported class file major version 69`
- **Cause:** Class file version 69 = Java 25. No Gradle 8.x version supports Java 25 (confirmed by Gradle team issue #35111)
- **Fix:** Downloaded Java 17 (Temurin zip, no MSI) to `~/.jdks/jdk-17`. Used `flutter config --jdk-dir` to point Flutter at it. Gradle 8.10.2 is stable with Java 17.

---

## [BUILD-008] `assets/animations/` folder missing but referenced in pubspec
- **Error:** Build silently choked on missing asset directory
- **Fix:** Created dir with placeholder.json so Flutter asset bundler doesn't crash

---

## [BUILD-009] `phosphor_flutter ^2.2.0` doesn't exist on pub.dev
- **Error:** `version solving failed` — no versions matching ^2.2.0
- **Cause:** Tried to bump phosphor to a version that was never published
- **Fix:** Dropped the package entirely (see BUILD-001)

---

## [BUILD-010] Kotlin incremental cache cross-drive error (cosmetic)
- **Error:** `IllegalArgumentException: this and base files have different roots: C:\...pub\cache and D:\...project`
- **Cause:** Project on D:\ but pub cache on C:\ — Kotlin incremental compiler can't relativize paths across drives
- **Status:** Non-fatal. Build completes successfully despite the wall of stack traces. Safe to ignore.

---

## [RUNTIME-001] Notifications not firing on device
- **Error:** Reminders set in the app never arrive
- **Cause (suspected):** `uiLocalNotificationDateInterpretation` param missing from `zonedSchedule()` call in flutter_local_notifications 17.x. Also `tz.setLocalLocation(tz.UTC)` instead of actual device timezone.
- **Fix:** TBD in Sprint A (notification overhaul sprint)

---

---

## [SPRINT-A-001] flutter_timezone needed for real device timezone
- **Error:** Notifications scheduled at wrong time (UTC hardcoded)
- **Cause:** `tz.setLocalLocation(tz.UTC)` in notification_service.dart — hardcoded UTC
- **Fix:** Added `flutter_timezone: ^1.0.8` to pubspec. Now calls `FlutterTimezone.getLocalTimezone()` before `tz.setLocalLocation()`. Falls back to UTC gracefully if plugin fails.

## [SPRINT-A-002] Test notification button added to Settings
- **Fix:** `showTestNotification()` method added to NotificationService — fires in 5 seconds. New `_testNotification()` method + tile added to SettingsScreen.

## [SPRINT-B-001] Home screen redesigned — streak as hero
- **Change:** Replaced progress ring + habit list layout with: Greeting → Streak hero (72px number) → Progress bar → Habits.
- **Rationale:** User feedback — "streak should be d first thing that catches ur eye"

## [SPRINT-C-001] Typography scale — real contrast added
- **Change:** statHero bumped to 72px, section labels to 11px/0.8 tracking, clear separation between hero/title/body/caption tiers.

## [SPRINT-D-001] Onboarding stripped to 3-step plain form
- **Change:** Replaced 3-page gradient carousel with plain 3-step: name → habit → reminder. No animations, no gradients, no marketing copy.
- **Rationale:** "It looks obviously created by AI" / "Use no fancy things, just classic"

## [REDESIGN-001] Ghost card pattern removed — Impeccable absolute ban
- **Error:** Cards had `border: Border.all()` + could be combined with shadows — classic ghost card
- **Fix:** Cards now use background-color elevation only. No borders on cards.

## [REDESIGN-002] Section label "TODAY'S HABITS" — softened
- **Before:** All-caps, letterSpacing 1.4 on every section — AI eyebrow pattern
- **Fix:** "Habits" in titleSmall weight. One label, deliberate, not eyebrow grammar.

## [REDESIGN-003] Color system — no cream, no safe grey defaults
- **Before:** darkBackground #0F0F13 (generic), lightBackground #F8F8FC (near-cream)
- **Fix:** darkBackground #0C0C12 (blue-black with intent), lightBackground #F7F7FA (pure cool)

## [REDESIGN-004] Check button border removed
- **Before:** Circle with `border: Border.all()` when unchecked — ghost decoration
- **Fix:** Unchecked = subtle tint fill. Checked = solid fill. State is clear without borders.

## [BUILD-011] flutter_timezone 1.0.8 — removed v1 Android embedding
- **Error:** `Unresolved reference 'Registrar'` in FlutterTimezonePlugin.kt
- **Cause:** flutter_timezone 1.0.8 uses the old v1 Android plugin embedding API (`Registrar` class) which was removed in Flutter 3.24+. The breaking fix landed in flutter_timezone 4.0.0.
- **Fix:** Bumped `flutter_timezone: ^1.0.8` → `^4.1.0` in pubspec.yaml
- **Lesson:** Always check pub.dev "available" version shown during `pub get`. If it shows a MAJOR version jump (1.x → 4.x), it almost always means a breaking Android/iOS API change that affects Flutter version compatibility.

## [BUG-001] Onboarding habit never saved to DB
- **Error:** User types habit name in Step 1, taps "Let's go" → empty home screen
- **Cause:** `_finish()` only saved to SharedPreferences, never called `repo.createHabit()`
- **Fix:** Added `createHabit()` call in `_finish()` with correct defaults

## [BUG-002] Notification permission never requested
- **Error:** Android 13+ silently drops all notifications — `POST_NOTIFICATIONS` not granted
- **Cause:** `requestPermission()` existed but was called from zero places
- **Fix:** Called in `_initNotifications()` on splash, right after `initialise()`

## [BUG-003] Streak hero number stale after check-in
- **Error:** Tap checkmark → DB updates → hero stays at 0 until restart
- **Cause:** `habitStreakProvider` is a FutureProvider — computed once, not reactive
- **Fix:** Added `ref.invalidate(habitStreakProvider(widget.habit.id))` after toggle

## [BUG-004] Home greeting ignores user's name
- **Error:** "Good morning" shown even after user entered name in onboarding
- **Cause:** `_Greeting` was a StatelessWidget that never read SharedPreferences
- **Fix:** Converted to StatefulWidget, reads `'user_name'` from prefs in `initState()`

## [BUG-005] Onboarding reminder time discarded
- **Error:** User picks 8:00 AM reminder → no notification ever created
- **Cause:** `_reminderTime` captured in state but `_finish()` never used it
- **Fix:** `_finish()` now converts `TimeOfDay` to "HH:MM" string, passes to `createHabit()`, then calls `rescheduleAll()`

## [BUG-006] todayCompletionsProvider computed once — stale past midnight
- **Error:** Leave app open past midnight → all habits show as unchecked but query is still yesterday
- **Cause:** `StreakDateUtils.today()` called once at provider creation
- **Fix:** Added `_todayDateProvider` state; `todayCompletionsProvider` watches it. 
  Date change → provider re-runs query.

## [BUG-009] Nav bar stays on "Today" when pushing other screens
- **Error:** Tap Analytics → nav stays highlighted on Today
- **Cause:** Screens were `push`-ed not `go`-d, `_navIndex` never updated
- **Fix:** `_onNavTap` now calls `setState(() => _navIndex = index)` then uses `.then((_) => setState(() => _navIndex = 0))` on pop

## [COLOR-001] Neon AI color palette
- **Error:** Violet #7C5CFC (universal 2025 AI purple), Tailwind neon rainbow, purple heatmap glow
- **Fix:** Full color system rebuild — brand #4F5FD3 (muted indigo), 4 desaturated habit tones, muted semantics

## [COLOR-002] Renamed color constants not updated across all files
- **Error:** `Member not found: 'accentVioletPrimary'` in app_theme.dart + habit_card.dart
- **Cause:** app_colors.dart was rewritten with new names but app_theme.dart still had old ones
- **Fix:** `sed -i` replace across all dart files for every renamed constant
- **Rule:** After ANY rename in app_colors.dart, immediately run `grep -rn "OldName" lib/` before zipping

## [DEP-FIX-001] local_auth 3.0.1 — AuthenticationOptions not const
- **Error:** `'const' can't be used with 'AuthenticationOptions'`
- **Cause:** local_auth 3.x removed the const constructor from `AuthenticationOptions`
- **Fix:** Removed `const` keyword from `const AuthenticationOptions(biometricOnly: false)` in both app.dart and settings_screen.dart

## [DEP-FIX-002] local_auth 3.0.1 — options param removed from authenticate()
- **Error:** `The named parameter 'options' isn't defined`
- **Cause:** local_auth 3.x removed the `options:` parameter from `authenticate()` entirely
- **Fix:** Removed `options: AuthenticationOptions(biometricOnly: false),` from both `auth.authenticate()` calls in app.dart and settings_screen.dart

## [DEP-FIX-003] GoRouter 17.3.0 — goBranch dropped initialLocationIfNeeded
- **Error:** `The named parameter 'initialLocationIfNeeded' isn't defined`
- **Cause:** GoRouter 17.x removed `initialLocationIfNeeded` from `goBranch()` entirely
- **Fix:** Changed `shell.goBranch(index, initialLocationIfNeeded: ...)` → `shell.goBranch(index)`

## [DEP-FIX-004] flutter_timezone 5.1.0 — getLocalTimezone() returns TimezoneInfo
- **Error:** `The property 'name' isn't defined on 'TimezoneInfo'`
- **Cause:** `getLocalTimezone()` returns a `TimezoneInfo` object in 5.x, not a `String`
- **Fix:** Changed `deviceTZ.name` → `deviceTZ.identifier` in notification_service.dart

## [DEP-FIX-005] flutter_local_notifications 21.0.0 — all params changed to named
- **Error:** 8 errors across `show()`, `zonedSchedule()`, and `initialize()`
- **Cause:** FLN 21.x changed ALL method signatures from positional to named params. Also removed `uiLocalNotificationDateInterpretation` (iOS-only, dropped in 21.x).
- **Fix:** Applied named params to every `show()` (id:, title:, body:, notificationDetails:) and `zonedSchedule()` (id:, title:, body:, scheduledDate:, notificationDetails:). Removed `uiLocalNotificationDateInterpretation:` entirely. `initialize()` changed to positional.

## [SYNTAX-FIX-001] habit_card.dart — missing GestureDetector closing paren
- **Error:** `Can't find ')' to match '('` in build() return
- **Cause:** Double `ScaleTransition` wrapping `GestureDetector` → `AnimatedContainer` was missing a closing `)` for `GestureDetector`
- **Fix:** Added `        ),` (8-space indent) between AnimatedContainer close and inner ScaleTransition close

## [IMPORT-FIX-001] app.dart — missing database_providers import
- **Error:** `Undefined name 'notificationServiceProvider'`
- **Cause:** `notificationServiceProvider` is defined in `database_providers.dart` but app.dart only imported `habit_providers.dart` and `theme_provider.dart`
- **Fix:** Added `import 'package:streak_it/presentation/providers/database_providers.dart';`

## [DEP-FIX-006] flutter_local_notifications 21.0.0 — initialize() uses 'settings:' named param, returns void
- **Error:** `Too many positional arguments: 0 allowed, but 1 found` on `_plugin.initialize()`
- **Cause:** My earlier fix added positional arg but FLN 20+ requires named param `settings:`. Also `initialize()` returns `Future<void>` now, not `Future<bool?>`.
- **Fix:** Changed from `_plugin.initialize(const InitializationSettings(...))` to `_plugin.initialize(settings: const InitializationSettings(...))`. Removed `final result = await` / `_initialised = result ?? false` pattern since return is void — just `_initialised = true` after await.

## [BUILD-012] Kotlin version mismatch — share_plus-13.1.0 needs Kotlin 2.2+
- **Error:** `Module was compiled with an incompatible version of Kotlin. The binary version of its metadata is 2.2.0, expected version is 2.0.0` + hundreds of `Unresolved reference` errors in share_plus Kotlin sources.
- **Cause:** Project removed `org.jetbrains.kotlin.android` from settings.gradle (thinking AGP 8.11+ built-in Kotlin was enough). But `share_plus-13.1.0` and `flutter_timezone-5.1.0` publish their own KGP and use Kotlin 2.2.x stdlib features. Without an explicit KGP version in settings.gradle, Kotlin 2.0.0 was used → incompatible with Kotlin 2.2.x stdlib.
- **Fix:** Added `id "org.jetbrains.kotlin.android" version "2.3.21" apply false` back to `android/settings.gradle` plugins block. This sets the Kotlin compiler to 2.3.21 (latest stable), which can read metadata versions up to 2.3.x.
