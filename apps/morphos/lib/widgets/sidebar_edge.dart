import 'package:flutter/material.dart';

import '../core/home_gestures.dart';
import '../core/models.dart';
import '../core/morph_controller.dart';
import 'app_icon_tile.dart';

class SidebarEdge extends StatefulWidget {
  const SidebarEdge({
    super.key,
    required this.controller,
    required this.apps,
    required this.onOpen,
    required this.onAdd,
  });

  final MorphController controller;
  final List<MorphAppItem> apps;
  final ValueChanged<MorphAppItem> onOpen;
  final VoidCallback onAdd;

  @override
  State<SidebarEdge> createState() => _SidebarEdgeState();
}

class _SidebarEdgeState extends State<SidebarEdge> {
  bool _open = false;

  List<MorphAppItem> get _apps {
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
    return apps;
  }

  @override
  Widget build(BuildContext context) {
    final apps = _apps;
    final openH = (72.0 + apps.length * 58.0 + 56.0).clamp(160.0, 420.0);
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
          width: _open
              ? HomeGestures.sidebarExpandedWidth
              : HomeGestures.sidebarHandleWidth,
          height: _open ? openH : HomeGestures.sidebarHandleHeight,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: _open ? 0.18 : 0.62),
            borderRadius: BorderRadius.circular(_open ? 22 : 99),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
              ),
            ],
          ),
          child: _open
              ? ListView(
                  padding: const EdgeInsets.symmetric(vertical: 10),
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
                        onLongPress: () async {
                          await widget.controller.setSidebar(
                            widget.controller.sidebar.remove(app.id),
                          );
                          if (mounted) setState(() {});
                        },
                      ),
                    IconButton(
                      tooltip: 'Add app',
                      onPressed: () {
                        setState(() => _open = false);
                        widget.onAdd();
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                    ),
                  ],
                )
              : const SizedBox.expand(),
        ),
      ),
    );
  }
}
