import 'package:flutter/material.dart';

import '../../core/app_search.dart';
import '../../core/models.dart';
import '../../core/morph_controller.dart';
import '../../widgets/app_icon_tile.dart';
import '../../widgets/glass_panel.dart';

/// Quick app search sheet — ranked display-name results.
Future<void> showAppSearchSheet({
  required BuildContext context,
  required MorphController controller,
  required List<MorphAppItem> apps,
  required void Function(MorphAppItem app) onOpenApp,
  void Function(MorphAppItem app)? onLongPress,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AppSearchSheet(
      controller: controller,
      apps: apps,
      onOpenApp: onOpenApp,
      onLongPress: onLongPress,
    ),
  );
}

class _AppSearchSheet extends StatefulWidget {
  const _AppSearchSheet({
    required this.controller,
    required this.apps,
    required this.onOpenApp,
    this.onLongPress,
  });

  final MorphController controller;
  final List<MorphAppItem> apps;
  final void Function(MorphAppItem app) onOpenApp;
  final void Function(MorphAppItem app)? onLongPress;

  @override
  State<_AppSearchSheet> createState() => _AppSearchSheetState();
}

class _AppSearchSheetState extends State<_AppSearchSheet> {
  final _focus = FocusNode();
  String _q = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final p = c.palette;
    final ranked = AppSearch.rank(
      widget.apps,
      _q,
      labelOf: c.labelFor,
    );
    final maxH = MediaQuery.sizeOf(context).height * 0.86;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: maxH,
        child: GlassPanel(
          palette: p,
          radius: 28,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: p.muted.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              TextField(
                focusNode: _focus,
                autofocus: true,
                style: TextStyle(color: p.ink),
                decoration: InputDecoration(
                  hintText: 'Search apps (e.g. Brave)',
                  hintStyle: TextStyle(color: p.muted),
                  prefixIcon: Icon(Icons.search, color: p.muted),
                  filled: true,
                  fillColor: p.scaffoldTint.withValues(alpha: 0.35),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: p.panelBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: p.panelBorder),
                  ),
                ),
                onChanged: (v) => setState(() => _q = v),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _q.trim().isEmpty
                      ? '${ranked.length} apps'
                      : '${ranked.length} matches',
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: ranked.isEmpty
                    ? Center(
                        child: Text(
                          'No apps match “$_q”',
                          style: TextStyle(color: p.muted),
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: aSearchSliver(c),
                        itemCount: ranked.length,
                        itemBuilder: (context, i) {
                          final app = ranked[i];
                          return AppIconTile(
                            app: app,
                            controller: c,
                            onTap: () {
                              Navigator.pop(context);
                              widget.onOpenApp(app);
                            },
                            onLongPress: widget.onLongPress == null
                                ? null
                                : () => widget.onLongPress!(app),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

SliverGridDelegateWithFixedCrossAxisCount aSearchSliver(MorphController c) {
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: c.gridColumns.clamp(3, 5),
    mainAxisSpacing: 6,
    crossAxisSpacing: 4,
    childAspectRatio: c.showLabels ? 0.78 : 1,
  );
}
