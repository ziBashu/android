import 'package:flutter/material.dart';
import 'package:zibashu_ui/zibashu_ui.dart';

import '../../core/morph_controller.dart';
import '../../widgets/morph_background.dart';
import '../../core/models.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.controller});

  final MorphController controller;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String? _focus;

  final _options = const [
    ('entertainment', 'Entertainment', Icons.movie_outlined, 'Media-first home'),
    ('productivity', 'Productivity', Icons.work_outline, 'Dock + cards workspace'),
    ('gaming', 'Gaming', Icons.sports_esports_outlined, 'Landscape morph ready'),
    ('minimal', 'Minimal', Icons.crop_free, 'Quiet single-column home'),
    ('creative', 'Creative', Icons.palette_outlined, 'Spatial glass layout'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final p = c.palette;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MorphBackground(
      wallpaperId: WallpaperId.cyberpunk,
      palette: p,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FromZiBashuBadge(compact: true, openWebsite: false),
              const SizedBox(height: 18),
              Text(
                'Welcome to MorphOS',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: p.ink,
                      fontSize: 30,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'A phone should not have one shape.\nIt becomes what you need right now.',
                style: TextStyle(color: p.muted, height: 1.4, fontSize: 15),
              ),
              const SizedBox(height: 10),
              Text(
                'How do you use your phone?',
                style: TextStyle(
                  color: p.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: _options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final o = _options[i];
                    final selected = _focus == o.$1;
                    return Material(
                      color: selected
                          ? p.accent.withValues(alpha: 0.28)
                          : p.panel,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => setState(() => _focus = o.$1),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected ? p.accent : p.panelBorder,
                              width: selected ? 1.6 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(o.$3, color: p.accentSecondary, size: 28),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      o.$2,
                                      style: TextStyle(
                                        color: p.ink,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      o.$4,
                                      style: TextStyle(color: p.muted, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              if (selected)
                                Icon(Icons.check_circle, color: p.accentSecondary),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _focus == null
                      ? null
                      : () => c.completeOnboarding(_focus!),
                  child: const Text('Create my environment'),
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
