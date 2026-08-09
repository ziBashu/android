import 'package:flutter/material.dart';

import '../../core/app_search.dart';
import '../../core/models.dart';
import '../../core/morph_controller.dart';
import '../../widgets/app_icon_tile.dart';
import '../../widgets/glass_panel.dart';

/// App drawer — device apps when available (Phase 3).
class AppDrawerSheet extends StatefulWidget {
  const AppDrawerSheet({
    super.key,
    required this.controller,
    required this.apps,
    required this.onOpenApp,
    required this.onRename,
    this.onRefresh,
    this.usingDeviceApps = false,
  });

  final MorphController controller;
  final List<MorphAppItem> apps;
  final void Function(MorphAppItem app) onOpenApp;
  final void Function(MorphAppItem app) onRename;
  final Future<void> Function()? onRefresh;
  final bool usingDeviceApps;

  @override
  State<AppDrawerSheet> createState() => _AppDrawerSheetState();
}

class _AppDrawerSheetState extends State<AppDrawerSheet> {
  String _q = '';
  bool _refreshing = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final p = c.palette;
    // Ranked search: label-first (Brave beats package noise).
    final filtered = AppSearch.rank(
      widget.apps,
      _q,
      labelOf: c.labelFor,
    );

    final maxH = MediaQuery.sizeOf(context).height * 0.88;

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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.usingDeviceApps
                          ? 'Device apps'
                          : 'Demo apps (device list unavailable)',
                      style: TextStyle(
                        color: p.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (widget.onRefresh != null)
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: _refreshing
                          ? null
                          : () async {
                              setState(() => _refreshing = true);
                              await widget.onRefresh!();
                              if (mounted) {
                                setState(() => _refreshing = false);
                              }
                            },
                      icon: _refreshing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.refresh, color: p.accentSecondary),
                    ),
                ],
              ),
              TextField(
                style: TextStyle(color: p.ink),
                decoration: InputDecoration(
                  hintText: 'Search apps',
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
                  '${filtered.length} apps',
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: c.gridColumns.clamp(3, 5),
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 4,
                    childAspectRatio: c.showLabels ? 0.78 : 1,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final app = filtered[i];
                    return AppIconTile(
                      app: app,
                      controller: c,
                      onTap: () {
                        Navigator.pop(context);
                        widget.onOpenApp(app);
                      },
                      onLongPress: () => widget.onRename(app),
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
