/// A known member of the ziBashu Android family (warehub / hub launcher).
class FamilyApp {
  const FamilyApp({
    required this.slug,
    required this.name,
    required this.packageId,
    required this.surface,
    required this.blurb,
    this.webRoute,
    this.available = true,
    this.accentHex = 0xFF2F6F4E,
  });

  final String slug;
  final String name;
  final String packageId;
  final String surface;
  final String blurb;
  final String? webRoute;

  /// When false, hub shows as "coming soon".
  final bool available;

  final int accentHex;
}

/// Static catalog shipped with the hub. Remote warehub can override later.
const List<FamilyApp> kFamilyCatalog = [
  FamilyApp(
    slug: 'hub',
    name: 'ziBashu Hub',
    packageId: 'com.zibashu.hub',
    surface: 'hub',
    blurb: 'Directory of ziBashu apps on your device and the web.',
    webRoute: '/',
    accentHex: 0xFF2F6F4E,
  ),
  FamilyApp(
    slug: 'seru',
    name: 'Seru',
    packageId: 'com.zibashu.seru',
    surface: 'messaging',
    blurb: 'Private messaging for the ziBashu system.',
    webRoute: '/seru',
    accentHex: 0xFF3D5A80,
  ),
  FamilyApp(
    slug: 'lumen',
    name: 'Lumen',
    packageId: 'com.zibashu.lumen',
    surface: 'lab',
    blurb: 'Cited web research engine (coming as a dedicated APK).',
    webRoute: '/lab/search',
    available: false,
    accentHex: 0xFFC9A227,
  ),
  FamilyApp(
    slug: 'studio',
    name: 'Studio',
    packageId: 'com.zibashu.studio',
    surface: 'studio',
    blurb: 'Local-first creative tools (Canvas, Comfy, and more).',
    webRoute: '/studio',
    available: false,
    accentHex: 0xFF8B5E3C,
  ),
  FamilyApp(
    slug: 'netkit',
    name: 'NetKit',
    packageId: 'com.zibashu.netkit',
    surface: 'tool',
    blurb: 'Network diagnostics for builders.',
    webRoute: '/hub',
    available: false,
    accentHex: 0xFF5C6B73,
  ),
  FamilyApp(
    slug: 'neon_chronos',
    name: 'Neon Chronos',
    packageId: 'com.zibashu.neon_chronos',
    surface: 'tool',
    blurb: 'Futuristic neon cyberpunk clock - digital HUD time device.',
    webRoute: '/hub',
    available: true,
    accentHex: 0xFF00E5FF,
  ),
  FamilyApp(
    slug: 'morphos',
    name: 'MorphOS',
    packageId: 'com.zibashu.morphos',
    surface: 'other',
    blurb:
        'Personal adaptive environment — shapes, spaces, intelligence, morph packs.',
    webRoute: '/hub',
    available: true,
    accentHex: 0xFF7C4DFF,
  ),
];
