# 🔥 Streak It — Premium Habit Tracker

> Build habits. Break limits.

A production-quality Flutter Android app with real analytics, streak tracking, XP gamification, mood logging, sub-tasks, and full offline-first privacy.

---

## 🚀 Build in 2 Steps

### Windows
```
1. Right-click setup.bat → Run as Administrator
2. Wait 5-10 min → APK appears automatically
```

### macOS / Linux
```bash
chmod +x setup.sh
./setup.sh
```

The script installs **everything from scratch**: Java 17, Android SDK, Flutter, generates code, and builds the APK. No manual steps required.

---

## ⚠️ Font Files Required

Before building, download and place these files in `assets/fonts/`:

**Inter** → https://fonts.google.com/specimen/Inter
- `Inter-Regular.ttf`, `Inter-Medium.ttf`, `Inter-SemiBold.ttf`, `Inter-Bold.ttf`

**Space Grotesk** → https://fonts.google.com/specimen/Space+Grotesk
- `SpaceGrotesk-Regular.ttf`, `SpaceGrotesk-Medium.ttf`, `SpaceGrotesk-SemiBold.ttf`, `SpaceGrotesk-Bold.ttf`

---

## 📱 Features

| Category | Features |
|---|---|
| **Habits** | Binary + quantified, positive + negative, custom schedules, grace days |
| **Analytics** | Heatmap, bar charts, trend lines, day-of-week analysis, per-habit rates |
| **Streaks** | Current + best streak, score (0-100), milestone tracking |
| **Gamification** | XP system, 10 levels, 20 achievements across 4 rarity tiers |
| **Celebrations** | Particle confetti overlay on milestones and level-ups |
| **Notifications** | Per-habit daily reminders, streak-at-risk alerts, milestone alerts |
| **Sub-tasks** | Per-habit checklist, per-day completion tracking |
| **Mood** | Daily 4-emoji mood log, per-habit |
| **Data** | CSV export, JSON backup/restore, biometric lock |
| **Privacy** | 100% offline, no account, no cloud, no tracking |

---

## 🏗️ Architecture

```
Flutter + Riverpod 2 + Drift SQLite
├── lib/core/          → theme, constants, utils, router
├── lib/data/          → Drift DB, DAOs, repositories
├── lib/domain/        → streak engine, XP, achievements, notifications, export
└── lib/presentation/  → screens, widgets, providers
```

See `docs/ARCHITECTURE.md` for full details.

---

## 🧪 Tests

```bash
flutter test
```

96 tests across unit, widget, and smoke levels.

---

## 📖 Docs

- `docs/ARCHITECTURE.md` — System design
- `docs/SPRINT_PLAN.md` — What was built in each sprint
- `docs/APK_BUILD_GUIDE.md` — Manual build guide (if auto-script fails)
