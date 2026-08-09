import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/morph_controller.dart';
import '../../core/system_morph_bridge.dart';
import '../../widgets/glass_panel.dart';

/// Explain + open the system Home picker (third-party launcher flow).
///
/// Android never allows silent takeover — user must choose MorphOS in Settings
/// or the RoleManager dialog (same as Nova / Niagara).
Future<void> showSetHomeSheet({
  required BuildContext context,
  required MorphController controller,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SetHomeSheet(controller: controller),
  );
}

class _SetHomeSheet extends StatefulWidget {
  const _SetHomeSheet({required this.controller});

  final MorphController controller;

  @override
  State<_SetHomeSheet> createState() => _SetHomeSheetState();
}

class _SetHomeSheetState extends State<_SetHomeSheet> {
  MorphController get c => widget.controller;
  bool _busy = false;
  HomeRoleResult? _last;
  HomeRoleResult? _probe;

  @override
  void initState() {
    super.initState();
    _refreshProbe();
  }

  Future<void> _refreshProbe() async {
    final probe = await SystemMorphBridge.probeHomeRegistration();
    await c.refreshSystemStatus();
    if (!mounted) return;
    setState(() => _probe = probe);
  }

  Future<void> _chooseHome() async {
    setState(() => _busy = true);
    HapticFeedback.selectionClick();
    final result = await SystemMorphBridge.requestHomeRole();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await c.refreshSystemStatus();
    final probe = await SystemMorphBridge.probeHomeRegistration();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _last = result;
      _probe = probe;
    });
  }

  Future<void> _openSettings() async {
    setState(() => _busy = true);
    await SystemMorphBridge.openHomeSettings();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await c.refreshSystemStatus();
    if (!mounted) return;
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final p = c.palette;
    final isDefault = c.systemStatus.isDefaultHome ||
        (_last?.isDefaultHome ?? false) ||
        (_probe?.isDefaultHome ?? false);
    final isCandidate =
        _probe?.isHomeCandidate ?? c.systemStatus.isHomeCandidate;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: GlassPanel(
        palette: p,
        radius: 24,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: p.muted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text(
              'Set MorphOS as Home',
              style: TextStyle(
                color: p.ink,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'MorphOS is a third-party launcher (like Nova). Android never lets '
              'an app silently replace the Home screen — you must choose it once '
              'in the system dialog or Settings → Default apps → Home app.',
              style: TextStyle(color: p.muted, height: 1.4, fontSize: 13),
            ),
            const SizedBox(height: 14),
            _statusRow(
              p,
              ok: isCandidate,
              title: isCandidate
                  ? 'Registered as Home candidate'
                  : 'Not registered as Home',
              detail: isCandidate
                  ? 'PackageManager sees MAIN + HOME + DEFAULT on MorphOS.'
                  : 'Reinstall the APK — Home filter missing on device.',
            ),
            _statusRow(
              p,
              ok: isDefault,
              title: isDefault
                  ? 'MorphOS is default Home'
                  : 'Not yet the default Home',
              detail: isDefault
                  ? 'Press the Home button — it should open MorphOS.'
                  : 'Tap “Choose MorphOS as Home” and select MorphOS.',
            ),
            if (_last != null) ...[
              const SizedBox(height: 8),
              Text(
                _last!.message,
                style: TextStyle(
                  color: _last!.ok ? p.accentSecondary : const Color(0xFFFF8A80),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _chooseHome,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.home_filled),
              label: Text(
                isDefault ? 'Open Home settings' : 'Choose MorphOS as Home',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _openSettings,
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Open system Home settings'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : _refreshProbe,
              child: const Text('Refresh status'),
            ),
            const SizedBox(height: 4),
            Text(
              'Manual path: Settings → Apps → Default apps → Home app → MorphOS',
              style: TextStyle(color: p.muted, fontSize: 11, height: 1.35),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusRow(
    dynamic p, {
    required bool ok,
    required String title,
    required String detail,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.radio_button_unchecked,
            color: ok ? p.accentSecondary : p.muted,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: p.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  detail,
                  style: TextStyle(color: p.muted, fontSize: 11, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
