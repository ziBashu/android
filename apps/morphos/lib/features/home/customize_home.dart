import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/home_occupancy.dart';
import '../../core/image_customize.dart';
import '../../core/models.dart';
import '../../core/morph_controller.dart';

Future<void> showCustomizeMenu({
  required BuildContext context,
  required MorphController controller,
  required VoidCallback onAddWidget,
  required VoidCallback onClearPage,
  required VoidCallback onToggleDock,
  VoidCallback? onAddApp,
}) async {
  final p = controller.palette;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: p.panel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onAddApp != null)
              ListTile(
                leading: const Icon(Icons.add_box_outlined),
                title: const Text('Add App'),
                subtitle: const Text('Place an installed app on this page'),
                onTap: () {
                  Navigator.pop(ctx);
                  onAddApp();
                },
              ),
            ListTile(
              leading: const Icon(Icons.widgets_outlined),
              title: const Text('Add Widget'),
              onTap: () {
                Navigator.pop(ctx);
                onAddWidget();
              },
            ),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Customize Theme'),
              onTap: () {
                Navigator.pop(ctx);
                showThemePicker(context: context, controller: controller);
              },
            ),
            ListTile(
              leading: const Icon(Icons.wallpaper_outlined),
              title: const Text('Edit Wallpaper'),
              onTap: () {
                Navigator.pop(ctx);
                showWallpaperPicker(context: context, controller: controller);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cleaning_services_outlined),
              title: const Text('Clear all apps on this page'),
              onTap: () {
                Navigator.pop(ctx);
                onClearPage();
              },
            ),
            ListTile(
              leading: Icon(
                controller.dockVisible
                    ? Icons.dock_outlined
                    : Icons.dock,
              ),
              title: Text(
                controller.dockVisible ? 'Remove dock' : 'Add dock',
              ),
              subtitle: Text(
                controller.dockVisible
                    ? 'Dock apps return to the home page'
                    : 'Show the glass app column',
                style: TextStyle(color: p.muted, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onToggleDock();
              },
            ),
          ],
        ),
      );
    },
  );
}

Future<void> showAddWidgetSheet({
  required BuildContext context,
  required MorphController controller,
}) async {
  final p = controller.palette;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: p.panel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (_, __) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Add Widget',
                    style: TextStyle(
                      color: p.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ),
                for (final kind in HomeWidgetKind.values)
                  SwitchListTile(
                    title: Text(kind.label),
                    subtitle: Text(
                      kind.blurb,
                      style: TextStyle(color: p.muted, fontSize: 12),
                    ),
                    value: controller.homeWidgets.contains(kind),
                    onChanged: (_) => controller.toggleHomeWidget(kind),
                  ),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      );
    },
  );
}

Future<void> showThemePicker({
  required BuildContext context,
  required MorphController controller,
}) async {
  final p = controller.palette;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: p.panel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (_, __) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MorphThemeId.values.map((t) {
                  return ChoiceChip(
                    label: Text(t.label),
                    selected: controller.themeId == t,
                    onSelected: (_) => controller.setTheme(t),
                  );
                }).toList(),
              ),
            );
          },
        ),
      );
    },
  );
}

Future<void> showWallpaperPicker({
  required BuildContext context,
  required MorphController controller,
}) async {
  final p = controller.palette;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: p.panel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (_, __) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Edit Wallpaper',
                    style: TextStyle(
                      color: p.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: WallpaperId.values.map((w) {
                      return ChoiceChip(
                        label: Text(w.label),
                        selected: controller.wallpaperId == w,
                        onSelected: (_) => controller.setWallpaper(w),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () =>
                        _pickPhoto(context, controller, landscape: false),
                    child: const Text('Portrait photo'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: () =>
                        _pickPhoto(context, controller, landscape: true),
                    child: const Text('Landscape photo'),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

Future<void> _pickPhoto(
  BuildContext context,
  MorphController controller, {
  required bool landscape,
}) async {
  try {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 88,
    );
    if (file == null) return;
    final raw = await file.readAsBytes();
    final prepared = ImageCustomize.prepareWallpaper(raw);
    if (prepared == null) return;
    if (landscape) {
      await controller.setCustomWallpapers(landscapeBytes: prepared);
    } else {
      await controller.setCustomWallpapers(portraitBytes: prepared);
    }
  } catch (_) {}
}

Future<void> showAddAppSheet({
  required BuildContext context,
  required MorphController controller,
  required List<MorphAppItem> apps,
  required Future<void> Function(MorphAppItem app) onAddHome,
  required Future<void> Function(MorphAppItem app) onAddDock,
}) async {
  final p = controller.palette;
  final available = apps.where((a) {
    return !controller.homeIds.contains(a.id) &&
        !controller.dockIds.contains(a.id) &&
        (a.packageName == null ||
            (!controller.homeIds.contains(a.packageName) &&
                !controller.dockIds.contains(a.packageName)));
  }).toList();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: p.panel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      var q = '';
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          final ranked = available.where((a) {
            if (q.trim().isEmpty) return true;
            final needle = q.toLowerCase();
            return controller.labelFor(a).toLowerCase().contains(needle) ||
                a.id.toLowerCase().contains(needle);
          }).toList();
          return SizedBox(
            height: MediaQuery.sizeOf(ctx).height * 0.78,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Add App',
                    style: TextStyle(
                      color: p.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    autofocus: true,
                    style: TextStyle(color: p.ink),
                    decoration: const InputDecoration(
                      hintText: 'Filter apps',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setLocal(() => q = v),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ranked.isEmpty
                      ? Center(
                          child: Text(
                            available.isEmpty
                                ? 'Every listed app is already on Home or the dock'
                                : 'No apps match',
                            style: TextStyle(color: p.muted),
                          ),
                        )
                      : ListView.builder(
                          itemCount: ranked.length,
                          itemBuilder: (_, i) {
                            final app = ranked[i];
                            return ListTile(
                              leading: app.iconBytes != null &&
                                      app.iconBytes!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.memory(
                                        Uint8List.fromList(app.iconBytes!),
                                        width: 36,
                                        height: 36,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Icon(app.icon, color: p.accent),
                              title: Text(
                                controller.labelFor(app),
                                style: TextStyle(color: p.ink),
                              ),
                              subtitle: Text(
                                app.packageName ?? app.id,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: p.muted, fontSize: 11),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () async {
                                      await onAddDock(app);
                                      if (ctx.mounted) Navigator.pop(ctx);
                                    },
                                    child: const Text('Dock'),
                                  ),
                                  FilledButton(
                                    onPressed: () async {
                                      await onAddHome(app);
                                      if (ctx.mounted) Navigator.pop(ctx);
                                    },
                                    child: const Text('Home'),
                                  ),
                                ],
                              ),
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

Future<String?> showAppPlacementSheet({
  required BuildContext context,
  required MorphController controller,
  required MorphAppItem app,
}) {
  final p = controller.palette;
  final onHome = controller.homeIds.contains(app.id) ||
      controller.dockIds.contains(app.id);
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: p.panel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                controller.labelFor(app),
                style: TextStyle(
                  color: p.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Open'),
              onTap: () => Navigator.pop(ctx, 'open'),
            ),
            ListTile(
              leading: const Icon(Icons.add_to_home_screen_outlined),
              title: Text(onHome ? 'Already on Home / dock' : 'Add to Home screen'),
              enabled: !onHome,
              onTap: onHome ? null : () => Navigator.pop(ctx, 'home'),
            ),
            ListTile(
              leading: const Icon(Icons.dock_outlined),
              title: const Text('Add to Dock'),
              onTap: () => Navigator.pop(ctx, 'dock'),
            ),
            ListTile(
              leading: Icon(
                controller.starredAppIds.contains(app.id)
                    ? Icons.star
                    : Icons.star_border,
              ),
              title: Text(
                controller.starredAppIds.contains(app.id)
                    ? 'Unstar'
                    : 'Star',
              ),
              onTap: () => Navigator.pop(ctx, 'star'),
            ),
            ListTile(
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(ctx, 'cancel'),
            ),
          ],
        ),
      );
    },
  );
}

class CustomizeTopBar extends StatelessWidget {
  const CustomizeTopBar({
    super.key,
    required this.onEdit,
    required this.onDone,
  });

  final VoidCallback onEdit;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          _Pill(label: 'Edit', onTap: onEdit),
          const Spacer(),
          _Pill(label: 'Done', onTap: onDone),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.38),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
