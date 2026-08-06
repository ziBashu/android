import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zibashu_core/zibashu_core.dart';
import 'package:zibashu_ui/zibashu_ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HubApp());
}

class HubApp extends StatelessWidget {
  const HubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ziBashu Hub',
      debugShowCheckedModeBanner: false,
      theme: buildZiBashuTheme(),
      home: const HubHomePage(),
    );
  }
}

class HubHomePage extends StatelessWidget {
  const HubHomePage({super.key});

  Future<void> _openWeb(String? route) async {
    final path = (route == null || route.isEmpty) ? '/' : route;
    final uri = Uri.parse('${ApiConfig.websiteUrl}$path');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final apps = kFamilyCatalog;

    return ZiBashuScaffold(
      title: 'ziBashu Hub',
      actions: [
        IconButton(
          tooltip: 'Open ziBashu on the web',
          onPressed: () => _openWeb('/'),
          icon: const Icon(Icons.language),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'Apps for the ziBashu system',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Each APK is a separate product. Install from warehub, or open the matching surface on the web.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ZiBashuBrand.ink.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 20),
          ...apps.map((app) => _AppCard(
                app: app,
                onOpenWeb: () => _openWeb(app.webRoute),
              )),
        ],
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  const _AppCard({
    required this.app,
    required this.onOpenWeb,
  });

  final FamilyApp app;
  final VoidCallback onOpenWeb;

  @override
  Widget build(BuildContext context) {
    final accent = Color(app.accentHex);
    final isHub = app.slug == 'hub';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _iconFor(app.surface),
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.name, style: Theme.of(context).textTheme.titleLarge),
                      Text(
                        app.packageId,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: ZiBashuBrand.ink.withValues(alpha: 0.5),
                            ),
                      ),
                    ],
                  ),
                ),
                if (!app.available)
                  Chip(
                    label: const Text('Soon'),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: ZiBashuBrand.mist,
                  )
                else if (isHub)
                  Chip(
                    label: const Text('This app'),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: accent.withValues(alpha: 0.15),
                    labelStyle: TextStyle(color: accent, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(app.blurb),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onOpenWeb,
                  icon: const Icon(Icons.open_in_browser, size: 18),
                  label: const Text('Open on web'),
                ),
                if (app.available && !isHub)
                  FilledButton.tonal(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Install ${app.name} from ziBashu warehub when available '
                            '(package ${app.packageId}).',
                          ),
                        ),
                      );
                    },
                    child: const Text('Warehub install'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String surface) {
    switch (surface) {
      case 'messaging':
        return Icons.forum_outlined;
      case 'lab':
        return Icons.science_outlined;
      case 'studio':
        return Icons.palette_outlined;
      case 'tool':
        return Icons.build_outlined;
      case 'hub':
      default:
        return Icons.apps_outlined;
    }
  }
}
