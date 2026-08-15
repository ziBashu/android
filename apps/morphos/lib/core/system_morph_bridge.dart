import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'models.dart';

/// Phase 2+ / 4 / 6 native bridge — system orientation + platform layer.
class SystemMorphBridge {
  SystemMorphBridge._();

  static const _channel = MethodChannel('com.zibashu.morphos/system');
  static const _launcherEvents =
      EventChannel('com.zibashu.morphos/launcher');
  static const _batteryEvents =
      EventChannel('com.zibashu.morphos/battery');

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Live `ACTION_BATTERY_CHANGED` extras as they arrive (plus sticky first).
  static Stream<Map<String, dynamic>> batteryEventStream() {
    if (!isAndroid) return const Stream.empty();
    return _batteryEvents.receiveBroadcastStream().map((raw) {
      if (raw is Map) {
        return raw.map((k, v) => MapEntry('$k', v));
      }
      return <String, dynamic>{};
    });
  }

  /// Stream of native launcher events: `{type: home|launcher|resume, ...}`.
  static Stream<Map<String, dynamic>> launcherEventStream() {
    if (!isAndroid) return const Stream.empty();
    return _launcherEvents.receiveBroadcastStream().map((raw) {
      if (raw is Map) {
        return raw.map((k, v) => MapEntry('$k', v));
      }
      return <String, dynamic>{'type': 'resume'};
    });
  }

  /// Launcher root: send MorphOS behind other apps (do not finish).
  static Future<bool> moveTaskToBack() async {
    if (!isAndroid) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('moveTaskToBack');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<SystemMorphStatus> getStatus() async {
    if (!isAndroid) return SystemMorphStatus.unsupported;
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>('getStatus');
      return SystemMorphStatus.fromMap(raw ?? const {});
    } catch (_) {
      return SystemMorphStatus.unsupported;
    }
  }

  static Future<PlatformInfo> getPlatformInfo() async {
    if (!isAndroid) return PlatformInfo.unsupported;
    try {
      final raw =
          await _channel.invokeMapMethod<String, dynamic>('getPlatformInfo');
      return PlatformInfo.fromMap(raw ?? const {});
    } catch (_) {
      return PlatformInfo.unsupported;
    }
  }

  static Future<SystemMorphStatus> setSystemMorphEnabled(bool enabled) async {
    if (!isAndroid) return SystemMorphStatus.unsupported;
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        'setSystemMorphEnabled',
        {'enabled': enabled},
      );
      return SystemMorphStatus.fromMap(raw ?? const {});
    } catch (_) {
      return SystemMorphStatus.unsupported;
    }
  }

  static Future<void> setGlobalOrientation(String mode) async {
    if (!isAndroid) return;
    try {
      await _channel.invokeMethod<void>('setGlobalOrientation', {'mode': mode});
    } catch (_) {}
  }

  /// Apply orientation now; returns whether Settings.System write succeeded.
  static Future<bool> applyGlobalOrientationNow(String mode) async {
    if (!isAndroid) return false;
    try {
      final ok = await _channel.invokeMethod<bool>(
        'applyGlobalOrientationNow',
        {'mode': mode},
      );
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Pulse landscape then leave it (user can reset via morph) — verifies WRITE_SETTINGS.
  static Future<String?> testRotationPulse() async {
    if (!isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('testRotationPulse');
    } catch (_) {
      return null;
    }
  }

  static Future<String?> cycleOrientationMode() async {
    if (!isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('cycleOrientationMode');
    } catch (_) {
      return null;
    }
  }

  /// Push package → orientation map derived from [AppMorphRule]s.
  static Future<void> syncPackageRules(Map<String, String> rules) async {
    if (!isAndroid) return;
    try {
      await _channel.invokeMethod<void>('syncPackageRules', {'rules': rules});
    } catch (_) {}
  }

  static Future<void> openAccessibilitySettings() async {
    if (!isAndroid) return;
    try {
      await _channel.invokeMethod<void>('openAccessibilitySettings');
    } catch (_) {}
  }

  static Future<void> openWriteSettings() async {
    if (!isAndroid) return;
    try {
      await _channel.invokeMethod<void>('openWriteSettings');
    } catch (_) {}
  }

  static Future<void> openOverlaySettings() async {
    if (!isAndroid) return;
    try {
      await _channel.invokeMethod<void>('openOverlaySettings');
    } catch (_) {}
  }

  static Future<bool> openHomeSettings() async {
    if (!isAndroid) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('openHomeSettings');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openBatteryOptimizationSettings() async {
    if (!isAndroid) return;
    try {
      await _channel.invokeMethod<void>('openBatteryOptimizationSettings');
    } catch (_) {}
  }

  static Future<void> openAppDetails() async {
    if (!isAndroid) return;
    try {
      await _channel.invokeMethod<void>('openAppDetails');
    } catch (_) {}
  }

  /// Open system Home picker / Home settings. Never silent — user must confirm.
  /// Returns diagnostics: action, ok, message, isHomeCandidate, isDefaultHome.
  static Future<HomeRoleResult> requestHomeRole() async {
    if (!isAndroid) {
      return const HomeRoleResult(
        ok: false,
        action: 'unsupported',
        message: 'Home role is Android-only.',
      );
    }
    try {
      final raw =
          await _channel.invokeMapMethod<String, dynamic>('requestHomeRole');
      return HomeRoleResult.fromMap(raw ?? const {});
    } catch (e) {
      return HomeRoleResult(
        ok: false,
        action: 'error',
        message: 'requestHomeRole failed: $e',
      );
    }
  }

  static Future<HomeRoleResult> probeHomeRegistration() async {
    if (!isAndroid) {
      return const HomeRoleResult(
        ok: false,
        action: 'unsupported',
        message: 'Android-only',
      );
    }
    try {
      final raw = await _channel
          .invokeMapMethod<String, dynamic>('probeHomeRegistration');
      final m = raw ?? const <String, dynamic>{};
      final candidate = m['isHomeCandidate'] as bool? ?? false;
      return HomeRoleResult(
        ok: candidate,
        action: 'probe',
        message: candidate
            ? 'PackageManager lists MorphOS as a Home candidate.'
            : 'MorphOS is NOT listed as a Home app — reinstall the APK.',
        isHomeCandidate: candidate,
        isDefaultHome: m['isDefaultHome'] as bool? ?? false,
        homeCandidateCount: m['homeCandidateCount'] as int? ?? 0,
        homeCandidates: (m['homeCandidates'] as List?)
                ?.map((e) => '$e')
                .toList() ??
            const [],
      );
    } catch (e) {
      return HomeRoleResult(
        ok: false,
        action: 'error',
        message: '$e',
      );
    }
  }

  static Future<void> setKeepScreenOn(bool keep) async {
    if (!isAndroid) return;
    try {
      await _channel.invokeMethod<void>('setKeepScreenOn', {'keep': keep});
    } catch (_) {}
  }

  static Future<DisplayInfo> getDisplayInfo() async {
    if (!isAndroid) {
      return const DisplayInfo(
        displayCount: 1,
        hasExternalDisplay: false,
        displays: [],
      );
    }
    try {
      final raw =
          await _channel.invokeMapMethod<String, dynamic>('getDisplayInfo');
      return DisplayInfo.fromMap(raw ?? const {});
    } catch (_) {
      return const DisplayInfo(
        displayCount: 1,
        hasExternalDisplay: false,
        displays: [],
      );
    }
  }

  /// Build package rules from app morph rules (only real-looking package ids).
  static Map<String, String> rulesFromAppMorph(
    List<AppMorphRule> appRules,
  ) {
    final out = <String, String>{};
    for (final r in appRules) {
      if (!r.enabled) continue;
      final id = r.appId;
      if (!_looksLikePackage(id)) continue;
      out[id] = r.profileId.systemOrientationMode;
    }
    return out;
  }

  static bool _looksLikePackage(String id) =>
      id.contains('.') && !id.contains(' ') && id.length > 3;

  /// MAIN+LAUNCHER rows from PackageManager (locale-accurate labels).
  static Future<List<Map<String, dynamic>>> queryLauncherApps() async {
    if (!isAndroid) return const [];
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('queryLauncherApps');
      if (raw == null) return const [];
      return raw
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry('$k', v)))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  /// Sticky `ACTION_BATTERY_CHANGED` extras.
  static Future<Map<String, dynamic>> getBatteryExtras() async {
    if (!isAndroid) return const {};
    try {
      final raw =
          await _channel.invokeMapMethod<String, dynamic>('getBatteryExtras');
      return raw ?? const {};
    } catch (_) {
      return const {};
    }
  }

  static Future<bool> setSystemWallpaper(List<int> bytes) async {
    if (!isAndroid || bytes.isEmpty) return false;
    try {
      final ok = await _channel.invokeMethod<bool>(
        'setSystemWallpaper',
        {'bytes': bytes},
      );
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Real MAIN+LAUNCHER icons as PNG bytes, keyed by package name.
  static Future<Map<String, List<int>>> getLauncherIcons(
    List<String> packages,
  ) async {
    if (!isAndroid || packages.isEmpty) return const {};
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        'getLauncherIcons',
        {'packages': packages},
      );
      if (raw == null) return const {};
      final out = <String, List<int>>{};
      raw.forEach((k, v) {
        if (v is List<int>) {
          out[k] = v;
        } else if (v is Uint8List) {
          out[k] = v;
        }
      });
      return out;
    } catch (_) {
      return const {};
    }
  }

  static Future<List<int>?> getLauncherIcon(String packageName) async {
    if (!isAndroid || packageName.isEmpty) return null;
    try {
      final raw = await _channel.invokeMethod<dynamic>(
        'getLauncherIcon',
        {'packageName': packageName},
      );
      if (raw is Uint8List) return raw;
      if (raw is List<int>) return raw;
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, String>> notesPaths() async {
    if (!isAndroid) {
      return const {
        'appPath': '',
        'publicPath': '',
      };
    }
    try {
      final raw =
          await _channel.invokeMapMethod<String, dynamic>('notesPaths');
      return {
        'appPath': '${raw?['appPath'] ?? ''}',
        'publicPath': '${raw?['publicPath'] ?? ''}',
      };
    } catch (_) {
      return const {'appPath': '', 'publicPath': ''};
    }
  }

  static Future<String?> readNotesJson() async {
    if (!isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('readNotesJson');
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, String>> writeNotesJson(String json) async {
    if (!isAndroid) return const {'appPath': '', 'publicPath': ''};
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        'writeNotesJson',
        {'json': json},
      );
      return {
        'appPath': '${raw?['appPath'] ?? ''}',
        'publicPath': '${raw?['publicPath'] ?? ''}',
      };
    } catch (_) {
      return const {'appPath': '', 'publicPath': ''};
    }
  }

  static Future<bool> openWebSearch(String query) async {
    if (query.trim().isEmpty) return false;
    if (!isAndroid) return false;
    try {
      final ok = await _channel.invokeMethod<bool>(
        'openWebSearch',
        {'query': query.trim()},
      );
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, String>> getDefaultBrowser() async {
    if (!isAndroid) return const {'packageName': '', 'label': ''};
    try {
      final raw =
          await _channel.invokeMapMethod<String, dynamic>('getDefaultBrowser');
      return {
        'packageName': '${raw?['packageName'] ?? ''}',
        'label': '${raw?['label'] ?? ''}',
      };
    } catch (_) {
      return const {'packageName': '', 'label': ''};
    }
  }

  static Future<Map<String, dynamic>> getLastLocation() async {
    if (!isAndroid) {
      return const {'ok': false, 'needPermission': false};
    }
    try {
      final raw =
          await _channel.invokeMapMethod<String, dynamic>('getLastLocation');
      return raw ?? const {'ok': false, 'needPermission': false};
    } catch (_) {
      return const {'ok': false, 'needPermission': false};
    }
  }

  static Future<bool> requestLocationPermission() async {
    if (!isAndroid) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('requestLocationPermission');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestUninstall(String packageName) async {
    if (!isAndroid || packageName.isEmpty) return false;
    try {
      final ok = await _channel.invokeMethod<bool>(
        'requestUninstall',
        {'packageName': packageName},
      );
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openAppInfo(String packageName) async {
    if (!isAndroid || packageName.isEmpty) return false;
    try {
      final ok = await _channel.invokeMethod<bool>(
        'openAppInfo',
        {'packageName': packageName},
      );
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> runShortcut(String action, {String? packageName}) async {
    if (!isAndroid) return false;
    try {
      final ok = await _channel.invokeMethod<bool>(
        'runShortcut',
        {'action': action, 'packageName': packageName ?? ''},
      );
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> getShadeSnapshot() async {
    if (!isAndroid) return const {};
    try {
      final raw =
          await _channel.invokeMapMethod<String, dynamic>('getShadeSnapshot');
      return raw ?? const {};
    } catch (_) {
      return const {};
    }
  }

  static Future<Map<String, dynamic>> toggleShadeTile(String id) async {
    if (!isAndroid) return const {};
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        'toggleShadeTile',
        {'id': id},
      );
      return raw ?? const {};
    } catch (_) {
      return const {};
    }
  }

  static Future<bool> setBrightness(double value) async {
    if (!isAndroid) return false;
    try {
      final ok = await _channel.invokeMethod<bool>(
        'setBrightness',
        {'value': value.clamp(0.0, 1.0)},
      );
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> islandCommand(String command) async {
    if (!isAndroid) return false;
    try {
      final ok = await _channel.invokeMethod<bool>(
        'islandCommand',
        {'command': command},
      );
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> getIslandSnapshot() async {
    if (!isAndroid) return const {};
    try {
      final raw =
          await _channel.invokeMapMethod<String, dynamic>('getIslandSnapshot');
      return raw ?? const {};
    } catch (_) {
      return const {};
    }
  }

  static Future<void> syncChrome(Map<String, dynamic> flags) async {
    if (!isAndroid) return;
    try {
      await _channel.invokeMethod<void>('syncChrome', flags);
    } catch (_) {}
  }

  static Future<void> setHomeVisible(bool visible) async {
    if (!isAndroid) return;
    try {
      await _channel.invokeMethod<void>('setHomeVisible', {'visible': visible});
    } catch (_) {}
  }

  static Future<void> openNotificationListenerSettings() async {
    if (!isAndroid) return;
    try {
      await _channel.invokeMethod<void>('openNotificationListenerSettings');
    } catch (_) {}
  }

  static const _chromeEvents = EventChannel('com.zibashu.morphos/chrome');

  static Stream<Map<String, dynamic>> chromeEventStream() {
    if (!isAndroid) return const Stream.empty();
    return _chromeEvents.receiveBroadcastStream().map((raw) {
      if (raw is Map) {
        return raw.map((k, v) => MapEntry('$k', v));
      }
      return <String, dynamic>{};
    });
  }
}

/// Result of opening the system Home-role / Home-settings UI.
class HomeRoleResult {
  const HomeRoleResult({
    required this.ok,
    required this.action,
    required this.message,
    this.isHomeCandidate = false,
    this.isDefaultHome = false,
    this.homeCandidateCount = 0,
    this.homeCandidates = const [],
    this.roleAvailable,
    this.roleHeld,
  });

  final bool ok;
  final String action;
  final String message;
  final bool isHomeCandidate;
  final bool isDefaultHome;
  final int homeCandidateCount;
  final List<String> homeCandidates;
  final bool? roleAvailable;
  final bool? roleHeld;

  factory HomeRoleResult.fromMap(Map<String, dynamic> m) {
    return HomeRoleResult(
      ok: m['ok'] as bool? ?? false,
      action: '${m['action'] ?? ''}',
      message: '${m['message'] ?? ''}',
      isHomeCandidate: m['isHomeCandidate'] as bool? ?? false,
      isDefaultHome: m['isDefaultHome'] as bool? ?? false,
      homeCandidateCount: m['homeCandidateCount'] as int? ?? 0,
      homeCandidates: (m['homeCandidates'] as List?)
              ?.map((e) => '$e')
              .toList() ??
          const [],
      roleAvailable: m['roleAvailable'] as bool?,
      roleHeld: m['roleHeld'] as bool?,
    );
  }
}

class SystemMorphStatus {
  const SystemMorphStatus({
    required this.systemMorphEnabled,
    required this.accessibilityRunning,
    required this.canWriteSettings,
    required this.canDrawOverlays,
    required this.globalOrientation,
    this.accessibilityEnabled = false,
    this.lastForegroundPackage,
    this.lastAppliedMode,
    this.lastApplyOk = false,
    this.displayCount = 1,
    this.hasExternalDisplay = false,
    this.isDefaultHome = false,
    this.isHomeCandidate = false,
    this.ignoringBatteryOptimizations = false,
    this.sdkInt = 0,
    this.manufacturer = '',
    this.model = '',
    this.supported = true,
  });

  final bool systemMorphEnabled;
  /// Service process connected (instance live).
  final bool accessibilityRunning;
  /// Toggle enabled in system Accessibility settings (even if not connected yet).
  final bool accessibilityEnabled;
  final bool canWriteSettings;
  final bool canDrawOverlays;
  final String globalOrientation;
  final String? lastForegroundPackage;
  final String? lastAppliedMode;
  final bool lastApplyOk;
  final int displayCount;
  final bool hasExternalDisplay;
  final bool isDefaultHome;
  /// PackageManager lists MorphOS under MAIN+HOME (eligible for Home picker).
  final bool isHomeCandidate;
  final bool ignoringBatteryOptimizations;
  final int sdkInt;
  final String manufacturer;
  final String model;
  final bool supported;

  static const unsupported = SystemMorphStatus(
    systemMorphEnabled: false,
    accessibilityRunning: false,
    canWriteSettings: false,
    canDrawOverlays: false,
    globalOrientation: 'sensor',
    isHomeCandidate: false,
    supported: false,
  );

  bool get a11yOk => accessibilityRunning || accessibilityEnabled;

  bool get readyForSystemMorph =>
      supported && a11yOk && canWriteSettings;

  /// Phase 6 readiness score 0–5.
  int get platformScore {
    var n = 0;
    if (isDefaultHome) n++;
    if (accessibilityRunning) n++;
    if (canWriteSettings) n++;
    if (canDrawOverlays) n++;
    if (ignoringBatteryOptimizations) n++;
    return n;
  }

  factory SystemMorphStatus.fromMap(Map<String, dynamic> m) {
    final lastFg = m['lastForegroundPackage'];
    final lastMode = m['lastAppliedMode'];
    return SystemMorphStatus(
      systemMorphEnabled: m['systemMorphEnabled'] as bool? ?? false,
      accessibilityRunning: m['accessibilityRunning'] as bool? ?? false,
      accessibilityEnabled: m['accessibilityEnabled'] as bool? ?? false,
      canWriteSettings: m['canWriteSettings'] as bool? ?? false,
      canDrawOverlays: m['canDrawOverlays'] as bool? ?? false,
      globalOrientation: m['globalOrientation'] as String? ?? 'sensor',
      lastForegroundPackage: lastFg == null || '$lastFg'.isEmpty
          ? null
          : '$lastFg',
      lastAppliedMode: lastMode == null || '$lastMode'.isEmpty
          ? null
          : '$lastMode',
      lastApplyOk: m['lastApplyOk'] as bool? ?? false,
      displayCount: m['displayCount'] as int? ?? 1,
      hasExternalDisplay: m['hasExternalDisplay'] as bool? ?? false,
      isDefaultHome: m['isDefaultHome'] as bool? ?? false,
      isHomeCandidate: m['isHomeCandidate'] as bool? ?? false,
      ignoringBatteryOptimizations:
          m['ignoringBatteryOptimizations'] as bool? ?? false,
      sdkInt: m['sdkInt'] as int? ?? 0,
      manufacturer: m['manufacturer'] as String? ?? '',
      model: m['model'] as String? ?? '',
    );
  }
}

class PlatformInfo {
  const PlatformInfo({
    required this.sdkInt,
    required this.release,
    required this.manufacturer,
    required this.model,
    required this.isDefaultHome,
    required this.ignoringBatteryOptimizations,
    required this.features,
    required this.platformLayer,
    this.versionLabel = '',
    this.supported = true,
  });

  final int sdkInt;
  final String release;
  final String manufacturer;
  final String model;
  final bool isDefaultHome;
  final bool ignoringBatteryOptimizations;
  final List<String> features;
  final String platformLayer;
  final String versionLabel;
  final bool supported;

  static const unsupported = PlatformInfo(
    sdkInt: 0,
    release: '',
    manufacturer: '',
    model: '',
    isDefaultHome: false,
    ignoringBatteryOptimizations: false,
    features: [],
    platformLayer: 'none',
    supported: false,
  );

  factory PlatformInfo.fromMap(Map<String, dynamic> m) {
    return PlatformInfo(
      sdkInt: m['sdkInt'] as int? ?? 0,
      release: '${m['release'] ?? ''}',
      manufacturer: m['manufacturer'] as String? ?? '',
      model: m['model'] as String? ?? '',
      isDefaultHome: m['isDefaultHome'] as bool? ?? false,
      ignoringBatteryOptimizations:
          m['ignoringBatteryOptimizations'] as bool? ?? false,
      features: (m['features'] as List?)?.map((e) => '$e').toList() ?? const [],
      platformLayer: m['platformLayer'] as String? ?? 'morphos-platform-v1',
      versionLabel: m['versionLabel'] as String? ?? '',
    );
  }
}

class DisplayInfo {
  const DisplayInfo({
    required this.displayCount,
    required this.hasExternalDisplay,
    required this.displays,
  });

  final int displayCount;
  final bool hasExternalDisplay;
  final List<Map<String, dynamic>> displays;

  factory DisplayInfo.fromMap(Map<String, dynamic> m) {
    final list = (m['displays'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        const <Map<String, dynamic>>[];
    return DisplayInfo(
      displayCount: m['displayCount'] as int? ?? list.length,
      hasExternalDisplay: m['hasExternalDisplay'] as bool? ?? false,
      displays: list,
    );
  }
}
