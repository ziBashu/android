import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';

import '../../core/clock_engine/clock_ticker.dart';
import '../../core/sound/sound_service.dart';
import '../../core/storage/settings_controller.dart';
import '../../core/theme_engine/neon_theme.dart';
import '../../widgets/glass_panel.dart';
import '../ambient/ambient_screen.dart';
import '../clock_faces/clock_builder_screen.dart';
import '../clock_faces/face_config_controller.dart';
import '../feed/feed_controller.dart';
import '../focus/focus_controller.dart';
import '../focus/focus_screen.dart';
import '../settings/settings_screen.dart';
import '../statistics/stats_controller.dart';
import '../themes/theme_market_screen.dart';
import '../viz/time_journey.dart';

/// Overflow hub: Focus, Builder, Themes, Journey, Ambient, Settings.
class MoreScreen extends StatefulWidget {
  const MoreScreen({
    super.key,
    required this.ticker,
    required this.settings,
    required this.sound,
    required this.feed,
    required this.focus,
    required this.stats,
    required this.faces,
  });

  final ClockTicker ticker;
  final SettingsController settings;
  final SoundService sound;
  final FeedController feed;
  final FocusController focus;
  final StatsController stats;
  final FaceConfigController faces;

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  final _battery = Battery();
  bool _charging = false;

  @override
  void initState() {
    super.initState();
    _pollBattery();
  }

  Future<void> _pollBattery() async {
    try {
      final state = await _battery.batteryState;
      if (mounted) {
        setState(() {
          _charging = state == BatteryState.charging ||
              state == BatteryState.full;
        });
      }
    } catch (_) {}
  }

  void _open(Widget page) {
    widget.sound.click();
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: const Duration(milliseconds: 360),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (_, anim, __, child) {
          final curved = CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0.02),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings.settings;
    final primary = s.accent.primary;
    final secondary = s.accent.secondary;

    final tiles = <(String, String, IconData, VoidCallback)>[
      (
        'FOCUS',
        'Pomodoro · history · time map',
        Icons.psychology_outlined,
        () => _open(FocusStatsScreen(
              ticker: widget.ticker,
              settings: widget.settings,
              focus: widget.focus,
              stats: widget.stats,
              sound: widget.sound,
            )),
      ),
      (
        'CLOCK BUILDER',
        'Create & share faces',
        Icons.architecture,
        () => _open(ClockBuilderScreen(
              ticker: widget.ticker,
              settings: widget.settings,
              faces: widget.faces,
              sound: widget.sound,
            )),
      ),
      (
        'THEME ARCHIVE',
        'Cyber City · Deep Space · more',
        Icons.palette_outlined,
        () => _open(ThemeMarketScreen(
              settings: widget.settings,
              sound: widget.sound,
            )),
      ),
      (
        'TIME JOURNEY',
        'Day landscape · solar path',
        Icons.wb_twilight,
        () => _open(Scaffold(
              backgroundColor: NeonColors.background,
              body: ListenableBuilder(
                listenable: Listenable.merge([widget.ticker, widget.settings]),
                builder: (context, _) => TimeJourneyScreen(
                  now: widget.ticker.now,
                  primary: widget.settings.settings.accent.primary,
                  secondary: widget.settings.settings.accent.secondary,
                ),
              ),
            )),
      ),
      (
        'AMBIENT',
        _charging ? 'Docked · desk clock' : 'Desk clock environment',
        Icons.desktop_windows_outlined,
        () => _open(AmbientScreen(
              ticker: widget.ticker,
              settings: widget.settings,
              faces: widget.faces,
              charging: _charging,
            )),
      ),
      (
        'SYSTEM',
        'Settings · feed · effects',
        Icons.tune,
        () => _open(Scaffold(
              backgroundColor: NeonColors.background,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                title: const Text('SYSTEM'),
              ),
              body: SettingsScreen(
                settings: widget.settings,
                sound: widget.sound,
                feed: widget.feed,
              ),
            )),
      ),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          Text(
            'TEMPORAL OS',
            style: TextStyle(
              color: primary,
              fontSize: 13,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w700,
              shadows: neonGlow(primary, blur: 10, spread: 0),
            ),
          ),
          Text(
            'v3.0 · digital artifact',
            style: TextStyle(
              color: secondary.withValues(alpha: 0.7),
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          if (_charging)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: GlassPanel(
                accent: NeonColors.ok,
                onTap: tiles[4].$4,
                child: Text(
                  'CHARGING DETECTED · TAP FOR AMBIENT',
                  style: TextStyle(
                    color: NeonColors.ok,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 14),
          ...tiles.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassPanel(
                accent: primary,
                onTap: t.$4,
                child: Row(
                  children: [
                    Icon(t.$3, color: primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.$1,
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            t.$2,
                            style: const TextStyle(
                              color: NeonColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: secondary.withValues(alpha: 0.6)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
