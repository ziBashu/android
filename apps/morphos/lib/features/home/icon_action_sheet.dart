import 'package:flutter/material.dart';

import '../../core/home_occupancy.dart';
import '../../core/models.dart';
import '../../core/morph_controller.dart';

Future<String?> showIconActionSheet({
  required BuildContext context,
  required MorphController controller,
  required MorphAppItem app,
}) {
  final p = controller.palette;
  final extras = IconActionMenu.extrasFor(
    id: app.id,
    packageName: app.packageName,
    label: controller.labelFor(app),
  );
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: p.panel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      Widget row(String label, {bool red = false}) {
        return ListTile(
          title: Text(
            label,
            style: TextStyle(
              color: red ? const Color(0xFFE53935) : p.ink,
              fontWeight: red ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          onTap: () => Navigator.pop(ctx, label),
        );
      }

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
              row('App info'),
              row('Select'),
              row('Hide'),
              row('Remove', red: true),
              row('Edit Homescreen'),
              for (final extra in extras) row(extra),
            ],
          ),
        ),
      );
    },
  );
}
