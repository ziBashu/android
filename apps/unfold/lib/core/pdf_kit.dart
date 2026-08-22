import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Conservative PDF 1.4 toolkit used by Unfold: parse, extract text, search,
/// annotate, rotate/delete/reorder pages, and write an incremental update.
class UnfoldPdf {
  UnfoldPdf._(this.bytes);

  Uint8List bytes;
  final Map<int, _Obj> _objs = {};
  final Set<int> _dirty = {};
  int _rootId = 1;
  int _pagesId = 2;
  int _size = 0;
  int _startXref = 0;
  int _nextId = 1;
  List<int> pageIds = [];

  static UnfoldPdf parse(Uint8List data) {
    final doc = UnfoldPdf._(Uint8List.fromList(data));
    doc._load();
    return doc;
  }

  int get pageCount => pageIds.length;

  int rotationOf(int page) {
    final dict = _pageDict(page);
    final r = dict['Rotate'];
    if (r is PdfNum) return r.asInt % 360;
    return 0;
  }

  String pageText(int page) {
    final dict = _pageDict(page);
    final contents = dict['Contents'];
    final buf = StringBuffer();
    for (final stream in _contentStreams(contents)) {
      buf.write(_extractText(stream));
      buf.write('\n');
    }
    return buf.toString();
  }

  String get allText {
    final buf = StringBuffer();
    for (var i = 0; i < pageCount; i++) {
      buf.writeln(pageText(i));
    }
    return buf.toString();
  }

  List<String> notesOn(int page) {
    final dict = _pageDict(page);
    final annots = dict['Annots'];
    final out = <String>[];
    for (final item in _asList(annots)) {
      final d = item is PdfRef ? _asDict(_resolve(item)) : (item is PdfDict ? item : null);
      if (d == null) continue;
      final c = d['Contents'];
      if (c is PdfStr) out.add(c.text);
    }
    return out;
  }

  List<String> get allNotes {
    final out = <String>[];
    for (var i = 0; i < pageCount; i++) {
      out.addAll(notesOn(i));
    }
    return out;
  }

  List<PdfHit> search(String query) {
    final q = query.trim();
    if (q.isEmpty) return [];
    final lower = q.toLowerCase();
    final hits = <PdfHit>[];
    for (var i = 0; i < pageCount; i++) {
      final text = pageText(i);
      final idx = text.toLowerCase().indexOf(lower);
      if (idx >= 0) {
        final start = max(0, idx - 24);
        final end = min(text.length, idx + q.length + 24);
        hits.add(PdfHit(page: i, snippet: text.substring(start, end).trim()));
      }
    }
    return hits;
  }

  void addNote(int page, String note) {
    final dict = _pageDict(page);
    final id = _nextId++;
    _size = max(_size, _nextId);
    final annot = PdfDict({
      'Type': PdfName('Annot'),
      'Subtype': PdfName('Text'),
      'Contents': PdfStr.fromText(note),
      'Rect': PdfArr([
        PdfNum(72),
        PdfNum(740),
        PdfNum(160),
        PdfNum(780),
      ]),
      'Name': PdfName('Comment'),
      'F': PdfNum(4),
    });
    _objs[id] = _Obj(id, 0, annot);
    _dirty.add(id);
    final existing = _asList(dict['Annots']);
    final refs = <PdfVal>[
      ...existing.map((e) => e is PdfRef ? e : e),
      PdfRef(id, 0),
    ];
    dict.map['Annots'] = PdfArr(refs);
    _dirty.add(pageIds[page]);
  }

  void rotatePage(int page, int degrees) {
    final dict = _pageDict(page);
    final next = (rotationOf(page) + degrees) % 360;
    dict.map['Rotate'] = PdfNum(next.toDouble());
    _dirty.add(pageIds[page]);
  }

  void deletePage(int page) {
    if (pageCount <= 1) {
      throw StateError('Cannot delete the last page.');
    }
    pageIds.removeAt(page);
    _rewritePageTree();
  }

  void movePage(int from, int to) {
    if (from == to) return;
    if (from < 0 || from >= pageCount || to < 0 || to >= pageCount) {
      throw RangeError('page index');
    }
    final id = pageIds.removeAt(from);
    pageIds.insert(to, id);
    _rewritePageTree();
  }

  Uint8List save() {
    if (_dirty.isEmpty) return bytes;
    final out = BytesBuilder();
    out.add(bytes);
    if (bytes.isEmpty || bytes.last != 0x0A) out.add([0x0A]);
    final offsets = <int, int>{};
    final dirtyIds = _dirty.toList()..sort();
    for (final id in dirtyIds) {
      final obj = _objs[id];
      if (obj == null) continue;
      offsets[id] = out.length;
      out.add(utf8.encode('$id ${obj.gen} obj\n${obj.value.toPdf()}\nendobj\n'));
    }
    final xrefAt = out.length;
    final buf = StringBuffer();
    buf.writeln('xref');
    for (final id in dirtyIds) {
      buf.writeln('$id 1');
      final off = offsets[id] ?? 0;
      buf.writeln('${off.toString().padLeft(10, '0')} 00000 n ');
    }
    buf.writeln('trailer');
    buf.writeln(
      '<< /Size $_size /Root $_rootId 0 R /Prev $_startXref >>',
    );
    buf.writeln('startxref');
    buf.writeln('$xrefAt');
    buf.writeln('%%EOF');
    out.add(utf8.encode(buf.toString()));
    bytes = Uint8List.fromList(out.takeBytes());
    _startXref = xrefAt;
    _dirty.clear();
    return bytes;
  }

  PdfDict _pageDict(int page) {
    if (page < 0 || page >= pageIds.length) {
      throw RangeError('page $page');
    }
    final v = _objs[pageIds[page]]?.value;
    if (v is! PdfDict) throw StateError('page is not a dictionary');
    return v;
  }

  void _rewritePageTree() {
    final pages = _asDict(_objs[_pagesId]?.value);
    if (pages == null) throw StateError('missing pages tree');
    pages.map['Kids'] = PdfArr(pageIds.map((id) => PdfRef(id, 0)).toList());
    pages.map['Count'] = PdfNum(pageIds.length.toDouble());
    pages.map['Type'] = PdfName('Pages');
    _dirty.add(_pagesId);
    for (final id in pageIds) {
      final d = _asDict(_objs[id]?.value);
      if (d != null) {
        d.map['Parent'] = PdfRef(_pagesId, 0);
        _dirty.add(id);
      }
    }
  }

  List<Uint8List> _contentStreams(PdfVal? contents) {
    final out = <Uint8List>[];
    if (contents == null) return out;
    if (contents is PdfArr) {
      for (final item in contents.items) {
        out.addAll(_contentStreams(item));
      }
      return out;
    }
    final resolved = contents is PdfRef ? _resolve(contents) : contents;
    if (resolved is PdfStream) {
      out.add(_decodeStream(resolved));
    } else if (resolved is PdfStr) {
      out.add(resolved.bytes);
    }
    return out;
  }

  PdfVal? _resolve(PdfRef ref) => _objs[ref.id]?.value;

  void _load() {
    _readXrefChain();
    if (_objs.isEmpty) _scanObjects();
    final catalog = _asDict(_objs[_rootId]?.value);
    if (catalog == null) {
      _scanObjects();
    }
    final cat = _asDict(_objs[_rootId]?.value);
    if (cat == null) throw FormatException('PDF catalog missing');
    final pagesRef = cat['Pages'];
    if (pagesRef is PdfRef) {
      _pagesId = pagesRef.id;
    }
    pageIds = _collectPages(_pagesId);
    _nextId = max(_size, (_objs.keys.isEmpty ? 1 : (_objs.keys.reduce(max) + 1)));
    _size = max(_size, _nextId);
  }

  List<int> _collectPages(int nodeId) {
    final v = _objs[nodeId]?.value;
    final dict = _asDict(v);
    if (dict == null) return [];
    final type = dict['Type'];
    final typeName = type is PdfName ? type.name : '';
    if (typeName == 'Page') return [nodeId];
    final kids = dict['Kids'];
    final out = <int>[];
    for (final item in _asList(kids)) {
      if (item is PdfRef) out.addAll(_collectPages(item.id));
    }
    return out;
  }

  void _readXrefChain() {
    final tailFrom = max(0, bytes.length - 8192);
    final tail = latin1.decode(bytes.sublist(tailFrom));
    final idx = tail.lastIndexOf('startxref');
    if (idx < 0) return;
    final m = RegExp(r'startxref\s+(\d+)').firstMatch(tail.substring(idx));
    if (m == null) return;
    var offset = int.parse(m.group(1)!);
    _startXref = offset;
    final seen = <int>{};
    var guard = 0;
    while (guard++ < 32) {
      if (offset < 0 || offset >= bytes.length) break;
      final cur = _Cursor(bytes, offset);
      cur.skip();
      if (cur.looking('xref')) {
        cur.takeWord();
        while (true) {
          cur.skip();
          if (cur.looking('trailer')) break;
          if (cur.eof) break;
          final first = cur.readInt();
          final count = cur.readInt();
          for (var i = 0; i < count; i++) {
            cur.skip();
            final off = cur.readInt();
            final gen = cur.readInt();
            cur.skip();
            final flag = cur.readWord();
            final id = first + i;
            if (flag == 'n' && !seen.contains(id) && off > 0) {
              seen.add(id);
              _readObjAt(off, id, gen);
            } else if (flag == 'n') {
              cur.skip();
            }
          }
        }
        cur.skip();
        if (!cur.looking('trailer')) break;
        cur.takeWord();
        final trailer = cur.parseVal();
        if (trailer is PdfDict) {
          final size = trailer['Size'];
          if (size is PdfNum) _size = max(_size, size.asInt);
          final root = trailer['Root'];
          if (root is PdfRef) _rootId = root.id;
          final prev = trailer['Prev'];
          if (prev is PdfNum) {
            offset = prev.asInt;
            continue;
          }
        }
        break;
      } else {
        break;
      }
    }
  }

  void _readObjAt(int offset, int id, int gen) {
    try {
      final cur = _Cursor(bytes, offset);
      final obj = cur.parseIndirect();
      _objs[id] = obj;
    } catch (_) {
      // Keep going; scan fallback may recover.
    }
  }

  void _scanObjects() {
    final cur = _Cursor(bytes, 0);
    while (!cur.eof) {
      cur.skip();
      if (cur.eof) break;
      final start = cur.p;
      if (cur.isDigit) {
        try {
          final obj = cur.parseIndirect();
          _objs[obj.id] = obj;
          continue;
        } catch (_) {
          cur.p = start + 1;
          continue;
        }
      }
      cur.p++;
    }
    if (_size == 0 && _objs.isNotEmpty) {
      _size = _objs.keys.reduce(max) + 1;
    }
  }
}

class PdfHit {
  PdfHit({required this.page, required this.snippet});
  final int page;
  final String snippet;
}

abstract class PdfVal {
  String toPdf();
}

class PdfNum extends PdfVal {
  PdfNum(this.value);
  final double value;
  int get asInt => value.round();
  @override
  String toPdf() => value == asInt.toDouble() ? '$asInt' : '$value';
}

class PdfName extends PdfVal {
  PdfName(this.name);
  final String name;
  @override
  String toPdf() => '/$name';
}

class PdfStr extends PdfVal {
  PdfStr(this.bytes, {this.hex = false});
  factory PdfStr.fromText(String text) {
    final latin = latin1.encode(text);
    final ok = latin.every((b) => b >= 32 && b < 127);
    if (ok) return PdfStr(Uint8List.fromList(latin));
    final out = BytesBuilder();
    out.add([0xFE, 0xFF]);
    for (final u in text.codeUnits) {
      out.add([(u >> 8) & 0xFF, u & 0xFF]);
    }
    return PdfStr(Uint8List.fromList(out.takeBytes()), hex: true);
  }
  final Uint8List bytes;
  final bool hex;
  String get text {
    if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
      final cu = <int>[];
      for (var i = 2; i + 1 < bytes.length; i += 2) {
        cu.add((bytes[i] << 8) | bytes[i + 1]);
      }
      return String.fromCharCodes(cu);
    }
    return latin1.decode(bytes);
  }

  @override
  String toPdf() {
    if (hex) {
      final hexStr = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      return '<$hexStr>';
    }
    final buf = StringBuffer('(');
    for (final b in bytes) {
      switch (b) {
        case 0x0A:
          buf.write('\\n');
        case 0x0D:
          buf.write('\\r');
        case 0x28:
          buf.write('\\(');
        case 0x29:
          buf.write('\\)');
        case 0x5C:
          buf.write('\\\\');
        default:
          if (b < 32 || b > 126) {
            buf.write('\\${b.toRadixString(8).padLeft(3, '0')}');
          } else {
            buf.writeCharCode(b);
          }
      }
    }
    buf.write(')');
    return buf.toString();
  }
}

class PdfArr extends PdfVal {
  PdfArr(this.items);
  final List<PdfVal> items;
  @override
  String toPdf() => '[${items.map((e) => e.toPdf()).join(' ')}]';
}

class PdfDict extends PdfVal {
  PdfDict(this.map);
  final Map<String, PdfVal> map;
  PdfVal? operator [](String key) => map[key];
  @override
  String toPdf() {
    final buf = StringBuffer('<< ');
    map.forEach((k, v) {
      buf.write('/$k ${v.toPdf()} ');
    });
    buf.write('>>');
    return buf.toString();
  }
}

class PdfRef extends PdfVal {
  PdfRef(this.id, this.gen);
  final int id;
  final int gen;
  @override
  String toPdf() => '$id $gen R';
}

class PdfBool extends PdfVal {
  PdfBool(this.value);
  final bool value;
  @override
  String toPdf() => value ? 'true' : 'false';
}

class PdfNull extends PdfVal {
  @override
  String toPdf() => 'null';
}

class PdfStream extends PdfVal {
  PdfStream(this.dict, this.data);
  final PdfDict dict;
  final Uint8List data;
  @override
  String toPdf() {
    final copy = PdfDict(Map.of(dict.map));
    copy.map['Length'] = PdfNum(data.length.toDouble());
    final out = BytesBuilder();
    out.add(utf8.encode('${copy.toPdf()}\nstream\n'));
    out.add(data);
    out.add(utf8.encode('\nendstream'));
    return latin1.decode(out.takeBytes());
  }
}

class _Obj {
  _Obj(this.id, this.gen, this.value);
  final int id;
  final int gen;
  PdfVal value;
}

PdfDict? _asDict(PdfVal? v) {
  if (v is PdfDict) return v;
  if (v is PdfStream) return v.dict;
  return null;
}

List<PdfVal> _asList(PdfVal? v) {
  if (v is PdfArr) return v.items;
  if (v == null) return const [];
  return [v];
}

Uint8List _decodeStream(PdfStream stream) {
  var data = stream.data;
  final filter = stream.dict['Filter'];
  final names = <String>[];
  if (filter is PdfName) names.add(filter.name);
  if (filter is PdfArr) {
    for (final n in filter.items) {
      if (n is PdfName) names.add(n.name);
    }
  }
  for (final name in names) {
    if (name == 'FlateDecode') {
      data = _inflate(data);
    }
  }
  return data;
}

Uint8List _inflate(Uint8List data) {
  try {
    return Uint8List.fromList(zlib.decode(data));
  } catch (_) {
    try {
      return Uint8List.fromList(
        ZLibCodec(raw: true).decode(data),
      );
    } catch (_) {
      return data;
    }
  }
}

String _extractText(Uint8List content) {
  final cur = _Cursor(content, 0);
  final stack = <PdfVal>[];
  final buf = StringBuffer();
  void writeStr(PdfVal? v) {
    if (v is PdfStr) {
      if (buf.isNotEmpty && !buf.toString().endsWith(' ') && !buf.toString().endsWith('\n')) {
        buf.write(' ');
      }
      buf.write(v.text);
    }
  }

  while (!cur.eof) {
    cur.skip();
    if (cur.eof) break;
    final c = cur.b[cur.p];
    if (c == 0x2F ||
        c == 0x28 ||
        c == 0x3C ||
        c == 0x5B ||
        c == 0x2B ||
        c == 0x2D ||
        c == 0x2E ||
        (c >= 0x30 && c <= 0x39)) {
      try {
        stack.add(cur.parseVal());
        continue;
      } catch (_) {
        cur.p++;
        continue;
      }
    }
    final op = cur.readWord();
    if (op.isEmpty) {
      cur.p++;
      continue;
    }
    switch (op) {
      case 'Tj':
      case "'":
      case '"':
        if (op != 'Tj') buf.write('\n');
        if (stack.isNotEmpty) writeStr(stack.removeLast());
      case 'TJ':
        if (stack.isNotEmpty) {
          final last = stack.removeLast();
          if (last is PdfArr) {
            for (final item in last.items) {
              writeStr(item);
            }
          }
        }
      case 'T*':
      case 'Td':
      case 'TD':
        buf.write('\n');
        stack.clear();
      case 'BT':
      case 'ET':
        stack.clear();
      default:
        stack.clear();
    }
  }
  return buf.toString();
}

class _Cursor {
  _Cursor(this.b, this.p);
  final Uint8List b;
  int p;
  int get n => b.length;
  bool get eof => p >= n;
  bool get isDigit => !eof && b[p] >= 0x30 && b[p] <= 0x39;

  void skip() {
    while (!eof) {
      final c = b[p];
      if (c == 0x00 ||
          c == 0x09 ||
          c == 0x0A ||
          c == 0x0C ||
          c == 0x0D ||
          c == 0x20) {
        p++;
        continue;
      }
      if (c == 0x25) {
        while (!eof && b[p] != 0x0A && b[p] != 0x0D) {
          p++;
        }
        continue;
      }
      break;
    }
  }

  bool looking(String s) {
    skip();
    if (p + s.length > n) return false;
    for (var i = 0; i < s.length; i++) {
      if (b[p + i] != s.codeUnitAt(i)) return false;
    }
    return true;
  }

  void takeWord() {
    skip();
    while (!eof && !_isDelim(b[p]) && b[p] > 0x20) {
      p++;
    }
  }

  String readWord() {
    skip();
    final start = p;
    while (!eof && !_isDelim(b[p]) && b[p] > 0x20) {
      p++;
    }
    return latin1.decode(b.sublist(start, p));
  }

  int readInt() {
    skip();
    final start = p;
    if (!eof && (b[p] == 0x2B || b[p] == 0x2D)) p++;
    while (!eof && b[p] >= 0x30 && b[p] <= 0x39) {
      p++;
    }
    return int.parse(latin1.decode(b.sublist(start, p)));
  }

  _Obj parseIndirect() {
    skip();
    final id = readInt();
    final gen = readInt();
    skip();
    if (!looking('obj')) {
      throw FormatException('expected obj at $p');
    }
    takeWord();
    skip();
    final val = parseVal();
    skip();
    if (looking('stream')) {
      takeWord();
      if (!eof && b[p] == 0x0D) p++;
      if (!eof && b[p] == 0x0A) p++;
      final dict = val is PdfDict ? val : PdfDict({});
      var length = 0;
      final lenVal = dict['Length'];
      if (lenVal is PdfNum) length = lenVal.asInt;
      Uint8List data;
      if (length > 0 && p + length <= n) {
        data = Uint8List.fromList(b.sublist(p, p + length));
        p += length;
        skip();
        if (looking('endstream')) takeWord();
      } else {
        final end = _findEndstream(p);
        data = Uint8List.fromList(b.sublist(p, end));
        p = end;
        if (looking('endstream')) takeWord();
      }
      skip();
      if (looking('endobj')) takeWord();
      return _Obj(id, gen, PdfStream(dict, data));
    }
    skip();
    if (looking('endobj')) takeWord();
    return _Obj(id, gen, val);
  }

  int _findEndstream(int from) {
    final needle = latin1.encode('endstream');
    for (var i = from; i + needle.length <= n; i++) {
      var ok = true;
      for (var j = 0; j < needle.length; j++) {
        if (b[i + j] != needle[j]) {
          ok = false;
          break;
        }
      }
      if (ok) return i;
    }
    return n;
  }

  PdfVal parseVal() {
    skip();
    if (eof) throw FormatException('eof');
    final c = b[p];
    if (c == 0x2F) return _parseName();
    if (c == 0x28) return _parseLiteral();
    if (c == 0x3C) {
      if (p + 1 < n && b[p + 1] == 0x3C) return _parseDict();
      return _parseHex();
    }
    if (c == 0x5B) return _parseArray();
    if (c == 0x74 && looking('true')) {
      takeWord();
      return PdfBool(true);
    }
    if (c == 0x66 && looking('false')) {
      takeWord();
      return PdfBool(false);
    }
    if (c == 0x6E && looking('null')) {
      takeWord();
      return PdfNull();
    }
    if (c == 0x2B || c == 0x2D || c == 0x2E || (c >= 0x30 && c <= 0x39)) {
      return _parseNumberOrRef();
    }
    throw FormatException('unexpected ${c.toRadixString(16)} at $p');
  }

  PdfVal _parseNumberOrRef() {
    final n1 = _readNumber();
    final saved = p;
    skip();
    if (!eof && ((b[p] >= 0x30 && b[p] <= 0x39) || b[p] == 0x2B || b[p] == 0x2D)) {
      try {
        final n2 = _readNumber();
        skip();
        if (!eof && b[p] == 0x52 && (p + 1 >= n || _isDelim(b[p + 1]) || b[p + 1] <= 0x20)) {
          p++;
          return PdfRef(n1.round(), n2.round());
        }
      } catch (_) {}
    }
    p = saved;
    return PdfNum(n1);
  }

  double _readNumber() {
    skip();
    final start = p;
    if (!eof && (b[p] == 0x2B || b[p] == 0x2D)) p++;
    var seenDot = false;
    while (!eof) {
      final c = b[p];
      if (c == 0x2E && !seenDot) {
        seenDot = true;
        p++;
        continue;
      }
      if (c >= 0x30 && c <= 0x39) {
        p++;
        continue;
      }
      break;
    }
    return double.parse(latin1.decode(b.sublist(start, p)));
  }

  PdfName _parseName() {
    p++;
    final start = p;
    while (!eof && !_isDelim(b[p]) && b[p] > 0x20) {
      p++;
    }
    var raw = latin1.decode(b.sublist(start, p));
    raw = raw.replaceAllMapped(RegExp(r'#([0-9A-Fa-f]{2})'), (m) {
      return String.fromCharCode(int.parse(m.group(1)!, radix: 16));
    });
    return PdfName(raw);
  }

  PdfStr _parseLiteral() {
    p++;
    final out = BytesBuilder();
    var depth = 1;
    while (!eof && depth > 0) {
      final c = b[p++];
      if (c == 0x5C) {
        if (eof) break;
        final e = b[p++];
        switch (e) {
          case 0x6E:
            out.addByte(0x0A);
          case 0x72:
            out.addByte(0x0D);
          case 0x74:
            out.addByte(0x09);
          case 0x62:
            out.addByte(0x08);
          case 0x66:
            out.addByte(0x0C);
          case 0x28:
            out.addByte(0x28);
          case 0x29:
            out.addByte(0x29);
          case 0x5C:
            out.addByte(0x5C);
          case 0x0A:
          case 0x0D:
            if (e == 0x0D && !eof && b[p] == 0x0A) p++;
          default:
            if (e >= 0x30 && e <= 0x37) {
              var oct = e - 0x30;
              for (var i = 0; i < 2 && !eof && b[p] >= 0x30 && b[p] <= 0x37; i++) {
                oct = (oct << 3) + (b[p++] - 0x30);
              }
              out.addByte(oct);
            } else {
              out.addByte(e);
            }
        }
      } else if (c == 0x28) {
        depth++;
        out.addByte(c);
      } else if (c == 0x29) {
        depth--;
        if (depth > 0) out.addByte(c);
      } else {
        out.addByte(c);
      }
    }
    return PdfStr(Uint8List.fromList(out.takeBytes()));
  }

  PdfStr _parseHex() {
    p++;
    final hex = StringBuffer();
    while (!eof && b[p] != 0x3E) {
      final c = b[p++];
      if (c > 0x20) hex.writeCharCode(c);
    }
    if (!eof && b[p] == 0x3E) p++;
    var s = hex.toString();
    if (s.length.isOdd) s = '${s}0';
    final out = Uint8List(s.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(s.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return PdfStr(out, hex: true);
  }

  PdfDict _parseDict() {
    p += 2;
    final map = <String, PdfVal>{};
    while (true) {
      skip();
      if (eof) break;
      if (p + 1 < n && b[p] == 0x3E && b[p + 1] == 0x3E) {
        p += 2;
        break;
      }
      final key = parseVal();
      final val = parseVal();
      if (key is PdfName) map[key.name] = val;
    }
    return PdfDict(map);
  }

  PdfArr _parseArray() {
    p++;
    final items = <PdfVal>[];
    while (true) {
      skip();
      if (eof) break;
      if (b[p] == 0x5D) {
        p++;
        break;
      }
      items.add(parseVal());
    }
    return PdfArr(items);
  }
}

bool _isDelim(int c) {
  return c == 0x28 ||
      c == 0x29 ||
      c == 0x3C ||
      c == 0x3E ||
      c == 0x5B ||
      c == 0x5D ||
      c == 0x7B ||
      c == 0x7D ||
      c == 0x2F ||
      c == 0x25;
}
