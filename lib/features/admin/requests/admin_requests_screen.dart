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

  static const _statuses = ['pending', 'accepted', 'in_progress', 'completed'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _statuses.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    _poll = Timer.periodic(AppConfig.pollInterval, (_) => _refresh());
  }

  @override
  void dispose() { _poll?.cancel(); _tabs.dispose(); super.dispose(); }

  Future<void> _refresh() =>
      context.read<RequestProvider>().loadForAdmin();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RequestProvider>();

    return Column(
      children: [
        // Tab bar with counts
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            tabs: _statuses.map((s) {
              final count = p.byStatus(s).length;
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(Fmt.titleCase(s)),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: statusColor(s).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text('$count',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: statusColor(s))),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
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
                  color: AppTheme.brand,
                  child: ListView(children: [
                    const SizedBox(height: 80),
                    EmptyView(
                      icon: statusIcon(s),
                      title: 'No ${Fmt.titleCase(s)} requests',
                    ),
                  ]),
                );
              }
              return RefreshIndicator(
                onRefresh: _refresh,
                color: AppTheme.brand,
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
    final r     = request;
    final color = statusColor(r.status);
    return PryntCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
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
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 2),
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

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Details
          if (r.address.isNotEmpty)
            InfoRow(
                icon: Icons.location_on_outlined,
                label: 'Address',
                value: r.address),
          InfoRow(
              icon: Icons.access_time_rounded,
              label: 'Created',
              value: Fmt.dateTime(r.createdAt)),
          if (r.acceptedAt != null)
            InfoRow(
                icon: Icons.thumb_up_rounded,
                label: 'Accepted',
                value: Fmt.dateTime(r.acceptedAt)),
          if (r.assignedName != null)
            InfoRow(
                icon: Icons.person_outline,
                label: 'Assigned to',
                value: r.assignedName!),
          if (r.isCompleted && r.completedAt != null)
            InfoRow(
                icon: Icons.check_circle_outline,
                label: 'Completed',
                value: Fmt.dateTime(r.completedAt)),

          // Navigate button
          if (r.hasCoordinates) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    MapsLauncher.navigateTo(r.latitude!, r.longitude!),
                icon: const Icon(Icons.navigation_rounded, size: 16),
                label: const Text('Navigate to kiosk'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
