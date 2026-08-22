import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:image/image.dart' as img;
import 'package:markdown/markdown.dart' as md;
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import 'detect.dart';
import 'ole.dart';
import 'pdf_kit.dart';

/// Opened local file. Format-specific work lives here so tests can drive
/// real files without a device.
class UnfoldDocument {
  UnfoldDocument._({
    required this.path,
    required this.kind,
    required this.bytes,
  }) : caps = capabilitiesFor(kind);

  final String path;
  final FileKind kind;
  final Capabilities caps;
  Uint8List bytes;

  String text = '';
  UnfoldPdf? pdf;
  img.Image? image;
  Archive? zip;
  List<EpubChapter> chapters = [];

  String get name => p.basename(path);

  int get imageWidth => image?.width ?? 0;
  int get imageHeight => image?.height ?? 0;

  static UnfoldDocument open(String path) {
    final file = File(path);
    final bytes = file.readAsBytesSync();
    final kind = detectKind(path, bytes);
    if (kind == FileKind.unknown) {
      throw FormatException('Unfold cannot open this file type: ${p.basename(path)}');
    }
    final doc = UnfoldDocument._(path: path, kind: kind, bytes: bytes);
    doc._load();
    return doc;
  }

  void _load() {
    switch (kind) {
      case FileKind.pdf:
        pdf = UnfoldPdf.parse(bytes);
        text = pdf!.allText;
      case FileKind.markdown:
      case FileKind.plainText:
      case FileKind.html:
        text = utf8.decode(bytes, allowMalformed: true);
      case FileKind.epub:
        _loadEpub();
      case FileKind.docx:
        text = extractDocx(bytes);
      case FileKind.doc:
        text = DocCodec.decode(bytes);
      case FileKind.image:
        image = img.decodeImage(bytes);
        if (image == null) {
          throw FormatException('Image could not be decoded');
        }
      case FileKind.zip:
        zip = ZipDecoder().decodeBytes(bytes);
      case FileKind.unknown:
        break;
    }
  }

  String previewHtml() {
    switch (kind) {
      case FileKind.markdown:
        return md.markdownToHtml(text);
      case FileKind.html:
        return text;
      default:
        return '<pre>${_escape(text)}</pre>';
    }
  }

  String plainFromHtml() {
    final parsed = html_parser.parse(kind == FileKind.html ? text : previewHtml());
    return (parsed.body?.text ?? parsed.documentElement?.text ?? '').trim();
  }

  List<PdfHit> search(String query) {
    if (pdf == null) {
      final idx = text.toLowerCase().indexOf(query.toLowerCase());
      if (idx < 0) return [];
      return [PdfHit(page: 0, snippet: text.substring(idx, (idx + 80).clamp(0, text.length)))];
    }
    return pdf!.search(query);
  }

  void addPdfNote(int page, String note) {
    pdf!.addNote(page, note);
  }

  void rotatePdfPage(int page, int degrees) {
    pdf!.rotatePage(page, degrees);
  }

  void deletePdfPage(int page) {
    pdf!.deletePage(page);
  }

  void movePdfPage(int from, int to) {
    pdf!.movePage(from, to);
  }

  void rotateImage90() {
    if (image == null) throw StateError('not an image');
    image = img.copyRotate(image!, angle: 90);
  }

  List<String> get zipNames {
    final z = zip;
    if (z == null) return const [];
    return z.files.where((f) => f.isFile).map((f) => f.name).toList();
  }

  Uint8List? zipBytes(String name) {
    final file = zip?.findFile(name);
    if (file == null) return null;
    final content = file.content;
    if (content is Uint8List) return content;
    if (content is List<int>) return Uint8List.fromList(content);
    return null;
  }

  void extractZipTo(String destDir, {String? only}) {
    final z = zip;
    if (z == null) throw StateError('not a zip');
    final root = Directory(destDir)..createSync(recursive: true);
    final rootPath = p.normalize(root.absolute.path);
    for (final f in z.files) {
      if (!f.isFile) continue;
      if (only != null && f.name != only) continue;
      final destPath = safeZipEntryPath(rootPath, f.name);
      if (destPath == null) {
        continue;
      }
      final dest = File(destPath);
      dest.parent.createSync(recursive: true);
      final content = f.content;
      final data = content is Uint8List
          ? content
          : Uint8List.fromList(content as List<int>);
      dest.writeAsBytesSync(data);
    }
  }

  /// Returns a path under [rootPath] for [entryName], or null if the name
  /// would escape the destination (zip-slip).
  static String? safeZipEntryPath(String rootPath, String entryName) {
    final cleaned = entryName.replaceAll('\\', '/');
    if (cleaned.isEmpty ||
        cleaned.startsWith('/') ||
        cleaned.contains(':') ||
        p.isAbsolute(cleaned)) {
      return null;
    }
    final dest = p.normalize(p.join(rootPath, cleaned));
    final root = p.normalize(rootPath);
    if (dest == root) return dest;
    final prefix = root.endsWith(p.separator) ? root : '$root${p.separator}';
    if (!dest.startsWith(prefix)) return null;
    return dest;
  }

  void save() {
    File(path).writeAsBytesSync(_exportBytes(path));
    bytes = File(path).readAsBytesSync();
  }

  void exportTo(String dest) {
    File(dest).parent.createSync(recursive: true);
    File(dest).writeAsBytesSync(_exportBytes(dest));
  }

  Uint8List pngBytes() {
    if (image == null) throw StateError('not an image');
    return Uint8List.fromList(img.encodePng(image!));
  }

  Uint8List _exportBytes(String dest) {
    final ext = p.extension(dest).toLowerCase();
    switch (kind) {
      case FileKind.pdf:
        return pdf!.save();
      case FileKind.image:
        return Uint8List.fromList(img.encodePng(image!));
      case FileKind.markdown:
        if (ext == '.html' || ext == '.htm') {
          return Uint8List.fromList(utf8.encode(previewHtml()));
        }
        return Uint8List.fromList(utf8.encode(text));
      case FileKind.plainText:
      case FileKind.html:
        return Uint8List.fromList(utf8.encode(text));
      case FileKind.epub:
      case FileKind.docx:
      case FileKind.doc:
        if (ext == '.txt' || ext == '.md' || ext == '.html') {
          final body = ext == '.html' ? '<pre>${_escape(text)}</pre>' : text;
          return Uint8List.fromList(utf8.encode(body));
        }
        return bytes;
      case FileKind.zip:
        return bytes;
      case FileKind.unknown:
        return bytes;
    }
  }

  void _loadEpub() {
    final archive = ZipDecoder().decodeBytes(bytes);
    zip = archive;
    String? opfPath;
    final container = archive.findFile('META-INF/container.xml');
    if (container != null) {
      final xml = XmlDocument.parse(
        utf8.decode(container.content as List<int>, allowMalformed: true),
      );
      for (final e in xml.findAllElements('rootfile')) {
        opfPath = e.getAttribute('full-path');
        break;
      }
    }
    opfPath ??= archive.files
        .map((f) => f.name)
        .firstWhere((n) => n.endsWith('.opf'), orElse: () => '');
    if (opfPath.isEmpty) {
      text = archive.files
          .where((f) => f.isFile && (f.name.endsWith('.xhtml') || f.name.endsWith('.html')))
          .map((f) => utf8.decode(f.content as List<int>, allowMalformed: true))
          .join('\n');
      return;
    }
    final opfFile = archive.findFile(opfPath);
    if (opfFile == null) {
      throw FormatException('EPUB package missing');
    }
    final opf = XmlDocument.parse(
      utf8.decode(opfFile.content as List<int>, allowMalformed: true),
    );
    final manifest = <String, String>{};
    for (final item in opf.findAllElements('item')) {
      final id = item.getAttribute('id');
      final href = item.getAttribute('href');
      if (id != null && href != null) manifest[id] = href;
    }
    final base = p.dirname(opfPath);
    final chs = <EpubChapter>[];
    final buf = StringBuffer();
    for (final ref in opf.findAllElements('itemref')) {
      final idref = ref.getAttribute('idref');
      if (idref == null) continue;
      final href = manifest[idref];
      if (href == null) continue;
      final pathIn = p.posix.normalize(base == '.' ? href : '$base/$href');
      ArchiveFile? file = archive.findFile(pathIn);
      file ??= archive.files.cast<ArchiveFile?>().firstWhere(
            (f) => f != null && f.name.replaceAll('\\', '/') == pathIn,
            orElse: () => null,
          );
      if (file == null) continue;
      final html = utf8.decode(file.content as List<int>, allowMalformed: true);
      final parsed = html_parser.parse(html);
      final title = parsed.querySelector('h1, h2, title')?.text.trim() ?? p.basename(href);
      final body = (parsed.body?.text ?? parsed.documentElement?.text ?? '').trim();
      chs.add(EpubChapter(title: title, html: html, text: body));
      buf.writeln(body);
    }
    chapters = chs;
    text = buf.toString();
  }
}

class EpubChapter {
  EpubChapter({required this.title, required this.html, required this.text});
  final String title;
  final String html;
  final String text;
}

String extractDocx(Uint8List bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final file = archive.findFile('word/document.xml');
  if (file == null) {
    throw FormatException('DOCX is missing word/document.xml');
  }
  final xml = XmlDocument.parse(
    utf8.decode(file.content as List<int>, allowMalformed: true),
  );
  final buf = StringBuffer();
  for (final pEl in xml.descendants.whereType<XmlElement>().where((e) => e.name.local == 'p')) {
    final line = pEl.descendants
        .whereType<XmlElement>()
        .where((e) => e.name.local == 't')
        .map((e) => e.innerText)
        .join();
    buf.writeln(line);
  }
  return buf.toString();
}

String _escape(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');
