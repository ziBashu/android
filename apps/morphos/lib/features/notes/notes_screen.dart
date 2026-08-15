import 'package:flutter/material.dart';

import '../../core/morph_controller.dart';
import '../../core/morph_palette.dart';
import '../../core/notes_store.dart';
import '../../widgets/morph_background.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({
    super.key,
    required this.controller,
    required this.store,
  });

  final MorphController controller;
  final NotesStore store;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  @override
  void initState() {
    super.initState();
    widget.store.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _openEditor({MorphNote? note}) async {
    final title = TextEditingController(text: note?.title ?? '');
    final body = TextEditingController(text: note?.body ?? '');
    final p = widget.controller.palette;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (ctx) => Scaffold(
          backgroundColor: p.scaffoldTint,
          appBar: AppBar(
            title: Text(note == null ? 'New note' : 'Edit note'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save'),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: title,
                  style: TextStyle(color: p.ink),
                  decoration: const InputDecoration(hintText: 'Title'),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TextField(
                    controller: body,
                    style: TextStyle(color: p.ink),
                    maxLines: null,
                    expands: true,
                    decoration: const InputDecoration(
                      hintText: 'Write a note…',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (saved != true) return;
    if (note == null) {
      await widget.store.create(title: title.text, body: body.text);
    } else {
      await widget.store.edit(note.id, title: title.text, body: body.text);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final p = c.palette;
    final notes = widget.store.notes;
    return MorphBackground(
      wallpaperId: c.wallpaperId,
      palette: p,
      customPortraitBytes: c.customWallpaperPortraitBytes,
      customLandscapeBytes: c.customWallpaperLandscapeBytes,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Notes'),
          backgroundColor: Colors.transparent,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openEditor(),
          child: const Icon(Icons.add),
        ),
        body: notes.isEmpty
            ? ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                children: [
                  _pathCard(p),
                  const SizedBox(height: 24),
                  Text(
                    'No notes yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.muted),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                itemCount: notes.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) return _pathCard(p);
                  final n = notes[i - 1];
                  return Dismissible(
                    key: ValueKey(n.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: const Color(0xFFE53935),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) async {
                      await widget.store.delete(n.id);
                      if (mounted) setState(() {});
                    },
                    child: ListTile(
                      title: Text(n.listLine, style: TextStyle(color: p.ink)),
                      subtitle: n.title.trim().isEmpty
                          ? null
                          : Text(
                              n.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: p.muted, fontSize: 12),
                            ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await widget.store.delete(n.id);
                          if (mounted) setState(() {});
                        },
                      ),
                      onTap: () => _openEditor(note: n),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _pathCard(MorphPalette p) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Where notes are written',
            style: TextStyle(
              color: p.ink,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.store.pathHelp,
            style: TextStyle(color: p.muted, fontSize: 12, height: 1.35),
          ),
        ],
      ),
    );
  }
}
