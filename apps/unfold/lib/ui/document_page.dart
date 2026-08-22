import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../core/detect.dart';
import '../core/unfold_doc.dart';
import '../native/bridge.dart';
import 'html_view.dart';
import 'tokens.dart';

class DocumentPage extends StatefulWidget {
  const DocumentPage({super.key, required this.path});

  final String path;

  @override
  State<DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  UnfoldDocument? _doc;
  Object? _error;
  final _text = TextEditingController();
  final _search = TextEditingController();
  String _status = '';
  int _page = 0;
  Uint8List? _pagePng;
  bool _preview = false;
  TransformationController? _zoom;

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void dispose() {
    _text.dispose();
    _search.dispose();
    _zoom?.dispose();
    super.dispose();
  }

  void _open() {
    try {
      final doc = UnfoldDocument.open(widget.path);
      _doc = doc;
      _text.text = doc.text;
      _error = null;
      if (doc.kind == FileKind.pdf) _loadPdfPage();
    } catch (e) {
      _error = e;
    }
  }

  Future<void> _loadPdfPage() async {
    final doc = _doc;
    if (doc == null || doc.pdf == null) return;
    final png = await UnfoldNative.renderPdfPage(doc.path, _page, 900);
    if (!mounted) return;
    setState(() => _pagePng = png);
  }

  Future<void> _save() async {
    final doc = _doc;
    if (doc == null) return;
    if (doc.caps.edit) doc.text = _text.text;
    doc.save();
    setState(() => _status = 'Saved.');
  }

  Future<void> _export() async {
    final doc = _doc;
    if (doc == null) return;
    if (doc.caps.edit) doc.text = _text.text;
    final dest = p.join(Directory.systemTemp.path, 'unfold-export-${doc.name}');
    if (doc.kind == FileKind.markdown) {
      final htmlDest = p.setExtension(dest, '.html');
      doc.exportTo(htmlDest);
      setState(() => _status = 'Exported $htmlDest');
      await UnfoldNative.share(htmlDest, mime: 'text/html');
      return;
    }
    doc.exportTo(dest);
    setState(() => _status = 'Exported $dest');
    await UnfoldNative.share(dest, mime: _mime(doc.kind));
  }

  Future<void> _share() async {
    final doc = _doc;
    if (doc == null) return;
    await UnfoldNative.share(doc.path, mime: _mime(doc.kind));
  }

  String _mime(FileKind kind) {
    switch (kind) {
      case FileKind.pdf:
        return 'application/pdf';
      case FileKind.html:
        return 'text/html';
      case FileKind.markdown:
      case FileKind.plainText:
        return 'text/plain';
      case FileKind.image:
        return 'image/png';
      case FileKind.zip:
        return 'application/zip';
      case FileKind.epub:
        return 'application/epub+zip';
      case FileKind.docx:
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case FileKind.doc:
        return 'application/msword';
      case FileKind.unknown:
        return 'application/octet-stream';
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = _doc;
    return Scaffold(
      backgroundColor: UnfoldTokens.paper,
      appBar: AppBar(
        title: Text(p.basename(widget.path)),
        actions: [
          if (doc != null && doc.caps.edit)
            IconButton(tooltip: 'Save', onPressed: _save, icon: const Icon(Icons.save_outlined)),
          if (doc != null && doc.caps.export)
            IconButton(tooltip: 'Export', onPressed: _export, icon: const Icon(Icons.ios_share)),
          if (doc != null && doc.caps.share)
            IconButton(tooltip: 'Share', onPressed: _share, icon: const Icon(Icons.share_outlined)),
        ],
      ),
      body: _error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('$_error')))
          : doc == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    if (_status.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(_status, style: const TextStyle(color: UnfoldTokens.muted)),
                        ),
                      ),
                    Expanded(child: _body(doc)),
                    const SafeArea(
                      top: false,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 8, top: 4),
                        child: Text(
                          'from ziBashu',
                          style: TextStyle(
                            color: UnfoldTokens.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _body(UnfoldDocument doc) {
    switch (doc.kind) {
      case FileKind.pdf:
        return _pdf(doc);
      case FileKind.markdown:
      case FileKind.html:
      case FileKind.plainText:
        return _textDoc(doc);
      case FileKind.epub:
        return _epub(doc);
      case FileKind.docx:
      case FileKind.doc:
        return _plain(doc.text);
      case FileKind.image:
        return _image(doc);
      case FileKind.zip:
        return _zip(doc);
      case FileKind.unknown:
        return const Center(child: Text('Unsupported file.'));
    }
  }

  Widget _plain(String text) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: SelectableText(text, style: const TextStyle(fontSize: 16, height: 1.45)),
    );
  }

  Widget _textDoc(UnfoldDocument doc) {
    return Column(
      children: [
        if (doc.caps.preview)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Edit')),
                ButtonSegment(value: true, label: Text('Preview')),
              ],
              selected: {_preview},
              onSelectionChanged: (s) => setState(() {
                _preview = s.first;
                doc.text = _text.text;
              }),
            ),
          ),
        Expanded(
          child: _preview && doc.caps.preview
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: SimpleHtmlView(html: doc.previewHtml()),
                )
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _text,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: UnfoldTokens.sheet,
                    ),
                    style: const TextStyle(fontSize: 16, height: 1.45),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _pdf(UnfoldDocument doc) {
    final pdf = doc.pdf!;
    final pageText = pdf.pageCount == 0 ? '' : pdf.pageText(_page);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    hintText: 'Search',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Find',
                onPressed: () => setState(() {}),
                icon: const Icon(Icons.search),
              ),
            ],
          ),
        ),
        if (_search.text.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                pdf.search(_search.text).isEmpty
                    ? 'No matches.'
                    : pdf.search(_search.text).map((h) => 'p${h.page + 1}: ${h.snippet}').join('\n'),
              ),
            ),
          ),
        Wrap(
          spacing: 4,
          children: [
            TextButton(
              onPressed: _page > 0
                  ? () {
                      setState(() => _page -= 1);
                      _loadPdfPage();
                    }
                  : null,
              child: const Text('Prev'),
            ),
            Text('Page ${_page + 1} / ${pdf.pageCount}  rot ${pdf.rotationOf(_page)}°'),
            TextButton(
              onPressed: _page + 1 < pdf.pageCount
                  ? () {
                      setState(() => _page += 1);
                      _loadPdfPage();
                    }
                  : null,
              child: const Text('Next'),
            ),
            TextButton(
              onPressed: () {
                pdf.rotatePage(_page, 90);
                pdf.save();
                File(doc.path).writeAsBytesSync(pdf.bytes);
                setState(() => _status = 'Rotated page.');
                _loadPdfPage();
              },
              child: const Text('Rotate'),
            ),
            TextButton(
              onPressed: pdf.pageCount > 1
                  ? () {
                      pdf.deletePage(_page);
                      if (_page >= pdf.pageCount) _page = pdf.pageCount - 1;
                      pdf.save();
                      File(doc.path).writeAsBytesSync(pdf.bytes);
                      setState(() => _status = 'Deleted page.');
                      _loadPdfPage();
                    }
                  : null,
              child: const Text('Delete page'),
            ),
            TextButton(
              onPressed: _page > 0
                  ? () {
                      pdf.movePage(_page, _page - 1);
                      _page -= 1;
                      pdf.save();
                      File(doc.path).writeAsBytesSync(pdf.bytes);
                      setState(() {});
                    }
                  : null,
              child: const Text('Move up'),
            ),
            TextButton(
              onPressed: () async {
                final note = await _ask('Annotation', 'Note text');
                if (note == null || note.trim().isEmpty) return;
                pdf.addNote(_page, note.trim());
                pdf.save();
                File(doc.path).writeAsBytesSync(pdf.bytes);
                setState(() => _status = 'Note added.');
              },
              child: const Text('Add note'),
            ),
          ],
        ),
        if (pdf.notesOn(_page).isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Notes: ${pdf.notesOn(_page).join(' · ')}'),
            ),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              width: double.infinity,
              color: UnfoldTokens.sheet,
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.all(16),
              child: _pagePng != null
                  ? InteractiveViewer(child: Image.memory(_pagePng!))
                  : SingleChildScrollView(child: SelectableText(pageText)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _epub(UnfoldDocument doc) {
    if (doc.chapters.isEmpty) return _plain(doc.text);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: doc.chapters.length,
      itemBuilder: (context, i) {
        final ch = doc.chapters[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ch.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              SimpleHtmlView(html: ch.html),
            ],
          ),
        );
      },
    );
  }

  Widget _image(UnfoldDocument doc) {
    _zoom ??= TransformationController();
    final bytes = doc.image == null ? null : doc.pngBytes();
    return Column(
      children: [
        Wrap(
          children: [
            TextButton(
              onPressed: () {
                doc.rotateImage90();
                setState(() => _status = '${doc.imageWidth}×${doc.imageHeight}');
              },
              child: const Text('Rotate 90°'),
            ),
            Text('${doc.imageWidth}×${doc.imageHeight}'),
          ],
        ),
        Expanded(
          child: InteractiveViewer(
            transformationController: _zoom,
            minScale: 0.4,
            maxScale: 8,
            child: bytes == null ? const SizedBox.shrink() : Image.memory(bytes),
          ),
        ),
      ],
    );
  }

  Widget _zip(UnfoldDocument doc) {
    final names = doc.zipNames;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              FilledButton(
                onPressed: () {
                  final dest = p.join(Directory.systemTemp.path, 'unfold-${doc.name}-extract');
                  doc.extractZipTo(dest);
                  setState(() => _status = 'Extracted to $dest');
                },
                child: const Text('Extract all'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              for (final name in names)
                ListTile(
                  title: Text(name),
                  trailing: TextButton(
                    onPressed: () async {
                      final destDir = p.join(Directory.systemTemp.path, 'unfold-share');
                      doc.extractZipTo(destDir, only: name);
                      await UnfoldNative.share(p.join(destDir, name));
                    },
                    child: const Text('Share'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<String?> _ask(String title, String hint) async {
    final c = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, decoration: InputDecoration(hintText: hint)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Add')),
        ],
      ),
    );
    c.dispose();
    return result;
  }
}
