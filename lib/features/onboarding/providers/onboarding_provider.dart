import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/isar_service.dart';
import '../../auth/models/user_profile.dart';
import '../../gamification/providers/gamification_provider.dart';
import '../../habits/providers/habit_provider.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ONBOARDING STATE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
final onboardingStepProvider = StateProvider<int>((ref) => 0);
final onboardingNameProvider = StateProvider<String>((ref) => '');
final onboardingChronotypeProvider = StateProvider<String>((ref) => 'balanced');
final onboardingMotivationProvider = StateProvider<String>((ref) => 'discipline');
final onboardingGoalsProvider = StateProvider<List<String>>((ref) => []);

final isOnboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final profile = await IsarService.profiles.where().findFirst();
  return profile?.onboardingCompleted ?? false;
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ONBOARDING ACTIONS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class OnboardingActions {
  Future<void> completeOnboarding({
    required String name,
    required String chronotype,
    required String motivationStyle,
    required List<String> goals,
  }) async {
    final existing = await IsarService.profiles.where().findFirst();
    final now = DateTime.now();

    final profile = existing ?? UserProfile()
      ..userId = 'local_${now.millisecondsSinceEpoch}'
      ..createdAt = now;

    profile.displayName = name;
    profile.chronotype = chronotype;
    profile.motivationStyle = motivationStyle;
    profile.initialGoalCategories = goals;
    profile.onboardingCompleted = true;
    profile.syncEnabled = false; // Privacy-first
    profile.notificationsEnabled = true;
    profile.widgetEnabled = true;
    profile.soundEnabled = true;
    profile.hapticEnabled = true;
    profile.totalXp = 0;
    profile.currentLevel = 1;
    profile.streakFlameIntensity = 0;
    profile.updatedAt = now;

    await IsarService.profiles.put(profile);

    // Seed badges
    await XpEngine.seedBadges();

    // Pre-seed habits based on goals
    await _seedHabits(goals);
  }

  Future<void> _seedHabits(List<String> goals) async {
    final suggestions = <String, List<Map<String, dynamic>>>{
      'fitness': [
        {'name': 'Morning workout', 'emoji': '🏋️', 'days': [0, 1, 2, 3, 4]},
        {'name': '10k steps', 'emoji': '🚶', 'days': [0, 1, 2, 3, 4, 5, 6]},
        {'name': 'Stretch for 5 min', 'emoji': '🧘', 'days': [0, 1, 2, 3, 4, 5, 6]},
      ],
      'mindfulness': [
        {'name': 'Meditate 5 min', 'emoji': '🧘', 'days': [0, 1, 2, 3, 4, 5, 6]},
        {'name': 'Gratitude journal', 'emoji': '🙏', 'days': [0, 1, 2, 3, 4, 5, 6]},
        {'name': 'No phone first hour', 'emoji': '📵', 'days': [0, 1, 2, 3, 4, 5, 6]},
      ],
      'productivity': [
        {'name': 'Deep work 1hr', 'emoji': '💻', 'days': [0, 1, 2, 3, 4]},
        {'name': 'Plan tomorrow', 'emoji': '📋', 'days': [0, 1, 2, 3, 4, 6]},
        {'name': 'Inbox zero', 'emoji': '📧', 'days': [0, 1, 2, 3, 4]},
      ],
      'health': [
        {'name': '8 glasses of water', 'emoji': '💧', 'days': [0, 1, 2, 3, 4, 5, 6]},
        {'name': '7+ hours sleep', 'emoji': '😴', 'days': [0, 1, 2, 3, 4, 5, 6]},
        {'name': 'No junk food', 'emoji': '🥗', 'days': [0, 1, 2, 3, 4, 5, 6]},
      ],
    };

    final habitActions = HabitActions();
    for (final goal in goals.take(2)) {
      final habitList = suggestions[goal] ?? [];
      for (final h in habitList.take(2)) {
        await habitActions.createHabit(
          name: h['name'] as String,
          emoji: h['emoji'] as String,
          activeDays: (h['days'] as List).cast<int>(),
        );
      }
    }
  }
}

final onboardingActionsProvider = Provider<OnboardingActions>((ref) => OnboardingActions());
