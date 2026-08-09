/// Pure home-root navigation policy (unit-testable, no platform).
///
/// MorphOS as default home must behave like LauncherOS / AOSP Launcher3:
/// - System Back at the Morph home root does **not** exit the app.
/// - Home re-entry always lands on the Morph home surface (pop to root).
class HomeNav {
  HomeNav._();

  /// When true, the host should [moveTaskToBack] instead of finishing.
  static bool shouldMoveTaskToBack({
    required bool navigatorCanPop,
    required bool atMorphHomeRoot,
  }) {
    if (navigatorCanPop) return false;
    return atMorphHomeRoot;
  }

  /// Whether a launcher event should force pop-to-root.
  static bool shouldPopToRoot(String eventType) {
    switch (eventType) {
      case 'home':
        return true;
      case 'launcher':
        // App-icon open may intentionally restore prior surface; Home must not.
        return false;
      case 'resume':
        return false;
      default:
        return eventType == 'home';
    }
  }

  /// True when intent categories indicate a HOME launch (mirror of native).
  static bool isHomeCategories(Iterable<String> categories) {
    return categories.contains('android.intent.category.HOME');
  }
}
