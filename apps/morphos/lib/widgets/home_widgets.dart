import 'package:flutter/material.dart';

import '../core/home_occupancy.dart';
import '../core/morph_controller.dart';
import '../core/notes_store.dart';
import '../core/productivity.dart';
import '../core/weather_service.dart';
import '../features/notes/notes_screen.dart';

class HomeWidgetStrip extends StatelessWidget {
  const HomeWidgetStrip({
    super.key,
    required this.controller,
    required this.kinds,
    required this.battery,
    required this.notes,
    required this.onSearch,
    required this.onRotate,
    required this.onLockRotate,
    required this.onWebSearch,
    this.weather,
    this.weatherBusy = false,
    this.browserLabel,
    this.onRefreshWeather,
  });

  final MorphController controller;
  final List<HomeWidgetKind> kinds;
  final BatterySnapshot battery;
  final NotesStore notes;
  final VoidCallback onSearch;
  final VoidCallback onRotate;
  final VoidCallback onLockRotate;
  final Future<void> Function(String query) onWebSearch;
  final WeatherSnapshot? weather;
  final bool weatherBusy;
  final String? browserLabel;
  final VoidCallback? onRefreshWeather;

  @override
  Widget build(BuildContext context) {
    if (kinds.isEmpty) return const SizedBox.shrink();
    final wide = MediaQuery.sizeOf(context).width - 32;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final kind in kinds)
            switch (kind) {
              HomeWidgetKind.clock => SizedBox(
                  width: wide,
                  child: ClockHomeWidget(),
                ),
              HomeWidgetKind.battery => BatteryHomeWidget(
                  snapshot: battery,
                  onTap: () => _showBatterySheet(context),
                ),
              HomeWidgetKind.rotate => RotateHomeWidget(
                  control: RotationControl(
                    action: controller.rotationAction,
                    locked: controller.rotationLocked,
                  ),
                  onCycle: onRotate,
                  onLock: onLockRotate,
                ),
              HomeWidgetKind.search => SearchHomeWidget(onTap: onSearch),
              HomeWidgetKind.notes => NotesHomeWidget(
                  store: notes,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => NotesScreen(
                          controller: controller,
                          store: notes,
                        ),
                      ),
                    );
                  },
                ),
              HomeWidgetKind.webSearch => SizedBox(
                  width: wide,
                  child: WebSearchHomeWidget(
                    browserLabel: browserLabel,
                    onSubmit: onWebSearch,
                  ),
                ),
              HomeWidgetKind.weather => WeatherHomeWidget(
                  snapshot: weather,
                  busy: weatherBusy,
                  onTap: onRefreshWeather ?? () {},
                ),
            },
        ],
      ),
    );
  }

  Future<void> _showBatterySheet(BuildContext context) async {
    final p = controller.palette;
    final b = battery;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Battery',
                style: TextStyle(
                  color: p.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              _row('Level', b.unknown ? '—' : '${b.level}%'),
              _row('Status', b.statusLabel),
              _row('Power source', b.powerSourceLabel),
              _row(
                'Temperature',
                b.temperatureC == null
                    ? '—'
                    : '${b.temperatureC!.toStringAsFixed(1)} °C',
              ),
              _row('Health', b.health),
              _row(
                'Voltage',
                b.voltageMv == null ? '—' : '${b.voltageMv} mV',
              ),
              _row('Technology', b.technology.isEmpty ? '—' : b.technology),
            ],
          ),
        );
      },
    );
  }

  Widget _row(String k, String v) {
    final p = controller.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(k, style: TextStyle(color: p.muted))),
          Text(v, style: TextStyle(color: p.ink, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class BatteryHomeWidget extends StatelessWidget {
  const BatteryHomeWidget({
    super.key,
    required this.snapshot,
    required this.onTap,
  });

  final BatterySnapshot snapshot;
  final VoidCallback onTap;

  Color get _color {
    switch (snapshot.colorKey) {
      case 'teal':
        return const Color(0xFF26A69A);
      case 'red':
        return const Color(0xFFE53935);
      case 'orange':
        return const Color(0xFFFB8C00);
      case 'amber':
        return const Color(0xFFFDD835);
      case 'green':
        return const Color(0xFF66BB6A);
      default:
        return const Color(0xFF90A4AE);
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = snapshot.unknown ? 0.0 : snapshot.level.clamp(0, 100) / 100;
    return _GlassCard(
      onTap: onTap,
      child: SizedBox(
        width: 148,
        child: Row(
          children: [
            SizedBox(
              width: 42,
              height: 42,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: snapshot.unknown ? null : level,
                    color: _color,
                    backgroundColor: Colors.white24,
                    strokeWidth: 4,
                  ),
                  Icon(
                    snapshot.charging
                        ? Icons.bolt
                        : Icons.battery_std,
                    size: 16,
                    color: _color,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    snapshot.unknown ? '—%' : '${snapshot.level}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${snapshot.statusLabel} · ${snapshot.powerSourceLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RotateHomeWidget extends StatelessWidget {
  const RotateHomeWidget({
    super.key,
    required this.control,
    required this.onCycle,
    required this.onLock,
  });

  final RotationControl control;
  final VoidCallback onCycle;
  final VoidCallback onLock;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      onTap: onCycle,
      child: SizedBox(
        width: 148,
        child: Row(
          children: [
            const Icon(Icons.screen_rotation, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                control.action.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: control.locked ? 'Unlock rotation' : 'Lock rotation',
              onPressed: onLock,
              icon: Icon(
                control.locked ? Icons.lock : Icons.lock_open,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchHomeWidget extends StatelessWidget {
  const SearchHomeWidget({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      onTap: onTap,
      child: const SizedBox(
        width: 148,
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Search',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotesHomeWidget extends StatelessWidget {
  const NotesHomeWidget({
    super.key,
    required this.store,
    required this.onTap,
  });

  final NotesStore store;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final first = store.notes.isEmpty ? 'Notes' : store.notes.first.listLine;
    return _GlassCard(
      onTap: onTap,
      child: SizedBox(
        width: 148,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              first,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClockHomeWidget extends StatelessWidget {
  const ClockHomeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final now = TimeOfDay.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 2, 6, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          time,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 56,
            fontWeight: FontWeight.w200,
            letterSpacing: -1.5,
            height: 1.0,
            shadows: [Shadow(blurRadius: 16, color: Colors.black45)],
          ),
        ),
      ),
    );
  }
}

class WebSearchHomeWidget extends StatefulWidget {
  const WebSearchHomeWidget({
    super.key,
    required this.onSubmit,
    this.browserLabel,
  });

  final Future<void> Function(String query) onSubmit;
  final String? browserLabel;

  @override
  State<WebSearchHomeWidget> createState() => _WebSearchHomeWidgetState();
}

class _WebSearchHomeWidgetState extends State<WebSearchHomeWidget> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    await widget.onSubmit(q);
  }

  @override
  Widget build(BuildContext context) {
    final hint = (widget.browserLabel != null && widget.browserLabel!.isNotEmpty)
        ? 'Search with ${widget.browserLabel}'
        : 'Search the web';
    return _GlassCard(
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _ctrl,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              cursorColor: Colors.white,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _go(),
              decoration: InputDecoration(
                isDense: true,
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: _go,
            icon: const Icon(Icons.north_east, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}

class WeatherHomeWidget extends StatelessWidget {
  const WeatherHomeWidget({
    super.key,
    required this.snapshot,
    required this.onTap,
    this.busy = false,
  });

  final WeatherSnapshot? snapshot;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final w = snapshot;
    return _GlassCard(
      onTap: onTap,
      child: SizedBox(
        width: 168,
        child: busy
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Text('Weather…', style: TextStyle(color: Colors.white)),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    w?.place ?? 'Weather',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    w == null ? '—' : w.tempLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      height: 1.05,
                    ),
                  ),
                  Text(
                    w?.condition ?? 'Tap to load',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
      ),
    );
  }
}

class SmallSearchPill extends StatelessWidget {
  const SmallSearchPill({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search, size: 16, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'Search',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
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

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.28),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: child,
        ),
      ),
    );
  }
}
