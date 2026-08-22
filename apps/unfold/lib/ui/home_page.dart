import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:zibashu_ui/zibashu_ui.dart';

import '../core/detect.dart';
import '../core/recents.dart';
import '../native/bridge.dart';
import 'document_page.dart';
import 'licenses_page.dart';
import 'tokens.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.recents});

  final RecentsStore recents;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<RecentItem> _recents;
  String? _status;

  static const _formats = [
    'PDF',
    'EPUB',
    'TXT',
    'Markdown',
    'HTML',
    'DOCX',
    'DOC',
    'PNG/JPEG',
    'ZIP',
  ];

  @override
  void initState() {
    super.initState();
    _recents = widget.recents.load();
    UnfoldNative.listenOpen(_openPath);
    UnfoldNative.incoming().then((path) {
      if (path != null && path.isNotEmpty && mounted) _openPath(path);
    });
  }

  Future<void> _pick() async {
    final path = await UnfoldNative.pick();
    if (!mounted) return;
    if (path == null || path.isEmpty) {
      setState(() => _status = 'No file selected.');
      return;
    }
    await _openPath(path);
  }

  Future<void> _openPath(String path) async {
    try {
      Uint8List bytes = Uint8List(0);
      final file = File(path);
      if (file.existsSync()) {
        bytes = file.readAsBytesSync();
      }
      final kind = bytes.isEmpty ? FileKind.unknown : detectKind(path, bytes);
      widget.recents.add(
        RecentItem(
          path: path,
          name: p.basename(path),
          kind: kindLabel(kind),
          openedAt: DateTime.now(),
        ),
      );
      if (!mounted) return;
      setState(() {
        _recents = widget.recents.load();
        _status = null;
      });
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => DocumentPage(path: path)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: UnfoldTokens.paper,
      appBar: AppBar(
        title: const Text('Unfold'),
        actions: [
          IconButton(
            tooltip: 'Licenses',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const LicensesPage()),
              );
            },
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
        children: [
          Text(
            'Unfold',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Open. Read. Edit.',
            style: theme.textTheme.titleMedium?.copyWith(
              color: UnfoldTokens.muted,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          const FromZiBashuBadge(openWebsite: false),
          const SizedBox(height: 22),
          Text(
            'A local-first file viewer. Files stay on this device. There is no account, no cloud, and no network in the open path.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: _pick,
            icon: const Icon(Icons.folder_open_outlined),
            label: const Text('Open a file'),
          ),
          if (_status != null) ...[
            const SizedBox(height: 12),
            Text(_status!, style: const TextStyle(color: UnfoldTokens.muted)),
          ],
          const SizedBox(height: 28),
          Text('Formats', style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in _formats)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: UnfoldTokens.sheet,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: UnfoldTokens.line),
                  ),
                  child: Text(f, style: const TextStyle(fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 28),
          Text('Recent', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          if (_recents.isEmpty)
            const Text(
              'Opened files will appear here.',
              style: TextStyle(color: UnfoldTokens.muted),
            )
          else
            for (final item in _recents)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.name),
                subtitle: Text('${item.kind}  ·  ${item.path}'),
                onTap: () => _openPath(item.path),
              ),
          const SizedBox(height: 24),
          const FromZiBashuBadge(compact: true, openWebsite: false),
        ],
      ),
    );
  }
}
