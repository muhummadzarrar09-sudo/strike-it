import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/isar_service.dart';
import '../../habits/models/habit.dart';
import '../../habits/models/habit_checkin.dart';
import '../../streaks/providers/streak_engine.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// COACH INSIGHT MODEL
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class CoachInsight {
  final String title;
  final String message;
  final String emoji;
  final InsightType type;
  const CoachInsight({required this.title, required this.message, required this.emoji, required this.type});
}

enum InsightType { encouragement, warning, pattern, suggestion, celebration }

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// AI COACH PROVIDER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
final coachInsightsProvider = FutureProvider<List<CoachInsight>>((ref) async {
  final insights = <CoachInsight>[];

  // 1. Analyze overall streak
  final allCheckins = await IsarService.checkins
      .filter()
      .isCompletedEqualTo(true)
      .findAll();
  final dates = allCheckins.map((c) => c.date).toList();
  final currentStreak = StreakEngine.calculateCurrentStreak(dates);
  final bestDay = StreakEngine.getBestDayOfWeek(dates);
  final worstDay = StreakEngine.getWorstDayOfWeek(dates);

  // Streak insights
  if (currentStreak == 0) {
    insights.add(const CoachInsight(
      title: 'FRESH START',
      message: 'Every streak begins with a single check-in. Today can be day 1.',
      emoji: '🌅',
      type: InsightType.encouragement,
    ));
  } else if (currentStreak < 3) {
    insights.add(CoachInsight(
      title: 'BUILDING MOMENTUM',
      message: '$currentStreak days and counting. You\'re building the foundation. Consistency > intensity.',
      emoji: '🧱',
      type: InsightType.encouragement,
    ));
  } else if (currentStreak >= 7 && currentStreak < 14) {
    insights.add(const CoachInsight(
      title: 'THE HABIT LOOP',
      message: 'You\'ve passed the 7-day mark. The habit loop is forming. Your brain is rewiring right now.',
      emoji: '🧠',
      type: InsightType.celebration,
    ));
  } else if (currentStreak >= 30) {
    insights.add(const CoachInsight(
      title: 'UNSTOPPABLE',
      message: '30+ days. This habit is now part of your identity. You\'re not "trying" anymore — you\'re doing.',
      emoji: '💀',
      type: InsightType.celebration,
    ));
  }

  // 2. Day-of-week pattern
  final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  if (bestDay >= 0 && bestDay != worstDay) {
    insights.add(CoachInsight(
      title: 'YOUR POWER DAY',
      message: 'You\'re strongest on ${dayNames[bestDay]}s. Schedule your hardest habits there.',
      emoji: '⚡',
      type: InsightType.pattern,
    ));
    insights.add(CoachInsight(
      title: 'WATCH ${dayNames[worstDay].toUpperCase()}S',
      message: '${dayNames[worstDay]}s are your weakest day. Consider making that day\'s habits easier.',
      emoji: '⚠️',
      type: InsightType.warning,
    ));
  }

  // 3. Habit-specific analysis
  final habits = await IsarService.habits.filter().isActiveEqualTo(true).findAll();
  for (final habit in habits) {
    final habitCheckins = await IsarService.checkins
        .filter()
        .habitIdEqualTo(habit.habitId)
        .isCompletedEqualTo(true)
        .findAll();

    final habitStreak = StreakEngine.calculateCurrentStreak(habitCheckins.map((c) => c.date).toList());

    if (habitStreak == 0 && habit.currentStreak > 0) {
      insights.add(CoachInsight(
        title: '${habit.emoji} ${habit.name}',
        message: 'This streak was broken recently. What happened? Was it too ambitious? Try a smaller version.',
        emoji: habit.emoji,
        type: InsightType.warning,
      ));
    }
  }

  // 4. Time-of-day suggestion (heuristic)
  final morningCheckins = allCheckins.where((c) => c.createdAt.hour < 10).length;
  final eveningCheckins = allCheckins.where((c) => c.createdAt.hour >= 18).length;

  if (morningCheckins > eveningCheckins) {
    insights.add(const CoachInsight(
      title: 'MORNING PERSON',
      message: 'You check off more habits in the morning. Front-load your important habits before 10am.',
      emoji: '🌅',
      type: InsightType.pattern,
    ));
  } else if (eveningCheckins > morningCheckins) {
    insights.add(const CoachInsight(
      title: 'NIGHT OWL',
      message: 'You peak in the evening. Schedule your habit check-ins for after 6pm when your energy aligns.',
      emoji: '🌙',
      type: InsightType.pattern,
    ));
  }

  // 5. Generate suggestion
  if (habits.length < 3) {
    insights.add(const CoachInsight(
      title: 'START SMALL',
      message: 'Research shows starting with 1-3 habits has the highest success rate. Don\'t overwhelm yourself.',
      emoji: '🧪',
      type: InsightType.suggestion,
    ));
  }

  return insights;
});