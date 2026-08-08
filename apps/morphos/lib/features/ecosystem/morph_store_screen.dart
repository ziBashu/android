import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zibashu_ui/zibashu_ui.dart';

import '../../core/models.dart';
import '../../core/morph_controller.dart';
import '../../core/morph_pack.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/morph_background.dart';
import 'morph_creator_screen.dart';

/// Phase 5 — Morph Store + My Modes library + community import.
class MorphStoreScreen extends StatefulWidget {
  const MorphStoreScreen({super.key, required this.controller});

  final MorphController controller;

  @override
  State<MorphStoreScreen> createState() => _MorphStoreScreenState();
}

class _MorphStoreScreenState extends State<MorphStoreScreen>
    with SingleTickerProviderStateMixin {
  MorphController get c => widget.controller;
  late final TabController _tabs;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  List<MorphPack> get _storeFiltered {
    final all = c.storeCatalog;
    if (_filter == 'all') return all;
    return all.where((p) => p.category == _filter).toList();
  }

  Future<void> _apply(MorphPack pack) async {
    await c.applyPack(pack, reason: 'store');
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Applied ${pack.name}')),
    );
  }

  Future<void> _install(MorphPack pack) async {
    await c.installPack(pack);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Installed ${pack.name}')),
    );
  }

  Future<void> _export(MorphPack pack) async {
    await Clipboard.setData(ClipboardData(text: c.exportPackJson(pack)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pack JSON copied — share with community')),
    );
  }

  Future<void> _importClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final pack = await c.importPackJson(data?.text ?? '');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pack == null
              ? 'Invalid morphpack JSON'
              : 'Imported ${pack.name}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = c.palette;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MorphBackground(
        wallpaperId: c.wallpaperId,
        palette: p,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Morph Store'),
            actions: [
              IconButton(
                tooltip: 'Import pack JSON',
                onPressed: _importClipboard,
                icon: Icon(Icons.download_outlined, color: p.accentSecondary),
              ),
              IconButton(
                tooltip: 'Morph Creator',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ListenableBuilder(
                        listenable: c,
                        builder: (_, __) =>
                            MorphCreatorScreen(controller: c),
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.design_services_outlined, color: p.accentSecondary),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: FromZiBashuBadge(compact: true, openWebsite: false),
              ),
            ],
            bottom: TabBar(
              controller: _tabs,
              labelColor: p.ink,
              unselectedLabelColor: p.muted,
              indicatorColor: p.accent,
              tabs: const [
                Tab(text: 'Store'),
                Tab(text: 'My Modes'),
                Tab(text: 'Community'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabs,
            children: [
              _buildStoreTab(p),
              _buildLibraryTab(p),
              _buildCommunityTab(p),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreTab(dynamic p) {
    final items = _storeFiltered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'Offline shelf · same schema as future online Morph Store',
            style: TextStyle(color: p.muted, fontSize: 12),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: kMorphPackCategories.map((cat) {
              final sel = _filter == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: sel,
                  onSelected: (_) => setState(() => _filter = cat),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: items.length,
            itemBuilder: (context, i) => _packCard(p, items[i], store: true),
          ),
        ),
      ],
    );
  }

  Widget _buildLibraryTab(dynamic p) {
    final items = c.packLibrary;
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No modes yet.\nInstall from Store or create one in Morph Creator.',
            textAlign: TextAlign.center,
            style: TextStyle(color: p.muted, height: 1.4),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items.length,
      itemBuilder: (context, i) => _packCard(p, items[i], store: false),
    );
  }

  Widget _buildCommunityTab(dynamic p) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        GlassPanel(
          palette: p,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Community packs',
                style: TextStyle(
                  color: p.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share morphpack/v1 JSON like a mini Steam Workshop for MorphOS.\n'
                'Copy a pack → send to a friend → Import here.\n'
                'Online Morph Store + creator tools ship later on warehub.',
                style: TextStyle(color: p.muted, height: 1.4, fontSize: 13),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _importClipboard,
                icon: const Icon(Icons.file_download_outlined),
                label: const Text('Import from clipboard'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ListenableBuilder(
                        listenable: c,
                        builder: (_, __) =>
                            MorphCreatorScreen(controller: c),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.design_services_outlined),
                label: const Text('Open Morph Creator'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Your shareable library',
          style: TextStyle(
            color: p.ink,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        if (c.packLibrary.isEmpty)
          Text(
            'Create or install a pack, then Export to share.',
            style: TextStyle(color: p.muted, fontSize: 13),
          )
        else
          ...c.packLibrary.map(
            (pack) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassPanel(
                palette: p,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pack.name,
                            style: TextStyle(
                              color: p.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'by ${pack.author} · ${pack.category}',
                            style: TextStyle(color: p.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _export(pack),
                      child: const Text('Export'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _packCard(dynamic p, MorphPack pack, {required bool store}) {
    final installed = c.isPackInstalled(pack.id);
    final active = c.activePackId == pack.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassPanel(
        palette: p,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: p.accent.withValues(alpha: 0.25),
                  child: Icon(
                    pack.targetProfile.icon,
                    color: p.accentSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pack.name,
                        style: TextStyle(
                          color: p.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${pack.author} · ${pack.category}'
                        '${active ? ' · active' : ''}'
                        '${installed && store ? ' · installed' : ''}',
                        style: TextStyle(color: p.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              pack.description,
              style: TextStyle(color: p.muted, height: 1.35, fontSize: 13),
            ),
            if (pack.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: pack.tags
                    .map(
                      (t) => Chip(
                        label: Text(t, style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                FilledButton(
                  onPressed: () => _apply(pack),
                  child: const Text('Apply'),
                ),
                if (store && !installed)
                  OutlinedButton(
                    onPressed: () => _install(pack),
                    child: const Text('Install'),
                  ),
                if (!store || installed)
                  OutlinedButton(
                    onPressed: () => _export(pack),
                    child: const Text('Export'),
                  ),
                if (!store && !pack.builtIn)
                  TextButton(
                    onPressed: () async {
                      await c.uninstallPack(pack.id);
                      if (mounted) setState(() {});
                    },
                    child: Text('Remove', style: TextStyle(color: p.muted)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
