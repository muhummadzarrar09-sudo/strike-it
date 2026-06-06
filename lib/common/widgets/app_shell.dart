import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../features/habits/screens/today_screen.dart';
import '../../features/habits/screens/habits_list_screen.dart';
import '../../features/analytics/screens/analytics_screen.dart';
import '../../features/journal/screens/journal_screen.dart';

final selectedTabProvider = StateProvider<int>((ref) => 0);

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _tabs = [
    ('Today', Icons.bolt),
    ('Habits', Icons.grid_3x3),
    ('Stats', Icons.trending_up),
    ('Journal', Icons.edit_note),
  ];

  static const _screens = [
    TodayScreen(),
    HabitsListScreen(),
    AnalyticsScreen(),
    JournalScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedTabProvider);

    return Scaffold(
      backgroundColor: StreakItTheme.black,
      body: IndexedStack(
        index: selected,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: StreakItTheme.darkGray, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: selected,
          onTap: (i) => ref.read(selectedTabProvider.notifier).state = i,
          backgroundColor: StreakItTheme.nearBlack,
          selectedItemColor: StreakItTheme.accent,
          unselectedItemColor: StreakItTheme.mutedGray,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, letterSpacing: 0.5),
          items: _tabs
              .map((t) => BottomNavigationBarItem(
                    icon: Icon(t.1),
                    activeIcon: Icon(t.1, color: StreakItTheme.accent),
                    label: t.0,
                  ))
              .toList(),
        ),
      ),
    );
  }
}
