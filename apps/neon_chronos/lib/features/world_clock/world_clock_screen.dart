import 'package:flutter/material.dart';

import '../../core/clock_engine/clock_format.dart';
import '../../core/clock_engine/clock_ticker.dart';
import '../../core/sound/sound_service.dart';
import '../../core/storage/settings_controller.dart';
import '../../core/theme_engine/neon_theme.dart';
import '../../widgets/glass_panel.dart';
import 'city_catalog.dart';
import 'world_clock_controller.dart';

class WorldClockScreen extends StatefulWidget {
  const WorldClockScreen({
    super.key,
    required this.ticker,
    required this.settings,
    required this.world,
    required this.sound,
  });

  final ClockTicker ticker;
  final SettingsController settings;
  final WorldClockController world;
  final SoundService sound;

  @override
  State<WorldClockScreen> createState() => _WorldClockScreenState();
}

class _WorldClockScreenState extends State<WorldClockScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openAdd() async {
    await widget.sound.click();
    if (!mounted) return;
    final primary = widget.settings.settings.accent.primary;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: NeonColors.surface,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final results = searchCities(_search.text);
            final selected = widget.world.cities.map((c) => c.id).toSet();
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.paddingOf(ctx).bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ADD LOCATION',
                    style: TextStyle(
                      color: primary,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _search,
                    style: const TextStyle(color: NeonColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search city…',
                      hintStyle: TextStyle(
                        color: NeonColors.textSecondary.withValues(alpha: 0.6),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primary.withValues(alpha: 0.35)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primary),
                      ),
                    ),
                    onChanged: (_) => setModal(() {}),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 320,
                    child: ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (_, i) {
                        final c = results[i];
                        final on = selected.contains(c.id);
                        return ListTile(
                          title: Text(
                            c.name,
                            style: const TextStyle(color: NeonColors.textPrimary),
                          ),
                          subtitle: Text(
                            '${c.region} · ${c.offsetLabel}',
                            style: const TextStyle(color: NeonColors.textSecondary),
                          ),
                          trailing: Icon(
                            on ? Icons.check_circle : Icons.add_circle_outline,
                            color: on ? NeonColors.ok : primary,
                          ),
                          onTap: () async {
                            if (on) {
                              await widget.world.removeCity(c.id);
                            } else {
                              await widget.world.addCity(c.id);
                            }
                            await widget.sound.click();
                            setModal(() {});
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    _search.clear();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.ticker, widget.settings, widget.world]),
      builder: (context, _) {
        final s = widget.settings.settings;
        final primary = s.accent.primary;
        final secondary = s.accent.secondary;
        final local = widget.ticker.now;
        final utc = DateTime.now().toUtc();
        final cities = widget.world.cities;

        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Text(
                      'WORLD NETWORK',
                      style: TextStyle(
                        color: primary,
                        fontSize: 13,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _openAdd,
                      icon: Icon(Icons.add_location_alt_outlined, color: primary),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassPanel(
                  accent: primary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionLabel('Local Time', color: secondary),
                      const SizedBox(height: 4),
                      Text(
                        ClockFormat.timeHms(local, hour24: s.hour24),
                        style: TextStyle(
                          color: primary,
                          fontSize: 32,
                          fontWeight: FontWeight.w300,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          shadows: neonGlow(primary, blur: 12),
                        ),
                      ),
                      Text(
                        'Device locale',
                        style: TextStyle(
                          color: NeonColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: cities.isEmpty
                    ? Center(
                        child: Text(
                          'No cities — tap + to add',
                          style: TextStyle(color: NeonColors.textSecondary),
                        ),
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: cities.length,
                        onReorder: (a, b) async {
                          await widget.world.reorder(a, b);
                          await widget.sound.click();
                        },
                        itemBuilder: (context, i) {
                          final c = cities[i];
                          final t = c.at(utc);
                          return Padding(
                            key: ValueKey(c.id),
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GlassPanel(
                              accent: i.isEven ? primary : secondary,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.name.toUpperCase(),
                                          style: TextStyle(
                                            color: NeonColors.textSecondary,
                                            fontSize: 11,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        Text(
                                          ClockFormat.timeHm(t, hour24: s.hour24),
                                          style: TextStyle(
                                            color: primary,
                                            fontSize: 26,
                                            fontWeight: FontWeight.w300,
                                            fontFeatures: const [
                                              FontFeature.tabularFigures()
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${c.region} · ${c.offsetLabel}',
                                          style: const TextStyle(
                                            color: NeonColors.textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      await widget.world.removeCity(c.id);
                                      await widget.sound.click();
                                    },
                                    icon: Icon(
                                      Icons.close,
                                      color: NeonColors.textSecondary.withValues(alpha: 0.7),
                                      size: 18,
                                    ),
                                  ),
                                  Icon(
                                    Icons.drag_handle,
                                    color: secondary.withValues(alpha: 0.5),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
