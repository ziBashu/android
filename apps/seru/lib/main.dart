import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zibashu_auth/zibashu_auth.dart';
import 'package:zibashu_core/zibashu_core.dart';
import 'package:zibashu_ui/zibashu_ui.dart';

import 'core/seru_client.dart';
import 'screens/shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SeruApp());
}

class SeruApp extends StatelessWidget {
  const SeruApp({super.key, this.demoShell = false});

  /// When true the four-tab shell opens on fixtures (widget tests).
  final bool demoShell;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seru',
      debugShowCheckedModeBanner: false,
      theme: buildZiBashuTheme(seed: const Color(0xFF3D5A80)),
      home: demoShell
          ? const SeruShell(demo: true, displayName: 'demo')
          : const SeruRoot(),
    );
  }
}

class SeruRoot extends StatefulWidget {
  const SeruRoot({super.key});

  @override
  State<SeruRoot> createState() => _SeruRootState();
}

class _SeruRootState extends State<SeruRoot> {
  late final AuthRepository _auth = AuthRepository(
    config: const ApiConfig(demoMode: false, userAgentTag: '1.0.0'),
  );

  AuthSession? _session;
  bool _demo = false;
  bool _booting = true;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    try {
      final session = await _auth.restore();
      if (!mounted) return;
      setState(() {
        _session = session;
        _booting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _booting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_booting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_demo) {
      return SeruShell(
        demo: true,
        displayName: 'demo',
        onLogout: () => setState(() => _demo = false),
      );
    }
    if (_session == null) {
      return LoginScreen(
        auth: _auth,
        onLoggedIn: (s) => setState(() => _session = s),
        onDemo: () => setState(() => _demo = true),
      );
    }
    return SeruShell(
      demo: false,
      displayName: _session!.name,
      client: SeruClient(_auth.client),
      onLogout: () async {
        await _auth.logout();
        if (!mounted) return;
        setState(() => _session = null);
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.auth,
    required this.onLoggedIn,
    required this.onDemo,
  });

  final AuthRepository auth;
  final ValueChanged<AuthSession> onLoggedIn;
  final VoidCallback onDemo;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  DeviceAuthChallenge? _challenge;
  String? _error;
  bool _busy = false;
  Timer? _poll;

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.auth.startDeviceAuth(clientName: 'Seru Android');
    if (!mounted) return;
    result.when(
      ok: (c) {
        setState(() {
          _challenge = c;
          _busy = false;
        });
        _open(c.verificationUriComplete);
        _beginPoll(c);
      },
      err: (e) => setState(() {
        _error = e.toString();
        _busy = false;
      }),
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _beginPoll(DeviceAuthChallenge challenge) {
    _poll?.cancel();
    _poll = Timer.periodic(Duration(seconds: challenge.interval), (_) async {
      final result = await widget.auth.pollDeviceAuth(challenge.deviceCode);
      if (!mounted) return;
      result.when(
        ok: (poll) {
          if (poll.status == 'approved' && poll.session != null) {
            _poll?.cancel();
            widget.onLoggedIn(poll.session!);
          } else if (poll.status != 'pending') {
            _poll?.cancel();
            setState(() => _error = poll.reason ?? poll.status);
          }
        },
        err: (e) {
          _poll?.cancel();
          setState(() => _error = e.toString());
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 24),
                Text('Seru', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Chat, friends, threads, and ZIBA pay — from ziBashu.\n'
                  'Message bodies stay on this device. Sign in with your ziBashu account.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ZiBashuBrand.ink.withValues(alpha: 0.7),
                      ),
                ),
                const SizedBox(height: 12),
                const FromZiBashuBadge(),
                const SizedBox(height: 28),
                if (_challenge != null) ...[
                  Text('Enter this code on ziBashu',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  SelectableText(
                    _challenge!.userCode,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _open(_challenge!.verificationUriComplete),
                    child: const Text('Open ziBashu to approve'),
                  ),
                ],
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!,
                        style: const TextStyle(color: ZiBashuBrand.danger)),
                  ),
                FilledButton(
                  onPressed: _busy ? null : _start,
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign in with ziBashu'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: widget.onDemo,
                  child: const Text('Continue in demo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
