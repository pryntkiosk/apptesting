import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/maps_launcher.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../models/service_request.dart';
import '../../../providers/request_provider.dart';

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  Timer? _poll;

  static const _statuses = [
    'pending',
    'accepted',
    'in_progress',
    'completed'
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _statuses.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    _poll = Timer.periodic(AppConfig.pollInterval, (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _refresh() => context.read<RequestProvider>().loadForAdmin();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RequestProvider>();
    return Column(
      children: [
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _statuses
              .map((s) => Tab(text: Fmt.titleCase(s)))
              .toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: _statuses.map((s) {
              final items = p.byStatus(s);
              if (p.loading && p.all.isEmpty) return const LoadingView();
              if (items.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    children: [
                      const SizedBox(height: 100),
                      EmptyView(
                          icon: Icons.assignment_outlined,
                          title: 'No ${Fmt.titleCase(s)} requests'),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _AdminRequestCard(request: items[i]),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _AdminRequestCard extends StatelessWidget {
  final ServiceRequest request;
  const _AdminRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(request.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                    request.isPaper
                        ? Icons.description_outlined
                        : Icons.water_drop_outlined,
                    color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(request.kioskName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                ),
                StatusChip(
                    label: Fmt.titleCase(request.status), color: color),
              ],
            ),
            const SizedBox(height: 6),
            Text(
                '${request.requestNumber} · ${Fmt.titleCase(request.alertType)} refill · ${Fmt.titleCase(request.source)}',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13)),
            if (request.address.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                      child: Text(request.address,
                          style: const TextStyle(fontSize: 13))),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.schedule, size: 14),
                const SizedBox(width: 4),
                Text(Fmt.relative(request.createdAt),
                    style: const TextStyle(fontSize: 12)),
                const Spacer(),
                if (request.assignedName != null)
                  Text('👤 ${request.assignedName}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            if (request.hasCoordinates) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => MapsLauncher.navigateTo(
                    request.latitude!, request.longitude!),
                icon: const Icon(Icons.navigation_outlined, size: 18),
                label: const Text('Navigate'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
