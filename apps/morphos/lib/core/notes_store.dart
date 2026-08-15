import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'system_morph_bridge.dart';

/// One local note. Survives process death via [NotesStore].
class MorphNote {
  const MorphNote({
    required this.id,
    required this.title,
    required this.body,
    required this.updatedAtMs,
  });

  final String id;
  final String title;
  final String body;
  final int updatedAtMs;

  /// Title if set, otherwise the first non-empty body line.
  String get listLine {
    final t = title.trim();
    if (t.isNotEmpty) return t;
    for (final line in body.split(RegExp(r'\r?\n'))) {
      final s = line.trim();
      if (s.isNotEmpty) return s;
    }
    return 'Untitled';
  }

  MorphNote copyWith({
    String? title,
    String? body,
    int? updatedAtMs,
  }) {
    return MorphNote(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'updatedAtMs': updatedAtMs,
      };

  static MorphNote fromJson(Map<String, dynamic> m) {
    return MorphNote(
      id: '${m['id'] ?? ''}',
      title: '${m['title'] ?? ''}',
      body: '${m['body'] ?? ''}',
      updatedAtMs: (m['updatedAtMs'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Create / edit / list / delete notes.
///
/// Dual-write: SharedPreferences (always) + a phone file so notes survive
/// switching the default Home app. MorphOS app data is not wiped when
/// another launcher is selected.
class NotesStore {
  NotesStore({this.prefsKey = defaultPrefsKey});

  static const defaultPrefsKey = 'morphos_notes_v1';

  final String prefsKey;
  List<MorphNote> notes = const [];

  /// App-private file (always writable).
  String? appPath;

  /// Public Documents file — stays if you switch Home; lost only if you
  /// uninstall MorphOS *and* delete Documents/MorphOS.
  String? publicPath;

  /// Path to show the user (public if we have it, otherwise app file).
  String get writingPath {
    final pub = publicPath?.trim() ?? '';
    if (pub.isNotEmpty) return pub;
    final app = appPath?.trim() ?? '';
    if (app.isNotEmpty) return app;
    return 'App storage (SharedPreferences $prefsKey)';
  }

  String get pathHelp =>
      'Notes are written to a file on this phone, not to the launcher you '
      'pick as Home. Switching to MIUI / Nova / another Home does not delete '
      'them. Use this path if you want to copy or back them up:\n$writingPath';

  Future<void> refreshPaths() async {
    final paths = await SystemMorphBridge.notesPaths();
    appPath = paths['appPath'];
    publicPath = paths['publicPath'];
  }

  List<MorphNote> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      final list = decoded is List
          ? decoded
          : (decoded is Map ? decoded['notes'] as List? : null);
      if (list == null) return const [];
      final out = list
          .whereType<Map>()
          .map((e) => MorphNote.fromJson(Map<String, dynamic>.from(e)))
          .where((n) => n.id.isNotEmpty)
          .toList();
      out.sort((a, b) => b.updatedAtMs.compareTo(a.updatedAtMs));
      return out;
    } catch (_) {
      return const [];
    }
  }

  String _encode() => jsonEncode(notes.map((n) => n.toJson()).toList());

  Future<void> load() async {
    await refreshPaths();
    final fileRaw = await SystemMorphBridge.readNotesJson();
    final prefs = await SharedPreferences.getInstance();
    final prefsRaw = prefs.getString(prefsKey);
    final fromFile = _decode(fileRaw);
    final fromPrefs = _decode(prefsRaw);
    if (fromFile.isNotEmpty) {
      notes = fromFile;
      if (fromPrefs.isEmpty || fromPrefs.length < fromFile.length) {
        await prefs.setString(prefsKey, _encode());
      }
      return;
    }
    notes = fromPrefs;
    if (notes.isNotEmpty) {
      await SystemMorphBridge.writeNotesJson(_encode());
      await refreshPaths();
    }
  }

  Future<void> _save() async {
    final encoded = _encode();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, encoded);
    final paths = await SystemMorphBridge.writeNotesJson(encoded);
    appPath = paths['appPath'] ?? appPath;
    publicPath = paths['publicPath'] ?? publicPath;
  }

  MorphNote? byId(String id) {
    for (final n in notes) {
      if (n.id == id) return n;
    }
    return null;
  }

  Future<MorphNote> create({String title = '', String body = ''}) async {
    final n = MorphNote(
      id: 'note_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      body: body,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    notes = [n, ...notes];
    await _save();
    return n;
  }

  Future<MorphNote?> edit(
    String id, {
    String? title,
    String? body,
  }) async {
    final i = notes.indexWhere((n) => n.id == id);
    if (i < 0) return null;
    final next = notes[i].copyWith(
      title: title,
      body: body,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    final copy = List<MorphNote>.from(notes);
    copy[i] = next;
    copy.sort((a, b) => b.updatedAtMs.compareTo(a.updatedAtMs));
    notes = copy;
    await _save();
    return next;
  }

  Future<bool> delete(String id) async {
    final before = notes.length;
    notes = notes.where((n) => n.id != id).toList(growable: false);
    if (notes.length == before) return false;
    await _save();
    return true;
  }
}
