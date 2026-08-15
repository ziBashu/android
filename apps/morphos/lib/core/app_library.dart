import 'models.dart';

/// App Library groups (page to the right of home).
class AppLibrary {
  AppLibrary._();

  static const suggestions = 'Suggestions';
  static const recentlyUsed = 'Recently used';
  static const other = 'Other';

  static String groupFor(MorphAppItem app) {
    final hay =
        '${app.label} ${app.packageName ?? app.id} ${app.category}'.toLowerCase();
    if (app.category == 'work' ||
        hay.contains('office') ||
        hay.contains('docs') ||
        hay.contains('pdf') ||
        hay.contains('mail') ||
        hay.contains('calendar')) {
      return 'Productivity';
    }
    if (hay.contains('whatsapp') ||
        hay.contains('telegram') ||
        hay.contains('wechat') ||
        hay.contains('sms') ||
        hay.contains('message') ||
        hay.contains('discord') ||
        hay.contains('slack') ||
        hay.contains('qq') ||
        hay.contains('line')) {
      return 'Social & Communication';
    }
    if (app.category == 'media' ||
        hay.contains('photo') ||
        hay.contains('gallery') ||
        hay.contains('camera')) {
      return 'Photos & Images';
    }
    if (hay.contains('youtube') ||
        hay.contains('netflix') ||
        hay.contains('video') ||
        hay.contains('movie') ||
        hay.contains('cinema')) {
      return 'Movies & Video';
    }
    if (app.category == 'game') return 'Games';
    if (app.category == 'nav' || app.category == 'travel') return 'Travel';
    if (app.category == 'read' || app.category == 'study') return 'Reading';
    if (hay.contains('news') || hay.contains('magazine')) {
      return 'News & Magazines';
    }
    return other;
  }

  /// Folders for the library page. [starredIds] / [launchCounts] fill Suggestions.
  static Map<String, List<MorphAppItem>> group(
    List<MorphAppItem> apps, {
    Iterable<String> starredIds = const [],
    Map<String, int> launchCounts = const {},
  }) {
    final stars = starredIds.toSet();
    final suggestionsList = <MorphAppItem>[];
    for (final a in apps) {
      final key = a.packageName ?? a.id;
      if (stars.contains(a.id) || stars.contains(key)) {
        suggestionsList.add(a);
      }
    }
    final byLaunch = List<MorphAppItem>.from(apps)
      ..sort((a, b) {
        final sa = launchCounts[a.id] ?? launchCounts[a.packageName ?? ''] ?? 0;
        final sb = launchCounts[b.id] ?? launchCounts[b.packageName ?? ''] ?? 0;
        return sb.compareTo(sa);
      });
    for (final a in byLaunch) {
      if (suggestionsList.length >= 8) break;
      if (suggestionsList.any((x) => x.id == a.id)) continue;
      final n = launchCounts[a.id] ?? launchCounts[a.packageName ?? ''] ?? 0;
      if (n > 0) suggestionsList.add(a);
    }

    final folders = <String, List<MorphAppItem>>{};
    if (suggestionsList.isNotEmpty) {
      folders[suggestions] = suggestionsList;
    }
    for (final a in apps) {
      final g = groupFor(a);
      folders.putIfAbsent(g, () => []).add(a);
    }
    return folders;
  }
}
