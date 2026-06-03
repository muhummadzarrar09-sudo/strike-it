import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

import '../core/constants/app_constants.dart';
import '../data/database/app_database.dart';
import '../data/repositories/habit_repository.dart';

/// Notification service — scheduling, cancellation, immediate alerts.
///
/// FIX HISTORY (see MISTAKE_LOG.md RUNTIME-001):
///   - tz.setLocalLocation(tz.UTC) was hardcoded → fixed with FlutterTimezone + .name
///   - FLN 21.x: all show/zonedSchedule params changed to named
///   - Added test notification (5-second delay) for user verification
///   - Added test notification (5-second delay) for user verification
///
/// Channel layout:
///   si_reminders    → daily habit reminders    (high importance)
///   si_alerts       → streak-at-risk warnings  (high importance)
///   si_celebrations → milestone / level-up     (default importance)
///
/// Notification ID allocation (collision-free):
///   Habit[i] time[t] → notificationBaseId + (i × slotSize) + t
///   Test             → notificationBaseId − 4  (996)
///   Milestone        → notificationBaseId − 3  (997)
///   Level-up         → notificationBaseId − 2  (998)
///   Streak-at-risk   → notificationBaseId − 1  (999)
class NotificationService {
  // ── Channel IDs ──────────────────────────────────────────────────────────
  static const _reminderId   = 'si_reminders';
  static const _reminderName = 'Habit Reminders';
  static const _reminderDesc = 'Daily reminders to check in on your habits.';

  static const _alertId   = 'si_alerts';
  static const _alertName = 'Streak Alerts';
  static const _alertDesc = 'Warnings when a streak is about to break.';

  static const _celebId   = 'si_celebrations';
  static const _celebName = 'Achievements';
  static const _celebDesc = 'Milestone and level-up celebrations.';

  static const _accentColor = Color(0xFFF59E0B);

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialised = false;

  NotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  // ── Init ──────────────────────────────────────────────────────────────────

  /// Initialise the plugin + set device-local timezone.
  /// Must be called before any schedule operation.
  /// Safe to call multiple times — guards with _initialised flag.
  Future<void> initialise() async {
    if (_initialised) return;

    // Step 1: Load the full timezone database.
    tz_data.initializeTimeZones();

    // Step 2: Get the REAL device timezone name via flutter_timezone.
    //         This is the root fix for RUNTIME-001: we were hardcoding UTC.
    try {
      final deviceTZ = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(deviceTZ.identifier));
      debugPrint('[NotificationService] Device timezone: $deviceTZ');
    } catch (e) {
      // Fallback to UTC if plugin fails (e.g., emulator quirk).
      // Reminders will still fire but may be offset.
      debugPrint('[NotificationService] TZ detection failed, using UTC: $e');
      tz.setLocalLocation(tz.UTC);
    }

    // Step 3: Initialise the plugin.
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    _initialised = true;
    debugPrint('[NotificationService] Plugin initialised: $_initialised');

    // Step 4: Create notification channels (Android 8+).
    await _createChannels();
  }

  Future<void> _createChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.createNotificationChannel(const AndroidNotificationChannel(
      _reminderId, _reminderName,
      description: _reminderDesc,
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      _alertId, _alertName,
      description: _alertDesc,
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      _celebId, _celebName,
      description: _celebDesc,
      importance: Importance.defaultImportance,
      enableVibration: true,
    ));
    debugPrint('[NotificationService] Channels created');
  }

  // ── Permission ────────────────────────────────────────────────────────────

  /// Requests POST_NOTIFICATIONS permission (Android 13+ / iOS).
  /// Returns true if granted.
  Future<bool> requestPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        debugPrint('[NotificationService] Android permission: $granted');
        return granted ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final granted = await ios.requestPermissions(
          alert: true, badge: true, sound: true,
        );
        debugPrint('[NotificationService] iOS permission: $granted');
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('[NotificationService] requestPermission error: $e');
    }
    return false;
  }

  // ── Reschedule All ────────────────────────────────────────────────────────

  /// Cancels ALL existing notifications and reschedules for current habits.
  /// Call after any habit CRUD, and on app startup.
  Future<void> rescheduleAll(List<Habit> habits) async {
    if (!_initialised) await initialise();
    await _plugin.cancelAll();

    int scheduled = 0;
    for (int i = 0; i < habits.length; i++) {
      final habit = habits[i];
      if (habit.isArchived) continue;

      final times = HabitRepository.parseReminderTimes(habit.reminderTimes);
      for (int t = 0; t < times.length && t < AppConstants.notificationSlotSize; t++) {
        final id = AppConstants.notificationBaseId +
            (i * AppConstants.notificationSlotSize) + t;
        final success = await _scheduleDailyReminder(
          id: id,
          habitName: habit.name,
          timeStr: times[t],
        );
        if (success) scheduled++;
      }
    }
    debugPrint('[NotificationService] Rescheduled $scheduled reminders');
  }

  /// Returns true if the notification was successfully scheduled.
  Future<bool> _scheduleDailyReminder({
    required int id,
    required String habitName,
    required String timeStr,
  }) async {
    final parts = timeStr.split(':');
    if (parts.length != 2) {
      debugPrint('[NotificationService] Bad time format: $timeStr');
      return false;
    }
    final hour   = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      debugPrint('[NotificationService] Non-numeric time: $timeStr');
      return false;
    }

    // Build the next occurrence in the device's local timezone.
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final body = _body(habitName);
    debugPrint('[NotificationService] Scheduling "$habitName" (id=$id) at $scheduled');

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: '🔥 Time to streak!',
        body: body,
        scheduledDate: scheduled,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _reminderId, _reminderName,
            channelDescription: _reminderDesc,
            importance: Importance.high,
            priority: Priority.high,
            color: _accentColor,
            styleInformation: BigTextStyleInformation(body),
            ticker: 'Habit reminder',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: true,
          ),
        ),
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      return true;
    } catch (e) {
      // Scheduling can fail if SCHEDULE_EXACT_ALARM permission is revoked.
      // App still works — just no reminders until user grants permission.
      debugPrint('[NotificationService] Schedule failed for "$habitName": $e');
      return false;
    }
  }

  // ── Test Notification (Sprint A requirement) ──────────────────────────────

  /// Fires a notification in 5 seconds. Call from Settings to verify setup.
  Future<void> showTestNotification() async {
    if (!_initialised) await initialise();

    final now = tz.TZDateTime.now(tz.local);
    final in5s = now.add(const Duration(seconds: 5));

    const body = 'Notifications are working! ✅ Your reminders will fire on time.';

    try {
      await _plugin.zonedSchedule(
        id: AppConstants.notificationBaseId - 4,
        title: '🔔 Test Notification',
        body: body,
        scheduledDate: in5s,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _reminderId, _reminderName,
            importance: Importance.high,
            priority: Priority.high,
            color: Color(0xFF2D9B6F),
            styleInformation: BigTextStyleInformation(body),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint('[NotificationService] Test notification scheduled for $in5s');
    } catch (e) {
      debugPrint('[NotificationService] Test notification failed: $e');
    }
  }

  // ── Immediate Alerts ──────────────────────────────────────────────────────

  Future<void> showStreakAtRisk({
    required String habitName,
    required int streak,
  }) async {
    if (!_initialised) await initialise();
    try {
      await _plugin.show(
        id: AppConstants.notificationBaseId - 1,
        title: '⚠️ Streak at risk!',
        body: '$habitName — your $streak-day streak breaks tonight. Log it now.',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _alertId, _alertName,
            importance: Importance.high,
            priority: Priority.high,
            color: Color(0xFFC07D2A),
          ),
          iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
        ),
      );
    } catch (e) {
      debugPrint('[NotificationService] showStreakAtRisk error: $e');
    }
  }

  Future<void> showLevelUp(int newLevel) async {
    if (!_initialised) await initialise();
    try {
      await _plugin.show(
        id: AppConstants.notificationBaseId - 2,
        title: '🎉 Level Up!',
        body: 'You reached Level $newLevel. Keep building those habits!',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _celebId, _celebName,
            importance: Importance.defaultImportance,
            color: Color(0xFF2D9B6F),
          ),
          iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
        ),
      );
    } catch (e) {
      debugPrint('[NotificationService] showLevelUp error: $e');
    }
  }

  Future<void> showMilestoneCelebration({
    required String habitName,
    required int milestone,
  }) async {
    if (!_initialised) await initialise();
    const messages = {
      7:   "7 days straight. You're building real momentum. 💪",
      21:  "21 days! Science says the habit is forming. Keep going. 🧠",
      30:  "30-day streak! One whole month. You're unstoppable. 🔥",
      66:  "66 days. This is on autopilot now. 🛸",
      100: "100 DAYS. You've entered a different league. 💯",
    };
    try {
      await _plugin.show(
        id: AppConstants.notificationBaseId - 3,
        title: '🏆 $milestone-day streak!',
        body: '$habitName — ${messages[milestone] ?? 'Legendary consistency.'}',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _celebId, _celebName,
            importance: Importance.defaultImportance,
            color: Color(0xFFFFD700),
          ),
          iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
        ),
      );
    } catch (e) {
      debugPrint('[NotificationService] showMilestoneCelebration error: $e');
    }
  }

  // ── Cancel ────────────────────────────────────────────────────────────────

  Future<void> cancelAll() => _plugin.cancelAll();

  // ── Body copy ─────────────────────────────────────────────────────────────

  int _bodyIdx = 0;
  static const _bodies = [
    "Small action, massive compound effect. Check in!",
    "Your streak won't build itself.",
    "One tap. That's all it takes.",
    "Consistency > perfection. Log it.",
    "Future you is grateful for present you.",
    "Don't let yesterday's effort go to waste.",
    "The chain is only as strong as today.",
  ];

  String _body(String habitName) {
    final msg = _bodies[_bodyIdx % _bodies.length];
    _bodyIdx++;
    return '$habitName — $msg';
  }
}
