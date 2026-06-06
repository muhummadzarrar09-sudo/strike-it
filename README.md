# STREAK IT

> **DON'T BREAK THE CHAIN.** — #FF4D1C on #000000

A **privacy-first, offline-first** habit tracker with a **dark brutalist design** that looks like nothing else on the market. Built with Flutter + Firebase.

---

## 🚀 QUICK START

```powershell
# First time:
.\build.ps1 setup

# Build & install on your phone:
.\build.ps1 dev
.\build.ps1 install
```

One command. That's it. The script handles everything.

---

## 📱 WHAT IT DOES

| Feature | Status |
|---|---|
| 4-Tab Navigation (Today, Habits, Stats, Journal) | ✅ Done |
| Binary Habit Tracking (done/not done) | ✅ Done |
| Habit CRUD (create, edit, delete, reorder) | ✅ Done |
| Streak Engine (current, longest, heatmap) | ✅ Done |
| GitHub-Style Heatmap (20-week view) | ✅ Done |
| Smart Reminders (per-habit, per-day scheduling) | ✅ Done |
| Analytics (bar charts, KPIs, top habits) | ✅ Done |
| Deep Journal (mood, energy, reflections, tags) | ✅ Done |
| Full Gamification (XP, levels, badges, thresholds) | ✅ Done |
| AI Coach (rule-based pattern analysis) | ✅ Done |
| Personality Quiz Onboarding (4-step wizard) | ✅ Done |
| Home Screen Widgets (3 types — native Kotlin) | ✅ Done |
| Offline-First (Isar local DB, Firebase optional) | ✅ Done |
| Google Sign-In (Firebase Auth) | ✅ Done |
| Privacy-First (sync is opt-in, data stays local) | ✅ Done |

---

## 🏗 TECH STACK

| Layer | Tech | Version |
|---|---|---|
| Framework | Flutter | 3.35+ |
| State | Riverpod | 3.3 |
| Local DB | Isar Community | 3.3 |
| Auth | Firebase Auth + Google Sign-In | 6.0 |
| Notifications | flutter_local_notifications | 19.5 |
| Charts | fl_chart | 1.2 |
| Animations | flutter_animate | 4.5 |
| Widgets | home_widget + workmanager | 0.7 / 0.5 |
| ML | flutter_litert (TFLite-ready) | 0.2 |
| Android | AGP 8.9, Kotlin 2.1, Gradle 8.11, minSdk 24 |

---

## 📁 PROJECT STRUCTURE

```
streak_it/
├── build.ps1                     ← THE SCRIPT. Run this.
├── lib/
│   ├── main.dart                 ← Entry (onboarding → app shell)
│   ├── core/
│   │   ├── theme/app_theme.dart  ← Dark brutalist design system
│   │   ├── constants/            ← XP values, IDs, thresholds
│   │   └── services/             ← Isar, Firebase, Notifications, Sync
│   ├── features/
│   │   ├── habits/               ← Binary CRUD, check-in, today screen
│   │   ├── streaks/              ← Streak engine, heatmap, header
│   │   ├── analytics/            ← Bar charts, KPIs
│   │   ├── journal/              ← Mood, energy, reflections
│   │   ├── gamification/         ← XP engine, badges, leveling
│   │   ├── ai_coach/             ← Pattern analysis, suggestions
│   │   ├── widgets/              ← Home screen widget bridge
│   │   ├── auth/                 ← Google Sign-In screen
│   │   └── onboarding/           ← 4-step personality quiz
│   └── common/widgets/           ← Shared UI components
├── android/                      ← Native Kotlin (widgets, manifest)
├── docs/                         ← Architecture, design, setup, deps
└── brand/                        ← Logo (#FF4D1C on black)
```

---

## 🎨 DESIGN SYSTEM

- **One color**: #FF4D1C — only on streaks, CTAs, active states
- **No shadows. No gradients. No rounded corners.**
- **Bold typography** (Space Grotesk via Google Fonts)
- **Raw borders > shadows** for hierarchy
- **Negative space is intentional**

---

## 📦 DEPENDENCIES (58 pinned)

See `docs/setup/DEPENDENCIES.md` for the full compatibility matrix.

---

## 🔧 BUILD SCRIPT COMMANDS

```powershell
.\build.ps1 setup    # First-time: fonts, assets, env check
.\build.ps1 dev      # Full pipeline → APK + AAB
.\build.ps1 prod     # Same, but prod Firebase
.\build.ps1 quick    # Fast: skip tests
.\build.ps1 run      # Build + install on phone
.\build.ps1 install  # Install last APK
.\build.ps1 clean    # Nuclear clean
.\build.ps1 doctor   # Env check
.\build.ps1 help     # Show help
```

---

Built with ☠️ and #FF4D1C
