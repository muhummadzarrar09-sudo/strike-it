import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/notification_service.dart';

/// Shown BEFORE any notifications are scheduled.
/// User must explicitly grant permission.
class NotificationPermissionScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;
  const NotificationPermissionScreen({super.key, required this.onComplete});

  @override
  ConsumerState<NotificationPermissionScreen> createState() => _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState extends ConsumerState<NotificationPermissionScreen> {
  bool _loading = false;

  Future<void> _enable() async {
    setState(() => _loading = true);

    final result = await NotificationService.instance.requestPermission();

    if (!mounted) return;
    setState(() => _loading = false);

    if (result == 'permanentlyDenied') {
      // Show dialog explaining how to enable in settings
      _showSettingsDialog();
    } else {
      widget.onComplete();
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: StreakItTheme.nearBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
          side: const BorderSide(color: StreakItTheme.darkGray, width: 1),
        ),
        title: Text('NOTIFICATIONS BLOCKED', style: StreakItTheme.textTheme.headlineSmall),
        content: Text(
          'You denied notifications. You can enable them later in Settings.\n\n'
          'Without notifications, you won\'t get habit reminders.',
          style: StreakItTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onComplete();
            },
            child: const Text('SKIP'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await openAppSettings();
              widget.onComplete();
            },
            child: Text('SETTINGS', style: TextStyle(color: StreakItTheme.accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StreakItTheme.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(color: StreakItTheme.accent, width: 2),
                  ),
                  child: const Icon(Icons.notifications_active, size: 40, color: StreakItTheme.accent),
                ),
                const SizedBox(height: 32),

                Text(
                  'STAY ON TRACK',
                  style: StreakItTheme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),

                Text(
                  'Streak It sends gentle reminders\nso you never break the chain.\n\nYou can change this anytime.',
                  style: StreakItTheme.textTheme.bodyMedium?.copyWith(color: StreakItTheme.mutedGray),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _enable,
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('ENABLE NOTIFICATIONS'),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: widget.onComplete,
                    child: Text('NOT NOW', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: StreakItTheme.mutedGray)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}