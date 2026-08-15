/// Home gesture + chrome metrics. Pure — tests, HomeScreen, and overlay share this.
library;

import 'chrome_flags.dart';
import 'smart_island.dart';

/// Who should own a downward pull that started at [startY].
enum ShadeOwner {
  /// Upmost / status-bar band — leave the OEM shade alone.
  system,

  /// Lower-upper band while Morph notification bar is on.
  morph,

  /// Morph layer off, or the pull is outside both bands.
  none,
}

/// Wallpaper / icon / sidebar / island rules.
class HomeGestures {
  HomeGestures._();

  /// Visible nub inside the hit target — not a full-height side frame.
  static const sidebarHandleWidth = 10.0;
  static const sidebarHandleHeight = 88.0;
  static const sidebarExpandedWidth = 68.0;

  /// Finger-sized tap / inward-swipe target. Strictly easier than 5×36.
  static const sidebarHitWidth = 32.0;
  static const sidebarHitHeight = 128.0;

  /// Idle Morph island reserves no chrome. Live activities use the live size.
  static const islandIdleWidth = 0.0;
  static const islandIdleHeight = 0.0;
  static const islandLiveWidth = 220.0;
  static const islandLiveHeight = 36.0;

  /// Overlay live island sits below the OEM cutout / Magic Capsule.
  static const islandOverlayTopInset = 56.0;

  /// Upmost band (status bar). Pulls that start here are the system shade.
  static const statusBarBandHeight = 32.0;

  /// Lower-upper band ends here. Pulls that start in
  /// [statusBarBandHeight, morphShadeBandBottom] may open Morph shade.
  static const morphShadeBandBottom = 108.0;

  static const shadePullVelocity = 280.0;

  static double get morphShadeBandHeight =>
      morphShadeBandBottom - statusBarBandHeight;

  /// Previous 5×36 rim line — new hit target must beat this area.
  static const double legacySidebarHitArea = 5.0 * 36.0;

  static double get sidebarHitArea => sidebarHitWidth * sidebarHitHeight;

  static bool sidebarHitContains({
    required double inwardFromRim,
    required double alongFromCenter,
  }) {
    if (inwardFromRim < 0) return false;
    return inwardFromRim <= sidebarHitWidth &&
        alongFromCenter.abs() <= sidebarHitHeight / 2;
  }

  /// Inward swipe that starts near the placed rim nub.
  static bool openSidebarFromRimSwipe({
    required ScreenRim rim,
    required double startX,
    required double startY,
    required double dx,
    required double dy,
    required double screenW,
    required double screenH,
    required double along,
  }) {
    if (screenW <= 0 || screenH <= 0) return false;
    final vertical = rim == ScreenRim.left || rim == ScreenRim.right;
    final alongPos = vertical ? startY : startX;
    final extent = vertical ? screenH : screenW;
    final center = along.clamp(0.08, 0.92) * extent;
    if ((alongPos - center).abs() > sidebarHitHeight / 2 + 24) return false;

    const near = 40.0;
    const minInward = 20.0;
    return switch (rim) {
      ScreenRim.left => startX <= near && dx >= minInward,
      ScreenRim.right => startX >= screenW - near && dx <= -minInward,
      ScreenRim.top => startY <= near && dy >= minInward,
      ScreenRim.bottom => startY >= screenH - near && dy <= -minInward,
    };
  }

  static double islandOccupancyHeight(IslandActivity activity) =>
      activity.isIdle ? 0 : islandLiveHeight;

  static bool islandDrawn(IslandActivity activity) => !activity.isIdle;

  static bool overlayIslandShown(IslandActivity activity) => !activity.isIdle;

  /// Overlay must never place a full-width steal on the status-bar edge.
  static const bool overlayStealsUpmostEdge = false;

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

  /// Decide who owns a downward pull. [startY] is global / screen Y.
  static ShadeOwner shadeOwnerForPull({
    required bool notificationBar,
    required double startY,
    required double primaryVelocity,
  }) {
    if (!notificationBar) return ShadeOwner.none;
    if (startY < statusBarBandHeight) return ShadeOwner.system;
    if (startY <= morphShadeBandBottom &&
        primaryVelocity > shadePullVelocity) {
      return ShadeOwner.morph;
    }
    return ShadeOwner.none;
  }

  /// Pull-down in the lower-upper band opens the Morph shade.
  ///
  /// [startY] defaults into that band so callers that only have velocity
  /// still map to Morph when the layer is on.
  static bool openShadeFromTopPull({
    required bool notificationBar,
    required double primaryVelocity,
    double startY = 56,
  }) =>
      shadeOwnerForPull(
        notificationBar: notificationBar,
        startY: startY,
        primaryVelocity: primaryVelocity,
      ) ==
      ShadeOwner.morph;
}
