import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app_shell.dart';
import 'core/sound/sound_service.dart';
import 'core/storage/settings_controller.dart';
import 'core/theme_engine/neon_theme.dart';
import 'features/alarm/alarm_controller.dart';
import 'features/clock_faces/face_config_controller.dart';
import 'features/feed/feed_controller.dart';
import 'features/focus/focus_controller.dart';
import 'features/home/home_layout_controller.dart';
import 'features/statistics/stats_controller.dart';
import 'features/world_clock/world_clock_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: NeonColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const NeonChronosApp());
}

class NeonChronosApp extends StatefulWidget {
  const NeonChronosApp({super.key});

  @override
  State<NeonChronosApp> createState() => _NeonChronosAppState();
}

class _NeonChronosAppState extends State<NeonChronosApp> {
  final SettingsController _settings = SettingsController();
  final SoundService _sound = SoundService();
  final WorldClockController _world = WorldClockController();
  late final AlarmController _alarms = AlarmController(sound: _sound);
  final FeedController _feed = FeedController();
  final FocusController _focus = FocusController();
  final StatsController _stats = StatsController();
  final FaceConfigController _faces = FaceConfigController();
  final HomeLayoutController _homeLayout = HomeLayoutController();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      _settings.load(),
      _world.load(),
      _alarms.load(),
      _feed.load(),
      _focus.load(),
      _stats.load(),
      _faces.load(),
      _homeLayout.load(),
    ]);
    _sound.syncFrom(_settings.settings);
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _settings.dispose();
    _world.dispose();
    _alarms.dispose();
    _feed.dispose();
    _focus.dispose();
    _stats.dispose();
    _faces.dispose();
    _homeLayout.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        return MaterialApp(
          title: 'Neon Chronos',
          debugShowCheckedModeBanner: false,
          theme: buildNeonTheme(accent: _settings.settings.accent),
          home: !_loaded
              ? const Scaffold(
                  backgroundColor: NeonColors.background,
                  body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : AppShell(
                  settings: _settings,
                  sound: _sound,
                  world: _world,
                  alarms: _alarms,
                  feed: _feed,
                  focus: _focus,
                  stats: _stats,
                  faces: _faces,
                  homeLayout: _homeLayout,
                ),
        );
      },
    );
  }
}
