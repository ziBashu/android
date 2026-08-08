import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

import 'models.dart';

/// Loads launcher-visible apps (Phase 3). Falls back to demo catalog offline.
class AppCatalog {
  AppCatalog();

  List<MorphAppItem> apps = List<MorphAppItem>.from(kDemoApps);
  bool usingDeviceApps = false;
  bool loading = false;
  String? lastError;

  Future<void> refresh() async {
    loading = true;
    lastError = null;
    try {
      if (kIsWeb) {
        apps = List<MorphAppItem>.from(kDemoApps);
        usingDeviceApps = false;
        return;
      }
      final List<AppInfo> installed = await InstalledApps.getInstalledApps(
        true, // exclude system apps where possible
        true, // with icons
      );
      if (installed.isEmpty) {
        apps = List<MorphAppItem>.from(kDemoApps);
        usingDeviceApps = false;
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
        final iconBytes = a.icon;
        mapped.add(
          MorphAppItem(
            id: pkg,
            label: name,
            icon: _iconForCategory(cat),
            packageName: pkg,
            color: _colorForCategory(cat),
            isSystemDemo: false,
            category: cat,
            iconBytes: iconBytes == null ? null : List<int>.from(iconBytes),
          ),
        );
      }
      mapped.sort(
        (x, y) => x.label.toLowerCase().compareTo(y.label.toLowerCase()),
      );
      if (mapped.isEmpty) {
        apps = List<MorphAppItem>.from(kDemoApps);
        usingDeviceApps = false;
      } else {
        // Keep demo "System" settings entry for MorphOS settings shortcut.
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
      }
    } catch (e) {
      lastError = '$e';
      apps = List<MorphAppItem>.from(kDemoApps);
      usingDeviceApps = false;
    } finally {
      loading = false;
    }
  }

  MorphAppItem? byId(String id) {
    for (final a in apps) {
      if (a.id == id) return a;
    }
    // Demo fallback for dock ids when using device apps.
    for (final a in kDemoApps) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Launch a package (real apps). Returns false if unavailable.
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
        _ => Icons.apps,
      };

  static Color _colorForCategory(String cat) => switch (cat) {
        'game' => const Color(0xFFEC407A),
        'nav' => const Color(0xFF26A69A),
        'read' => const Color(0xFFA1887F),
        'work' => const Color(0xFF5C6BC0),
        'media' => const Color(0xFFAB47BC),
        _ => const Color(0xFF7C4DFF),
      };

  static ImageProvider? imageProvider(MorphAppItem app) {
    final b = app.iconBytes;
    if (b == null || b.isEmpty) return null;
    return MemoryImage(Uint8List.fromList(b));
  }
}
