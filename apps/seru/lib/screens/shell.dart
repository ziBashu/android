import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zibashu_ui/zibashu_ui.dart';

import '../core/friend_gate.dart';
import '../core/local_messages.dart';
import '../core/models.dart';
import '../core/pay_code.dart';
import '../core/seru_client.dart';

const seruTabLabels = ['Chat', 'Friends', 'Thread', 'Me'];

class SeruShell extends StatefulWidget {
  const SeruShell({
    super.key,
    required this.demo,
    this.client,
    this.displayName,
    this.onLogout,
    LocalMessageStore? messages,
  }) : messages = messages;

  final bool demo;
  final SeruClient? client;
  final String? displayName;
  final VoidCallback? onLogout;
  final LocalMessageStore? messages;

  @override
  State<SeruShell> createState() => _SeruShellState();
}

class _SeruShellState extends State<SeruShell> {
  int _index = 0;
  late final LocalMessageStore _store =
      widget.messages ?? LocalMessageStore();

  List<SeruPeer> _friends = [];
  List<SeruPeer> _search = [];
  List<SeruPeer> _incoming = [];
  List<ThreadCard> _threads = [];
  ZibaAssets _assets = const ZibaAssets(balance: '0.00000000');
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.demo) {
      _friends = const [
        SeruPeer(id: 2, name: 'Quiet Harbor', username: 'quiet'),
        SeruPeer(id: 3, name: 'Studio desk', username: 'studio'),
      ];
      _threads = const [
        ThreadCard(
          id: 1,
          title: 'A note from Home',
          body: 'Public threads from ziBashu show up here.',
          author: 'ziBashu',
        ),
      ];
      _assets = const ZibaAssets(balance: '1.00000000', payCode: 'ZBA-DEMO01');
    } else {
      _reload();
    }
  }

  Future<void> _reload() async {
    final client = widget.client;
    if (client == null) return;
    setState(() => _busy = true);
    final friends = await client.friends();
    final threads = await client.threads();
    final assets = await client.assets();
    final reqs = await client.requests();
    if (!mounted) return;
    setState(() {
      _busy = false;
      friends.when(
        ok: (v) => _friends = v,
        err: (e) => _error = e.toString(),
      );
      threads.when(
        ok: (v) => _threads = v,
        err: (e) => _error = e.toString(),
      );
      assets.when(
        ok: (v) => _assets = v,
        err: (e) => _error = e.toString(),
      );
      reqs.when(
        ok: (body) {
          final inc = body['incoming'];
          if (inc is List) {
            _incoming = inc
                .whereType<Map>()
                .map((row) {
                  final peer = row['peer'];
                  return peer is Map ? SeruPeer.fromJson(peer) : null;
                })
                .whereType<SeruPeer>()
                .toList();
          }
        },
        err: (e) => _error = e.toString(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _ChatTab(
        friends: _friends,
        store: _store,
        demo: widget.demo,
        client: widget.client,
      ),
      _FriendsTab(
        friends: _friends,
        incoming: _incoming,
        search: _search,
        demo: widget.demo,
        client: widget.client,
        onSearch: (q) async {
          if (widget.demo) {
            setState(() {
              _search = _friends
                  .where((p) => p.name.toLowerCase().contains(q.toLowerCase()))
                  .toList();
            });
            return;
          }
          final client = widget.client;
          if (client == null) return;
          final r = await client.search(q);
          r.when(
            ok: (v) => setState(() => _search = v),
            err: (e) => setState(() => _error = e.toString()),
          );
        },
        onChanged: _reload,
        onOpenChat: (peer) {
          setState(() => _index = 0);
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ConversationPage(
              peer: peer,
              store: _store,
              demo: widget.demo,
              client: widget.client,
              relationship: FriendGate.friends,
            ),
          ));
        },
      ),
      _ThreadTab(threads: _threads),
      _MeTab(
        name: widget.displayName ?? (widget.demo ? 'demo' : 'member'),
        assets: _assets,
        demo: widget.demo,
        client: widget.client,
        onLogout: widget.onLogout,
        onRefresh: _reload,
      ),
    ];

    return ZiBashuScaffold(
      title: seruTabLabels[_index],
      body: Column(
        children: [
          if (_error != null)
            MaterialBanner(
              content: Text(_error!),
              actions: [
                TextButton(
                  onPressed: () => setState(() => _error = null),
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: pages[_index]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'Friends'),
          NavigationDestination(icon: Icon(Icons.auto_stories_outlined), label: 'Thread'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Me'),
        ],
      ),
    );
  }
}

class _ChatTab extends StatelessWidget {
  const _ChatTab({
    required this.friends,
    required this.store,
    required this.demo,
    required this.client,
  });

  final List<SeruPeer> friends;
  final LocalMessageStore store;
  final bool demo;
  final SeruClient? client;

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return const EmptyState(
        title: 'No chats yet',
        message: 'Add a friend first, then talk here.',
      );
    }
    return ListView.separated(
      itemCount: friends.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final p = friends[i];
        final last = store.lastBody(p.id);
        return ListTile(
          leading: CircleAvatar(child: Text(p.name.isEmpty ? '?' : p.name[0])),
          title: Text(p.name),
          subtitle: Text(last ?? 'No messages on this device yet'),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ConversationPage(
              peer: p,
              store: store,
              demo: demo,
              client: client,
              relationship: FriendGate.friends,
            ),
          )),
        );
      },
    );
  }
}

class _FriendsTab extends StatefulWidget {
  const _FriendsTab({
    required this.friends,
    required this.incoming,
    required this.search,
    required this.demo,
    required this.client,
    required this.onSearch,
    required this.onChanged,
    required this.onOpenChat,
  });

  final List<SeruPeer> friends;
  final List<SeruPeer> incoming;
  final List<SeruPeer> search;
  final bool demo;
  final SeruClient? client;
  final Future<void> Function(String q) onSearch;
  final VoidCallback onChanged;
  final ValueChanged<SeruPeer> onOpenChat;

  @override
  State<_FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<_FriendsTab> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _q,
          decoration: const InputDecoration(
            labelText: 'Find someone',
            hintText: 'name or @username',
          ),
          onSubmitted: widget.onSearch,
        ),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: () => widget.onSearch(_q.text.trim()),
          child: const Text('Search'),
        ),
        if (widget.search.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Results', style: Theme.of(context).textTheme.titleSmall),
          ...widget.search.map((p) => ListTile(
                title: Text(p.name),
                subtitle: Text(p.handle),
                trailing: TextButton(
                  onPressed: () async {
                    if (widget.demo) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Demo — request sent locally.')),
                      );
                      return;
                    }
                    final r = await widget.client?.requestConnect(p.id);
                    r?.when(
                      ok: (_) => widget.onChanged(),
                      err: (e) => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$e')),
                      ),
                    );
                  },
                  child: const Text('Add'),
                ),
              )),
        ],
        if (widget.incoming.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Requests for you', style: Theme.of(context).textTheme.titleSmall),
          ...widget.incoming.map((p) => ListTile(
                title: Text(p.name),
                trailing: TextButton(
                  onPressed: () async {
                    if (widget.demo) return;
                    await widget.client?.respond(p.id, 'accept');
                    widget.onChanged();
                  },
                  child: const Text('Accept'),
                ),
              )),
        ],
        const SizedBox(height: 16),
        Text('Friends', style: Theme.of(context).textTheme.titleSmall),
        if (widget.friends.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('No friends yet.'),
          ),
        ...widget.friends.map((p) => ListTile(
              title: Text(p.name),
              subtitle: Text(p.handle),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline),
                    onPressed: () => widget.onOpenChat(p),
                  ),
                  IconButton(
                    icon: const Icon(Icons.block),
                    onPressed: () async {
                      if (widget.demo) return;
                      await widget.client?.block(p.id);
                      widget.onChanged();
                    },
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _ThreadTab extends StatelessWidget {
  const _ThreadTab({required this.threads});
  final List<ThreadCard> threads;

  @override
  Widget build(BuildContext context) {
    if (threads.isEmpty) {
      return const EmptyState(
        title: 'No threads yet',
        message: 'Public Home posts will land here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: threads.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final t = threads[i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(t.body),
                const SizedBox(height: 8),
                Text(t.author, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MeTab extends StatelessWidget {
  const _MeTab({
    required this.name,
    required this.assets,
    required this.demo,
    required this.client,
    required this.onLogout,
    required this.onRefresh,
  });

  final String name;
  final ZibaAssets assets;
  final bool demo;
  final SeruClient? client;
  final VoidCallback? onLogout;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        const Text('Settings · Assets'),
        const SizedBox(height: 20),
        Card(
          child: ListTile(
            title: const Text('ZIBA balance'),
            subtitle: Text('${assets.balance} ZBA'),
            trailing: const Icon(Icons.qr_code_2),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PayPage(
                demo: demo,
                client: client,
                assets: assets,
                onChanged: onRefresh,
              ),
            )),
          ),
        ),
        if (assets.payCode != null)
          ListTile(
            title: const Text('Your receive code'),
            subtitle: Text(assets.payCode!),
            trailing: IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: assets.payCode!));
              },
            ),
          ),
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PayPage(
              demo: demo,
              client: client,
              assets: assets,
              onChanged: onRefresh,
            ),
          )),
          child: const Text('Pay with ZIBA via code'),
        ),
        const SizedBox(height: 24),
        if (onLogout != null)
          TextButton(onPressed: onLogout, child: const Text('Log out')),
      ],
    );
  }
}

class ConversationPage extends StatefulWidget {
  const ConversationPage({
    super.key,
    required this.peer,
    required this.store,
    required this.demo,
    required this.client,
    required this.relationship,
  });

  final SeruPeer peer;
  final LocalMessageStore store;
  final bool demo;
  final SeruClient? client;
  final String relationship;

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final _text = TextEditingController();
  String? _err;

  Future<void> _send() async {
    final body = _text.text.trim();
    if (body.isEmpty) return;
    try {
      final msg = widget.store.sendToFriend(
        relationshipState: widget.relationship,
        peerId: widget.peer.id,
        body: body,
      );
      _text.clear();
      setState(() => _err = null);
      if (!widget.demo && widget.client != null) {
        final r = await widget.client!.sendEnvelope(
          receiverId: widget.peer.id,
          clientId: msg.clientId,
          body: msg.body,
        );
        r.when(ok: (_) {}, err: (e) => setState(() => _err = e.toString()));
      }
    } on FriendGateException catch (e) {
      setState(() => _err = e.message);
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final msgs = widget.store.conversation(widget.peer.id);
    return Scaffold(
      appBar: AppBar(title: Text(widget.peer.name)),
      body: Column(
        children: [
          if (_err != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(_err!, style: const TextStyle(color: ZiBashuBrand.danger)),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: msgs.length,
              itemBuilder: (context, i) {
                final m = msgs[i];
                final mine = m.direction == 'sent';
                return Align(
                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: mine ? const Color(0xFF3D5A80) : ZiBashuBrand.mist,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      m.body,
                      style: TextStyle(color: mine ? Colors.white : ZiBashuBrand.ink),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextField(
                      controller: _text,
                      decoration: const InputDecoration(hintText: 'Message'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                IconButton(onPressed: _send, icon: const Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PayPage extends StatefulWidget {
  const PayPage({
    super.key,
    required this.demo,
    required this.client,
    required this.assets,
    required this.onChanged,
  });

  final bool demo;
  final SeruClient? client;
  final ZibaAssets assets;
  final VoidCallback onChanged;

  @override
  State<PayPage> createState() => _PayPageState();
}

class _PayPageState extends State<PayPage> {
  final _code = TextEditingController();
  final _amount = TextEditingController();
  String? _status;
  String? _myCode;

  @override
  void initState() {
    super.initState();
    _myCode = widget.assets.payCode;
  }

  @override
  void dispose() {
    _code.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _issue() async {
    if (widget.demo) {
      setState(() {
        _myCode = 'ZBA-DEMO01';
        _status = 'Demo receive code ready.';
      });
      return;
    }
    final r = await widget.client?.createPayCode();
    r?.when(
      ok: (p) => setState(() {
        _myCode = p.code;
        _status = 'Show this code to the payer.';
      }),
      err: (e) => setState(() => _status = e.toString()),
    );
    widget.onChanged();
  }

  Future<void> _pay() async {
    final parsed = ZibaPayCodes.parse(_code.text);
    if (parsed == null) {
      setState(() => _status = 'That is not a ZIBA pay code.');
      return;
    }
    try {
      final intent = ZibaPayCodes.apply(
        payload: parsed,
        enteredAmount: _amount.text.trim().isEmpty ? null : _amount.text.trim(),
      );
      if (widget.demo) {
        setState(() => _status = 'Demo paid ${intent.amount} ZBA to ${intent.code}.');
        return;
      }
      final r = await widget.client?.pay(intent);
      r?.when(
        ok: (amt) {
          setState(() => _status = 'Paid $amt ZBA.');
          widget.onChanged();
        },
        err: (e) => setState(() => _status = e.toString()),
      );
    } on FormatException catch (e) {
      setState(() => _status = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ZIBA pay')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Balance ${widget.assets.balance} ZBA'),
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: _issue, child: const Text('Make my receive code')),
          if (_myCode != null) ...[
            const SizedBox(height: 8),
            SelectableText(_myCode!, style: Theme.of(context).textTheme.headlineSmall),
            TextButton(
              onPressed: () => Clipboard.setData(ClipboardData(text: 'ziba://pay/$_myCode')),
              child: const Text('Copy ziba:// pay URI'),
            ),
          ],
          const Divider(height: 32),
          const Text('Pay someone'),
          TextField(
            controller: _code,
            decoration: const InputDecoration(
              labelText: 'Receive code',
              hintText: 'ZBA-XXXXXX or ziba://pay/…',
            ),
          ),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount (if not fixed)'),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _pay, child: const Text('Pay')),
          if (_status != null) ...[
            const SizedBox(height: 12),
            Text(_status!),
          ],
        ],
      ),
    );
  }
}
