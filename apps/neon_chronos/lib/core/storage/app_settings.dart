import '../theme_engine/accent.dart';

/// Global Chronos preferences (persisted).
class AppSettings {
  const AppSettings({
    this.mode = ClockMode.digital,
    this.hour24 = true,
    this.glow = 0.75,
    this.animation = true,
    this.accent = NeonAccent.cyanMatrix,
    this.sound = true,
    this.background = BackgroundMode.cyberGrid,
    this.particleAmount = 0.7,
    this.gridSpeed = 0.55,
    this.animationLevel = 1.0,
  });

  final ClockMode mode;
  final bool hour24;
  final double glow;
  final bool animation;
  final NeonAccent accent;
  final bool sound;
  final BackgroundMode background;
  final double particleAmount;
  final double gridSpeed;

  /// 0 = minimal motion, 1 = full.
  final double animationLevel;

  static const defaults = AppSettings();

  AppSettings copyWith({
    ClockMode? mode,
    bool? hour24,
    double? glow,
    bool? animation,
    NeonAccent? accent,
    bool? sound,
    BackgroundMode? background,
    double? particleAmount,
    double? gridSpeed,
    double? animationLevel,
  }) {
    return AppSettings(
      mode: mode ?? this.mode,
      hour24: hour24 ?? this.hour24,
      glow: glow ?? this.glow,
      animation: animation ?? this.animation,
      accent: accent ?? this.accent,
      sound: sound ?? this.sound,
      background: background ?? this.background,
      particleAmount: particleAmount ?? this.particleAmount,
      gridSpeed: gridSpeed ?? this.gridSpeed,
      animationLevel: animationLevel ?? this.animationLevel,
    );
  }

  Map<String, Object> toMap() => {
        'mode': mode.name,
        'hour24': hour24,
        'glow': glow,
        'animation': animation,
        'accent': accent.name,
        'sound': sound,
        'background': background.name,
        'particleAmount': particleAmount,
        'gridSpeed': gridSpeed,
        'animationLevel': animationLevel,
      };

  factory AppSettings.fromMap(Map<String, Object?> map) {
    return AppSettings(
      mode: ClockMode.fromName(map['mode'] as String?),
      hour24: map['hour24'] as bool? ?? true,
      glow: (map['glow'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.75,
      animation: map['animation'] as bool? ?? true,
      accent: NeonAccent.fromName(map['accent'] as String?),
      sound: map['sound'] as bool? ?? true,
      background: BackgroundMode.fromName(map['background'] as String?),
      particleAmount:
          (map['particleAmount'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.7,
      gridSpeed: (map['gridSpeed'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.55,
      animationLevel:
          (map['animationLevel'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 1.0,
    );
  }
}
