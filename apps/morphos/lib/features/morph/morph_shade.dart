import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/morph_controller.dart';
import '../../core/productivity.dart';
import '../../core/shade_tiles.dart';

Future<void> showMorphShade(
  BuildContext context,
  MorphController controller, {
  required ShadeSnapshot snapshot,
  required Future<ShadeSnapshot> Function() refresh,
  required Future<void> Function(ShadeTileId id) onToggle,
  required Future<void> Function(double value) onBrightness,
  Future<void> Function(String command)? onMediaCommand,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Morph shade',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (ctx, _, __) {
      return SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: _MorphShadeSheet(
            controller: controller,
            initial: snapshot,
            refresh: refresh,
            onToggle: onToggle,
            onBrightness: onBrightness,
            onMediaCommand: onMediaCommand,
          ),
        ),
      );
    },
    transitionBuilder: (ctx, anim, _, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
  );
}

class _MorphShadeSheet extends StatefulWidget {
  const _MorphShadeSheet({
    required this.controller,
    required this.initial,
    required this.refresh,
    required this.onToggle,
    required this.onBrightness,
    this.onMediaCommand,
  });

  final MorphController controller;
  final ShadeSnapshot initial;
  final Future<ShadeSnapshot> Function() refresh;
  final Future<void> Function(ShadeTileId id) onToggle;
  final Future<void> Function(double value) onBrightness;
  final Future<void> Function(String command)? onMediaCommand;

  @override
  State<_MorphShadeSheet> createState() => _MorphShadeSheetState();
}

class _MorphShadeSheetState extends State<_MorphShadeSheet> {
  late ShadeSnapshot _snap;

  @override
  void initState() {
    super.initState();
    _snap = widget.initial;
  }

  Future<void> _reload() async {
    final next = await widget.refresh();
    if (mounted) setState(() => _snap = next.copyWith(expanded: _snap.expanded));
  }

  @override
  Widget build(BuildContext context) {
    final now = _snap.now;
    final tiles = _snap.expanded
        ? [..._snap.firstPageTiles, ..._snap.extraTiles]
        : _snap.firstPageTiles;
    final heroes = tiles.take(4).toList();
    final rest = tiles.skip(4).toList();
    final time =
        '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')}';
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    final date =
        '${_weekday(now.weekday)}  ·  ${_month(now.month)} ${now.day}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.82,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xE6141824),
                  const Color(0xCC0B1020),
                  Colors.black.withValues(alpha: 0.82),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              borderRadius: BorderRadius.circular(32),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        time,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w200,
                          fontSize: 44,
                          height: 0.95,
                          letterSpacing: -1.4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          ampm,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '${_snap.batteryPercent.clamp(0, 100)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.35,
                    children: [
                      for (final t in heroes)
                        _HeroTile(
                          tile: t,
                          onTap: () async {
                            await widget.onToggle(t.id);
                            await _reload();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in rest)
                        _ChipTile(
                          tile: t,
                          onTap: () async {
                            await widget.onToggle(t.id);
                            await _reload();
                          },
                        ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _snap = _snap.expanded ? _snap.collapse() : _snap.expand();
                    }),
                    child: Text(
                      _snap.expanded ? 'Show less' : 'Show more',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.wb_sunny_outlined,
                          color: Colors.white54, size: 16),
                      Expanded(
                        child: Slider(
                          value: _snap.brightness.clamp(0, 1),
                          activeColor: Colors.white,
                          onChanged: (v) async {
                            setState(() => _snap = _snap.copyWith(brightness: v));
                            await widget.onBrightness(v);
                          },
                        ),
                      ),
                      const Icon(Icons.wb_sunny, color: Colors.white, size: 18),
                    ],
                  ),
                  if (_snap.media != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _snap.media!.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          if (_snap.media!.artist.isNotEmpty)
                            Text(
                              _snap.media!.artist,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          if (_snap.media!.hasTransport) ...[
                            Slider(
                              value: _snap.media!.progress.clamp(0, 1),
                              onChanged: widget.onMediaCommand == null
                                  ? null
                                  : (v) async {
                                      setState(() {
                                        _snap = _snap.copyWith(
                                          media: ShadeMedia(
                                            title: _snap.media!.title,
                                            artist: _snap.media!.artist,
                                            playing: _snap.media!.playing,
                                            progress: v,
                                          ),
                                        );
                                      });
                                      await widget.onMediaCommand!('seek:$v');
                                    },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: widget.onMediaCommand == null
                                      ? null
                                      : () => widget.onMediaCommand!('previous'),
                                  icon: const Icon(
                                    Icons.skip_previous,
                                    color: Colors.white,
                                  ),
                                ),
                                IconButton(
                                  onPressed: widget.onMediaCommand == null
                                      ? null
                                      : () => widget.onMediaCommand!('pause'),
                                  icon: Icon(
                                    _snap.media!.playing
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                IconButton(
                                  onPressed: widget.onMediaCommand == null
                                      ? null
                                      : () => widget.onMediaCommand!('next'),
                                  icon: const Icon(
                                    Icons.skip_next,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const Text(
                    'NOW',
                    style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_snap.notifications.isEmpty)
                    const Text(
                      'Quiet for now',
                      style: TextStyle(color: Colors.white54),
                    )
                  else
                    for (final n in _snap.notifications.take(6))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (n.body.isNotEmpty)
                              Text(
                                n.body,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _weekday(int d) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[(d - 1).clamp(0, 6)];
  }

  String _month(int m) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[(m - 1).clamp(0, 11)];
  }
}

class _HeroTile extends StatelessWidget {
  const _HeroTile({required this.tile, required this.onTap});

  final ShadeTileView tile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final on = tile.on;
    return Material(
      color: on ? const Color(0xFFE8F0FF) : const Color(0x22FFFFFF),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tile.id.shortLabel,
                style: TextStyle(
                  color: on ? const Color(0xFF10203A) : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Text(
                tile.stateLabel,
                style: TextStyle(
                  color: on ? const Color(0xFF10203A) : Colors.white,
                  fontWeight: FontWeight.w300,
                  fontSize: 26,
                  height: 1,
                ),
              ),
              if (tile.detail.isNotEmpty)
                Text(
                  tile.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: on ? const Color(0x9910203A) : Colors.white70,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipTile extends StatelessWidget {
  const _ChipTile({required this.tile, required this.onTap});

  final ShadeTileView tile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final on = tile.on;
    return Material(
      color: on ? const Color(0xCCFFFFFF) : const Color(0x18FFFFFF),
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            '${tile.id.shortLabel}  ${tile.stateLabel}',
            style: TextStyle(
              color: on ? const Color(0xFF10203A) : Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

ShadeSnapshot shadeSnapshotFallback({
  required BatterySnapshot battery,
  DateTime? now,
}) {
  return ShadeSnapshot(
    now: now ?? DateTime.now(),
    batteryPercent: battery.unknown ? 0 : battery.level.clamp(0, 100),
    tiles: [
      for (final id in ShadeTileId.values) ShadeTileView(id: id, on: false),
    ],
  );
}
