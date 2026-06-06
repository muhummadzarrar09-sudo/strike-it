import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import '../../../core/constants/app_constants.dart';

class WidgetService {
  WidgetService._();
  static final _instance = WidgetService._();
  static WidgetService get instance => _instance;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await HomeWidget.setAppGroupId(AppConstants.packageName);
    _initialized = true;
  }

  Future<void> updateStreakWidget({required int streak, required bool hasCheckedInToday}) async {
    if (!_initialized) await init();
    try {
      await HomeWidget.saveWidgetData('streak', streak);
      await HomeWidget.saveWidgetData('checked_in_today', hasCheckedInToday);
      await HomeWidget.updateWidget(
        androidName: AppConstants.androidWidgetProvider,
        qualifiedAndroidName: 'app.streakit.android.StreakItWidgetProvider',
      );
    } catch (e) {
      // Widget update is best-effort
    }
  }

  Future<void> updateQuickCheckWidget({required List<String> habitNames, required List<bool> completed}) async {
    if (!_initialized) await init();
    try {
      await HomeWidget.saveWidgetData('habit_names', habitNames.join(','));
      await HomeWidget.saveWidgetData('habit_completed', completed.map((c) => c ? '1' : '0').join(','));
      await HomeWidget.updateWidget(
        androidName: 'QuickCheckWidgetProvider',
        qualifiedAndroidName: 'app.streakit.android.QuickCheckWidgetProvider',
      );
    } catch (e) {
      // Best effort
    }
  }

  Future<void> updateProgressWidget({required double percent}) async {
    if (!_initialized) await init();
    try {
      await HomeWidget.saveWidgetData('progress_percent', percent);
      await HomeWidget.updateWidget(
        androidName: 'ProgressRingWidgetProvider',
        qualifiedAndroidName: 'app.streakit.android.ProgressRingWidgetProvider',
      );
    } catch (e) {
      // Best effort
    }
  }
}

final widgetServiceProvider = Provider<WidgetService>((ref) => WidgetService.instance);
