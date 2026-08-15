/// Home gesture policy. Pure — tests and HomeScreen share this.
library;

/// Wallpaper / icon gesture rules for Morph chrome + edit rearrange.
class HomeGestures {
  HomeGestures._();

  /// Icon long-press is disabled in edit mode so [LongPressDraggable] wins.
  static bool iconLongPressEnabled({required bool editing}) => !editing;

  /// Swipe-down only intercepts when the Morph notification bar is on.
  /// Off: do not steal the gesture — system shade stays available.
  static bool interceptSwipeDown({required bool notificationBar}) =>
      notificationBar;
}
