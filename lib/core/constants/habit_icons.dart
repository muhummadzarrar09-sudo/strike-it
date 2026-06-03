import 'package:flutter/material.dart';

/// Curated icon set for habits using Flutter Material Icons.
///
/// Each entry is a [HabitIconEntry] with a unique [id], display [label],
/// and a Flutter [IconData] icon.
///
/// Icons are grouped by category for the icon-picker bottom sheet.

class HabitIconEntry {
  final String id;
  final String label;
  final IconData icon;

  const HabitIconEntry({
    required this.id,
    required this.label,
    required this.icon,
  });
}

abstract final class HabitIcons {
  static const List<HabitIconEntry> all = [
    // ── Fitness & Health ─────────────────────────────────────────────────
    HabitIconEntry(id: 'barbell', label: 'Barbell', icon: Icons.fitness_center),
    HabitIconEntry(id: 'heartbeat', label: 'Heartbeat', icon: Icons.favorite_border),
    HabitIconEntry(id: 'person_simple_run', label: 'Run', icon: Icons.directions_run),
    HabitIconEntry(id: 'bicycle', label: 'Bike', icon: Icons.directions_bike),
    HabitIconEntry(id: 'swimming_pool', label: 'Swim', icon: Icons.waves),
    HabitIconEntry(id: 'yoga', label: 'Yoga', icon: Icons.person),
    HabitIconEntry(id: 'moon', label: 'Sleep', icon: Icons.dark_mode),
    HabitIconEntry(id: 'drop', label: 'Hydration', icon: Icons.water_drop),
    HabitIconEntry(id: 'apple', label: 'Apple', icon: Icons.eco),
    HabitIconEntry(id: 'pill', label: 'Medication', icon: Icons.medication),
    HabitIconEntry(id: 'pulse', label: 'Pulse', icon: Icons.show_chart),
    HabitIconEntry(id: 'scales', label: 'Weight', icon: Icons.balance),

    // ── Mind & Wellness ───────────────────────────────────────────────────
    HabitIconEntry(id: 'brain', label: 'Brain', icon: Icons.psychology),
    HabitIconEntry(id: 'smiley', label: 'Mood', icon: Icons.sentiment_satisfied),
    HabitIconEntry(id: 'flower', label: 'Mindfulness', icon: Icons.local_florist),
    HabitIconEntry(id: 'sun', label: 'Morning', icon: Icons.wb_sunny),
    HabitIconEntry(id: 'coffee', label: 'Coffee', icon: Icons.coffee),
    HabitIconEntry(id: 'pencil_line', label: 'Journal', icon: Icons.edit_note),
    HabitIconEntry(id: 'hand_heart', label: 'Gratitude', icon: Icons.back_hand),
    HabitIconEntry(id: 'butterfly', label: 'Calm', icon: Icons.spa),

    // ── Learning & Work ───────────────────────────────────────────────────
    HabitIconEntry(id: 'book', label: 'Reading', icon: Icons.menu_book),
    HabitIconEntry(id: 'graduation_cap', label: 'Study', icon: Icons.school),
    HabitIconEntry(id: 'code', label: 'Coding', icon: Icons.code),
    HabitIconEntry(id: 'pencil', label: 'Writing', icon: Icons.edit),
    HabitIconEntry(id: 'lightbulb', label: 'Ideas', icon: Icons.lightbulb_outline),
    HabitIconEntry(id: 'chart_line', label: 'Goals', icon: Icons.show_chart),
    HabitIconEntry(id: 'presentation_chart', label: 'Work', icon: Icons.bar_chart),
    HabitIconEntry(id: 'clock', label: 'Time', icon: Icons.access_time),
    HabitIconEntry(id: 'timer', label: 'Focus', icon: Icons.timer),
    HabitIconEntry(id: 'folder', label: 'Project', icon: Icons.folder_open),

    // ── Social & Relationships ────────────────────────────────────────────
    HabitIconEntry(id: 'chat_circle', label: 'Social', icon: Icons.chat_bubble_outline),
    HabitIconEntry(id: 'phone', label: 'Call', icon: Icons.phone),
    HabitIconEntry(id: 'envelope', label: 'Email', icon: Icons.mail_outline),
    HabitIconEntry(id: 'users', label: 'Friends', icon: Icons.group),
    HabitIconEntry(id: 'heart', label: 'Love', icon: Icons.favorite_border),
    HabitIconEntry(id: 'hand_waving', label: 'Gratitude', icon: Icons.back_hand),

    // ── Finance & Productivity ────────────────────────────────────────────
    HabitIconEntry(id: 'wallet', label: 'Budget', icon: Icons.account_balance_wallet),
    HabitIconEntry(id: 'currency_dollar', label: 'Money', icon: Icons.attach_money),
    HabitIconEntry(id: 'list_checks', label: 'To-Do', icon: Icons.checklist),
    HabitIconEntry(id: 'check_square', label: 'Task', icon: Icons.check_box_outline_blank),
    HabitIconEntry(id: 'target', label: 'Target', icon: Icons.my_location),
    HabitIconEntry(id: 'trophy', label: 'Win', icon: Icons.emoji_events),

    // ── Hobbies & Lifestyle ───────────────────────────────────────────────
    HabitIconEntry(id: 'music_note', label: 'Music', icon: Icons.music_note),
    HabitIconEntry(id: 'palette', label: 'Art', icon: Icons.palette),
    HabitIconEntry(id: 'camera', label: 'Photo', icon: Icons.camera_alt),
    HabitIconEntry(id: 'game_controller', label: 'Gaming', icon: Icons.sports_esports),
    HabitIconEntry(id: 'cooking_pot', label: 'Cook', icon: Icons.restaurant),
    HabitIconEntry(id: 'plant', label: 'Garden', icon: Icons.yard),
    HabitIconEntry(id: 'dog', label: 'Pet', icon: Icons.pets),
    HabitIconEntry(id: 'car', label: 'Drive', icon: Icons.directions_car),
    HabitIconEntry(id: 'airplane', label: 'Travel', icon: Icons.flight),
    HabitIconEntry(id: 'star', label: 'Star', icon: Icons.star_border),

    // ── Negative Habits (stop these) ──────────────────────────────────────
    HabitIconEntry(id: 'cigarette', label: 'No Smoking', icon: Icons.block),
    HabitIconEntry(id: 'wine', label: 'No Alcohol', icon: Icons.block),
    HabitIconEntry(id: 'device_mobile', label: 'Screen Time', icon: Icons.smartphone),
    HabitIconEntry(id: 'cookie', label: 'No Junk', icon: Icons.cookie),
    HabitIconEntry(id: 'warning', label: 'Warning', icon: Icons.warning_amber),
    HabitIconEntry(id: 'x_circle', label: 'Stop', icon: Icons.close),
  ];

  /// Quick lookup by id. Returns first match or falls back to 'star'.
  static HabitIconEntry fromId(String id) {
    return all.firstWhere(
      (e) => e.id == id,
      orElse: () => all.firstWhere((e) => e.id == 'star'),
    );
  }
}
