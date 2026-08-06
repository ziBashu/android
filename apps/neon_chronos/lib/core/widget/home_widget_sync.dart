import 'package:home_widget/home_widget.dart';

import '../clock_engine/clock_format.dart';
import '../storage/app_settings.dart';

/// Pushes time + label to Android home screen widget.
class HomeWidgetSync {
  static const androidName = 'ChronosWidgetProvider';

  static Future<void> update({
    required DateTime now,
    required AppSettings settings,
    String? nextAlarm,
  }) async {
    try {
      final time = ClockFormat.timeHm(now, hour24: settings.hour24);
      await HomeWidget.saveWidgetData<String>('time', time);
      await HomeWidget.saveWidgetData<String>('title', 'NEON CHRONOS');
      await HomeWidget.saveWidgetData<String>(
        'subtitle',
        nextAlarm == null ? 'SYSTEM NORMAL' : 'NEXT $nextAlarm',
      );
      await HomeWidget.updateWidget(
        androidName: androidName,
        qualifiedAndroidName: 'com.zibashu.neon_chronos.ChronosWidgetProvider',
      );
    } catch (_) {
      // Widget optional; never crash the app.
    }
  }
}
