import 'package:flutter/material.dart';

import 'from_zibashu_badge.dart';

/// Standard shell: app bar + optional footer badge.
class ZiBashuScaffold extends StatelessWidget {
  const ZiBashuScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showFromBadge = true,
    this.bottomNavigationBar,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showFromBadge;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      body: Column(
        children: [
          Expanded(child: body),
          if (showFromBadge)
            const SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: FromZiBashuBadge(compact: true),
              ),
            ),
        ],
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
