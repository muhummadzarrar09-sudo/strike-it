import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const SectionHeader({super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: StreakItTheme.textTheme.labelLarge),
              if (subtitle != null)
                Text(subtitle!, style: StreakItTheme.textTheme.bodySmall?.copyWith(color: StreakItTheme.mutedGray)),
            ],
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
