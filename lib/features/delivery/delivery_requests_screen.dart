import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/maps_launcher.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/service_request.dart';
import '../../providers/request_provider.dart';

/// initialTab: 0 = Available, 1 = My Tasks
class DeliveryRequestsScreen extends StatefulWidget {
  final int initialTab;
  const DeliveryRequestsScreen({super.key, this.initialTab = 0});

  @override
  State<DeliveryRequestsScreen> createState() => _DeliveryRequestsScreenState();
}

class _DeliveryRequestsScreenState extends State<DeliveryRequestsScreen> {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    _poll = Timer.periodic(AppConfig.pollInterval, (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() => context.read<RequestProvider>().loadForDelivery();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RequestProvider>();
    final showAvailable = widget.initialTab == 0;
    final items = showAvailable ? p.available : p.assigned;

    if (p.loading && items.isEmpty) return const LoadingView();
    if (p.error != null && items.isEmpty) {
      return ErrorView(message: p.error!, onRetry: _refresh);
    }
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            EmptyView(
              icon: showAvailable
                  ? Icons.inbox_outlined
                  : Icons.assignment_turned_in_outlined,
              title: showAvailable
                  ? 'No available requests'
                  : 'No assigned tasks',
              subtitle: showAvailable
                  ? 'New refill requests will appear here.'
                  : 'Accept a request to get started.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _RequestCard(
          request: items[i],
          showAccept: showAvailable,
          onChanged: _refresh,
        ),
      ),
    );
  }
}

class _RequestCard extends StatefulWidget {
  final ServiceRequest request;
  final bool showAccept;
  final Future<void> Function() onChanged;

  const _RequestCard({
    required this.request,
    required this.showAccept,
    required this.onChanged,
  });

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _busy = false;

  Future<void> _accept() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<RequestProvider>().accept(widget.request.id);
      messenger.showSnackBar(const SnackBar(
          content: Text('Request accepted — it is now in My Tasks'),
          backgroundColor: AppTheme.success));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: e.isConflict ? AppTheme.warning : AppTheme.danger));
      await widget.onChanged();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setStatus(String status) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<RequestProvider>().setStatus(widget.request.id, status);
      await widget.onChanged();
      messenger.showSnackBar(SnackBar(
          content: Text(status == 'completed'
              ? 'Marked as completed'
              : 'Marked as in progress'),
          backgroundColor: AppTheme.success));
    } on ApiException catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppTheme.danger));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final color = statusColor(r.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(
                      r.isPaper
                          ? Icons.description_outlined
                          : Icons.water_drop_outlined,
                      color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.kioskName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                      Text('${Fmt.titleCase(r.alertType)} refill · ${r.requestNumber}',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 13)),
                    ],
                  ),
                ),
                StatusChip(label: Fmt.titleCase(r.status), color: color),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow(Icons.bar_chart, 'Level', _levelText(r)),
            if (r.locationName.isNotEmpty)
              _infoRow(Icons.school_outlined, 'Location', r.locationName),
            if (r.address.isNotEmpty)
              _infoRow(Icons.location_on_outlined, 'Address', r.address),
            _infoRow(Icons.schedule, 'Created', Fmt.relative(r.createdAt)),
            const SizedBox(height: 14),
            Row(
              children: [
                if (r.hasCoordinates)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          MapsLauncher.navigateTo(r.latitude!, r.longitude!),
                      icon: const Icon(Icons.navigation_outlined, size: 18),
                      label: const Text('Navigate'),
                    ),
                  ),
                if (r.hasCoordinates) const SizedBox(width: 10),
                Expanded(child: _actionButton(r)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(ServiceRequest r) {
    if (_busy) {
      return const FilledButton(
        onPressed: null,
        child: SizedBox(
            height: 20,
            width: 20,
            child:
                CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
      );
    }
    if (widget.showAccept && r.isPending) {
      return FilledButton.icon(
        onPressed: _accept,
        icon: const Icon(Icons.check, size: 18),
        label: const Text('Accept'),
      );
    }
    if (r.isAccepted) {
      return FilledButton.icon(
        onPressed: () => _setStatus('in_progress'),
        icon: const Icon(Icons.play_arrow, size: 18),
        label: const Text('Start'),
      );
    }
    if (r.isInProgress) {
      return FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: AppTheme.success),
        onPressed: () => _setStatus('completed'),
        icon: const Icon(Icons.done_all, size: 18),
        label: const Text('Complete'),
      );
    }
    return OutlinedButton.icon(
      onPressed: null,
      icon: const Icon(Icons.check_circle, size: 18),
      label: const Text('Completed'),
    );
  }

  String _levelText(ServiceRequest r) {
    if (r.isPaper) return '${r.levelValue} pages';
    return '${r.levelValue}%';
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 8),
          SizedBox(
              width: 76,
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
