import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/extensions.dart';
import '../../providers/database_providers.dart';
import '../../providers/habit_providers.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _localAuth = LocalAuthentication();
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _exportingCSV = false;
  bool _exportingBackup = false;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    bool available = false;
    try {
      available = await _localAuth.canCheckBiometrics;
    } on PlatformException catch (e) {
      debugPrint('[Settings] canCheckBiometrics: $e');
    }

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _biometricEnabled =
          prefs.getBool(AppConstants.prefBiometricEnabled) ?? false;
      _biometricAvailable = available;
      _userName = prefs.getString('user_name') ?? '';
    });
  }

  Future<void> _editName() async {
    final ctrl = TextEditingController(text: _userName);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Your Name'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Enter your name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', result);
    if (mounted) setState(() => _userName = result);
  }

  Future<void> _toggleBiometric(bool enable) async {
    if (enable) {
      // FIX 2: authenticate FIRST, only save if auth succeeds.
      // Revert toggle with helpful message on failure.
      bool authenticated = false;
      try {
        authenticated = await _localAuth.authenticate(
          localizedReason: 'Verify your identity to enable lock',
          options: AuthenticationOptions(biometricOnly: false),
        );
      } on PlatformException catch (e) {
        debugPrint('[Settings] Biometric error: ${e.code} — ${e.message}');
        if (!mounted) return;

        // notEnrolled / notAvailable → guide user to device settings
        if (e.code == 'NotEnrolled' ||
            e.code == 'notEnrolled' ||
            e.code == 'no_fragment_activity' ||
            e.code == 'NotAvailable' ||
            e.code == 'notAvailable') {
          context.showSnack(
            'No biometrics enrolled. Go to Settings → Security to add a fingerprint or face.',
            isError: true,
          );
        } else {
          context.showSnack('Authentication cancelled.', isError: true);
        }
        // Revert toggle — auth failed, do not enable
        setState(() => _biometricEnabled = false);
        return;
      }

      if (!authenticated) {
        // User cancelled (returned false without exception)
        if (mounted) {
          context.showSnack('Authentication cancelled.', isError: true);
          setState(() => _biometricEnabled = false);
        }
        return;
      }

      // Auth succeeded → save and confirm
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.prefBiometricEnabled, true);
      if (mounted) {
        setState(() => _biometricEnabled = true);
        context.showSnack('Biometric lock enabled ✓');
      }
      return;
    }

    // Disabling biometric — no auth needed, just save
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefBiometricEnabled, false);
    if (mounted) setState(() => _biometricEnabled = false);
  }

  Future<void> _exportCSV() async {
    if (_exportingCSV) return;
    setState(() => _exportingCSV = true);
    try {
      await ref.read(exportServiceProvider).exportCSV();
      if (mounted) context.showSnack('Exported ✓  Check your share sheet.');
    } catch (e) {
      if (mounted) {
        context.showSnack('Export failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _exportingCSV = false);
    }
  }

  Future<void> _exportBackup() async {
    if (_exportingBackup) return;
    setState(() => _exportingBackup = true);
    try {
      await ref.read(exportServiceProvider).exportBackup();
      if (mounted) context.showSnack('Backup saved ✓');
    } catch (e) {
      if (mounted) {
        context.showSnack('Backup failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _exportingBackup = false);
    }
  }

  Future<void> _rescheduleNotifications() async {
    try {
      final habits = await ref.read(habitRepositoryProvider).getAllActive();
      await ref.read(notificationServiceProvider).rescheduleAll(habits);
      if (mounted) context.showSnack('Reminders rescheduled ✓');
    } catch (e) {
      if (mounted) {
        context.showSnack('Could not reschedule: $e', isError: true);
      }
    }
  }


  Future<void> _testNotification() async {
    try {
      await ref.read(notificationServiceProvider).showTestNotification();
      if (mounted) {
        context.showSnack('Test notification fires in 5 seconds 🔔');
      }
    } catch (e) {
      if (mounted) {
        context.showSnack('Test failed: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final isDark = theme.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Profile ────────────────────────────────────────────────────────
          _Header('Profile'),
          _Tile(
            icon: Icons.person_outline,
            label: 'Your Name',
            subtitle: _userName.isEmpty ? 'Tap to set your name' : null,
            trailing: _userName.isEmpty
                ? const SizedBox.shrink()
                : Text(
                    _userName,
                    style: AppTypography.labelMedium.copyWith(
                        color: context.textMuted),
                  ),
            onTap: _editName,
          ),
          const Divider(height: 1, indent: 20),

          // ── Appearance ─────────────────────────────────────────────────
          _Header('Appearance'),
          _Tile(
            icon: Icons.dark_mode,
            label: 'Dark Mode',
            trailing: Switch(
              value: isDark,
              onChanged: (_) =>
                  ref.read(themeProvider.notifier).toggleTheme(),
            ),
          ),
          _Tile(
            icon: Icons.palette,
            label: 'Accent Color',
            trailing: const SizedBox.shrink(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(54, 0, 20, 16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AccentPalette.all.asMap().entries.map((e) {
                final i = e.key;
                final palette = e.value;
                final selected = theme.accentIndex == i;
                return GestureDetector(
                  onTap: () =>
                      ref.read(themeProvider.notifier).setAccent(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: palette.primary,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(
                              color: context.isDark
                                  ? Colors.white
                                  : Colors.black,
                              width: 2.5,
                            )
                          : null,
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: palette.primary.withValues(alpha: 0.45),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 15)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1, indent: 20),

          // ── Notifications ──────────────────────────────────────────────
          _Header('Notifications'),
          _Tile(
            icon: Icons.notifications,
            label: 'Reschedule Reminders',
            subtitle: 'Run this if reminders stopped working.',
            trailing:
                Icon(Icons.refresh, size: 18,
                    color: context.textSecondary),
            onTap: _rescheduleNotifications,
          ),
          _Tile(
            icon: Icons.notifications_active,
            label: 'Test Notification',
            subtitle: 'Fires in 5 seconds — tap to verify reminders work.',
            trailing: Icon(Icons.play_arrow, size: 18,
                color: context.textSecondary),
            onTap: _testNotification,
          ),
          const Divider(height: 1, indent: 20),

          // ── Security ───────────────────────────────────────────────────
          _Header('Security'),
          _biometricAvailable
              ? _Tile(
                  icon: Icons.fingerprint,
                  label: 'Biometric Lock',
                  subtitle: 'Require fingerprint or face to open the app.',
                  trailing: Switch(
                    value: _biometricEnabled,
                    onChanged: _toggleBiometric,
                  ),
                )
              : _Tile(
                  icon: Icons.fingerprint,
                  label: 'Biometric Lock',
                  subtitle: 'Not supported on this device.',
                  trailing: Text(
                    'Unavailable',
                    style: AppTypography.labelSmall
                        .copyWith(color: context.textMuted),
                  ),
                ),
          const Divider(height: 1, indent: 20),

          // ── Data ───────────────────────────────────────────────────────
          _Header('Data & Export'),
          _Tile(
            icon: Icons.description,
            label: 'Export to CSV',
            subtitle: 'Share your full habit history as a spreadsheet.',
            trailing: _exportingCSV
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.open_in_new, size: 18,
                    color: context.textSecondary),
            onTap: _exportingCSV ? null : _exportCSV,
          ),
          _Tile(
            icon: Icons.save_alt,
            label: 'Backup to Device',
            subtitle: 'Save a full JSON backup of all your data.',
            trailing: _exportingBackup
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.download, size: 18,
                    color: context.textSecondary),
            onTap: _exportingBackup ? null : _exportBackup,
          ),
          _Tile(
            icon: Icons.verified_user,
            label: 'Privacy First',
            subtitle:
                'All data stays on your device. No account. No cloud. No tracking. Ever.',
            trailing: const SizedBox.shrink(),
          ),
          const Divider(height: 1, indent: 20),

          // ── About ──────────────────────────────────────────────────────
          _Header('About'),
          _Tile(
            icon: Icons.info_outline,
            label: 'Version',
            trailing: Text(
              AppConstants.appVersion,
              style: AppTypography.labelMedium
                  .copyWith(color: context.textMuted),
            ),
          ),
          _Tile(
            icon: Icons.local_fire_department,
            label: 'Streak It',
            subtitle: 'Build habits. Break limits.',
            trailing: const SizedBox.shrink(),
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

// ── Supporting widgets ─────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 6),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: context.textMuted,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _Tile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.trailing,
    this.onTap,
  });


  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: context.textSecondary, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.bodyMedium
                        .copyWith(color: context.textPrimary),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTypography.bodySmall
                          .copyWith(color: context.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing,
          ],
        ),
      ),
    );
  }
}
