import 'package:flutter/material.dart';

import '../../core/app_library.dart';
import '../../core/app_search.dart';
import '../../core/models.dart';
import '../../core/morph_controller.dart';
import '../../core/morph_palette.dart';
import '../../widgets/app_icon_tile.dart';

class AppLibraryPage extends StatefulWidget {
  const AppLibraryPage({
    super.key,
    required this.controller,
    required this.apps,
    required this.onOpenApp,
    required this.onPlaceApp,
  });

  final MorphController controller;
  final List<MorphAppItem> apps;
  final void Function(MorphAppItem app) onOpenApp;
  final Future<void> Function(MorphAppItem app) onPlaceApp;

  @override
  State<AppLibraryPage> createState() => _AppLibraryPageState();
}

class _AppLibraryPageState extends State<AppLibraryPage> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final p = widget.controller.palette;
    final query = _q.trim();
    if (query.isNotEmpty) {
      return SafeArea(
        child: Column(
          children: [
            _searchField(p),
            Expanded(child: _resultsGrid()),
          ],
        ),
      );
    }

    final folders = AppLibrary.group(
      widget.apps,
      starredIds: widget.controller.starredAppIds,
      launchCounts: widget.controller.launchCounts,
    );
    final entries = folders.entries.toList();
    return SafeArea(
      child: Column(
        children: [
          _searchField(p),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.05,
              ),
              itemCount: entries.length,
              itemBuilder: (context, i) {
                final name = entries[i].key;
                final group = entries[i].value;
                return _Folder(
                  title: name,
                  apps: group,
                  controller: widget.controller,
                  onOpen: widget.onOpenApp,
                  onPlace: widget.onPlaceApp,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField(MorphPalette p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: TextField(
        style: TextStyle(color: p.ink),
        cursorColor: Colors.white,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'App Library',
          hintStyle: TextStyle(color: p.muted),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (v) => setState(() => _q = v),
      ),
    );
  }

  Widget _resultsGrid() {
    final ranked = AppSearch.rank(
      widget.apps,
      _q,
      labelOf: widget.controller.labelFor,
      starredIds: widget.controller.starredAppIds,
    );
    if (ranked.isEmpty) {
      return const Center(
        child: Text(
          'No apps match',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.controller.gridColumns.clamp(3, 5),
        childAspectRatio: 0.78,
      ),
      itemCount: ranked.length,
      itemBuilder: (_, i) {
        final a = ranked[i];
        return AppIconTile(
          app: a,
          controller: widget.controller,
          onTap: () => widget.onOpenApp(a),
          onLongPress: () => widget.onPlaceApp(a),
        );
      },
    );
  }
}

class _Folder extends StatelessWidget {
  const _Folder({
    required this.title,
    required this.apps,
    required this.controller,
    required this.onOpen,
    required this.onPlace,
  });

  final String title;
  final List<MorphAppItem> apps;
  final MorphController controller;
  final void Function(MorphAppItem app) onOpen;
  final Future<void> Function(MorphAppItem app) onPlace;

  @override
  Widget build(BuildContext context) {
    final preview = apps.take(4).toList();
    return Column(
      children: [
        Expanded(
          child: Material(
            color: Colors.black.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => _openFolder(context),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: GridView.count(
                  crossAxisCount: 2,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  children: [
                    for (final a in preview)
                      AppIconTile(
                        app: a,
                        controller: controller,
                        compact: true,
                        showLabel: false,
                        onTap: () => onOpen(a),
                        onLongPress: () => onPlace(a),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
            shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
          ),
        ),
      ],
    );
  }

  Future<void> _openFolder(BuildContext context) async {
    final p = controller.palette;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        var q = '';
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final ranked = AppSearch.rank(
              apps,
              q,
              labelOf: controller.labelFor,
              starredIds: controller.starredAppIds,
            );
            return SizedBox(
              height: MediaQuery.sizeOf(ctx).height * 0.72,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      title,
                      style: TextStyle(
                        color: p.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      style: TextStyle(color: p.ink),
                      decoration: const InputDecoration(
                        hintText: 'Filter this folder',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) => setLocal(() => q = v),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: controller.gridColumns.clamp(3, 5),
                        childAspectRatio: 0.78,
                      ),
                      itemCount: ranked.length,
                      itemBuilder: (_, i) {
                        final a = ranked[i];
                        return AppIconTile(
                          app: a,
                          controller: controller,
                          onTap: () {
                            Navigator.pop(ctx);
                            onOpen(a);
                          },
                          onLongPress: () async {
                            await onPlace(a);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
