import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zibashu_auth/zibashu_auth.dart';
import 'package:zibashu_core/zibashu_core.dart';
import 'package:zibashu_ui/zibashu_ui.dart';

/// Flux VPN — ziBashu family client.
/// HULK foundation: all VPN functions hard-locked.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FluxApp());
}

class FluxGate {
  static const productName = 'Flux';
  static const version = '0.1.0';
  static const codename = 'HULK';
  static const localHardLock = true;

  static bool serverUnlock = false;

  static bool get isVpnUnlocked => !localHardLock && serverUnlock;

  static String get lockReason => localHardLock
      ? 'Foundation build — VPN functions are locked for everyone.'
      : 'Account not entitled / server gate closed.';
}

class FluxApp extends StatelessWidget {
  const FluxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flux',
      debugShowCheckedModeBanner: false,
      theme: buildZiBashuTheme(seed: const Color(0xFF2EE6D6)),
      home: const FluxRoot(),
    );
  }
}

class FluxRoot extends StatefulWidget {
  const FluxRoot({super.key});

  @override
  State<FluxRoot> createState() => _FluxRootState();
}

class _FluxRootState extends State<FluxRoot> {
  late final AuthRepository _auth = AuthRepository(
    config: const ApiConfig(demoMode: true),
  );

  AuthSession? _session;
  bool _booting = true;
  Map<String, dynamic>? _control;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final session = await _auth.restore();
    await _refreshControl();
    if (!mounted) return;
    setState(() {
      _session = session;
      _booting = false;
      _statusMessage = FluxGate.lockReason;
    });
  }

  Future<void> _refreshControl() async {
    try {
      final uri = Uri.parse('${ApiConfig.defaultBaseUrl}/api/flux/control');
      final resp = await http.get(uri).timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body is Map<String, dynamic>) {
          FluxGate.serverUnlock = body['enabled'] == true;
          if (!mounted) return;
          setState(() => _control = body);
          return;
        }
      }
    } catch (_) {
      // Offline / foundation: keep stub control.
    }
    if (!mounted) return;
    setState(() {
      _control = {
        'enabled': false,
        'maintenance': true,
        'message': 'Control offline — foundation lock active.',
        'nodes': [
          {
            'id': 'stub-sea',
            'label': 'Seattle (stub)',
            'region': 'us-west',
            'available': false,
          },
          {
            'id': 'stub-tyo',
            'label': 'Tokyo (stub)',
            'region': 'ap-ne',
            'available': false,
          },
        ],
      };
    });
  }

  Future<void> _onLoggedIn(AuthSession session) async {
    setState(() => _session = session);
    await _refreshControl();
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    setState(() => _session = null);
  }

  Future<void> _tryConnect() async {
    setState(() {
      _statusMessage = FluxGate.isVpnUnlocked
          ? 'Connect path not implemented in foundation.'
          : FluxGate.lockReason;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_statusMessage ?? FluxGate.lockReason)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_booting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_session == null) {
      return _LoginPage(auth: _auth, onLoggedIn: _onLoggedIn);
    }

    final nodes = (_control?['nodes'] as List?) ?? const [];
    final message =
        (_control?['message'] as String?) ?? FluxGate.lockReason;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2748),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.bolt, color: Color(0xFF2EE6D6)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Flux',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        'from ziBashu · ${FluxGate.codename} foundation',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const FromZiBashuBadge(),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2308),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                message,
                style: const TextStyle(color: Color(0xFFF0B429), fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Signed in as ${_session!.name ?? "user"}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            Text(
              '${_session!.email ?? ""} · linked ziBashu account',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
            ),
            const SizedBox(height: 20),
            Text(
              'Status',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
            ),
            Text(
              FluxGate.isVpnUnlocked ? 'Ready' : 'Locked · idle',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _statusMessage ?? FluxGate.lockReason,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13),
            ),
            const SizedBox(height: 20),
            Text(
              'Nodes (stub)',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
            ),
            const SizedBox(height: 8),
            ...nodes.map((n) {
              final m = n is Map ? n : <String, dynamic>{};
              return Card(
                color: const Color(0xFF141C33),
                child: ListTile(
                  title: Text(
                    '${m['label'] ?? m['id'] ?? 'node'}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '${m['region'] ?? ''} · unavailable',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  ),
                  trailing: const Icon(Icons.lock_outline, color: Color(0xFFF0B429)),
                ),
              );
            }),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _tryConnect,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1A2748),
                foregroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Connect (locked)'),
            ),
            const SizedBox(height: 12),
            Text(
              'Flux v${FluxGate.version} · control /api/flux · dual ship: warehub APK + Play AAB',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginPage extends StatefulWidget {
  const _LoginPage({required this.auth, required this.onLoggedIn});

  final AuthRepository auth;
  final ValueChanged<AuthSession> onLoggedIn;

  @override
  State<_LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<_LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.auth.login(
      email: _email.text.trim(),
      password: _password.text,
    );
    if (!mounted) return;
    result.when(
      ok: (session) => widget.onLoggedIn(session),
      err: (e) => setState(() {
        _error = e.toString();
        _busy = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 24),
                Text(
                  'Flux',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Private network client for the ziBashu system.\n'
                  'Foundation release — VPN is locked for everyone.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
                ),
                const SizedBox(height: 12),
                const FromZiBashuBadge(),
                const SizedBox(height: 28),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'ziBashu email',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF2A3A5C)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF2EE6D6)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF2A3A5C)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF2EE6D6)),
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: ZiBashuBrand.danger)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2EE6D6),
                    foregroundColor: const Color(0xFF0B1020),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue (demo)'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Demo accepts any email/password. Live mode uses ziBashu Sanctum '
                  'POST /api/mobile/login. Account is the same ziBashu identity.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
