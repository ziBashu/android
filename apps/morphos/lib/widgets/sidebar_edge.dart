import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/morph_controller.dart';
import 'app_icon_tile.dart';

class SidebarEdge extends StatefulWidget {
  const SidebarEdge({
    super.key,
    required this.controller,
    required this.apps,
    required this.onOpen,
  });

  final MorphController controller;
  final List<MorphAppItem> apps;
  final ValueChanged<MorphAppItem> onOpen;

  @override
  State<SidebarEdge> createState() => _SidebarEdgeState();
}

class _SidebarEdgeState extends State<SidebarEdge> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final ids = widget.controller.sidebar.shortcutIds;
    final apps = <MorphAppItem>[];
    for (final id in ids) {
      for (final a in widget.apps) {
        if (a.id == id || a.packageName == id) {
          apps.add(a);
          break;
        }
      }
    }
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () => setState(() => _open = !_open),
        onHorizontalDragUpdate: (d) {
          if (d.delta.dx < -4 && !_open) setState(() => _open = true);
          if (d.delta.dx > 4 && _open) setState(() => _open = false);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: _open ? 76 : 8,
          margin: const EdgeInsets.only(right: 0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: _open ? 0.16 : 0.45),
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
          ),
          child: _open
              ? ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    for (final app in apps)
                      AppIconTile(
                        app: app,
                        controller: widget.controller,
                        compact: true,
                        showLabel: false,
                        onTap: () {
                          widget.onOpen(app);
                          setState(() => _open = false);
                        },
                      ),
                    if (apps.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.add, color: Colors.white54, size: 18),
                      ),
                  ],
                )
              : const SizedBox.expand(),
        ),
      ),
    );
  }
}
