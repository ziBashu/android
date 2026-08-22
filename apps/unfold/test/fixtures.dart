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
  return buildTestZipEntries({name: payload});
}

Uint8List buildTestZipEntries(Map<String, String> files) {
  final archive = Archive();
  files.forEach((name, payload) {
    final data = utf8.encode(payload);
    archive.addFile(ArchiveFile(name, data.length, data));
  });
  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

void _w16(Uint8List b, int o, int v) {
  b[o] = v & 0xFF;
  b[o + 1] = (v >> 8) & 0xFF;
}

void _w32(Uint8List b, int o, int v) {
  b[o] = v & 0xFF;
  b[o + 1] = (v >> 8) & 0xFF;
  b[o + 2] = (v >> 16) & 0xFF;
  b[o + 3] = (v >> 24) & 0xFF;
}

/// Independent Word 97 (.doc) writer: MS-CFB + FIB + Unicode piece table.
/// Does not call Unfold's DocCodec or OleFile.
Uint8List buildTestDoc(String body) {
  const sector = 512;
  const eoc = 0xFFFFFFFE;
  const fatSect = 0xFFFFFFFD;
  const free = 0xFFFFFFFF;
  const textAt = 2048;
  final units = '$body\r'.codeUnits;
  final wdLen = textAt + units.length * 2;
  final wdSectors = (wdLen + sector - 1) ~/ sector;
  final wdPad = wdSectors * sector;

  // CLX: Pcdt + PlcPcd with one Unicode piece.
  final clx = Uint8List(21);
  clx[0] = 0x02;
  _w32(clx, 1, 16);
  _w32(clx, 5, 0);
  _w32(clx, 9, units.length);
  _w32(clx, 15, textAt);

  final wd = Uint8List(wdPad);
  wd[0] = 0xEC;
  wd[1] = 0xA5;
  wd[2] = 0xC1;
  wd[3] = 0x00;
  _w16(wd, 0x0A, 0x0200);
  _w16(wd, 0x20, 0x000E);
  _w16(wd, 0x3E, 0x0016);
  _w32(wd, 0x4C, units.length);
  _w16(wd, 0x98, 0x005D);
  _w32(wd, 0x1A2, 0);
  _w32(wd, 0x1A6, clx.length);
  for (var i = 0; i < units.length; i++) {
    wd[textAt + i * 2] = units[i] & 0xFF;
    wd[textAt + i * 2 + 1] = (units[i] >> 8) & 0xFF;
  }

  final tablePad = Uint8List(sector);
  tablePad.setRange(0, clx.length, clx);

  // Sectors: 0 FAT, 1 directory, 2.. word, then table.
  final wdStart = 2;
  final tableStart = wdStart + wdSectors;
  final fat = List<int>.filled(sector ~/ 4, free);
  fat[0] = fatSect;
  fat[1] = eoc;
  for (var i = 0; i < wdSectors; i++) {
    fat[wdStart + i] = i == wdSectors - 1 ? eoc : wdStart + i + 1;
  }
  fat[tableStart] = eoc;

  final dir = Uint8List(sector);
  void dirEnt(int index, String name, int type, int start, int size,
      {int child = -1, int right = -1}) {
    final off = index * 128;
    for (var i = 0; i < name.length && i < 31; i++) {
      dir[off + i * 2] = name.codeUnitAt(i) & 0xFF;
      dir[off + i * 2 + 1] = (name.codeUnitAt(i) >> 8) & 0xFF;
    }
    _w16(dir, off + 0x40, (name.length + 1) * 2);
    dir[off + 0x42] = type;
    _w32(dir, off + 0x44, 0xFFFFFFFF);
    _w32(dir, off + 0x48, right);
    _w32(dir, off + 0x4C, child);
    _w32(dir, off + 0x74, start);
    _w32(dir, off + 0x78, size);
  }

  dirEnt(0, 'Root Entry', 5, 0, 0, child: 1);
  dirEnt(1, 'WordDocument', 2, wdStart, wdLen, right: 2);
  dirEnt(2, '1Table', 2, tableStart, clx.length);

  final header = Uint8List(512);
  final sig = [0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1];
  for (var i = 0; i < 8; i++) {
    header[i] = sig[i];
  }
  header[0x18] = 0x3E;
  header[0x1A] = 0x03;
  header[0x1C] = 0xFE;
  header[0x1D] = 0xFF;
  header[0x1E] = 9;
  header[0x20] = 6;
  _w32(header, 0x2C, 1);
  _w32(header, 0x30, 1);
  _w32(header, 0x38, 4096);
  _w32(header, 0x3C, eoc);
  _w32(header, 0x44, eoc);
  _w32(header, 0x4C, 0);
  for (var i = 1; i < 109; i++) {
    _w32(header, 0x4C + i * 4, free);
  }

  final fatBytes = Uint8List(sector);
  for (var i = 0; i < fat.length; i++) {
    _w32(fatBytes, i * 4, fat[i]);
  }

  final out = BytesBuilder();
  out.add(header);
  out.add(fatBytes);
  out.add(dir);
  out.add(wd);
  out.add(tablePad);
  return Uint8List.fromList(out.takeBytes());
}
