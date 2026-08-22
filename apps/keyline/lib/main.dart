import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zibashu_ui/zibashu_ui.dart';

const _host = MethodChannel('com.zibashu.keyline/host');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KEYLINEApp());
}

class KEYLINEApp extends StatelessWidget {
  const KEYLINEApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KEYLINE',
      debugShowCheckedModeBanner: false,
      theme: buildZiBashuTheme(seed: const Color(0xFF6B5E4E)),
      home: const KeylineHomePage(),
    );
  }
}

class KeylineHomePage extends StatelessWidget {
  const KeylineHomePage({super.key});

  Future<void> _openImeSettings() async {
    await _host.invokeMethod<void>('openInputMethodSettings');
  }

  Future<void> _openKeylineSettings() async {
    await _host.invokeMethod<void>('openKeylineSettings');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ZiBashuScaffold(
      title: 'KEYLINE',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('A quiet physical keyboard for Android.', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          const FromZiBashuBadge(openWebsite: false),
          const SizedBox(height: 20),
          Text(
            'KEYLINE never sends what you type to a server. Suggestions and '
            'corrections use a local dictionary on this device. There is no '
            'account, no cloud, and no network in the typing path.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Text('Enable the keyboard', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            '1. Open Android keyboard settings.\n'
            '2. Turn on KEYLINE.\n'
            '3. Choose KEYLINE as the current input method.\n'
            '4. Type in any ordinary text field.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _openImeSettings,
            child: const Text('Open keyboard settings'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _openKeylineSettings,
            child: const Text('KEYLINE settings'),
          ),
          const SizedBox(height: 28),
          Text('V1', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'English QWERTY, numbers and symbols, long-press accents, '
            'basic local suggestions, conservative autocorrect, light and dark themes. '
            'No AI, ads, voice input, or GIF search.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
