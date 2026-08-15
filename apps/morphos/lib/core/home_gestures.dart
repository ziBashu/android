/// Home gesture + chrome metrics. Pure — tests and HomeScreen share this.
library;

/// Wallpaper / icon / sidebar / island rules.
class HomeGestures {
  HomeGestures._();

  /// Short MIUI-style handle — not a full-height side frame.
  static const sidebarHandleWidth = 6.0;
  static const sidebarHandleHeight = 88.0;
  static const sidebarExpandedWidth = 72.0;

  /// Always-visible island capsule (idle is a pill, not a 10px speck).
  static const islandIdleWidth = 128.0;
  static const islandIdleHeight = 36.0;

  /// Icon long-press is disabled in edit mode so [LongPressDraggable] wins.
  static bool iconLongPressEnabled({required bool editing}) => !editing;

  /// Empty-wallpaper long-press must not fight rearrange.
  static bool parentWallpaperLongPress({
    required bool editing,
    required bool selecting,
  }) =>
      !editing && !selecting;

  /// Grid scroll steals icon drags — lock it while rearranging.
  static bool gridScrollEnabled({required bool editing}) => !editing;

  /// Swipe-down only intercepts when the Morph notification bar is on.
  /// Off: do not steal the gesture — system shade stays available.
  static bool interceptSwipeDown({required bool notificationBar}) =>
      notificationBar;

  /// Pull-down on the island / top chrome opens the Morph shade.
  static bool openShadeFromTopPull({
    required bool notificationBar,
    required double primaryVelocity,
  }) =>
      notificationBar && primaryVelocity > 280;
}
