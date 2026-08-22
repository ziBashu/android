import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

enum FileKind {
  pdf,
  epub,
  markdown,
  plainText,
  html,
  docx,
  doc,
  image,
  zip,
  unknown,
}

class Capabilities {
  const Capabilities({
    this.view = true,
    this.edit = false,
    this.preview = false,
    this.search = false,
    this.annotate = false,
    this.pageManipulate = false,
    this.export = true,
    this.zoom = false,
    this.rotate = false,
    this.share = true,
    this.browse = false,
    this.extract = false,
  });

  final bool view;
  final bool edit;
  final bool preview;
  final bool search;
  final bool annotate;
  final bool pageManipulate;
  final bool export;
  final bool zoom;
  final bool rotate;
  final bool share;
  final bool browse;
  final bool extract;
}

Capabilities capabilitiesFor(FileKind kind) {
  switch (kind) {
    case FileKind.pdf:
      return const Capabilities(
        search: true,
        annotate: true,
        pageManipulate: true,
        export: true,
      );
    case FileKind.markdown:
      return const Capabilities(edit: true, preview: true, export: true);
    case FileKind.plainText:
      return const Capabilities(edit: true, export: true);
    case FileKind.html:
      return const Capabilities(edit: true, preview: true, export: true);
    case FileKind.epub:
      return const Capabilities(export: true);
    case FileKind.docx:
    case FileKind.doc:
      return const Capabilities(export: true);
    case FileKind.image:
      return const Capabilities(zoom: true, rotate: true, export: true);
    case FileKind.zip:
      return const Capabilities(browse: true, extract: true, export: true);
    case FileKind.unknown:
      return const Capabilities(view: false, export: false, share: false);
  }
}

FileKind detectKind(String path, Uint8List bytes) {
  final ext = p.extension(path).toLowerCase();
  if (bytes.length >= 5 &&
      bytes[0] == 0x25 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x44 &&
      bytes[3] == 0x46) {
    return FileKind.pdf;
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return FileKind.image;
  }
  if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
    return FileKind.image;
  }
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return FileKind.image;
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0xD0 &&
      bytes[1] == 0xCF &&
      bytes[2] == 0x11 &&
      bytes[3] == 0xE0) {
    return FileKind.doc;
  }
  if (bytes.length >= 4 &&
      bytes[0] == 0x50 &&
      bytes[1] == 0x4B &&
      bytes[2] == 0x03 &&
      bytes[3] == 0x04) {
    return _kindFromZip(bytes, ext);
  }
  if (ext == '.md' || ext == '.markdown') return FileKind.markdown;
  if (ext == '.html' || ext == '.htm') return FileKind.html;
  if (ext == '.txt') return FileKind.plainText;
  if (ext == '.pdf') return FileKind.pdf;
  if (ext == '.png' || ext == '.jpg' || ext == '.jpeg' || ext == '.webp') {
    return FileKind.image;
  }
  if (ext == '.docx') return FileKind.docx;
  if (ext == '.doc') return FileKind.doc;
  if (ext == '.epub') return FileKind.epub;
  if (ext == '.zip') return FileKind.zip;
  final sniff = latin1.decode(bytes.sublist(0, bytes.length < 256 ? bytes.length : 256));
  final trimmed = sniff.trimLeft().toLowerCase();
  if (trimmed.startsWith('<!doctype html') || trimmed.startsWith('<html')) {
    return FileKind.html;
  }
  if (ext == '.csv' || ext == '.json') return FileKind.plainText;
  if (_looksLikeText(bytes)) return FileKind.plainText;
  return FileKind.unknown;
}

FileKind _kindFromZip(Uint8List bytes, String ext) {
  try {
    final archive = ZipDecoder().decodeBytes(bytes, verify: false);
    final names = archive.files.map((f) => f.name.replaceAll('\\', '/')).toList();
    if (names.any((n) => n == 'mimetype')) {
      final mime = archive.findFile('mimetype');
      final text = mime == null
          ? ''
          : latin1.decode(mime.content as List<int>? ?? const []);
      if (text.contains('epub')) return FileKind.epub;
    }
    if (names.any((n) => n.endsWith('META-INF/container.xml'))) {
      return FileKind.epub;
    }
    if (names.any((n) => n == 'word/document.xml' || n.endsWith('/word/document.xml'))) {
      return FileKind.docx;
    }
  } catch (_) {
    if (ext == '.epub') return FileKind.epub;
    if (ext == '.docx') return FileKind.docx;
  }
  if (ext == '.epub') return FileKind.epub;
  if (ext == '.docx') return FileKind.docx;
  return FileKind.zip;
}

bool _looksLikeText(Uint8List bytes) {
  if (bytes.isEmpty) return true;
  var odd = 0;
  final n = bytes.length < 2048 ? bytes.length : 2048;
  for (var i = 0; i < n; i++) {
    final b = bytes[i];
    if (b == 0) return false;
    if (b < 7 || (b > 13 && b < 32)) odd++;
  }
  return odd < n / 20;
}

String kindLabel(FileKind kind) {
  switch (kind) {
    case FileKind.pdf:
      return 'PDF';
    case FileKind.epub:
      return 'EPUB';
    case FileKind.markdown:
      return 'Markdown';
    case FileKind.plainText:
      return 'Text';
    case FileKind.html:
      return 'HTML';
    case FileKind.docx:
      return 'DOCX';
    case FileKind.doc:
      return 'DOC';
    case FileKind.image:
      return 'Image';
    case FileKind.zip:
      return 'ZIP';
    case FileKind.unknown:
      return 'Unknown';
  }
}
