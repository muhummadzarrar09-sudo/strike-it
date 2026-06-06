import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../constants/app_constants.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _permissionGranted = false;

  bool get isPermissionGranted => _permissionGranted;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // INITIALIZE
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    // Create notification channel
    const androidChannel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: AppConstants.notificationChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
    debugPrint('✅ Notification service initialized');
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // PERMISSION — MUST be called before any scheduling
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Returns: 'granted', 'denied', 'permanentlyDenied'
  Future<String> requestPermission() async {
    var status = await Permission.notification.status;

    if (status.isGranted) {
      _permissionGranted = true;
      debugPrint('🔔 Notifications already granted');
      return 'granted';
    }

    if (status.isPermanentlyDenied) {
      _permissionGranted = false;
      debugPrint('🔕 Notifications permanently denied — user must enable in Settings');
      return 'permanentlyDenied';
    }

    // Request
    status = await Permission.notification.request();

    if (status.isGranted) {
      _permissionGranted = true;
      debugPrint('🔔 Notifications granted by user');
      return 'granted';
    }

    if (status.isPermanentlyDenied) {
      _permissionGranted = false;
      debugPrint('🔕 User denied notifications permanently');
      return 'permanentlyDenied';
    }

    _permissionGranted = false;
    debugPrint('🔕 Notifications denied');
    return 'denied';
  }

  /// Opens Android app settings so user can enable notifications manually
  Future<bool> openNotificationSettings() async {
    // permission_handler exports openAppSettings() as a top-level function
    return await openAppSettings();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // SCHEDULING (only if permission granted)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> scheduleHabitReminder({
    required int id,
    required String habitName,
    required String habitEmoji,
    required int hour,
    required int minute,
    required List<int> activeDays,
  }) async {
    if (!_permissionGranted) {
      debugPrint('🔕 Skipping schedule — permission not granted');
      return;
    }

    await _plugin.cancel(id);

    final now = DateTime.now();
    for (final day in activeDays) {
      var scheduledDate = tz.TZDateTime.local(now.year, now.month, now.day, hour, minute)
          .add(Duration(days: (day - now.weekday + 1 + 7) % 7));

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 7));
      }

      await _plugin.zonedSchedule(
        id * 10 + day,
        habitEmoji,
        'Time for $habitName',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            AppConstants.notificationChannelId,
            AppConstants.notificationChannelName,
            channelDescription: AppConstants.notificationChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
            color: Color(0xFFFF4D1C),
            ledColor: Color(0xFFFF4D1C),
            enableLights: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }

    debugPrint('🔔 Scheduled: $habitEmoji $habitName at $hour:$minute');
  }

  Future<void> scheduleStreakWarning({required int currentStreak}) async {
    if (!_permissionGranted || currentStreak < 3) return;

    final now = DateTime.now();
    final scheduledDate = tz.TZDateTime.local(now.year, now.month, now.day, 21, 0);
    if (scheduledDate.isBefore(now)) return; // Already past 9pm

    await _plugin.zonedSchedule(
      9999,
      '⚠️',
      'Your $currentStreak-day streak is at risk. Don\'t break the chain.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          channelDescription: AppConstants.notificationChannelDesc,
          importance: Importance.max,
          priority: Priority.max,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // SHOW IMMEDIATE (for testing / explicit user actions)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> showNow({required String title, required String body}) async {
    if (!_permissionGranted) return;
    await _plugin.show(
      DateTime.now().millisecond,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          channelDescription: AppConstants.notificationChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFFFF4D1C),
        ),
      ),
    );
  }

  Future<void> cancelAll() async => _plugin.cancelAll();
  Future<void> cancelHabit(int id) async => _plugin.cancel(id);
}