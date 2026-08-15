import 'package:flutter/material.dart';

import 'models.dart';

/// Locale-agnostic mapping of PackageManager launcher rows.
///
/// A real home must list every MAIN+LAUNCHER activity, including labels that
/// are not English. Empty labels fall back to the package tail — they are
/// never dropped for being CJK / non-Latin.
class LauncherListing {
  LauncherListing._();

  static const morphosPackage = 'com.zibashu.morphos';

  static MorphAppItem morphOsApp() => const MorphAppItem(
        id: morphosPackage,
        label: 'MorphOS',
        icon: Icons.auto_awesome,
        packageName: morphosPackage,
        color: Color(0xFF7C4DFF),
        isSystemDemo: false,
        category: 'other',
      );

  static MorphAppItem? fromRow(Map<dynamic, dynamic> row) {
    final pkg =
        '${row['packageName'] ?? row['package'] ?? ''}'.trim();
    if (pkg.isEmpty) return null;
    var label = '${row['label'] ?? ''}'.trim();
    if (label.isEmpty) {
      label = pkg.contains('.') ? pkg.split('.').last : pkg;
    }
    if (pkg == morphosPackage) {
      return morphOsApp().copyWith(label: label.isEmpty ? 'MorphOS' : label);
    }
    final cat = inferAppCategory(name: label, packageName: pkg);
    return MorphAppItem(
      id: pkg,
      label: label,
      icon: _iconForCategory(cat),
      packageName: pkg,
      color: _colorForCategory(cat),
      isSystemDemo: false,
      category: cat,
    );
  }

  static List<MorphAppItem> fromRows(Iterable<dynamic> rows) {
    final out = <MorphAppItem>[];
    final seen = <String>{};
    for (final raw in rows) {
      if (raw is! Map) continue;
      final item = fromRow(raw);
      if (item == null) continue;
      if (!seen.add(item.id)) continue;
      out.add(item);
    }
    if (!seen.contains(morphosPackage)) {
      out.add(morphOsApp());
    }
    out.sort(
      (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
    return out;
  }

  static IconData _iconForCategory(String cat) => switch (cat) {
        'game' => Icons.sports_esports_outlined,
        'nav' => Icons.map_outlined,
        'read' => Icons.menu_book_outlined,
        'work' => Icons.work_outline,
        'media' => Icons.movie_outlined,
        'study' => Icons.school_outlined,
        'travel' => Icons.flight_takeoff,
        _ => Icons.apps,
      };

  static Color _colorForCategory(String cat) => switch (cat) {
        'game' => const Color(0xFFEC407A),
        'nav' => const Color(0xFF26A69A),
        'read' => const Color(0xFFA1887F),
        'work' => const Color(0xFF5C6BC0),
        'media' => const Color(0xFFAB47BC),
        'study' => const Color(0xFF43A047),
        'travel' => const Color(0xFF1E88E5),
        _ => const Color(0xFF7C4DFF),
      };
}
