import 'package:flutter/material.dart';
import 'package:zibashu_ui/zibashu_ui.dart';

class LicensesPage extends StatelessWidget {
  const LicensesPage({super.key});

  static const entries = [
    'Flutter and Dart SDK — BSD 3-Clause',
    'archive — Apache License 2.0',
    'image — MIT',
    'markdown — BSD 3-Clause',
    'html — BSD 3-Clause (Dart)',
    'xml — MIT',
    'path / path_provider — BSD 3-Clause',
    'zibashu_ui / zibashu_core — ziBashu',
  ];

  @override
  Widget build(BuildContext context) {
    return ZiBashuScaffold(
      title: 'Licenses',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            'Unfold uses license-compatible libraries. No GPL or AGPL code is copied into this app.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('• $e'),
            ),
        ],
      ),
    );
  }
}
