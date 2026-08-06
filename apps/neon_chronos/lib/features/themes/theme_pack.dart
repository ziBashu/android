import '../../core/theme_engine/accent.dart';

/// Local theme pack (marketplace-ready structure, offline only).
class ThemePack {
  const ThemePack({
    required this.id,
    required this.name,
    required this.blurb,
    required this.accent,
    required this.background,
    this.installed = true,
    this.builtIn = true,
  });

  final String id;
  final String name;
  final String blurb;
  final NeonAccent accent;
  final BackgroundMode background;
  final bool installed;
  final bool builtIn;
}

const kThemeMarketplace = <ThemePack>[
  ThemePack(
    id: 'cyber_city',
    name: 'Cyber City',
    blurb: 'Neon streets · cyan grid horizon',
    accent: NeonAccent.cyanMatrix,
    background: BackgroundMode.cyberGrid,
  ),
  ThemePack(
    id: 'deep_space',
    name: 'Deep Space',
    blurb: 'Void purple · drifting stars',
    accent: NeonAccent.purpleVoid,
    background: BackgroundMode.spaceMode,
  ),
  ThemePack(
    id: 'retro_terminal',
    name: 'Retro Terminal',
    blurb: 'Green phosphor · digital rain',
    accent: NeonAccent.greenTerminal,
    background: BackgroundMode.digitalRain,
  ),
  ThemePack(
    id: 'minimal_white',
    name: 'Minimal White',
    blurb: 'Clean future · soft white core',
    accent: NeonAccent.whiteFuture,
    background: BackgroundMode.cyberGrid,
  ),
  ThemePack(
    id: 'industrial',
    name: 'Industrial',
    blurb: 'Red warning · heavy grid',
    accent: NeonAccent.redWarning,
    background: BackgroundMode.cyberGrid,
  ),
];
