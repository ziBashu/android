import 'package:flutter/material.dart';
import 'package:zibashu_auth/zibashu_auth.dart';
import 'package:zibashu_core/zibashu_core.dart';
import 'package:zibashu_ui/zibashu_ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SeruApp());
}

class SeruApp extends StatelessWidget {
  const SeruApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seru',
      debugShowCheckedModeBanner: false,
      theme: buildZiBashuTheme(seed: const Color(0xFF3D5A80)),
      home: const SeruRoot(),
    );
  }
}

class SeruRoot extends StatefulWidget {
  const SeruRoot({super.key});

  @override
  State<SeruRoot> createState() => _SeruRootState();
}

class _SeruRootState extends State<SeruRoot> {
  // Demo mode keeps the app usable without a mobile login API.
  late final AuthRepository _auth = AuthRepository(
    config: const ApiConfig(demoMode: true),
  );

  AuthSession? _session;
  bool _booting = true;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final session = await _auth.restore();
    if (!mounted) return;
    setState(() {
      _session = session;
      _booting = false;
    });
  }

  Future<void> _onLoggedIn(AuthSession session) async {
    setState(() => _session = session);
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    setState(() => _session = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_booting) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_session == null) {
      return LoginPage(auth: _auth, onLoggedIn: _onLoggedIn);
    }

    return InboxPage(session: _session!, onLogout: _logout);
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.auth,
    required this.onLoggedIn,
  });

  final AuthRepository auth;
  final ValueChanged<AuthSession> onLoggedIn;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
      ok: (session) {
        widget.onLoggedIn(session);
      },
      err: (e) {
        setState(() {
          _error = e.toString();
          _busy = false;
        });
      },
    );
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
                  'Private messaging for the ziBashu system.\n'
                  'Message bodies stay on your device in the long-term model.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ZiBashuBrand.ink.withValues(alpha: 0.7),
                      ),
                ),
                const SizedBox(height: 12),
                const FromZiBashuBadge(),
                const SizedBox(height: 28),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'you@example.com',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  onSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: ZiBashuBrand.danger)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _submit,
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
                  'Demo mode accepts any email/password. Live Sanctum login will use '
                  'POST /api/mobile/login on the ziBashu server.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ZiBashuBrand.ink.withValues(alpha: 0.55),
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

class Conversation {
  const Conversation({
    required this.id,
    required this.title,
    required this.preview,
    required this.updatedLabel,
  });

  final String id;
  final String title;
  final String preview;
  final String updatedLabel;
}

const _demoInbox = [
  Conversation(
    id: '1',
    title: 'Studio handoff',
    preview: 'Exported the canvas proof sidecar.',
    updatedLabel: '2h',
  ),
  Conversation(
    id: '2',
    title: 'Lab notes',
    preview: 'Lumen session expires in a few hours.',
    updatedLabel: 'Yesterday',
  ),
  Conversation(
    id: '3',
    title: 'World portal',
    preview: 'Meet in the Drawing room later?',
    updatedLabel: 'Mon',
  ),
];

class InboxPage extends StatelessWidget {
  const InboxPage({
    super.key,
    required this.session,
    required this.onLogout,
  });

  final AuthSession session;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return ZiBashuScaffold(
      title: 'Seru',
      actions: [
        IconButton(
          tooltip: 'Sign out',
          onPressed: onLogout,
          icon: const Icon(Icons.logout),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Signed in as ${session.name ?? session.email ?? 'member'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ZiBashuBrand.ink.withValues(alpha: 0.6),
                  ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _demoInbox.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final c = _demoInbox[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(c.title),
                    subtitle: Text(c.preview),
                    trailing: Text(
                      c.updatedLabel,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ThreadPage(conversation: c),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Compose will wire to Seru channel auth next. Local demo only for now.',
              ),
            ),
          );
        },
        child: const Icon(Icons.edit_outlined),
      ),
    );
  }
}

class ThreadPage extends StatefulWidget {
  const ThreadPage({super.key, required this.conversation});

  final Conversation conversation;

  @override
  State<ThreadPage> createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage> {
  final _controller = TextEditingController();
  late final List<_Msg> _messages = [
    _Msg(fromMe: false, text: widget.conversation.preview),
    const _Msg(fromMe: true, text: 'Got it — keeping this local for now.'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_Msg(fromMe: true, text: text));
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.conversation.title)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                return Align(
                  alignment:
                      m.fromMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      color: m.fromMe
                          ? const Color(0xFF3D5A80)
                          : Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(14),
                      border: m.fromMe
                          ? null
                          : Border.all(
                              color: ZiBashuBrand.ink.withValues(alpha: 0.08),
                            ),
                    ),
                    child: Text(
                      m.text,
                      style: TextStyle(
                        color: m.fromMe ? Colors.white : ZiBashuBrand.ink,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Message (local only)',
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: FromZiBashuBadge(compact: true),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  const _Msg({required this.fromMe, required this.text});
  final bool fromMe;
  final String text;
}
