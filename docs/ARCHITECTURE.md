# StreakIt — Architecture Guide

## Overview

StreakIt follows a layered architecture with clean separation of concerns:

```
┌─────────────────────────────────────┐
│         Presentation Layer          │  ← Flutter Widgets, Screens
│    (Riverpod Providers, Screens)    │
├─────────────────────────────────────┤
│           Domain Layer              │  ← Business Logic Services
│  (StreakCalculator, Achievements,   │
│   NotificationService)              │
├─────────────────────────────────────┤
│            Data Layer               │  ← Repositories, DAOs
│  (HabitRepository, CompletionRepo)  │
├─────────────────────────────────────┤
│          Database Layer             │  ← Drift ORM + SQLite
│       (AppDatabase, Tables)         │
└─────────────────────────────────────┘
```

## Key Principles

1. **Unidirectional data flow**: Data flows up from DB → Repo → Provider → Widget.
2. **Immutable state**: All Riverpod state is replaced, not mutated.
3. **Reactive streams**: Habit lists and completions use `Stream<T>` so the UI
   updates automatically when data changes.
4. **Offline-first**: Zero network calls. No accounts. Data lives in SQLite.
5. **Testable**: All business logic is in pure Dart classes with no Flutter deps.

## State Management

We use **Riverpod 2.x** with a simple `StreamProvider` / `FutureProvider` /
`StateNotifier` split:

| Provider Type       | Use Case                              |
|---------------------|---------------------------------------|
| `StreamProvider`    | Reactive DB streams (habit list)      |
| `FutureProvider`    | One-shot async operations             |
| `StateNotifier`     | Complex state with actions (theme)    |
| `Provider`          | Singleton services (DB, repos)        |

## Database Schema

```
habits          → Core habit definitions
completions     → One row per (habit, date) completion
habit_tasks     → Sub-tasks per habit
mood_entries    → Optional daily mood logs
```

## Streak Algorithm

See `lib/core/utils/streak_calculator.dart`.

Uses exponential smoothing (Loop Habit Tracker model):
```
score = prev_score × (1 - decay) + completion × decay × 100
```
- `decay = 0.1` (configurable via `AppConstants`)
- Score range: 0–100
- At-risk: score < 40 OR today not completed

## Code Generation

Drift requires code generation. After changing table definitions, run:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Navigation

Uses **GoRouter** with named routes defined in `AppRouter`.
Route guards: `SplashScreen` resolves initial route (onboarding vs home).
