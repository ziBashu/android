import 'package:flutter/material.dart';

import '../core/chrome_flags.dart';
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

  void _moveTo(Offset global, Size screen) {
    final next = SidebarPlacement.fromPoint(global.dx, global.dy, screen.width, screen.height);
    widget.controller.setSidebar(widget.controller.sidebar.withPlacement(next));
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.controller.sidebar.placement;
    final apps = _apps;
    final openH = (64.0 + apps.length * 54.0 + 48.0).clamp(120.0, 360.0);
    final w = _open ? HomeGestures.sidebarExpandedWidth : HomeGestures.sidebarHandleWidth;
    final h = _open
        ? (place.rim == ScreenRim.top || place.rim == ScreenRim.bottom
            ? HomeGestures.sidebarHandleHeight
            : openH)
        : (place.rim == ScreenRim.top || place.rim == ScreenRim.bottom
            ? HomeGestures.sidebarHandleWidth
            : HomeGestures.sidebarHandleHeight);

    return LayoutBuilder(
      builder: (context, box) {
        final ox = switch (place.rim) {
          ScreenRim.left => 2.0,
          ScreenRim.right => box.maxWidth - w - 2,
          ScreenRim.top => place.along * (box.maxWidth - w),
          ScreenRim.bottom => place.along * (box.maxWidth - w),
        };
        final oy = switch (place.rim) {
          ScreenRim.left => place.along * (box.maxHeight - h),
          ScreenRim.right => place.along * (box.maxHeight - h),
          ScreenRim.top => 2.0,
          ScreenRim.bottom => box.maxHeight - h - 2,
        };
        return Stack(
          children: [
            Positioned(
              left: ox,
              top: oy,
              width: w,
              height: h,
              child: GestureDetector(
                onTap: () => setState(() => _open = !_open),
                onLongPressMoveUpdate: (d) =>
                    _moveTo(d.globalPosition, Size(box.maxWidth, box.maxHeight)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: _open ? 0.18 : 0.7),
                    borderRadius: BorderRadius.circular(_open ? 20 : 99),
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
                              icon: const Icon(Icons.add, color: Colors.white, size: 18),
                            ),
                          ],
                        )
                      : const SizedBox.expand(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
