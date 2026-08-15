import 'models.dart';

/// Ranked app search — label-first, not package-id noise.
///
/// Query `brave` should surface an app labeled **Brave** ahead of
/// `com.brave.browser` package-only matches and unrelated substring noise.
class AppSearch {
  AppSearch._();

  /// Score one app against [query]. Higher is better. Zero means no match.
  static int scoreApp(
    MorphAppItem app,
    String query, {
    String Function(MorphAppItem)? labelOf,
  }) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return 0;

    final label = (labelOf?.call(app) ?? app.label).trim();
    final labelLower = label.toLowerCase();
    final pkg = (app.packageName ?? app.id).toLowerCase();
    final pkgTail = pkg.contains('.') ? pkg.split('.').last : pkg;

    // Exact label
    if (labelLower == q) return 1000;

    // Label starts with query (Brave ← brave)
    if (labelLower.startsWith(q)) return 900 + _lengthBonus(labelLower, q);

    // Word-boundary prefix: "Google Chrome" ← "chrome"
    final words = labelLower.split(RegExp(r'[\s\-_/.:]+'));
    for (final w in words) {
      if (w == q) return 850;
      if (w.startsWith(q)) return 800 + _lengthBonus(w, q);
    }

    // Label contains query as substring
    if (labelLower.contains(q)) {
      final idx = labelLower.indexOf(q);
      // Prefer earlier occurrence
      return 600 - idx.clamp(0, 100) + _lengthBonus(labelLower, q);
    }

    // Package tail exact / prefix (weaker than label)
    if (pkgTail == q) return 400;
    if (pkgTail.startsWith(q)) return 350;
    if (pkg.contains(q)) return 200;

    return 0;
  }

  static int _lengthBonus(String hay, String needle) {
    // Prefer shorter labels when equally matched (Brave > Brave Browser Helper)
    final extra = hay.length - needle.length;
    return (40 - extra.clamp(0, 40)).clamp(0, 40);
  }

  /// Filter + rank apps. Empty query returns [apps] sorted A–Z by label.
  /// When [starredIds] is set, those apps sort above the rest.
  static List<MorphAppItem> rank(
    List<MorphAppItem> apps,
    String query, {
    String Function(MorphAppItem)? labelOf,
    Iterable<String> starredIds = const [],
  }) {
    final q = query.trim();
    List<MorphAppItem> ranked;
    if (q.isEmpty) {
      ranked = List<MorphAppItem>.from(apps);
      ranked.sort((a, b) {
        final la = (labelOf?.call(a) ?? a.label).toLowerCase();
        final lb = (labelOf?.call(b) ?? b.label).toLowerCase();
        return la.compareTo(lb);
      });
    } else {
      final scored = <({MorphAppItem app, int score})>[];
      for (final app in apps) {
        final s = scoreApp(app, q, labelOf: labelOf);
        if (s > 0) scored.add((app: app, score: s));
      }
      scored.sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        final la = (labelOf?.call(a.app) ?? a.app.label).toLowerCase();
        final lb = (labelOf?.call(b.app) ?? b.app.label).toLowerCase();
        return la.compareTo(lb);
      });
      ranked = scored.map((e) => e.app).toList();
    }
    return pinStars(ranked, starredIds);
  }

  /// Latin first letter A–Z, or `*` for non-English / non-Latin labels.
  static String indexBucket(String label) {
    final t = label.trim();
    if (t.isEmpty) return '*';
    final code = t.toUpperCase().codeUnitAt(0);
    if (code >= 65 && code <= 90) {
      return String.fromCharCode(code);
    }
    return '*';
  }

  /// Side-index map. Keys are `*` then A–Z, only buckets that have apps.
  static Map<String, List<MorphAppItem>> bucketByIndex(
    List<MorphAppItem> apps, {
    String Function(MorphAppItem)? labelOf,
  }) {
    final buckets = <String, List<MorphAppItem>>{};
    for (final app in apps) {
      final label = labelOf?.call(app) ?? app.label;
      final key = indexBucket(label);
      buckets.putIfAbsent(key, () => []).add(app);
    }
    final ordered = <String, List<MorphAppItem>>{};
    if (buckets.containsKey('*')) {
      ordered['*'] = buckets['*']!;
    }
    for (var c = 65; c <= 90; c++) {
      final k = String.fromCharCode(c);
      final list = buckets[k];
      if (list != null && list.isNotEmpty) ordered[k] = list;
    }
    return ordered;
  }

  static bool isStarred(MorphAppItem app, Iterable<String> starredIds) {
    final set = starredIds is Set<String> ? starredIds : starredIds.toSet();
    if (set.contains(app.id)) return true;
    final pkg = app.packageName;
    return pkg != null && set.contains(pkg);
  }

  /// Starred apps first, original relative order otherwise.
  static List<MorphAppItem> pinStars(
    List<MorphAppItem> apps,
    Iterable<String> starredIds,
  ) {
    if (starredIds.isEmpty) return List<MorphAppItem>.from(apps);
    final stars = <MorphAppItem>[];
    final rest = <MorphAppItem>[];
    for (final app in apps) {
      if (isStarred(app, starredIds)) {
        stars.add(app);
      } else {
        rest.add(app);
      }
    }
    return [...stars, ...rest];
  }
}
