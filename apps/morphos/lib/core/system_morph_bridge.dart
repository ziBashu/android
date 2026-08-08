import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'models.dart';

/// Phase 2+ / 4 native bridge — system orientation + display info.
class SystemMorphBridge {
  SystemMorphBridge._();

  static const _channel = MethodChannel('com.zibashu.morphos/system');

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<SystemMorphStatus> getStatus() async {
    if (!isAndroid) return SystemMorphStatus.unsupported;
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>('getStatus');
      return SystemMorphStatus.fromMap(raw ?? const {});
    } catch (_) {
      return SystemMorphStatus.unsupported;
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
    this.lastForegroundPackage,
    this.lastAppliedMode,
    this.displayCount = 1,
    this.hasExternalDisplay = false,
    this.supported = true,
  });

  final bool systemMorphEnabled;
  final bool accessibilityRunning;
  final bool canWriteSettings;
  final bool canDrawOverlays;
  final String globalOrientation;
  final String? lastForegroundPackage;
  final String? lastAppliedMode;
  final int displayCount;
  final bool hasExternalDisplay;
  final bool supported;

  static const unsupported = SystemMorphStatus(
    systemMorphEnabled: false,
    accessibilityRunning: false,
    canWriteSettings: false,
    canDrawOverlays: false,
    globalOrientation: 'sensor',
    supported: false,
  );

  bool get readyForSystemMorph =>
      supported && accessibilityRunning && canWriteSettings;

  factory SystemMorphStatus.fromMap(Map<String, dynamic> m) {
    return SystemMorphStatus(
      systemMorphEnabled: m['systemMorphEnabled'] as bool? ?? false,
      accessibilityRunning: m['accessibilityRunning'] as bool? ?? false,
      canWriteSettings: m['canWriteSettings'] as bool? ?? false,
      canDrawOverlays: m['canDrawOverlays'] as bool? ?? false,
      globalOrientation: m['globalOrientation'] as String? ?? 'sensor',
      lastForegroundPackage: m['lastForegroundPackage'] as String?,
      lastAppliedMode: m['lastAppliedMode'] as String?,
      displayCount: m['displayCount'] as int? ?? 1,
      hasExternalDisplay: m['hasExternalDisplay'] as bool? ?? false,
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
