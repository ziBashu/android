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
  Offset? _pointerDown;

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
    final vertical = place.rim == ScreenRim.left || place.rim == ScreenRim.right;
    final w = _open
        ? HomeGestures.sidebarExpandedWidth
        : (vertical
            ? HomeGestures.sidebarHitWidth
            : HomeGestures.sidebarHitHeight);
    final h = _open
        ? (vertical ? openH : HomeGestures.sidebarHitWidth)
        : (vertical
            ? HomeGestures.sidebarHitHeight
            : HomeGestures.sidebarHitWidth);

    return LayoutBuilder(
      builder: (context, box) {
        final screen = Size(box.maxWidth, box.maxHeight);
        final ox = switch (place.rim) {
          ScreenRim.left => 0.0,
          ScreenRim.right => box.maxWidth - w,
          ScreenRim.top => place.along * (box.maxWidth - w),
          ScreenRim.bottom => place.along * (box.maxWidth - w),
        };
        final oy = switch (place.rim) {
          ScreenRim.left => place.along * (box.maxHeight - h),
          ScreenRim.right => place.along * (box.maxHeight - h),
          ScreenRim.top => HomeGestures.statusBarBandHeight,
          ScreenRim.bottom => box.maxHeight - h,
        };
        return Stack(
          children: [
            Positioned(
              left: ox,
              top: oy,
              width: w,
              height: h,
              child: Listener(
                onPointerDown: (e) => _pointerDown = e.position,
                onPointerUp: (e) {
                  final start = _pointerDown;
                  _pointerDown = null;
                  if (start == null || _open) return;
                  if (HomeGestures.openSidebarFromRimSwipe(
                    rim: place.rim,
                    startX: start.dx,
                    startY: start.dy,
                    dx: e.position.dx - start.dx,
                    dy: e.position.dy - start.dy,
                    screenW: screen.width,
                    screenH: screen.height,
                    along: place.along,
                  )) {
                    setState(() => _open = true);
                  }
                },
                child: GestureDetector(
                  onTap: () => setState(() => _open = !_open),
                  onLongPressMoveUpdate: (d) =>
                      _moveTo(d.globalPosition, screen),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: _open ? 0.18 : 0.22),
                      borderRadius: BorderRadius.circular(_open ? 20 : 16),
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
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ],
                          )
                        : Center(
                            child: Container(
                              width: vertical
                                  ? HomeGestures.sidebarHandleWidth
                                  : HomeGestures.sidebarHandleHeight,
                              height: vertical
                                  ? HomeGestures.sidebarHandleHeight
                                  : HomeGestures.sidebarHandleWidth,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.78),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
