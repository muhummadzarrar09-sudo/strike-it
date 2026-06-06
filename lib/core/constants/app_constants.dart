class AppConstants {
  AppConstants._();

  static const String appName = 'Streak It';
  static const String tagline = "Don't break the chain.";
  static const String packageName = 'app.streakit.android';
  static const String isarDbName = 'streak_it.db';

  static const String devProjectId = 'streak-it-dev';
  static const String prodProjectId = 'streak-it-prod';

  static const int xpPerHabitCompletion = 10;
  static const int xpPerPerfectDay = 25;
  static const List<int> levelThresholds = [0, 100, 250, 500, 1000, 2000, 4000, 8000];

  static const String notificationChannelId = 'streak_it_reminders';
  static const String notificationChannelName = 'Habit Reminders';
  static const String widgetBackgroundTask = 'widgetBackgroundUpdate';

  static const int maxFreeHabits = 5;
  static const Duration syncTimeout = Duration(seconds: 30);
}