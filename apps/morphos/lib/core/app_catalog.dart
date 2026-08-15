import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

import 'launcher_listing.dart';
import 'models.dart';
import 'system_morph_bridge.dart';

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

  /// Include system packages that still expose a launcher icon.
  bool includeSystemApps = true;

  Future<void> refresh({bool loadIcons = true}) async {
    loading = true;
    lastError = null;
    try {
      if (kIsWeb || !SystemMorphBridge.isAndroid) {
        apps = List<MorphAppItem>.from(kDemoApps);
        usingDeviceApps = false;
        deviceAppCount = 0;
        return;
      }

      var mapped = <MorphAppItem>[];
      try {
        final rows = await SystemMorphBridge.queryLauncherApps();
        if (rows.isNotEmpty) {
          mapped = LauncherListing.fromRows(rows);
        }
      } catch (e) {
        lastError = 'Launcher query: $e';
      }

      if (mapped.isEmpty) {
        List<AppInfo> installed;
        try {
          // Include system apps with launcher icons. Labels as PM returns them
          // (any language). Full icon decode of all packages can OOM.
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
        mapped = LauncherListing.fromRows(
          installed.map(
            (a) => {
              'packageName': a.packageName,
              'label': a.name,
            },
          ),
        );
      }

      if (mapped.isEmpty) {
        apps = List<MorphAppItem>.from(kDemoApps);
        usingDeviceApps = false;
        deviceAppCount = 0;
      } else {
        apps = mapped;
        usingDeviceApps = true;
        deviceAppCount =
            mapped.where((a) => a.id != LauncherListing.morphosPackage).length;
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
      final want = packages
          .where((p) => p.contains('.') && p != 'com.zibashu.morphos')
          .toList();
      for (var i = 0; i < want.length; i += 24) {
        final end = (i + 24) > want.length ? want.length : i + 24;
        final batch = want.sublist(i, end);
        final native = await SystemMorphBridge.getLauncherIcons(batch);
        native.forEach((pkg, bytes) {
          if (bytes.isEmpty) return;
          final idx = apps.indexWhere(
            (a) => a.id == pkg || a.packageName == pkg,
          );
          if (idx < 0) return;
          apps[idx] = apps[idx].copyWith(iconBytes: bytes);
          loaded++;
        });
        for (final pkg in batch) {
          final already = apps.any(
            (a) =>
                (a.id == pkg || a.packageName == pkg) &&
                a.iconBytes != null &&
                a.iconBytes!.isNotEmpty,
          );
          if (already) continue;
          try {
            final info = await InstalledApps.getAppInfo(pkg, null);
            final icon = info?.icon;
            if (icon == null || icon.isEmpty) continue;
            final bytes = icon.toList();
            if (bytes.length > 180 * 1024) continue;
            final idx = apps.indexWhere(
              (a) => a.id == pkg || a.packageName == pkg,
            );
            if (idx < 0) continue;
            apps[idx] = apps[idx].copyWith(iconBytes: bytes);
            loaded++;
          } catch (_) {}
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
      final native = await SystemMorphBridge.getLauncherIcon(packageName);
      if (native != null && native.isNotEmpty) {
        final i = apps.indexWhere(
          (a) => a.id == packageName || a.packageName == packageName,
        );
        if (i >= 0) {
          apps[i] = apps[i].copyWith(iconBytes: native);
        }
        return native;
      }
      final info = await InstalledApps.getAppInfo(packageName, null);
      final icon = info?.icon;
      if (icon == null || icon.isEmpty) return null;
      final bytes = icon.toList();
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

  static ImageProvider? imageProvider(MorphAppItem app) {
    final b = app.iconBytes;
    if (b == null || b.isEmpty) return null;
    return MemoryImage(Uint8List.fromList(b));
  }
}
