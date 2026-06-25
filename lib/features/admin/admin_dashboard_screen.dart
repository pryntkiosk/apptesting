import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../providers/dashboard_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
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

  Future<void> _refresh() async {
    final p = context.read<DashboardProvider>();
    await p.loadAdmin();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DashboardProvider>();
    final d = p.admin;

    if (d == null && p.loading) return const LoadingView();
    if (d == null && p.error != null) {
      return ErrorView(message: p.error!, onRetry: _refresh);
    }
    if (d == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              StatCard(
                  label: 'Total Kiosks',
                  value: '${d.totalKiosks}',
                  icon: Icons.print_rounded,
                  color: AppTheme.info),
              StatCard(
                  label: 'Online',
                  value: '${d.onlineKiosks}',
                  icon: Icons.wifi_rounded,
                  color: AppTheme.success),
              StatCard(
                  label: 'Offline',
                  value: '${d.offlineKiosks}',
                  icon: Icons.wifi_off_rounded,
                  color: Colors.grey),
              StatCard(
                  label: 'Active Alerts',
                  value: '${d.activeAlerts}',
                  icon: Icons.warning_amber_rounded,
                  color: AppTheme.danger),
            ],
          ),
          const SizedBox(height: 16),
          Text('Service Requests',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _MiniStat(
                      label: 'Pending',
                      value: d.pendingRequests,
                      color: AppTheme.warning)),
              const SizedBox(width: 10),
              Expanded(
                  child: _MiniStat(
                      label: 'Accepted',
                      value: d.acceptedRequests,
                      color: AppTheme.info)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _MiniStat(
                      label: 'In Progress',
                      value: d.inProgressRequests,
                      color: const Color(0xFF7C3AED))),
              const SizedBox(width: 10),
              Expanded(
                  child: _MiniStat(
                      label: 'Completed',
                      value: d.completedRequests,
                      color: AppTheme.success)),
            ],
          ),
          const SizedBox(height: 20),
          Text('Recent Activity',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (d.recentActivity.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: EmptyView(
                  icon: Icons.history,
                  title: 'No activity yet',
                  subtitle: 'Service requests will appear here.'),
            )
          else
            ...d.recentActivity.map((r) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: statusColor(r.status).withOpacity(0.15),
                      child: Icon(
                          r.isPaper
                              ? Icons.description_outlined
                              : Icons.water_drop_outlined,
                          color: statusColor(r.status)),
                    ),
                    title: Text('${r.kioskName} · ${Fmt.titleCase(r.alertType)}'),
                    subtitle: Text(
                        '${r.requestNumber} · ${Fmt.relative(r.createdAt)}'),
                    trailing: StatusChip(
                        label: Fmt.titleCase(r.status),
                        color: statusColor(r.status)),
                  ),
                )),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        child: Column(
          children: [
            Text('$value',
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
