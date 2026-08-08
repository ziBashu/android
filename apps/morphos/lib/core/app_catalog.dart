import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

import 'models.dart';

/// Loads launcher-visible apps from the phone. Falls back to demo catalog.
///
/// **Names** come from the package manager; MorphOS can override labels.
/// **Icons** load in a second pass (limited batch) so first paint stays safe.
class AppCatalog {
  AppCatalog();

  List<MorphAppItem> apps = List<MorphAppItem>.from(kDemoApps);
  bool usingDeviceApps = false;
  bool loading = false;
  bool loadingIcons = false;
  int deviceAppCount = 0;
  String? lastError;

  /// Include more system packages (Maps, Phone, …) when true.
  bool includeSystemApps = false;

  Future<void> refresh({bool loadIcons = true}) async {
    loading = true;
    lastError = null;
    try {
      if (kIsWeb) {
        apps = List<MorphAppItem>.from(kDemoApps);
        usingDeviceApps = false;
        deviceAppCount = 0;
        return;
      }

      List<AppInfo> installed;
      try {
        // Labels first — full icon decode of all packages can OOM.
        installed = await InstalledApps.getInstalledApps(
          !includeSystemApps,
          false,
        );
      } catch (e) {
        lastError = 'App list: $e';
        apps = List<MorphAppItem>.from(kDemoApps);
        usingDeviceApps = false;
        deviceAppCount = 0;
        return;
      }

      if (installed.isEmpty) {
        apps = List<MorphAppItem>.from(kDemoApps);
        usingDeviceApps = false;
        deviceAppCount = 0;
        return;
      }

      final mapped = <MorphAppItem>[];
      for (final a in installed) {
        final pkg = a.packageName;
        if (pkg.isEmpty) continue;
        if (pkg == 'com.zibashu.morphos') continue;
        final name = a.name.trim().isEmpty ? pkg : a.name.trim();
        if (name.isEmpty) continue;
        final cat = inferAppCategory(name: name, packageName: pkg);
        mapped.add(
          MorphAppItem(
            id: pkg,
            label: name,
            icon: _iconForCategory(cat),
            packageName: pkg,
            color: _colorForCategory(cat),
            isSystemDemo: false,
            category: cat,
          ),
        );
      }
      mapped.sort(
        (x, y) => x.label.toLowerCase().compareTo(y.label.toLowerCase()),
      );

      if (mapped.isEmpty) {
        apps = List<MorphAppItem>.from(kDemoApps);
        usingDeviceApps = false;
        deviceAppCount = 0;
      } else {
        apps = [
          ...mapped,
          const MorphAppItem(
            id: 'settings',
            label: 'MorphOS Settings',
            icon: Icons.settings_outlined,
            color: Color(0xFF90A4AE),
            category: 'other',
          ),
        ];
        usingDeviceApps = true;
        deviceAppCount = mapped.length;
      }
    } catch (e) {
      lastError = '$e';
      apps = List<MorphAppItem>.from(kDemoApps);
      usingDeviceApps = false;
      deviceAppCount = 0;
    } finally {
      loading = false;
    }

    if (loadIcons && usingDeviceApps) {
      await loadIconsForPackages(
        apps
            .where((a) => !a.isSystemDemo && a.packageName != null)
            .take(32)
            .map((a) => a.packageName!)
            .toList(),
      );
    }
  }

  /// Fetch real launcher icons for specific packages (safe batch).
  Future<int> loadIconsForPackages(List<String> packages) async {
    if (kIsWeb || packages.isEmpty) return 0;
    loadingIcons = true;
    var loaded = 0;
    try {
      for (final pkg in packages) {
        if (pkg.isEmpty || pkg == 'com.zibashu.morphos') continue;
        try {
          final info = await InstalledApps.getAppInfo(pkg, null);
          final icon = info?.icon;
          if (icon == null || icon.isEmpty) continue;
          final bytes = icon.toList();
          // Cap icon payload (~96KB) to avoid memory spikes.
          if (bytes.length > 96 * 1024) continue;
          final i = apps.indexWhere(
            (a) => a.id == pkg || a.packageName == pkg,
          );
          if (i < 0) continue;
          apps[i] = apps[i].copyWith(iconBytes: bytes);
          loaded++;
        } catch (_) {
          // Skip single-package failures.
        }
      }
    } finally {
      loadingIcons = false;
    }
    return loaded;
  }

  /// Load / refresh one package icon from the phone.
  Future<List<int>?> loadDeviceIcon(String packageName) async {
    if (kIsWeb || packageName.isEmpty) return null;
    try {
      final info = await InstalledApps.getAppInfo(packageName, null);
      final icon = info?.icon;
      if (icon == null || icon.isEmpty) return null;
      final bytes = icon.toList();
      if (bytes.length > 128 * 1024) {
        // Still use — single icon is fine.
      }
      final i = apps.indexWhere(
        (a) => a.id == packageName || a.packageName == packageName,
      );
      if (i >= 0) {
        apps[i] = apps[i].copyWith(iconBytes: bytes);
      }
      return bytes;
    } catch (_) {
      return null;
    }
  }

  MorphAppItem? byId(String id) {
    for (final a in apps) {
      if (a.id == id) return a;
    }
    for (final a in kDemoApps) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Apply MorphOS renames + custom icon overrides onto a catalog item.
  MorphAppItem decorate(
    MorphAppItem app, {
    required Map<String, String> renames,
    required Map<String, String> iconOverridesB64,
  }) {
    final key = app.packageName ?? app.id;
    final rename = renames[app.id] ?? renames[key];
    List<int>? overrideBytes;
    final b64 = iconOverridesB64[app.id] ?? iconOverridesB64[key];
    if (b64 != null && b64.isNotEmpty) {
      try {
        overrideBytes = base64Decode(b64);
      } catch (_) {}
    }
    return app.copyWith(
      label: rename ?? app.label,
      iconBytes: overrideBytes ?? app.iconBytes,
    );
  }

  Future<bool> launch(MorphAppItem app) async {
    final pkg = app.packageName ?? (app.isSystemDemo ? null : app.id);
    if (pkg == null || pkg.isEmpty || app.isSystemDemo) return false;
    try {
      final ok = await InstalledApps.startApp(pkg);
      return ok ?? true;
    } catch (_) {
      return false;
    }
  }

  static IconData _iconForCategory(String cat) => switch (cat) {
        'game' => Icons.sports_esports_outlined,
        'nav' => Icons.map_outlined,
        'read' => Icons.menu_book_outlined,
        'work' => Icons.work_outline,
        'media' => Icons.movie_outlined,
        'study' => Icons.school_outlined,
        'travel' => Icons.flight_takeoff,
        _ => Icons.apps,
      };

  static Color _colorForCategory(String cat) => switch (cat) {
        'game' => const Color(0xFFEC407A),
        'nav' => const Color(0xFF26A69A),
        'read' => const Color(0xFFA1887F),
        'work' => const Color(0xFF5C6BC0),
        'media' => const Color(0xFFAB47BC),
        'study' => const Color(0xFF43A047),
        'travel' => const Color(0xFF1E88E5),
        _ => const Color(0xFF7C4DFF),
      };

  static ImageProvider? imageProvider(MorphAppItem app) {
    final b = app.iconBytes;
    if (b == null || b.isEmpty) return null;
    return MemoryImage(Uint8List.fromList(b));
  }
}
