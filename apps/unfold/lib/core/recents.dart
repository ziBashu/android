import 'dart:convert';
import 'dart:io';

class RecentItem {
  RecentItem({
    required this.path,
    required this.name,
    required this.kind,
    required this.openedAt,
  });

  final String path;
  final String name;
  final String kind;
  final DateTime openedAt;

  Map<String, dynamic> toJson() => {
        'path': path,
        'name': name,
        'kind': kind,
        'openedAt': openedAt.toIso8601String(),
      };

  static RecentItem fromJson(Map<String, dynamic> j) => RecentItem(
        path: j['path'] as String,
        name: j['name'] as String,
        kind: j['kind'] as String? ?? '',
        openedAt: DateTime.tryParse(j['openedAt'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
}

abstract class RecentsStore {
  List<RecentItem> load();
  void add(RecentItem item);
}

class MemoryRecents implements RecentsStore {
  MemoryRecents([List<RecentItem>? seed]) : _items = [...?seed];
  final List<RecentItem> _items;

  @override
  List<RecentItem> load() => List.unmodifiable(_items);

  @override
  void add(RecentItem item) {
    _items.removeWhere((e) => e.path == item.path);
    _items.insert(0, item);
    if (_items.length > 30) _items.removeRange(30, _items.length);
  }
}

class FileRecents implements RecentsStore {
  FileRecents(this.file);
  final File file;

  @override
  List<RecentItem> load() {
    if (!file.existsSync()) return [];
    try {
      final data = jsonDecode(file.readAsStringSync());
      if (data is! List) return [];
      return data
          .whereType<Map>()
          .map((e) => RecentItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  void add(RecentItem item) {
    final items = load();
    items.removeWhere((e) => e.path == item.path);
    items.insert(0, item);
    if (items.length > 30) items.removeRange(30, items.length);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(jsonEncode(items.map((e) => e.toJson()).toList()));
  }
}
