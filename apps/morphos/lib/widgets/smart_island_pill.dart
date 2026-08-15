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
      behavior: HitTestBehavior.deferToChild,
      onTap: onTap,
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) > HomeGestures.shadePullVelocity) {
          onPullDown?.call();
        }
      },
      child: activity.expanded ? _expanded() : _compact(),
    );
  }

  Widget _compact() {
    return Center(
      child: Container(
        width: HomeGestures.islandLiveWidth,
        height: HomeGestures.islandLiveHeight,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: Colors.white24),
        ),
        alignment: Alignment.center,
        child: Text(
          activity.compactLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _expanded() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                activity.title.isEmpty ? activity.compactLabel : activity.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              if (activity.subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  activity.subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
              if (activity.isMusic) ...[
                const SizedBox(height: 10),
                Slider(
                  value: activity.progress.clamp(0, 1),
                  onChanged: onSeek,
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
                        size: 32,
                      ),
                    ),
                    IconButton(
                      onPressed: onNext,
                      icon: const Icon(Icons.skip_next, color: Colors.white),
                    ),
                  ],
                ),
              ] else if (activity.elapsedLabel.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  activity.elapsedLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (onOpenShade != null)
                TextButton(
                  onPressed: onOpenShade,
                  child: const Text('Control center'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
