import 'package:flutter/material.dart';

import '../../core/morph_controller.dart';
import '../../core/productivity.dart';
import '../../core/shade_tiles.dart';
import '../../widgets/glass_panel.dart';

Future<void> showMorphShade(
  BuildContext context,
  MorphController controller, {
  required ShadeSnapshot snapshot,
  required Future<ShadeSnapshot> Function() refresh,
  required Future<void> Function(ShadeTileId id) onToggle,
  required Future<void> Function(double value) onBrightness,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Morph shade',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 220),
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
  });

  final MorphController controller;
  final ShadeSnapshot initial;
  final Future<ShadeSnapshot> Function() refresh;
  final Future<void> Function(ShadeTileId id) onToggle;
  final Future<void> Function(double value) onBrightness;

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
    final p = widget.controller.palette;
    final now = _snap.now;
    final weekday = _weekday(now.weekday);
    final month = _month(now.month);
    final tiles = _snap.expanded
        ? [..._snap.firstPageTiles, ..._snap.extraTiles]
        : _snap.firstPageTiles;
    final time =
        '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      child: Material(
        color: Colors.transparent,
        child: GlassPanel(
          palette: p,
          radius: 28,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          color: p.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_snap.batteryPercent.clamp(0, 100)}%',
                        style: TextStyle(
                          color: p.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$weekday, $month ${now.day}',
                    style: TextStyle(color: p.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final tile in tiles)
                        _ShadeTileCard(
                          tile: tile,
                          onTap: () async {
                            await widget.onToggle(tile.id);
                            await _reload();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() {
                      _snap = _snap.expanded ? _snap.collapse() : _snap.expand();
                    }),
                    child: Text(_snap.expanded ? 'Show less' : 'Show more'),
                  ),
                  Text(
                    'Brightness',
                    style: TextStyle(color: p.muted, fontSize: 12),
                  ),
                  Slider(
                    value: _snap.brightness.clamp(0, 1),
                    onChanged: (v) async {
                      setState(() => _snap = _snap.copyWith(brightness: v));
                      await widget.onBrightness(v);
                    },
                  ),
                  if (_snap.media != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _snap.media!.title,
                      style: TextStyle(
                        color: p.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_snap.media!.artist.isNotEmpty)
                      Text(
                        _snap.media!.artist,
                        style: TextStyle(color: p.muted, fontSize: 12),
                      ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'NOTIFICATIONS',
                    style: TextStyle(
                      color: p.muted,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (_snap.notifications.isEmpty)
                    Text(
                      'No notifications',
                      style: TextStyle(color: p.muted, fontSize: 13),
                    )
                  else
                    for (final n in _snap.notifications.take(8))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.title,
                              style: TextStyle(
                                color: p.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (n.body.isNotEmpty)
                              Text(
                                n.body,
                                style: TextStyle(color: p.muted, fontSize: 12),
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

class _ShadeTileCard extends StatelessWidget {
  const _ShadeTileCard({required this.tile, required this.onTap});

  final ShadeTileView tile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final on = tile.on;
    return Material(
      color: on ? const Color(0xFFE8F5E9) : const Color(0x33212121),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 108,
          height: 88,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tile.id.shortLabel,
                  style: TextStyle(
                    color: on ? Colors.black87 : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  tile.stateLabel,
                  style: TextStyle(
                    color: on ? Colors.black87 : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                if (tile.detail.isNotEmpty)
                  Text(
                    tile.detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: on ? Colors.black54 : Colors.white70,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Default tiles when native shade state is unavailable (tests / desktop).
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
