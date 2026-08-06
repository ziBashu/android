import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/clock_engine/clock_format.dart';
import '../../core/clock_engine/clock_ticker.dart';
import '../../core/engine/clock_face_config.dart';
import '../../core/storage/settings_controller.dart';
import '../../core/theme_engine/neon_theme.dart';
import '../clock_faces/advanced_faces.dart';
import '../clock_faces/face_config_controller.dart';

/// Desk-clock / ambient environment (charging or manual).
class AmbientScreen extends StatefulWidget {
  const AmbientScreen({
    super.key,
    required this.ticker,
    required this.settings,
    required this.faces,
    this.charging = false,
  });

  final ClockTicker ticker;
  final SettingsController settings;
  final FaceConfigController faces;
  final bool charging;

  @override
  State<AmbientScreen> createState() => _AmbientScreenState();
}

class _AmbientScreenState extends State<AmbientScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.ticker,
        widget.settings,
        widget.faces,
      ]),
      builder: (context, _) {
        final s = widget.settings.settings;
        final primary = s.accent.primary;
        final secondary = s.accent.secondary;
        final now = widget.ticker.now;
        // Dim for night ambient
        final dim = s.glow.clamp(0.25, 0.7);

        return GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Opacity(
              opacity: 0.55 + dim * 0.45,
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.charging ? 'NEON MODE · DOCKED' : 'AMBIENT MODE',
                        style: TextStyle(
                          color: secondary.withValues(alpha: 0.7),
                          letterSpacing: 3,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: 280,
                        height: 280,
                        child: AdvancedClockFace(
                          now: now,
                          settings: s,
                          face: widget.faces.config.copyWith(
                            kind: FaceKind.digitalHud,
                            glow: dim,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        ClockFormat.timeHm(now, hour24: s.hour24),
                        style: TextStyle(
                          color: primary,
                          fontSize: 56,
                          fontWeight: FontWeight.w200,
                          letterSpacing: 6,
                          shadows: neonGlow(primary, blur: 20, intensity: dim),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) {
                          return Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primary.withValues(alpha: 0.5 + i * 0.15),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'TAP TO EXIT',
                        style: TextStyle(
                          color: NeonColors.textSecondary.withValues(alpha: 0.4),
                          fontSize: 10,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
