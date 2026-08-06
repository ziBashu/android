import 'package:flutter_test/flutter_test.dart';
import 'package:neon_chronos/core/clock_engine/clock_format.dart';
import 'package:neon_chronos/core/engine/clock_face_config.dart';
import 'package:neon_chronos/features/home/home_module.dart';
import 'package:neon_chronos/features/themes/theme_pack.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('ClockFormat day progress', () {
    final t = DateTime(2026, 8, 6, 12, 0);
    expect(ClockFormat.dayProgress(t), closeTo(0.5, 0.01));
  });

  test('ClockFaceConfig export/import', () {
    const c = ClockFaceConfig(
      kind: FaceKind.quantum,
      shape: FaceShape.hexagon,
      showNumbers: false,
      glow: 0.6,
      particles: 0.4,
      animSpeed: 0.8,
      name: 'Test Face',
    );
    final code = c.exportCode();
    expect(code.startsWith('NC3:'), isTrue);
    final back = ClockFaceConfig.importCode(code);
    expect(back, isNotNull);
    expect(back!.kind, FaceKind.quantum);
    expect(back.shape, FaceShape.hexagon);
    expect(back.name, 'Test Face');
  });

  test('Theme marketplace has packs', () {
    expect(kThemeMarketplace.length, greaterThanOrEqualTo(5));
    expect(kThemeMarketplace.first.id, isNotEmpty);
  });

  test('Default home modules', () {
    expect(kDefaultHomeModules, contains(HomeModule.timeCore));
    expect(HomeModule.focusStatus.title, 'FOCUS');
  });
}
