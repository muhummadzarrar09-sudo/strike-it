# Streak It — Architecture Overview

## Tech Stack (2026)

| Layer | Technology | Version |
|---|---|---|
| Framework | Flutter (Dart) | >=3.35.0 |
| State Management | Riverpod | 3.3.1 |
| Local DB | Isar Community | 3.3.2 |
| Cloud DB | Cloud Firestore | 6.0.1 |
| Auth | Firebase Auth + Google Sign-In | 6.0.2 |
| Notifications | flutter_local_notifications | 19.5.0 |
| Widgets | home_widget + workmanager | 0.7.0 / 0.5.2 |
| Charts | fl_chart | 1.2.0 |
| Heatmap | contribution_heatmap | 0.5.3 |
| AI/ML | flutter_litert (TFLite) | 0.2.0 |
| Animations | flutter_animate + staggered | 4.5.2 / 1.1.1 |

## Architecture Decisions

1. **Feature-First**: Each feature is a self-contained folder with models, providers, screens, widgets
2. **Offline-First**: All habit data in Isar locally. Firebase sync is opt-in
3. **Privacy-First**: Habit data stays on-device by default
4. **Sprint-Based Development**: Layer features on working code, never delete

## Build System

Single `.ps1` script handles everything:
```powershell
.\scripts\streak_it_build.ps1 dev     # Dev build
.\scripts\streak_it_build.ps1 prod    # Prod build
.\scripts\streak_it_build.ps1 run     # Run on device
.\scripts\streak_it_build.ps1 test    # Tests
.\scripts\streak_it_build.ps1 clean   # Clean
.\scripts\streak_it_build.ps1 doctor  # Env check
.\scripts\streak_it_build.ps1 all     # Both dev + prod
```

## Sprint Roadmap

| Sprint | Feature |
|---|---|
| 1 | Scaffold + Theme + Navigation |
| 2 | Habits CRUD + Isar Models |
| 3 | Streaks Engine + Heatmap |
| 4 | Smart Reminders |
| 5 | Analytics Dashboard |
| 6 | Widget Suite |
| 7 | Micro-Journal + Mood |
| 8 | Gamification |
| 9 | AI Coach (TFLite) |
| 10 | Firebase Sync + Polish |