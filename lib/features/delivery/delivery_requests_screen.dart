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
  void dispose() { _poll?.cancel(); super.dispose(); }

  Future<void> _refresh() =>
      context.read<RequestProvider>().loadForDelivery();

  @override
  Widget build(BuildContext context) {
    final p           = context.watch<RequestProvider>();
    final showAvail   = widget.initialTab == 0;
    final items       = showAvail ? p.available : p.assigned;

    if (p.loading && items.isEmpty) return const LoadingView();
    if (p.error != null && items.isEmpty) {
      return ErrorView(message: p.error!, onRetry: _refresh);
    }
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        color: AppTheme.brand,
        child: ListView(children: [
          const SizedBox(height: 100),
          EmptyView(
            icon: showAvail
                ? Icons.inbox_outlined
                : Icons.task_outlined,
            title: showAvail
                ? 'No available requests'
                : 'No active tasks',
            subtitle: showAvail
                ? 'Pull to refresh — new requests will appear here.'
                : 'Accept a request from the Available tab.',
          ),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppTheme.brand,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _RequestCard(
          request: items[i],
          showAccept: showAvail,
          onChanged: _refresh,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────

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
          content: Text('Request accepted — check My Tasks'),
          backgroundColor: AppTheme.success));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor:
              e.isConflict ? AppTheme.warning : AppTheme.danger));
      await widget.onChanged();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setStatus(String status) async {
    // Confirm completion
    if (status == 'completed') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Mark as completed?'),
          content: const Text(
              'This will mark the refill as done and restore the kiosk level.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.success),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Complete'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context
          .read<RequestProvider>()
          .setStatus(widget.request.id, status);
      await widget.onChanged();
      messenger.showSnackBar(SnackBar(
          content: Text(status == 'completed'
              ? '✓ Marked as completed'
              : 'Started — navigate to the kiosk'),
          backgroundColor: AppTheme.success));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(e.message), backgroundColor: AppTheme.danger));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r     = widget.request;
    final color = statusColor(r.status);

    return PryntCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  r.isPaper
                      ? Icons.description_rounded
                      : Icons.water_drop_rounded,
                  color: color, size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.kioskName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        AlertTypeBadge(isPaper: r.isPaper),
                        const SizedBox(width: 6),
                        Text(r.requestNumber,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              StatusChip(label: Fmt.titleCase(r.status), color: color),
            ],
          ),

          const SizedBox(height: 14),

          // ── Level indicator ────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  r.isPaper
                      ? Icons.description_outlined
                      : Icons.water_drop_outlined,
                  size: 16, color: color,
                ),
                const SizedBox(width: 8),
                Text(
                  r.isPaper
                      ? '${r.levelValue} pages remaining'
                      : '${r.levelValue}% ink remaining',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Info rows ──────────────────────────────
          if (r.locationName.isNotEmpty)
            _Row(Icons.school_outlined, r.locationName),
          if (r.address.isNotEmpty)
            _Row(Icons.location_on_outlined, r.address),
          _Row(Icons.access_time_rounded, Fmt.relative(r.createdAt)),

          const SizedBox(height: 14),

          // ── Action buttons ─────────────────────────
          Row(
            children: [
              if (r.hasCoordinates) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => MapsLauncher.navigateTo(
                        r.latitude!, r.longitude!),
                    icon: const Icon(Icons.navigation_rounded, size: 16),
                    label: const Text('Navigate'),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44)),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(child: _ActionButton(
                  r: r,
                  showAccept: widget.showAccept,
                  busy: _busy,
                  onAccept: _accept,
                  onStatus: _setStatus)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Row(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(icon,
                size: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 7),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
          ],
        ),
      );
}

class _ActionButton extends StatelessWidget {
  final ServiceRequest r;
  final bool showAccept, busy;
  final VoidCallback onAccept;
  final void Function(String) onStatus;
  const _ActionButton({
    required this.r,
    required this.showAccept,
    required this.busy,
    required this.onAccept,
    required this.onStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return FilledButton(
        onPressed: null,
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
        child: const SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white)),
      );
    }
    if (showAccept && r.isPending) {
      return FilledButton.icon(
        onPressed: onAccept,
        icon: const Icon(Icons.check_rounded, size: 18),
        label: const Text('Accept Request'),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
      );
    }
    if (r.isAccepted) {
      return FilledButton.icon(
        onPressed: () => onStatus('in_progress'),
        icon: const Icon(Icons.play_arrow_rounded, size: 18),
        label: const Text('Start Job'),
        style: FilledButton.styleFrom(
            backgroundColor: AppTheme.info,
            minimumSize: const Size.fromHeight(44)),
      );
    }
    if (r.isInProgress) {
      return FilledButton.icon(
        onPressed: () => onStatus('completed'),
        icon: const Icon(Icons.done_all_rounded, size: 18),
        label: const Text('Mark Complete'),
        style: FilledButton.styleFrom(
            backgroundColor: AppTheme.success,
            minimumSize: const Size.fromHeight(44)),
      );
    }
    return FilledButton.icon(
      onPressed: null,
      icon: const Icon(Icons.check_circle_rounded, size: 18),
      label: const Text('Completed'),
      style: FilledButton.styleFrom(
          backgroundColor: AppTheme.success.withOpacity(0.4),
          minimumSize: const Size.fromHeight(44)),
    );
  }
}
