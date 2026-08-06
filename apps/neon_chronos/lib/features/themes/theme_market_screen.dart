import 'package:flutter/material.dart';

import '../../core/sound/sound_service.dart';
import '../../core/storage/settings_controller.dart';
import '../../core/theme_engine/neon_theme.dart';
import '../../widgets/glass_panel.dart';
import 'theme_pack.dart';

class ThemeMarketScreen extends StatelessWidget {
  const ThemeMarketScreen({
    super.key,
    required this.settings,
    required this.sound,
  });

  final SettingsController settings;
  final SoundService sound;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final s = settings.settings;
        final primary = s.accent.primary;
        final secondary = s.accent.secondary;

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              Text(
                'THEME ARCHIVE',
                style: TextStyle(
                  color: primary,
                  fontSize: 13,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w700,
                  shadows: neonGlow(primary, blur: 10, spread: 0),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Local packs · marketplace-ready structure',
                style: TextStyle(
                  color: NeonColors.textSecondary,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 14),
              ...kThemeMarketplace.map((pack) {
                final active = s.accent == pack.accent &&
                    s.background == pack.background;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassPanel(
                    accent: pack.accent.primary,
                    onTap: () async {
                      await settings.setAccent(pack.accent);
                      await settings.setBackground(pack.background);
                      await sound.click();
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                pack.accent.primary,
                                pack.accent.secondary,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: pack.accent.primary.withValues(alpha: 0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pack.name.toUpperCase(),
                                style: TextStyle(
                                  color: pack.accent.primary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                pack.blurb,
                                style: const TextStyle(
                                  color: NeonColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          active ? 'ACTIVE' : 'APPLY',
                          style: TextStyle(
                            color: active ? NeonColors.ok : secondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
