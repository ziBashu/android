/// User-built clock face parameters (Clock Creator).
enum FaceShape { circle, square, hexagon }

enum FaceKind {
  digitalHud,
  orbital,
  quantum,
  custom,
}

extension FaceKindX on FaceKind {
  String get label {
    switch (this) {
      case FaceKind.digitalHud:
        return 'Digital HUD';
      case FaceKind.orbital:
        return 'Orbital';
      case FaceKind.quantum:
        return 'Quantum';
      case FaceKind.custom:
        return 'Custom';
    }
  }

  static FaceKind fromName(String? n) {
    return FaceKind.values.firstWhere(
      (e) => e.name == n,
      orElse: () => FaceKind.digitalHud,
    );
  }
}

extension FaceShapeX on FaceShape {
  String get label {
    switch (this) {
      case FaceShape.circle:
        return 'Circle';
      case FaceShape.square:
        return 'Square';
      case FaceShape.hexagon:
        return 'Hexagon';
    }
  }

  static FaceShape fromName(String? n) {
    return FaceShape.values.firstWhere(
      (e) => e.name == n,
      orElse: () => FaceShape.circle,
    );
  }
}

class ClockFaceConfig {
  const ClockFaceConfig({
    this.kind = FaceKind.digitalHud,
    this.shape = FaceShape.circle,
    this.showNumbers = true,
    this.glow = 0.75,
    this.particles = 0.5,
    this.animSpeed = 0.55,
    this.name = 'My Chronos Face',
  });

  final FaceKind kind;
  final FaceShape shape;
  final bool showNumbers;
  final double glow;
  final double particles;
  final double animSpeed; // 0 = slow, 1 = fast
  final String name;

  static const defaults = ClockFaceConfig();

  ClockFaceConfig copyWith({
    FaceKind? kind,
    FaceShape? shape,
    bool? showNumbers,
    double? glow,
    double? particles,
    double? animSpeed,
    String? name,
  }) {
    return ClockFaceConfig(
      kind: kind ?? this.kind,
      shape: shape ?? this.shape,
      showNumbers: showNumbers ?? this.showNumbers,
      glow: glow ?? this.glow,
      particles: particles ?? this.particles,
      animSpeed: animSpeed ?? this.animSpeed,
      name: name ?? this.name,
    );
  }

  Map<String, Object> toMap() => {
        'kind': kind.name,
        'shape': shape.name,
        'showNumbers': showNumbers,
        'glow': glow,
        'particles': particles,
        'animSpeed': animSpeed,
        'name': name,
      };

  factory ClockFaceConfig.fromMap(Map<String, Object?> m) {
    return ClockFaceConfig(
      kind: FaceKindX.fromName(m['kind'] as String?),
      shape: FaceShapeX.fromName(m['shape'] as String?),
      showNumbers: m['showNumbers'] as bool? ?? true,
      glow: (m['glow'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.75,
      particles: (m['particles'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.5,
      animSpeed: (m['animSpeed'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.55,
      name: m['name'] as String? ?? 'My Chronos Face',
    );
  }

  /// Shareable theme blob (JSON-ready map).
  String exportCode() {
    final parts = [
      kind.name,
      shape.name,
      showNumbers ? '1' : '0',
      glow.toStringAsFixed(2),
      particles.toStringAsFixed(2),
      animSpeed.toStringAsFixed(2),
      Uri.encodeComponent(name),
    ];
    return 'NC3:${parts.join('|')}';
  }

  static ClockFaceConfig? importCode(String code) {
    if (!code.startsWith('NC3:')) return null;
    final body = code.substring(4).split('|');
    if (body.length < 7) return null;
    return ClockFaceConfig(
      kind: FaceKindX.fromName(body[0]),
      shape: FaceShapeX.fromName(body[1]),
      showNumbers: body[2] == '1',
      glow: double.tryParse(body[3])?.clamp(0.0, 1.0) ?? 0.75,
      particles: double.tryParse(body[4])?.clamp(0.0, 1.0) ?? 0.5,
      animSpeed: double.tryParse(body[5])?.clamp(0.0, 1.0) ?? 0.55,
      name: Uri.decodeComponent(body[6]),
    );
  }
}
