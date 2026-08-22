import 'dart:math';
import 'dart:typed_data';

/// OLE Compound File (MS-CFB) reader/writer used for legacy Word .doc files.
class OleFile {
  OleFile(this.streams);

  final Map<String, Uint8List> streams;

  Uint8List? stream(String name) {
    for (final e in streams.entries) {
      if (_norm(e.key) == _norm(name)) return e.value;
    }
    return null;
  }

  bool has(String name) => stream(name) != null;

  static String _norm(String n) =>
      n.replaceAll(RegExp(r'^[\x00-\x1f]'), '').toLowerCase();

  static OleFile parse(Uint8List bytes) {
    if (bytes.length < 512 ||
        bytes[0] != 0xD0 ||
        bytes[1] != 0xCF ||
        bytes[2] != 0x11 ||
        bytes[3] != 0xE0) {
      throw FormatException('Not an OLE compound file');
    }
    final sectorShift = _u16(bytes, 0x1E);
    final miniShift = _u16(bytes, 0x20);
    final sectorSize = 1 << sectorShift;
    final miniSize = 1 << miniShift;
    final numFat = _u32(bytes, 0x2C);
    final firstDir = _u32(bytes, 0x30);
    final cutoff = _u32(bytes, 0x38);
    final firstMiniFat = _u32(bytes, 0x3C);
    final difat = <int>[];
    for (var i = 0; i < 109; i++) {
      difat.add(_u32(bytes, 0x4C + i * 4));
    }
    final fat = <int>[];
    for (var i = 0; i < numFat && i < difat.length; i++) {
      final sec = difat[i];
      if (sec >= 0xFFFFFFF0) break;
      final off = (sec + 1) * sectorSize;
      for (var j = 0; j < sectorSize / 4; j++) {
        fat.add(_u32(bytes, off + j * 4));
      }
    }
    Uint8List fatChain(int start, int length) {
      final out = BytesBuilder();
      var sec = start;
      var left = length;
      var guard = 0;
      while (sec < 0xFFFFFFF0 && left > 0 && guard++ < 1 << 20) {
        final off = (sec + 1) * sectorSize;
        final take = left < sectorSize ? left : sectorSize;
        if (off >= bytes.length) break;
        final end = (off + take).clamp(0, bytes.length);
        out.add(bytes.sublist(off, end));
        left -= take;
        if (sec >= fat.length) break;
        sec = fat[sec];
      }
      return Uint8List.fromList(out.takeBytes());
    }

    final dirBytes = fatChain(firstDir, sectorSize * 4);
    final entries = <_DirEnt>[];
    for (var i = 0; i + 128 <= dirBytes.length; i += 128) {
      final slice = dirBytes.sublist(i, i + 128);
      final nameLen = _u16(slice, 0x40);
      if (nameLen < 2) {
        entries.add(_DirEnt.empty());
        continue;
      }
      final name = String.fromCharCodes([
        for (var k = 0; k < (nameLen ~/ 2) - 1; k++) _u16(slice, k * 2),
      ]);
      entries.add(
        _DirEnt(
          name: name,
          type: slice[0x42],
          start: _u32(slice, 0x74),
          size: _u32(slice, 0x78),
        ),
      );
    }
    if (entries.isEmpty) throw FormatException('OLE directory empty');
    final root = entries.first;
    final miniStream = root.size > 0 ? fatChain(root.start, root.size) : Uint8List(0);
    final miniFatBytes = firstMiniFat < 0xFFFFFFF0
        ? fatChain(firstMiniFat, sectorSize)
        : Uint8List(0);
    final miniFat = <int>[];
    for (var i = 0; i + 4 <= miniFatBytes.length; i += 4) {
      miniFat.add(_u32(miniFatBytes, i));
    }

    Uint8List miniChain(int start, int length) {
      final out = BytesBuilder();
      var sec = start;
      var left = length;
      var guard = 0;
      while (sec < 0xFFFFFFF0 && left > 0 && guard++ < 1 << 20) {
        final off = sec * miniSize;
        final take = left < miniSize ? left : miniSize;
        if (off >= miniStream.length) break;
        final end = (off + take).clamp(0, miniStream.length);
        out.add(miniStream.sublist(off, end));
        left -= take;
        if (sec >= miniFat.length) break;
        sec = miniFat[sec];
      }
      return Uint8List.fromList(out.takeBytes());
    }

    final streams = <String, Uint8List>{};
    for (final e in entries) {
      if (e.type != 2 || e.name.isEmpty) continue;
      final data = (e.size < cutoff && miniStream.isNotEmpty)
          ? miniChain(e.start, e.size)
          : fatChain(e.start, e.size);
      streams[e.name] = data;
    }
    return OleFile(streams);
  }

  static Uint8List pack(Map<String, Uint8List> streams) {
    const sectorSize = 512;
    const miniSize = 64;
    const cutoff = 4096;
    const eoc = 0xFFFFFFFE;
    const fatSect = 0xFFFFFFFD;
    const free = 0xFFFFFFFF;

    final names = streams.keys.toList();
    final miniParts = <Uint8List>[];
    final miniStarts = <int>[];
    final miniFat = <int>[];
    var miniSec = 0;
    for (final name in names) {
      final data = streams[name]!;
      miniStarts.add(miniSec);
      final padded = _pad(data, miniSize);
      final count = padded.length ~/ miniSize;
      for (var i = 0; i < count; i++) {
        miniParts.add(padded.sublist(i * miniSize, (i + 1) * miniSize));
        miniFat.add(i == count - 1 ? eoc : miniSec + 1);
        miniSec++;
      }
      if (count == 0) {
        miniParts.add(Uint8List(miniSize));
        miniFat.add(eoc);
        miniSec++;
      }
    }
    final miniStream = Uint8List.fromList(
      miniParts.expand((e) => e).toList(),
    );

    // Sectors: 0 FAT, 1 Directory, 2 MiniFAT, 3+ mini stream
    final miniStreamPadded = _pad(miniStream, sectorSize);
    final miniStreamSectors = miniStreamPadded.length ~/ sectorSize;
    final miniFatPadded = _pad(_u32list(miniFat), sectorSize);
    final miniFatSectors = miniFatPadded.length ~/ sectorSize;

    final dir = Uint8List(sectorSize);
    void writeDir(int index, String name, int type, int start, int size, {int child = -1, int right = -1}) {
      final off = index * 128;
      final units = name.codeUnits;
      for (var i = 0; i < units.length && i < 31; i++) {
        dir[off + i * 2] = units[i] & 0xFF;
        dir[off + i * 2 + 1] = (units[i] >> 8) & 0xFF;
      }
      final nameLen = (name.length + 1) * 2;
      dir[off + 0x40] = nameLen & 0xFF;
      dir[off + 0x41] = (nameLen >> 8) & 0xFF;
      dir[off + 0x42] = type;
      _put32(dir, off + 0x44, 0xFFFFFFFF); // left
      _put32(dir, off + 0x48, right); // right
      _put32(dir, off + 0x4C, child);
      _put32(dir, off + 0x74, start);
      _put32(dir, off + 0x78, size);
    }

    writeDir(0, 'Root Entry', 5, 3, miniStream.length, child: names.isEmpty ? -1 : 1);
    for (var i = 0; i < names.length && i < 3; i++) {
      final right = i + 1 < names.length ? i + 2 : -1;
      writeDir(
        i + 1,
        names[i],
        2,
        miniStarts[i],
        streams[names[i]]!.length,
        right: right,
      );
    }

    final fat = List<int>.filled(sectorSize ~/ 4, free);
    fat[0] = fatSect;
    fat[1] = eoc;
    fat[2] = eoc;
    for (var i = 0; i < miniStreamSectors; i++) {
      final idx = 3 + i;
      fat[idx] = i == miniStreamSectors - 1 ? eoc : idx + 1;
    }

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
    _put32(header, 0x2C, 1); // num FAT
    _put32(header, 0x30, 1); // first dir
    _put32(header, 0x38, cutoff);
    _put32(header, 0x3C, 2); // first mini FAT
    _put32(header, 0x40, miniFatSectors);
    _put32(header, 0x44, eoc);
    _put32(header, 0x4C, 0); // DIFAT[0] = sector 0
    for (var i = 1; i < 109; i++) {
      _put32(header, 0x4C + i * 4, free);
    }

    final out = BytesBuilder();
    out.add(header);
    out.add(_u32list(fat));
    out.add(dir);
    out.add(miniFatPadded);
    out.add(miniStreamPadded);
    return Uint8List.fromList(out.takeBytes());
  }
}

class _DirEnt {
  _DirEnt({
    required this.name,
    required this.type,
    required this.start,
    required this.size,
  });
  factory _DirEnt.empty() => _DirEnt(name: '', type: 0, start: 0, size: 0);
  final String name;
  final int type;
  final int start;
  final int size;
}

int _u16(Uint8List b, int o) => b[o] | (b[o + 1] << 8);
int _u32(Uint8List b, int o) =>
    b[o] | (b[o + 1] << 8) | (b[o + 2] << 16) | (b[o + 3] << 24);

void _put16(Uint8List b, int o, int v) {
  b[o] = v & 0xFF;
  b[o + 1] = (v >> 8) & 0xFF;
}

void _put32(Uint8List b, int o, int v) {
  b[o] = v & 0xFF;
  b[o + 1] = (v >> 8) & 0xFF;
  b[o + 2] = (v >> 16) & 0xFF;
  b[o + 3] = (v >> 24) & 0xFF;
}

Uint8List _pad(Uint8List data, int size) {
  if (data.length % size == 0 && data.isNotEmpty) return data;
  final n = data.isEmpty ? size : ((data.length + size - 1) ~/ size) * size;
  final out = Uint8List(n);
  out.setRange(0, data.length, data);
  return out;
}

Uint8List _u32list(List<int> v) {
  final out = Uint8List(v.length * 4);
  for (var i = 0; i < v.length; i++) {
    _put32(out, i * 4, v[i]);
  }
  return out;
}

/// Word 97–2003 (.doc) text via MS-DOC FIB + piece table (CLX / PlcPcd).
class DocCodec {
  static const _textAt = 2048;

  static Uint8List encode(String text) {
    final units = '$text\r'.codeUnits;
    final wd = Uint8List(_textAt + units.length * 2);
    wd[0] = 0xEC;
    wd[1] = 0xA5;
    wd[2] = 0xC1;
    wd[3] = 0x00;
    _put16(wd, 0x20, 0x000E);
    _put16(wd, 0x3E, 0x0016);
    _put16(wd, 0x0A, 0x0200);
    _put32(wd, 0x4C, units.length);
    _put16(wd, 0x98, 0x005D);
    final clx = _clx(units.length, _textAt);
    _put32(wd, 0x1A2, 0);
    _put32(wd, 0x1A6, clx.length);
    for (var i = 0; i < units.length; i++) {
      wd[_textAt + i * 2] = units[i] & 0xFF;
      wd[_textAt + i * 2 + 1] = (units[i] >> 8) & 0xFF;
    }
    return OleFile.pack({
      'WordDocument': wd,
      '1Table': clx,
    });
  }

  static Uint8List _clx(int charCount, int fc) {
    final plcLen = 16;
    final out = Uint8List(5 + plcLen);
    out[0] = 0x02;
    _put32(out, 1, plcLen);
    _put32(out, 5, 0);
    _put32(out, 9, charCount);
    _put32(out, 15, fc);
    return out;
  }

  static String decode(Uint8List bytes) {
    final ole = OleFile.parse(bytes);
    final wd = ole.stream('WordDocument');
    if (wd == null || wd.length < 0x1AA) {
      throw FormatException('WordDocument stream missing or truncated');
    }
    if (_u16(wd, 0) != 0xA5EC) {
      throw FormatException('Not a Word binary document');
    }
    final flags = _u16(wd, 0x0A);
    if (flags & 0x0100 != 0) {
      throw FormatException('Encrypted Word document');
    }
    final tableName = (flags & 0x0200) != 0 ? '1Table' : '0Table';
    final table = ole.stream(tableName);
    if (table == null) {
      throw FormatException('Word table stream missing');
    }
    final fcClx = _u32(wd, 0x1A2);
    final lcbClx = _u32(wd, 0x1A6);
    if (lcbClx == 0 || fcClx < 0 || fcClx + lcbClx > table.length) {
      throw FormatException('Word piece table missing');
    }
    final clx = table.sublist(fcClx, fcClx + lcbClx);
    return _textFromClx(wd, clx);
  }

  static String _textFromClx(Uint8List wordDoc, Uint8List clx) {
    var i = 0;
    while (i < clx.length) {
      final marker = clx[i];
      if (marker == 0x01) {
        if (i + 3 > clx.length) break;
        final cb = clx[i + 1] | (clx[i + 2] << 8);
        i += 3 + cb;
        continue;
      }
      if (marker == 0x02) {
        if (i + 5 > clx.length) break;
        final lcb = _u32(clx, i + 1);
        i += 5;
        if (lcb <= 0 || i + lcb > clx.length) break;
        return _textFromPlcPcd(wordDoc, clx.sublist(i, i + lcb));
      }
      i++;
    }
    throw FormatException('Word piece table (Pcdt) not found');
  }

  static String _textFromPlcPcd(Uint8List wordDoc, Uint8List plc) {
    if (plc.length < 16) {
      throw FormatException('PlcPcd too small');
    }
    final n = (plc.length - 4) ~/ 12;
    if (n < 1) throw FormatException('Word document has no text pieces');
    final cps = List<int>.generate(n + 1, (k) => _u32(plc, k * 4));
    final pcd0 = (n + 1) * 4;
    final buf = StringBuffer();
    for (var k = 0; k < n; k++) {
      final chars = cps[k + 1] - cps[k];
      if (chars <= 0) continue;
      final fcRaw = _u32(plc, pcd0 + k * 8 + 2);
      final compressed = (fcRaw & 0x40000000) != 0;
      var fc = fcRaw & 0x3FFFFFFF;
      if (compressed) {
        fc = fc ~/ 2;
        final end = min(fc + chars, wordDoc.length);
        for (var b = fc; b < end; b++) {
          buf.write(_docChar(wordDoc[b]));
        }
      } else {
        final end = min(fc + chars * 2, wordDoc.length);
        for (var b = fc; b + 1 < end; b += 2) {
          buf.write(_docChar(wordDoc[b] | (wordDoc[b + 1] << 8)));
        }
      }
    }
    return buf.toString();
  }

  static String _docChar(int cu) {
    if (cu == 0x0D || cu == 0x0B || cu == 0x0C || cu == 0x0E) return '\n';
    if (cu == 0x07) return '\t';
    if (cu == 0x00 || cu == 0x01 || cu == 0x05 || cu == 0x08) return '';
    if (cu == 0x13 || cu == 0x14 || cu == 0x15) return '';
    if (cu < 0x20 && cu != 0x09) return '';
    return String.fromCharCode(cu);
  }
}
