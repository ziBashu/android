import 'package:flutter/material.dart';

import '../../core/home_occupancy.dart';
import '../../core/models.dart';
import '../../core/morph_controller.dart';

Future<String?> showIconMinusSheet({
  required BuildContext context,
  required MorphController controller,
  required MorphAppItem app,
}) {
  final p = controller.palette;
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: p.panel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                controller.labelFor(app),
                style: TextStyle(
                  color: p.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text(IconMinusMenu.deleteFromHomeScreen),
                onTap: () =>
                    Navigator.pop(ctx, IconMinusMenu.deleteFromHomeScreen),
              ),
              ListTile(
                title: const Text(
                  IconMinusMenu.deleteApplication,
                  style: TextStyle(color: Color(0xFFE53935)),
                ),
                onTap: () =>
                    Navigator.pop(ctx, IconMinusMenu.deleteApplication),
              ),
              ListTile(
                title: const Text(IconMinusMenu.cancel),
                onTap: () => Navigator.pop(ctx, IconMinusMenu.cancel),
              ),
            ],
          ),
        ),
      );
    },
  );
}
