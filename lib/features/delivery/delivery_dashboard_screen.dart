import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';

class DeliveryDashboardScreen extends StatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  State<DeliveryDashboardScreen> createState() =>
      _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen> {
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

  Future<void> _refresh() => context.read<DashboardProvider>().loadDelivery();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DashboardProvider>();
    final d = p.delivery;
    final name = context.read<AuthProvider>().user?.name ?? 'Partner';

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
          Text('Hello, $name 👋',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Here are your service requests',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              StatCard(
                  label: 'Available',
                  value: '${d.availableRequests}',
                  icon: Icons.list_alt_rounded,
                  color: AppTheme.warning),
              StatCard(
                  label: 'Assigned to me',
                  value: '${d.assignedRequests}',
                  icon: Icons.assignment_ind_outlined,
                  color: AppTheme.info),
              StatCard(
                  label: 'Completed',
                  value: '${d.completedRequests}',
                  icon: Icons.check_circle_outline,
                  color: AppTheme.success),
              StatCard(
                  label: 'Total done',
                  value: '${d.completedRequests}',
                  icon: Icons.emoji_events_outlined,
                  color: const Color(0xFF7C3AED)),
            ],
          ),
        ],
      ),
    );
  }
}
