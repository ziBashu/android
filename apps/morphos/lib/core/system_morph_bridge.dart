import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'models.dart';

/// Phase 2+ / 4 / 6 native bridge — system orientation + platform layer.
class SystemMorphBridge {
  SystemMorphBridge._();

  static const _channel = MethodChannel('com.zibashu.morphos/system');
  static const _launcherEvents =
      EventChannel('com.zibashu.morphos/launcher');

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

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

  static Future<void> openHomeSettings() async {
    if (!isAndroid) return;
    try {
      await _channel.invokeMethod<void>('openHomeSettings');
    } catch (_) {}
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

  static Future<void> requestHomeRole() async {
    if (!isAndroid) return;
    try {
      await _channel.invokeMethod<void>('requestHomeRole');
    } catch (_) {}
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
