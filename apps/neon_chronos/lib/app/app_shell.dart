import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/clock_engine/clock_ticker.dart';
import '../core/sound/sound_service.dart';
import '../core/storage/settings_controller.dart';
import '../core/theme_engine/neon_theme.dart';
import '../core/widget/home_widget_sync.dart';
import '../features/alarm/alarm_controller.dart';
import '../features/alarm/alarm_ring_overlay.dart';
import '../features/alarm/alarm_screen.dart';
import '../features/ambient/ambient_screen.dart';
import '../features/boot/boot_overlay.dart';
import '../features/clock/clock_screen.dart';
import '../features/clock_faces/face_config_controller.dart';
import '../features/feed/feed_controller.dart';
import '../features/focus/focus_controller.dart';
import '../features/home/chronos_home_screen.dart';
import '../features/home/home_layout_controller.dart';
import '../features/more/more_screen.dart';
import '../features/statistics/stats_controller.dart';
import '../features/timer/timer_controllers.dart';
import '../features/timer/timer_suite_screen.dart';
import '../features/world_clock/world_clock_controller.dart';
import '../features/world_clock/world_clock_screen.dart';
import '../widgets/backgrounds/background_layer.dart';
import '../widgets/glass_panel.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.settings,
    required this.sound,
    required this.world,
    required this.alarms,
    required this.feed,
    required this.focus,
    required this.stats,
    required this.faces,
    required this.homeLayout,
  });

  final SettingsController settings;
  final SoundService sound;
  final WorldClockController world;
  final AlarmController alarms;
  final FeedController feed;
  final FocusController focus;
  final StatsController stats;
  final FaceConfigController faces;
  final HomeLayoutController homeLayout;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with TickerProviderStateMixin {
  late final ClockTicker _ticker;
  late final CountdownController _countdown;
  late final ChronosStopwatch _stopwatch;
  final _battery = Battery();
  int _tab = 0;
  bool _booting = true;
  bool _charging = false;
  bool _ambientOffered = false;
  DateTime? _lastWidgetSync;

  @override
  void initState() {
    super.initState();
    _ticker = ClockTicker()..start();
    _countdown = CountdownController(sound: widget.sound);
    _stopwatch = ChronosStopwatch(sound: widget.sound);
    _ticker.addListener(_onTick);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _watchBattery();
  }

  Future<void> _watchBattery() async {
    try {
      _battery.onBatteryStateChanged.listen((state) {
        final charging =
            state == BatteryState.charging || state == BatteryState.full;
        if (!mounted) return;
        setState(() => _charging = charging);
        if (charging && !_ambientOffered && !_booting) {
          _ambientOffered = true;
          _offerAmbient();
        }
        if (!charging) _ambientOffered = false;
      });
    } catch (_) {}
  }

  void _offerAmbient() {
    if (!mounted) return;
    final primary = widget.settings.settings.accent.primary;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: NeonColors.surface.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: primary.withValues(alpha: 0.4)),
        ),
        content: Text(
          'Charging detected · Ambient Mode ready',
          style: TextStyle(color: primary, letterSpacing: 0.4),
        ),
        action: SnackBarAction(
          label: 'OPEN',
          textColor: NeonColors.ok,
          onPressed: () {
            Navigator.of(context).push(
              PageRouteBuilder<void>(
                pageBuilder: (_, a, __) => AmbientScreen(
                  ticker: _ticker,
                  settings: widget.settings,
                  faces: widget.faces,
                  charging: true,
                ),
                transitionsBuilder: (_, a, __, child) {
                  return FadeTransition(opacity: a, child: child);
                },
                transitionDuration: const Duration(milliseconds: 400),
              ),
            );
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _onTick() {
    final now = _ticker.now;
    widget.alarms.tick(now);
    if (_countdown.running) _countdown.tick(now);

    final last = _lastWidgetSync;
    if (last == null ||
        now.difference(last).inSeconds >= 30 ||
        now.minute != last.minute) {
      _lastWidgetSync = now;
      final next = widget.alarms.nextFireTime(now);
      final nextLabel = next == null
          ? null
          : '${next.hour.toString().padLeft(2, '0')}:${next.minute.toString().padLeft(2, '0')}';
      HomeWidgetSync.update(
        now: now,
        settings: widget.settings.settings,
        nextAlarm: nextLabel,
      );
    }
  }

  @override
  void dispose() {
    _ticker.removeListener(_onTick);
    _ticker.dispose();
    _countdown.dispose();
    _stopwatch.dispose();
    super.dispose();
  }

  Widget _page(int index) {
    switch (index) {
      case 0:
        return ChronosHomeScreen(
          ticker: _ticker,
          settings: widget.settings,
          alarms: widget.alarms,
          feed: widget.feed,
          focus: widget.focus,
          stats: widget.stats,
          layout: widget.homeLayout,
          sound: widget.sound,
          onOpenTab: (i) => setState(() => _tab = i.clamp(0, 5)),
        );
      case 1:
        return ClockScreen(
          ticker: _ticker,
          settings: widget.settings,
          sound: widget.sound,
          alarms: widget.alarms,
          faces: widget.faces,
        );
      case 2:
        return WorldClockScreen(
          ticker: _ticker,
          settings: widget.settings,
          world: widget.world,
          sound: widget.sound,
        );
      case 3:
        return AlarmScreen(
          settings: widget.settings,
          alarms: widget.alarms,
          sound: widget.sound,
        );
      case 4:
        return TimerSuiteScreen(
          ticker: _ticker,
          settings: widget.settings,
          sound: widget.sound,
          countdown: _countdown,
          stopwatch: _stopwatch,
        );
      default:
        return MoreScreen(
          ticker: _ticker,
          settings: widget.settings,
          sound: widget.sound,
          feed: widget.feed,
          focus: widget.focus,
          stats: widget.stats,
          faces: widget.faces,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.settings, widget.alarms]),
      builder: (context, _) {
        final s = widget.settings.settings;
        final primary = s.accent.primary;
        final secondary = s.accent.secondary;
        final ringing = widget.alarms.ringing;

        return Scaffold(
          backgroundColor: NeonColors.background,
          body: Stack(
            fit: StackFit.expand,
            children: [
              BackgroundLayer(settings: s),
              // Smooth tab content transition
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 340),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) {
                  final slide = Tween<Offset>(
                    begin: const Offset(0.03, 0.01),
                    end: Offset.zero,
                  ).animate(anim);
                  return FadeTransition(
                    opacity: anim,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(_tab),
                  child: _page(_tab),
                ),
              ),
              // Bottom nav fade-in after boot
              AnimatedPositioned(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                left: 12,
                right: 12,
                bottom: _booting
                    ? -80
                    : 12 + MediaQuery.paddingOf(context).bottom,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 350),
                  opacity: _booting ? 0 : 1,
                  child: _NavBar(
                    index: _tab,
                    primary: primary,
                    secondary: secondary,
                    charging: _charging,
                    onSelect: (i) {
                      if (i == _tab) return;
                      widget.sound.click();
                      setState(() => _tab = i);
                    },
                  ),
                ),
              ),
              // Alarm overlay
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 380),
                child: ringing == null
                    ? const SizedBox.shrink(key: ValueKey('no-alarm'))
                    : AlarmRingOverlay(
                        key: const ValueKey('alarm'),
                        alarm: ringing,
                        primary: primary,
                        onSnooze: () => widget.alarms.snooze(),
                        onDismiss: () => widget.alarms.dismiss(),
                      ),
              ),
              // Boot
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: _booting
                    ? BootOverlay(
                        key: const ValueKey('boot'),
                        primary: primary,
                        secondary: secondary,
                        sound: widget.sound,
                        onComplete: () {
                          if (mounted) setState(() => _booting = false);
                        },
                      )
                    : const SizedBox.shrink(key: ValueKey('booted')),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.index,
    required this.primary,
    required this.secondary,
    required this.onSelect,
    this.charging = false,
  });

  final int index;
  final Color primary;
  final Color secondary;
  final ValueChanged<int> onSelect;
  final bool charging;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, int)>[
      (Icons.home_outlined, 'HOME', 0),
      (Icons.schedule, 'TIME', 1),
      (Icons.public, 'WORLD', 2),
      (Icons.alarm, 'ALARM', 3),
      (Icons.timer_outlined, 'TOOLS', 4),
      (Icons.grid_view_rounded, 'MORE', 5),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: NeonColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: charging
              ? NeonColors.ok.withValues(alpha: 0.55)
              : primary.withValues(alpha: 0.32),
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: items.map((e) {
          return NeonNavItem(
            icon: e.$1,
            label: e.$2,
            selected: index == e.$3,
            color: primary,
            dimColor: NeonColors.textSecondary.withValues(alpha: 0.75),
            onTap: () => onSelect(e.$3),
          );
        }).toList(),
      ),
    );
  }
}
