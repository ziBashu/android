import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zibashu_ui/zibashu_ui.dart';

import '../../core/app_catalog.dart';
import '../../core/image_customize.dart';
import '../../core/models.dart';
import '../../core/morph_controller.dart';
import '../../widgets/morph_background.dart';

class AppsCustomizeScreen extends StatefulWidget {
  const AppsCustomizeScreen({super.key, required this.controller});

  final MorphController controller;

  @override
  State<AppsCustomizeScreen> createState() => _AppsCustomizeScreenState();
}

class _AppsCustomizeScreenState extends State<AppsCustomizeScreen> {
  final AppCatalog _catalog = AppCatalog();
  bool _ready = false;

  MorphController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    _catalog.refresh().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = c.palette;
    final apps = _catalog.apps.map(c.displayApp).toList();
    return MorphBackground(
      wallpaperId: c.wallpaperId,
      palette: p,
      customPortraitBytes: c.customWallpaperPortraitBytes,
      customLandscapeBytes: c.customWallpaperLandscapeBytes,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('All apps'),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 12),
              child: FromZiBashuBadge(compact: true, openWebsite: false),
            ),
          ],
        ),
        body: !_ready
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: apps.length,
                itemBuilder: (context, i) {
                  final app = apps[i];
                  final hidden = c.hiddenIds.contains(app.id) ||
                      (app.packageName != null &&
                          c.hiddenIds.contains(app.packageName));
                  final hideName = c.hideNameFor(app.id, packageName: app.packageName);
                  final scale = c.sizeScaleFor(app.id, packageName: app.packageName);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: app.color,
                      child: Icon(app.icon, color: Colors.white, size: 18),
                    ),
                    title: Text(
                      c.labelFor(app),
                      style: TextStyle(color: p.ink),
                    ),
                    subtitle: Text(
                      [
                        if (hidden) 'Hidden',
                        if (hideName) 'Name hidden',
                        'Size ${scale.toStringAsFixed(2)}',
                        app.packageName ?? app.id,
                      ].join(' · '),
                      style: TextStyle(color: p.muted, fontSize: 11),
                    ),
                    onTap: () => _edit(app),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _edit(MorphAppItem raw) async {
    final p = c.palette;
    final nameCtrl = TextEditingController(text: c.labelFor(raw));
    var hideName = c.hideNameFor(raw.id, packageName: raw.packageName);
    var scale = c.sizeScaleFor(raw.id, packageName: raw.packageName);
    var hidden = c.hiddenIds.contains(raw.id);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.panel,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: StatefulBuilder(
            builder: (ctx, setLocal) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      raw.label,
                      style: TextStyle(
                        color: p.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: p.ink),
                      decoration: InputDecoration(
                        labelText: 'Display name',
                        labelStyle: TextStyle(color: p.muted),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Hide name', style: TextStyle(color: p.ink)),
                      value: hideName,
                      onChanged: (v) => setLocal(() => hideName = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Hidden from library',
                          style: TextStyle(color: p.ink)),
                      value: hidden,
                      onChanged: (v) => setLocal(() => hidden = v),
                    ),
                    Text('Icon size', style: TextStyle(color: p.muted, fontSize: 12)),
                    Slider(
                      value: scale,
                      min: 0.7,
                      max: 1.6,
                      onChanged: (v) => setLocal(() => scale = v),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilledButton(
                          onPressed: () async {
                            await c.renameApp(raw.id, nameCtrl.text);
                            await c.setAppHideName(raw.id, hideName);
                            await c.setAppSizeScale(raw.id, scale);
                            if (hidden) {
                              await c.hideApp(raw.id);
                            } else {
                              await c.unhideApp(raw.id);
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) setState(() {});
                          },
                          child: const Text('Save'),
                        ),
                        TextButton(
                          onPressed: () async {
                            try {
                              final picker = ImagePicker();
                              final file = await picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 1024,
                                maxHeight: 1024,
                              );
                              if (file == null) return;
                              final bytes = await file.readAsBytes();
                              final cropped = ImageCustomize.cropIconSquare(
                                bytes,
                                maxSize: 192,
                              );
                              if (cropped != null) {
                                await c.setAppIconOverride(raw.id, cropped);
                              }
                            } catch (_) {}
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) setState(() {});
                          },
                          child: const Text('Change icon'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
    nameCtrl.dispose();
  }
}
