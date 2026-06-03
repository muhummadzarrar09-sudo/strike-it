import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


import '../../../core/constants/habit_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/extensions.dart';
import '../../providers/database_providers.dart';
import '../../providers/habit_providers.dart';
import '../../providers/theme_provider.dart';

class AddEditHabitScreen extends ConsumerStatefulWidget {
  final String? editHabitId;
  const AddEditHabitScreen({super.key, this.editHabitId});

  bool get isEditing => editHabitId != null;

  @override
  ConsumerState<AddEditHabitScreen> createState() =>
      _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends ConsumerState<AddEditHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _colorHex = '#F59E0B';
  String _iconId = 'star';
  String _kind = 'binary';
  int _targetCount = 1;
  String _freqType = 'daily';
  List<int> _targetDays = [];
  int _graceDays = 0;
  bool _isNegative = false;
  List<String> _reminders = [];
  bool _isSaving = false;
  bool _loaded = false;

  static const _weekdays = [
    (1, 'Mon'), (2, 'Tue'), (3, 'Wed'),
    (4, 'Thu'), (5, 'Fri'), (6, 'Sat'), (7, 'Sun'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _loadExisting();
  }

  Future<void> _loadExisting() async {
    final h = await ref.read(habitRepositoryProvider).getById(widget.editHabitId!);
    if (h == null || !mounted) return;
    setState(() {
      _nameCtrl.text = h.name;
      _descCtrl.text = h.description ?? '';
      _colorHex = h.colorHex;
      _iconId = h.iconId;
      _kind = h.kind;
      _targetCount = h.targetCount;
      _freqType = h.frequencyType;
      _targetDays = h.targetDays.isEmpty
          ? []
          : h.targetDays.split(',').map(int.parse).toList();
      _graceDays = h.graceDays;
      _isNegative = h.isNegative;
      _reminders = h.reminderTimes.isEmpty ? [] : h.reminderTimes.split(',');
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final repo = ref.read(habitRepositoryProvider);
      final notifService = ref.read(notificationServiceProvider);

      if (widget.isEditing) {
        await repo.updateHabit(
          id: widget.editHabitId!,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim().blankToNull,
          colorHex: _colorHex,
          iconId: _iconId,
          kind: _kind,
          targetCount: _targetCount,
          frequencyType: _freqType,
          targetDays: _targetDays,
          graceDays: _graceDays,
          isNegative: _isNegative,
          reminderTimes: _reminders,
        );
      } else {
        final existing = await repo.getAllActive();
        await repo.createHabit(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim().blankToNull,
          colorHex: _colorHex,
          iconId: _iconId,
          kind: _kind,
          targetCount: _targetCount,
          frequencyType: _freqType,
          targetDays: _targetDays,
          graceDays: _graceDays,
          isNegative: _isNegative,
          reminderTimes: _reminders,
          sortOrder: existing.length,
        );
      }

      // Always reschedule after any habit change.
      final allHabits = await repo.getAllActive();
      await notifService.rescheduleAll(allHabits);

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) context.showSnack('Failed to save: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = ref.watch(themeProvider).accent.primary;

    if (widget.isEditing && !_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Habit' : 'New Habit'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: context.pop,
        ),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Center(
                    child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: Text(
                    'Save',
                    style: AppTypography.labelLarge.copyWith(color: accent),
                  ),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            // ── Name ────────────────────────────────────────────────────
            _Label('Habit Name'),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'e.g. Morning run, Read 20 pages...',
              ),
              style: AppTypography.bodyLarge.copyWith(color: context.textPrimary),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Name your habit.';
                if (v.trim().length > 100) return 'Max 100 chars.';
                return null;
              },
              maxLength: 100,
            ),

            const SizedBox(height: 20),

            // ── Description ──────────────────────────────────────────────
            _Label('Why this habit? (optional)'),
            TextFormField(
              controller: _descCtrl,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Your "why" — it keeps you going when motivation fades.',
              ),
              style: AppTypography.bodyMedium.copyWith(color: context.textPrimary),
              maxLength: 300,
            ),

            const SizedBox(height: 20),

            // ── Color ────────────────────────────────────────────────────
            _Label('Color'),
            _ColorGrid(
              selected: _colorHex,
              onChanged: (h) => setState(() => _colorHex = h),
            ),

            const SizedBox(height: 20),

            // ── Icon ─────────────────────────────────────────────────────
            _Label('Icon'),
            _IconGrid(
              selectedId: _iconId,
              colorHex: _colorHex,
              onChanged: (id) => setState(() => _iconId = id),
            ),

            const SizedBox(height: 20),

            // ── Habit type ────────────────────────────────────────────────
            _Label('Habit Type'),
            Row(
              children: [
                _Chip(
                  label: 'Do it ✓',
                  selected: !_isNegative,
                  accent: accent,
                  onTap: () => setState(() => _isNegative = false),
                ),
                const SizedBox(width: 10),
                _Chip(
                  label: 'Avoid it ✗',
                  selected: _isNegative,
                  accent: AppColors.destructive,
                  onTap: () => setState(() => _isNegative = true),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Tracking ──────────────────────────────────────────────────
            _Label('Tracking Method'),
            Row(
              children: [
                _Chip(
                  label: 'Yes / No',
                  selected: _kind == 'binary',
                  accent: accent,
                  onTap: () => setState(() => _kind = 'binary'),
                ),
                const SizedBox(width: 10),
                _Chip(
                  label: 'Count-based',
                  selected: _kind == 'quantified',
                  accent: accent,
                  onTap: () => setState(() => _kind = 'quantified'),
                ),
              ],
            ),

            if (_kind == 'quantified') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Daily target:',
                    style: AppTypography.bodyMedium.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _CounterRow(
                    value: _targetCount,
                    accent: accent,
                    onChanged: (v) => setState(() => _targetCount = v),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // ── Schedule ──────────────────────────────────────────────────
            _Label('Schedule'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Chip(
                  label: 'Every day',
                  selected: _freqType == 'daily',
                  accent: accent,
                  onTap: () => setState(() {
                    _freqType = 'daily';
                    _targetDays = [];
                  }),
                ),
                _Chip(
                  label: 'Weekdays',
                  selected: _freqType == 'weekdays',
                  accent: accent,
                  onTap: () => setState(() {
                    _freqType = 'weekdays';
                    _targetDays = [1, 2, 3, 4, 5];
                  }),
                ),
                _Chip(
                  label: 'Weekends',
                  selected: _freqType == 'weekends',
                  accent: accent,
                  onTap: () => setState(() {
                    _freqType = 'weekends';
                    _targetDays = [6, 7];
                  }),
                ),
                _Chip(
                  label: 'Custom',
                  selected: _freqType == 'custom',
                  accent: accent,
                  onTap: () => setState(() {
                    _freqType = 'custom';
                    _targetDays = [];
                  }),
                ),
              ],
            ),

            if (_freqType == 'custom') ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _weekdays.map((day) {
                  final sel = _targetDays.contains(day.$1);
                  return _Chip(
                    label: day.$2,
                    selected: sel,
                    accent: accent,
                    onTap: () {
                      setState(() {
                        if (sel) {
                          _targetDays.remove(day.$1);
                        } else {
                          _targetDays.add(day.$1);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 20),

            // ── Grace days ────────────────────────────────────────────────
            _Label('Grace Days — Streak Protection'),
            Text(
              _graceDays == 0
                  ? 'No grace days — miss once and your streak resets.'
                  : 'Allow $_graceDays missed day${_graceDays > 1 ? 's' : ''} without breaking the streak.',
              style: AppTypography.bodySmall.copyWith(color: context.textMuted),
            ),
            Slider(
              value: _graceDays.toDouble(),
              min: 0,
              max: 3,
              divisions: 3,
              label: '$_graceDays',
              onChanged: (v) => setState(() => _graceDays = v.round()),
            ),

            const SizedBox(height: 20),

            // ── Reminders ─────────────────────────────────────────────────
            _Label('Reminders'),
            ..._reminders.asMap().entries.map(
              (e) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.notifications,
                    color: accent, size: 20),
                title: Text(
                  e.value,
                  style: AppTypography.bodyMedium
                      .copyWith(color: context.textPrimary),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: AppColors.destructive, size: 18),
                  onPressed: () =>
                      setState(() => _reminders.removeAt(e.key)),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _addReminder,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Reminder'),
            ),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Future<void> _addReminder() async {
    final t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (t == null) return;
    final s =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (!_reminders.contains(s)) _reminders.add(s);
    });
  }
}

// ── Supporting widgets ─────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: AppTypography.titleSmall.copyWith(color: context.textSecondary),
        ),
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.14) : context.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusCircle),
          border: Border.all(
            color: selected ? accent : context.borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: selected ? accent : context.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _ColorGrid extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _ColorGrid({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: AppColors.habitColors.map((c) {
        final hex =
            '#${c.value.toRadixString(16).substring(2).toUpperCase()}';
        final isSel = hex.toLowerCase() == selected.toLowerCase();
        return GestureDetector(
          onTap: () => onChanged(hex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: isSel ? Border.all(color: Colors.white, width: 2.5) : null,
              boxShadow: isSel
                  ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 8)]
                  : null,
            ),
            child: isSel
                ? const Icon(Icons.check,
                    color: Colors.white, size: 15)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

class _IconGrid extends StatefulWidget {
  final String selectedId;
  final String colorHex;
  final ValueChanged<String> onChanged;

  const _IconGrid({
    required this.selectedId,
    required this.colorHex,
    required this.onChanged,
  });

  @override
  State<_IconGrid> createState() => _IconGridState();
}

class _IconGridState extends State<_IconGrid> {
  bool _expanded = false;

  Color get _c {
    try {
      return Color(
          int.parse('FF${widget.colorHex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.brand;
    }
  }

  @override
  Widget build(BuildContext context) {
    final icons =
        _expanded ? HabitIcons.all : HabitIcons.all.take(14).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: icons.map((entry) {
            final sel = entry.id == widget.selectedId;
            return GestureDetector(
              onTap: () => widget.onChanged(entry.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: sel ? _c.withValues(alpha: 0.18) : context.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  border: Border.all(
                    color: sel ? _c : context.borderColor,
                    width: sel ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    entry.icon,
                    color: sel ? _c : context.textMuted,
                    size: 20,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        TextButton(
          onPressed: () => setState(() => _expanded = !_expanded),
          child: Text(_expanded ? 'Show less' : 'Show all icons'),
        ),
      ],
    );
  }
}

class _CounterRow extends StatelessWidget {
  final int value;
  final Color accent;
  final ValueChanged<int> onChanged;

  const _CounterRow({
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CBtn(
          icon: Icons.remove,
          enabled: value > 1,
          accent: accent,
          onTap: () => onChanged(value - 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            '$value',
            style: AppTypography.statMedium.copyWith(color: context.textPrimary),
          ),
        ),
        _CBtn(
          icon: Icons.add,
          enabled: value < 999,
          accent: accent,
          onTap: () => onChanged(value + 1),
        ),
      ],
    );
  }
}

class _CBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final Color accent;
  final VoidCallback onTap;

  const _CBtn({
    required this.icon,
    required this.enabled,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? accent.withValues(alpha: 0.12) : context.surface2Color,
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          border: Border.all(color: context.borderColor),
        ),
        child: Icon(
          icon,
          size: 15,
          color: enabled ? accent : context.textMuted,
        ),
      ),
    );
  }
}
