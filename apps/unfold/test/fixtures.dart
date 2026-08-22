import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;

/// Independent PDF writer for tests. Not the product parser.
Uint8List buildTestPdf(List<String> pages) {
  final out = BytesBuilder();
  void w(String s) => out.add(utf8.encode(s));
  w('%PDF-1.4\n%\xE2\xE3\xCF\xD3\n');
  final offsets = <int, int>{};
  void obj(int id, String body) {
    offsets[id] = out.length;
    w('$id 0 obj\n$body\nendobj\n');
  }

  obj(3, '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>');
  final pageIds = <int>[];
  for (var i = 0; i < pages.length; i++) {
    final pageId = 4 + i * 2;
    final contentId = 5 + i * 2;
    pageIds.add(pageId);
    final escaped = pages[i]
        .replaceAll('\\', r'\\')
        .replaceAll('(', r'\(')
        .replaceAll(')', r'\)');
    final content = 'BT /F1 18 Tf 72 720 Td ($escaped) Tj ET';
    final data = utf8.encode('$content\n');
    obj(contentId, '<< /Length ${data.length} >>\nstream\n$content\nendstream');
    obj(
      pageId,
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] '
      '/Resources << /Font << /F1 3 0 R >> >> /Contents $contentId 0 R >>',
    );
  }
  obj(
    2,
    '<< /Type /Pages /Count ${pageIds.length} /Kids [${pageIds.map((id) => '$id 0 R').join(' ')}] >>',
  );
  obj(1, '<< /Type /Catalog /Pages 2 0 R >>');
  final xrefAt = out.length;
  final size = 4 + pages.length * 2;
  w('xref\n0 $size\n');
  w('0000000000 65535 f \n');
  for (var i = 1; i < size; i++) {
    w('${offsets[i]!.toString().padLeft(10, '0')} 00000 n \n');
  }
  w('trailer\n<< /Size $size /Root 1 0 R >>\nstartxref\n$xrefAt\n%%EOF\n');
  return Uint8List.fromList(out.takeBytes());
}

Uint8List buildTestDocx(String body) {
  final archive = Archive();
  void add(String name, String xml) {
    final data = utf8.encode(xml);
    archive.addFile(ArchiveFile(name, data.length, data));
  }

  add(
    '[Content_Types].xml',
    '''<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''',
  );
  add(
    '_rels/.rels',
    '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''',
  );
  add(
    'word/document.xml',
    '''<?xml version="1.0" encoding="UTF-8"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p><w:r><w:t>$body</w:t></w:r></w:p>
  </w:body>
</w:document>''',
  );
  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

Uint8List buildTestEpub(String heading, String body) {
  final archive = Archive();
  void add(String name, String text, {bool store = false}) {
    final data = utf8.encode(text);
    final f = ArchiveFile(name, data.length, data);
    if (store) f.compress = false;
    archive.addFile(f);
  }

  add('mimetype', 'application/epub+zip', store: true);
  add(
    'META-INF/container.xml',
    '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''',
  );
  add(
    'OEBPS/content.opf',
    '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" unique-identifier="id" version="3.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>Unfold EPUB</dc:title>
    <dc:identifier id="id">unfold-epub</dc:identifier>
    <dc:language>en</dc:language>
  </metadata>
  <manifest>
    <item id="ch1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="ch1"/>
  </spine>
</package>''',
  );
  add(
    'OEBPS/ch1.xhtml',
    '''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head><title>$heading</title></head>
  <body><h1>$heading</h1><p>$body</p></body>
</html>''',
  );
  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

Uint8List buildTestPng() {
  final image = img.Image(width: 20, height: 10);
  img.fill(image, color: img.ColorRgb8(200, 20, 20));
  image.setPixelRgba(0, 0, 0, 255, 0, 255);
  return Uint8List.fromList(img.encodePng(image));
}

Uint8List buildTestZip(String name, String payload) {
  final archive = Archive();
  final data = utf8.encode(payload);
  archive.addFile(ArchiveFile(name, data.length, data));
  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}
