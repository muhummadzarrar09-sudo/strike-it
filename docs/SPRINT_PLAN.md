# StreakIt — Sprint Plan

## ✅ COMPLETED

### Sprint 0 — Foundation
- [x] Project structure, pubspec.yaml (no outdated deps)
- [x] Full color token system (AppColors) — 60-30-10, 6 accents, heatmap scale
- [x] Dual-font typography (Inter + SpaceGrotesk) — tabular figures for stats
- [x] Complete dark + light ThemeData — every M3 component themed
- [x] App constants (decay factors, XP thresholds, milestones, notification IDs)
- [x] 60+ Phosphor icon library with categories
- [x] GoRouter navigation with onboarding guard

### Sprint 1 — Core Loop
- [x] Drift database (4 tables: Habits, Completions, Tasks, Moods)
- [x] 4 type-safe DAOs with reactive streams
- [x] AppDatabase with WAL mode, FK enforcement, migration scaffold
- [x] HabitRepository + CompletionRepository (toggle, increment, decrement)
- [x] Riverpod providers (DB, repos, services)
- [x] Home screen — reactive list, progress ring, FAB
- [x] One-tap check-in with haptic feedback
- [x] Add/Edit habit screen — full form (name, desc, color, icon, type, freq, grace, reminders)
- [x] Splash screen — branded animation, parallel init
- [x] Onboarding — 3 gradient pages with flutter_animate

### Sprint 2 — Streaks Engine
- [x] StreakCalculator — exponential smoothing score, grace days, at-risk, milestones
- [x] Habit cards show streak badge + milestone countdown + at-risk warning
- [x] Habit detail screen — 35-day mini-calendar, streak stats, score ring

### Sprint 3 — Notifications + XP Engine
- [x] NotificationService — per-channel config, exact alarm scheduling
- [x] Daily reminder scheduling (per habit, per time slot, repeating)
- [x] Streak-at-risk, level-up, milestone celebration notifications
- [x] Notification reschedule on every habit save/edit/delete
- [x] XPService — award, cache, persist to SharedPreferences
- [x] XP awarded on every completion with milestone bonus
- [x] Level-up detection and notification trigger
- [x] CelebrationOverlay — procedural particle confetti, no Lottie file needed
- [x] HabitCard fully wired: check-in → XP → celebration → notification

### Sprint 4 — Sub-tasks + Mood + UX Polish
- [x] TaskChecklist widget — reactive, inline add, toggle per-day, long-press delete
- [x] Sub-task completion persisted per-day in SQLite
- [x] Habit detail screen rebuilt with task checklist + mood section
- [x] MoodSection — 4-emoji picker, upsert to DB, per-day tracking
- [x] 35-day calendar with checkmark on completed cells
- [x] Streak badges with milestone countdown chips
- [x] Add/Edit habit — notifications rescheduled on save

### Sprint 5 — Export + Backup + Polish
- [x] ExportService — CSV export (all completions) via share sheet
- [x] JSON backup — full snapshot (habits, completions, tasks, moods)
- [x] JSON restore — destructive re-import from backup file
- [x] Settings screen — live export/backup buttons with loading states
- [x] Biometric lock (local_auth) with authentication gate
- [x] Notification reschedule button in settings
- [x] Accent color picker fully wired + persisted
- [x] main.dart — edge-to-edge rendering, orientation lock

### Sprint 6 — Test Suite
- [x] streak_calculator_test.dart — 25 unit tests (all edge cases)
- [x] date_utils_test.dart — 18 unit tests
- [x] achievement_service_test.dart — 15 unit tests
- [x] xp_service_test.dart — 12 unit tests
- [x] extensions_test.dart — 18 unit tests
- [x] progress_ring_test.dart — 5 widget tests
- [x] habit_card_smoke_test.dart — 3 smoke tests

## 🔲 REMAINING

### APK Build Guide
- [x] Step-by-step guide already written: `docs/APK_BUILD_GUIDE.md`
- [ ] **ACTION FOR USER**: Install Flutter SDK → run build_runner → flutter build apk --release

---

## Architecture Summary

```
main.dart
  └── ProviderScope
        └── StreakItApp (MaterialApp.router)
              └── GoRouter → Screens
                    ├── SplashScreen
                    ├── OnboardingScreen
                    ├── HomeScreen
                    │     └── HabitCard (XP + notifications wired)
                    ├── HabitDetailScreen
                    │     ├── TaskChecklist (reactive)
                    │     └── MoodSection
                    ├── AddEditHabitScreen (reschedules notifications on save)
                    ├── AnalyticsScreen (fl_chart: bars, heatmap, day-of-week)
                    ├── AchievementsScreen (20 achievements, XP ring)
                    └── SettingsScreen (theme, accent, biometric, export, backup)

Providers:
  databaseProvider → AppDatabase (Drift SQLite, WAL, FK enforced)
  habitRepositoryProvider → HabitRepository
  completionRepositoryProvider → CompletionRepository
  notificationServiceProvider → NotificationService
  xpServiceProvider → XPService
  exportServiceProvider → ExportService
  themeProvider → ThemeNotifier (dark/light, accent)

Domain:
  StreakCalculator → score, streak, milestones, XP, levels
  AchievementService → 20 achievements, 4 rarities, pure evaluation
  NotificationService → channels, scheduling, alerts, celebrations
  XPService → award, cache, persist
  ExportService → CSV, JSON backup, JSON restore
```
