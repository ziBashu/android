import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/morph_controller.dart';
import 'core/morph_palette.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Portrait first frame — avoids zero-size relaunch while prefs load.
  SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
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

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Stable MaterialApp shell — only inner content listens (avoids full tree thrash).
    return MaterialApp(
      title: 'MorphOS',
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
                child: CircularProgressIndicator(color: Color(0xFF7C4DFF)),
              ),
            );
          }
          if (!_controller.onboardingDone) {
            return OnboardingScreen(controller: _controller);
          }
          return HomeScreen(controller: _controller);
        },
      ),
    );
  }
}
