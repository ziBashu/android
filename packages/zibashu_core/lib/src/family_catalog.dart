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
    blurb: 'Chat, friends, threads, and ZIBA pay — from ziBashu.',
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
        'Personal adaptive environment â€” shapes, spaces, intelligence, morph packs.',
    webRoute: '/hub',
    available: true,
    accentHex: 0xFF7C4DFF,
  ),
  FamilyApp(
    slug: 'flux',
    name: 'Flux',
    packageId: 'com.zibashu.flux',
    surface: 'tool',
    blurb: 'Flux VPN - ziBashu-linked private network client (foundation, locked).',
    webRoute: '/flux',
    available: true,
    accentHex: 0xFF2EE6D6,
  ),
  FamilyApp(
    slug: 'meld',
    name: 'Meld',
    packageId: 'com.zibashu.meld',
    surface: 'studio',
    blurb: 'Local-first video and audio editor. Your files stay on the device.',
    webRoute: '/hub/warehub/meld',
    available: true,
    accentHex: 0xFF1A9B8E,
  ),
  FamilyApp(
    slug: 'continuum',
    name: 'Continuum',
    packageId: 'com.zibashu.continuum',
    surface: 'studio',
    blurb: 'Professional drawing studio that follows the artist from Windows to Android.',
    webRoute: '/hub/warehub/continuum',
    available: true,
    accentHex: 0xFF3EC8FF,
  ),
  FamilyApp(
    slug: 'keyline',
    name: 'KEYLINE',
    packageId: 'com.zibashu.keyline',
    surface: 'tool',
    blurb: 'Offline-first English keyboard. Typing stays on the device.',
    webRoute: '/hub/warehub/keyline',
    available: true,
    accentHex: 0xFF6B5E4E,
  ),
  FamilyApp(
    slug: 'unfold',
    name: 'Unfold',
    packageId: 'com.zibashu.unfold',
    surface: 'tool',
    blurb: 'Local-first file viewer. Open, read, and edit without leaving the device.',
    webRoute: '/hub/warehub/unfold',
    available: true,
    accentHex: 0xFF3D6B54,
  ),
];
