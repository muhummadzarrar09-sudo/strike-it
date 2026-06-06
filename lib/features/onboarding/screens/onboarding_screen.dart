import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  final _nameCtrl = TextEditingController();

  static const _goalOptions = [
    ('🏋️', 'Fitness', 'fitness'),
    ('🧘', 'Mindfulness', 'mindfulness'),
    ('💻', 'Productivity', 'productivity'),
    ('🩺', 'Health', 'health'),
    ('🎨', 'Creativity', 'creativity'),
    ('🤝', 'Social', 'social'),
  ];

  static const _chronoOptions = [
    ('🌅', 'Early Bird', 'early_bird', 'I crush mornings'),
    ('🌙', 'Night Owl', 'night_owl', 'I come alive at night'),
    ('⚖️', 'Balanced', 'balanced', 'Depends on the day'),
  ];

  static const _motiveOptions = [
    ('📐', 'Discipline', 'discipline', 'Routine keeps me grounded'),
    ('🎁', 'Reward', 'reward', 'I need to see the payoff'),
    ('👥', 'Accountability', 'accountability', 'I thrive with others watching'),
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _nextPage() => _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  void _prevPage() => _pageCtrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);

  Future<void> _finish() async {
    await ref.read(onboardingActionsProvider).completeOnboarding(
      name: ref.read(onboardingNameProvider),
      chronotype: ref.read(onboardingChronotypeProvider),
      motivationStyle: ref.read(onboardingMotivationProvider),
      goals: ref.read(onboardingGoalsProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StreakItTheme.black,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: List.generate(4, (i) {
                  final step = ref.watch(onboardingStepProvider);
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                      color: i <= step ? StreakItTheme.accent : StreakItTheme.darkGray,
                    ),
                  );
                }),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => ref.read(onboardingStepProvider.notifier).state = i,
                children: [
                  _namePage(),
                  _chronotypePage(),
                  _motivationPage(),
                  _goalsPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _namePage() {
    final name = ref.watch(onboardingNameProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('STREAK IT', style: StreakItTheme.textTheme.displaySmall?.copyWith(color: StreakItTheme.accent)),
          const SizedBox(height: 8),
          Text('What should we call you?', style: StreakItTheme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Your data stays on your device.\nNo account required.', style: StreakItTheme.textTheme.bodyMedium?.copyWith(color: StreakItTheme.mutedGray), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            onChanged: (v) => ref.read(onboardingNameProvider.notifier).state = v,
            style: StreakItTheme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(hintText: 'Your name...'),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: name.trim().isNotEmpty ? _nextPage : null,
              child: const Text('NEXT'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chronotypePage() {
    final selected = ref.watch(onboardingChronotypeProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('When do you feel most ALIVE?', style: StreakItTheme.textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 32),
          ..._chronoOptions.map((o) => GestureDetector(
            onTap: () {
              ref.read(onboardingChronotypeProvider.notifier).state = o.$3;
              _nextPage();
            },
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected == o.$3 ? StreakItTheme.accent.withAlpha(20) : StreakItTheme.charcoal,
                border: Border.all(color: selected == o.$3 ? StreakItTheme.accent : StreakItTheme.darkGray, width: selected == o.$3 ? 2 : 1),
              ),
              child: Row(
                children: [
                  Text(o.$1, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o.$2, style: StreakItTheme.textTheme.titleMedium),
                        Text(o.$4, style: StreakItTheme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: StreakItTheme.mutedGray),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _motivationPage() {
    final selected = ref.watch(onboardingMotivationProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('What drives you?', style: StreakItTheme.textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 32),
          ..._motiveOptions.map((o) => GestureDetector(
            onTap: () {
              ref.read(onboardingMotivationProvider.notifier).state = o.$3;
              _nextPage();
            },
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected == o.$3 ? StreakItTheme.accent.withAlpha(20) : StreakItTheme.charcoal,
                border: Border.all(color: selected == o.$3 ? StreakItTheme.accent : StreakItTheme.darkGray, width: selected == o.$3 ? 2 : 1),
              ),
              child: Row(
                children: [
                  Text(o.$1, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o.$2, style: StreakItTheme.textTheme.titleMedium),
                        Text(o.$4, style: StreakItTheme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: StreakItTheme.mutedGray),
                ],
              ),
            ),
          )),
          const Spacer(),
          TextButton(onPressed: _nextPage, child: const Text('SKIP')),
        ],
      ),
    );
  }

  Widget _goalsPage() {
    final goals = ref.watch(onboardingGoalsProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('What do you want to improve?', style: StreakItTheme.textTheme.headlineMedium, textAlign: TextAlign.center),
          Text('Pick up to 3. We\'ll pre-seed habits for you.', style: StreakItTheme.textTheme.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _goalOptions.map((o) {
              final picked = goals.contains(o.$3);
              return GestureDetector(
                onTap: () {
                  final list = [...goals];
                  if (picked) {
                    list.remove(o.$3);
                  } else if (list.length < 3) {
                    list.add(o.$3);
                  }
                  ref.read(onboardingGoalsProvider.notifier).state = list;
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: picked ? StreakItTheme.accent.withAlpha(25) : StreakItTheme.charcoal,
                    border: Border.all(color: picked ? StreakItTheme.accent : StreakItTheme.darkGray, width: picked ? 2 : 1),
                  ),
                  child: Text('${o.$1} ${o.$2}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: picked ? StreakItTheme.accent : StreakItTheme.offWhite)),
                ),
              );
            }).toList(),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: goals.isNotEmpty ? _finish : null, child: const Text('LET\'S GO')),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: _finish, child: const Text('SKIP — I\'LL ADD MY OWN')),
        ],
      ),
    );
  }
}
