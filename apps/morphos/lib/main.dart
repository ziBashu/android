import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/home_nav.dart';
import 'core/morph_controller.dart';
import 'core/morph_palette.dart';
import 'core/system_morph_bridge.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

/// Root navigator — Home re-entry pops pushed Morph screens to root.
final GlobalKey<NavigatorState> morphNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Do NOT lock orientation before first frame — causes Width=0 / stuck splash
  // on some Android 15–17 emulators. Portrait is applied after Home paints.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black54,
    ),
  );
  runApp(const MorphOSApp());
}

class MorphOSApp extends StatefulWidget {
  const MorphOSApp({super.key});

  @override
  State<MorphOSApp> createState() => _MorphOSAppState();
}

class _MorphOSAppState extends State<MorphOSApp> {
  final MorphController _controller = MorphController();
  StreamSubscription<Map<String, dynamic>>? _launcherSub;
  Widget? _homeHold;

  @override
  void initState() {
    super.initState();
    _controller.load();
    _listenLauncherEvents();
  }

  void _listenLauncherEvents() {
    _launcherSub?.cancel();
    _launcherSub = SystemMorphBridge.launcherEventStream().listen((event) {
      final type = '${event['type'] ?? ''}';
      if (!HomeNav.shouldPopToRoot(type)) return;
      _popToMorphHome();
      // Refresh default-home status after role / home picker returns.
      unawaited(_controller.refreshSystemStatus());
    });
  }

  /// Pop every pushed route so Morph home is the only surface (LauncherOS).
  void _popToMorphHome() {
    final nav = morphNavigatorKey.currentState;
    if (nav == null) return;
    while (nav.canPop()) {
      nav.pop();
    }
  }

  @override
  void dispose() {
    _launcherSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Stable MaterialApp shell — only inner content listens (avoids full tree thrash).
    return MaterialApp(
      title: 'MorphOS',
      navigatorKey: morphNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: MorphPalette.forTheme(_controller.themeId).toThemeData(),
      builder: (context, child) {
        return ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final theme = _controller.palette.toThemeData();
            return Theme(
              data: theme,
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
      home: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (!_controller.ready) {
            return const Scaffold(
              backgroundColor: Color(0xFF070A14),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF7C4DFF)),
                    SizedBox(height: 16),
                    Text(
                      'Loading MorphOS…',
                      style: TextStyle(color: Color(0xFFB0B8D0)),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!_controller.onboardingDone) {
            _homeHold = null;
            return OnboardingScreen(controller: _controller);
          }
          // Reuse the same HomeScreen instance so notifyListeners() does not
          // drop state (or flash Loading) on every controller tick.
          return _homeHold ??= HomeScreen(controller: _controller);
        },
      ),
    );
  }
}
