import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models.dart';
import '../../core/morph_controller.dart';
import '../../core/morph_palette.dart';
import '../../widgets/app_icon_tile.dart';
import '../../widgets/glass_panel.dart';

/// Phase 4 — MorphOS Desktop Mode: rail + workspace + floating tasks.
class DesktopShell extends StatefulWidget {
  const DesktopShell({
    super.key,
    required this.controller,
    required this.apps,
    required this.dockApps,
    required this.onOpenApp,
    required this.onRename,
    required this.onOpenDrawer,
  });

  final MorphController controller;
  final List<MorphAppItem> apps;
  final List<MorphAppItem> dockApps;
  final Future<void> Function(MorphAppItem app) onOpenApp;
  final Future<void> Function(MorphAppItem app) onRename;
  final VoidCallback onOpenDrawer;

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  MorphController get c => widget.controller;
  final List<_FloatTask> _floats = [];

  List<MorphAppItem> get _railApps {
    final source = widget.apps.where((a) => a.id != 'settings').toList();
    return source.take(10).toList(growable: false);
  }

  void _spawnFloat(MorphAppItem app) {
    if (!c.floatingWindowsEnabled) return;
    setState(() {
      final i = _floats.length;
      _floats.add(
        _FloatTask(
          id: '${app.id}_${DateTime.now().millisecondsSinceEpoch}',
          app: app,
          offset: Offset(48.0 + i * 28, 40.0 + i * 24),
          size: const Size(260, 180),
        ),
      );
    });
    HapticFeedback.selectionClick();
  }

  void _closeFloat(String id) {
    setState(() => _floats.removeWhere((f) => f.id == id));
  }

  Future<void> _open(MorphAppItem app) async {
    if (c.floatingWindowsEnabled &&
        HardwareKeyboard.instance.isControlPressed) {
      _spawnFloat(app);
      return;
    }
    await widget.onOpenApp(app);
  }

  @override
  Widget build(BuildContext context) {
    final p = c.palette;
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 600;

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide) _buildRail(p) else const SizedBox(width: 0),
              Expanded(child: _buildWorkspace(p, wide)),
            ],
          ),
        ),
        _buildTaskbar(p),
      ],
    );
  }

  Widget _buildRail(MorphPalette p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
      child: GlassPanel(
        palette: p,
        radius: 20,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: SizedBox(
          width: 76,
          child: Column(
            children: [
              Text(
                'Apps',
                style: TextStyle(
                  color: p.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _railApps.length,
                  itemBuilder: (context, i) {
                    final app = _railApps[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: AppIconTile(
                          app: app,
                          controller: c,
                          compact: true,
                          showLabel: false,
                          onTap: () => _open(app),
                          onLongPress: () => _spawnFloat(app),
                        ),
                      ),
                    );
                  },
                ),
              ),
              IconButton(
                tooltip: 'All apps',
                onPressed: widget.onOpenDrawer,
                icon: Icon(Icons.apps_rounded, color: p.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkspace(MorphPalette p, bool wide) {
    return Padding(
      padding: EdgeInsets.fromLTRB(wide ? 4 : 10, 4, 10, 4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassPanel(
                palette: p,
                radius: 18,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.desktop_windows_outlined,
                            color: p.accentSecondary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Desktop workspace',
                            style: TextStyle(
                              color: p.ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (c.displayInfo.hasExternalDisplay)
                          _chip(p, 'External display', Icons.cast_connected),
                        if (c.pointerConnected)
                          _chip(p, 'Mouse', Icons.mouse_outlined),
                        if (c.keyboardConnected)
                          _chip(p, 'Keyboard', Icons.keyboard_outlined),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c.floatingWindowsEnabled
                          ? 'Long-press or Ctrl+tap app → floating task. Tap launches.'
                          : 'Floating tasks off — apps launch directly.',
                      style: TextStyle(color: p.muted, fontSize: 12),
                    ),
                    if (c.systemStatus.systemMorphEnabled) ...[
                      const SizedBox(height: 4),
                      Text(
                        'System morph: ${c.profileId.systemOrientationMode}'
                        '${c.systemStatus.accessibilityRunning ? ' · a11y on' : ' · enable Accessibility'}',
                        style: TextStyle(
                          color: p.accentSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: GlassPanel(
                  palette: p,
                  radius: 18,
                  padding: const EdgeInsets.all(12),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = constraints.maxWidth > 700
                          ? 5
                          : constraints.maxWidth > 420
                              ? 4
                              : 3;
                      final gridApps = widget.apps
                          .where((a) => a.id != 'settings')
                          .take(cols * 3)
                          .toList();
                      return GridView.builder(
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.9,
                        ),
                        itemCount: gridApps.length,
                        itemBuilder: (context, i) {
                          final app = gridApps[i];
                          return MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: AppIconTile(
                              app: app,
                              controller: c,
                              onTap: () => _open(app),
                              onLongPress: () => _spawnFloat(app),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          for (final f in _floats)
            _FloatingWindow(
              key: ValueKey(f.id),
              task: f,
              palette: p,
              controller: c,
              onClose: () => _closeFloat(f.id),
              onOpen: () => widget.onOpenApp(f.app),
              onMoved: (o) => setState(() => f.offset = o),
            ),
        ],
      ),
    );
  }

  Widget _chip(MorphPalette p, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: p.accent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: p.panelBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: p.accentSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: p.ink, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskbar(MorphPalette p) {
    final dock = widget.dockApps;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: GlassPanel(
        palette: p,
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 6, right: 8),
                child: Icon(Icons.circle, size: 10, color: p.accent),
              ),
              for (final app in dock.take(6))
                Expanded(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: AppIconTile(
                      app: app,
                      controller: c,
                      compact: true,
                      showLabel: false,
                      onTap: () => _open(app),
                      onLongPress: () => widget.onRename(app),
                    ),
                  ),
                ),
              Expanded(
                child: Center(
                  child: IconButton(
                    tooltip: 'All apps',
                    onPressed: widget.onOpenDrawer,
                    icon: Icon(Icons.apps_rounded, color: p.ink, size: 26),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatTask {
  _FloatTask({
    required this.id,
    required this.app,
    required this.offset,
    required this.size,
  });

  final String id;
  final MorphAppItem app;
  Offset offset;
  Size size;
}

class _FloatingWindow extends StatelessWidget {
  const _FloatingWindow({
    super.key,
    required this.task,
    required this.palette,
    required this.controller,
    required this.onClose,
    required this.onOpen,
    required this.onMoved,
  });

  final _FloatTask task;
  final MorphPalette palette;
  final MorphController controller;
  final VoidCallback onClose;
  final VoidCallback onOpen;
  final ValueChanged<Offset> onMoved;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Positioned(
      left: task.offset.dx,
      top: task.offset.dy,
      width: task.size.width,
      height: task.size.height,
      child: GestureDetector(
        onPanUpdate: (d) {
          onMoved(task.offset + d.delta);
        },
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(14),
          color: p.panel.withValues(alpha: 0.94),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.panelBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: p.accent.withValues(alpha: 0.18),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(task.app.icon, size: 16, color: p.accentSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          controller.labelFor(task.app),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: p.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        onPressed: onOpen,
                        icon: Icon(Icons.open_in_new, size: 16, color: p.ink),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        onPressed: onClose,
                        icon: Icon(Icons.close, size: 16, color: p.muted),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Floating task',
                          style: TextStyle(
                            color: p.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Phase 4 multitask panel for ${controller.labelFor(task.app)}. '
                          'Drag title bar · Open launches the real app.',
                          style: TextStyle(
                            color: p.muted,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                        const Spacer(),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: onOpen,
                            child: const Text('Launch'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
