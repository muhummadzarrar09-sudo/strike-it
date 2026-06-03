import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

// ── State ──────────────────────────────────────────────────────────────────

class ThemeState {
  final ThemeMode themeMode;
  final int accentIndex; // 0–5 index into AccentPalette.all

  const ThemeState({
    this.themeMode = ThemeMode.dark,
    this.accentIndex = 0,
  });

  AccentPalette get accent => AccentPalette.all[accentIndex];

  ThemeData get darkTheme => AppTheme.dark(accent: accent.primary);
  ThemeData get lightTheme => AppTheme.light(accent: accent.light);

  ThemeState copyWith({ThemeMode? themeMode, int? accentIndex}) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      accentIndex: accentIndex ?? this.accentIndex,
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────────────────

class ThemeNotifier extends Notifier<ThemeState> {
  @override
  ThemeState build() {
    // Load from prefs asynchronously after first build.
    _loadFromPrefs();
    return const ThemeState();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString(AppConstants.prefThemeMode) ?? 'dark';
    final accentIdx = prefs.getInt(AppConstants.prefAccentIndex) ?? 0;

    ThemeMode mode;
    switch (modeStr) {
      case 'light':
        mode = ThemeMode.light;
        break;
      case 'system':
        mode = ThemeMode.system;
        break;
      default:
        mode = ThemeMode.dark;
    }

    state = ThemeState(
      themeMode: mode,
      accentIndex: accentIdx.clamp(0, AccentPalette.all.length - 1),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    String modeStr;
    switch (mode) {
      case ThemeMode.light:
        modeStr = 'light';
        break;
      case ThemeMode.system:
        modeStr = 'system';
        break;
      default:
        modeStr = 'dark';
    }
    await prefs.setString(AppConstants.prefThemeMode, modeStr);
  }

  Future<void> setAccent(int index) async {
    final clamped = index.clamp(0, AccentPalette.all.length - 1);
    state = state.copyWith(accentIndex: clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefAccentIndex, clamped);
  }

  void toggleTheme() {
    final next = state.themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    setThemeMode(next);
  }
}

// ── Provider ───────────────────────────────────────────────────────────────

final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(
  ThemeNotifier.new,
);
