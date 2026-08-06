/// Metadata written next to each release APK for ziBashu warehub.
class WarehubMeta {
  const WarehubMeta({
    required this.slug,
    required this.name,
    required this.packageId,
    required this.versionName,
    required this.versionCode,
    required this.surface,
    required this.apk,
    this.minSdk = 24,
    this.family = 'ziBashu',
    this.website = 'https://zibashu4.com',
    this.route,
    this.blurb,
  });

  final String slug;
  final String name;
  final String packageId;
  final String versionName;
  final int versionCode;
  final int minSdk;
  final String family;
  final String surface;
  final String apk;
  final String website;
  final String? route;
  final String? blurb;

  Map<String, Object?> toJson() => {
        'slug': slug,
        'name': name,
        'packageId': packageId,
        'versionName': versionName,
        'versionCode': versionCode,
        'minSdk': minSdk,
        'family': family,
        'surface': surface,
        'apk': apk,
        'website': website,
        if (route != null) 'route': route,
        if (blurb != null) 'blurb': blurb,
      };
}
