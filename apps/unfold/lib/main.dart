import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:zibashu_ui/zibashu_ui.dart';

import 'core/recents.dart';
import 'ui/home_page.dart';
import 'ui/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  RecentsStore recents = MemoryRecents();
  try {
    final dir = await getApplicationDocumentsDirectory();
    recents = FileRecents(File(p.join(dir.path, 'unfold_recents.json')));
  } catch (_) {}
  runApp(UnfoldApp(recents: recents));
}

class UnfoldApp extends StatelessWidget {
  const UnfoldApp({super.key, this.recents});

  final RecentsStore? recents;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unfold',
      debugShowCheckedModeBanner: false,
      theme: buildZiBashuTheme(seed: UnfoldTokens.forest).copyWith(
        scaffoldBackgroundColor: UnfoldTokens.paper,
      ),
      home: HomePage(recents: recents ?? MemoryRecents()),
    );
  }
}
