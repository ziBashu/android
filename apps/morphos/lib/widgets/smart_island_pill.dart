import 'package:flutter/material.dart';

import '../core/home_gestures.dart';
import '../core/smart_island.dart';

class SmartIslandPill extends StatelessWidget {
  const SmartIslandPill({
    super.key,
    required this.activity,
    required this.onTap,
    this.onPullDown,
    this.onOpenShade,
    this.onSeek,
    this.onPrevious,
    this.onPause,
    this.onNext,
  });

  final IslandActivity activity;
  final VoidCallback onTap;
  final VoidCallback? onPullDown;
  final VoidCallback? onOpenShade;
  final ValueChanged<double>? onSeek;
  final VoidCallback? onPrevious;
  final VoidCallback? onPause;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    if (!HomeGestures.islandDrawn(activity)) {
      return const SizedBox.shrink();
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) > HomeGestures.shadePullVelocity) {
          onPullDown?.call();
        }
      },
      child: AnimatedSize(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: activity.expanded ? _expanded() : _compact(),
      ),
    );
  }

  Widget _compact() {
    return Center(
      child: Container(
        width: HomeGestures.islandCompactWidth,
        height: HomeGestures.islandCompactHeight,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xF20A0A0C),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              activity.isMusic
                  ? (activity.playing
                      ? Icons.graphic_eq_rounded
                      : Icons.pause_rounded)
                  : _kindIcon,
              size: 15,
              color: const Color(0xFFE8FF6A),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                activity.compactLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData get _kindIcon {
    return switch (activity.kind) {
      IslandKind.timer => Icons.timer_outlined,
      IslandKind.download => Icons.downloading,
      IslandKind.navigation => Icons.near_me_rounded,
      IslandKind.call => Icons.call,
      IslandKind.recording => Icons.fiber_manual_record,
      IslandKind.music => Icons.graphic_eq_rounded,
      IslandKind.idle => Icons.circle,
    };
  }

  Widget _expanded() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          decoration: BoxDecoration(
            color: const Color(0xF2141418),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1F24),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_kindIcon, color: const Color(0xFFE8FF6A), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title.isEmpty
                              ? activity.compactLabel
                              : activity.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (activity.subtitle.isNotEmpty)
                          Text(
                            activity.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (onOpenShade != null)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: onOpenShade,
                      icon: const Icon(
                        Icons.tune_rounded,
                        color: Colors.white54,
                        size: 18,
                      ),
                    ),
                ],
              ),
              if (activity.isMusic) ...[
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: SliderComponentShape.noOverlay,
                    activeTrackColor: const Color(0xFFE8FF6A),
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: activity.progress.clamp(0, 1),
                    onChanged: onSeek,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: onPrevious,
                      icon: const Icon(Icons.skip_previous, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: onPause,
                      icon: Icon(
                        activity.playing ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    IconButton(
                      onPressed: onNext,
                      icon: const Icon(Icons.skip_next, color: Colors.white),
                    ),
                  ],
                ),
              ] else if (activity.elapsedLabel.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  activity.elapsedLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
