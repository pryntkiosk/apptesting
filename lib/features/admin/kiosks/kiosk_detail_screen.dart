import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/maps_launcher.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../models/app_user.dart';
import '../../../models/kiosk.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/kiosk_provider.dart';
import 'kiosk_form_screen.dart';

class KioskDetailScreen extends StatefulWidget {
  final String kioskId;
  const KioskDetailScreen({super.key, required this.kioskId});

  @override
  State<KioskDetailScreen> createState() => _KioskDetailScreenState();
}

class _KioskDetailScreenState extends State<KioskDetailScreen> {
  Kiosk? _kiosk;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final k = await context.read<KioskProvider>().getOne(widget.kioskId);
      setState(() => _kiosk = k);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _sendAlert(String type) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<KioskProvider>().sendAlert(widget.kioskId, type);
      messenger.showSnackBar(SnackBar(
        content: Text('$type refill alert sent to all delivery partners'),
        backgroundColor: AppTheme.success,
      ));
    } on ApiException catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppTheme.warning));
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete kiosk?'),
        content: Text(
            'This permanently removes "${_kiosk?.name}" and all its service requests.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await context.read<KioskProvider>().remove(widget.kioskId);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Kiosk deleted')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppTheme.danger));
    }
  }

  Future<void> _editLevels() async {
    final k = _kiosk!;
    final pagesCtl = TextEditingController(text: '${k.pagesRemaining}');
    final inkCtl = TextEditingController(text: '${k.inkLevel}');
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Update levels'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pagesCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Paper (pages)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: inkCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Ink (%)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (result == true) {
      await context.read<KioskProvider>().updateLevels(
            widget.kioskId,
            pages: int.tryParse(pagesCtl.text),
            ink: int.tryParse(inkCtl.text),
          );
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_kiosk?.name ?? 'Kiosk'),
        actions: [
          if (_kiosk != null) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => KioskFormScreen(existing: _kiosk)),
                );
                _load();
              },
            ),
            if (user.isMainAdmin)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: AppTheme.danger,
                onPressed: _delete,
              ),
          ],
        ],
      ),
      body: Builder(builder: (_) {
        if (_loading) return const LoadingView();
        if (_error != null) return ErrorView(message: _error!, onRetry: _load);
        final k = _kiosk!;
        return RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _infoCard(k, user),
              const SizedBox(height: 16),
              _levelsCard(k),
              const SizedBox(height: 16),
              if (k.hasCoordinates) _mapCard(k),
              const SizedBox(height: 16),
              _alertsCard(),
            ],
          ),
        );
      }),
    );
  }

  Widget _infoCard(Kiosk k, AppUser user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(k.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                StatusChip(
                  label: k.isOnline ? 'Online' : 'Offline',
                  color: k.isOnline ? AppTheme.success : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _row(Icons.tag, 'Kiosk ID', k.id),
            _row(Icons.school_outlined, 'Location', k.locationName),
            if (k.address.isNotEmpty)
              _row(Icons.location_on_outlined, 'Address', k.address),
            if (k.hasCoordinates)
              _row(Icons.my_location, 'Coordinates',
                  '${k.latitude}, ${k.longitude}'),
            _row(Icons.update, 'Last updated', Fmt.dateTime(k.lastUpdated ?? k.lastSeen)),
          ],
        ),
      ),
    );
  }

  Widget _levelsCard(Kiosk k) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Inventory Levels',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _editLevels,
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('Update'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LevelBar(
                label: 'Paper (${k.pagesRemaining} pages)',
                percent: k.paperLevelPct,
                icon: Icons.description_outlined,
                low: k.lowPaper),
            const SizedBox(height: 12),
            LevelBar(
                label: 'Ink',
                percent: k.inkLevel,
                icon: Icons.water_drop_outlined,
                low: k.lowInk),
          ],
        ),
      ),
    );
  }

  Widget _mapCard(Kiosk k) {
    final pos = LatLng(k.latitude!, k.longitude!);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: pos, zoom: 15),
              markers: {
                Marker(markerId: MarkerId(k.id), position: pos),
              },
              liteModeEnabled: true,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: OutlinedButton.icon(
              onPressed: () =>
                  MapsLauncher.navigateTo(k.latitude!, k.longitude!),
              icon: const Icon(Icons.navigation_outlined),
              label: const Text('Navigate'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Manual Alerts',
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Notify all delivery partners and create a service request.',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _sendAlert('paper'),
                    icon: const Icon(Icons.description_outlined),
                    label: const Text('Paper Refill'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _sendAlert('ink'),
                    icon: const Icon(Icons.water_drop_outlined),
                    label: const Text('Ink Refill'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 10),
          SizedBox(
              width: 96,
              child: Text(label,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
