import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/request_provider.dart';

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
  void dispose() { _poll?.cancel(); super.dispose(); }

  Future<void> _refresh() async {
    await context.read<DashboardProvider>().loadDelivery();
    await context.read<RequestProvider>().loadForDelivery();
  }

  @override
  Widget build(BuildContext context) {
    final p       = context.watch<DashboardProvider>();
    final d       = p.delivery;
    final rp      = context.watch<RequestProvider>();
    final name    = context.read<AuthProvider>().user?.name ?? 'Partner';

    if (d == null && p.loading) return const LoadingView();
    if (d == null && p.error != null) {
      return ErrorView(message: p.error!, onRetry: _refresh);
    }
    if (d == null) return const SizedBox.shrink();

    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppTheme.brand,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // ── Greeting banner ───────────────────────────
          _DeliveryGreeting(
            greeting: greeting,
            name: name,
            available: d.availableRequests,
            assigned: d.assignedRequests,
          ),
          const SizedBox(height: 20),

          // ── Stats ─────────────────────────────────────
          const SectionHeader(title: 'Your Stats'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              StatCard(
                  label: 'Available',
                  value: '${d.availableRequests}',
                  icon: Icons.inbox_rounded,
                  color: AppTheme.warning),
              StatCard(
                  label: 'Assigned to me',
                  value: '${d.assignedRequests}',
                  icon: Icons.assignment_ind_rounded,
                  color: AppTheme.info),
              StatCard(
                  label: 'In Progress',
                  value: '${rp.assigned.where((r) => r.isInProgress).length}',
                  icon: Icons.directions_run_rounded,
                  color: AppTheme.purple),
              StatCard(
                  label: 'Total Completed',
                  value: '${d.completedRequests}',
                  icon: Icons.check_circle_rounded,
                  color: AppTheme.success),
            ],
          ),

          // ── My active tasks ───────────────────────────
          if (rp.assigned.isNotEmpty) ...[
            const SizedBox(height: 20),
            const SectionHeader(title: 'Active Tasks'),
            ...rp.assigned.take(3).map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PryntCard(
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: statusColor(r.status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        r.isPaper
                            ? Icons.description_rounded
                            : Icons.water_drop_rounded,
                        color: statusColor(r.status),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.kioskName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(
                            '${Fmt.titleCase(r.alertType)} refill · ${Fmt.relative(r.createdAt)}',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    StatusChip(
                        label: Fmt.titleCase(r.status),
                        color: statusColor(r.status)),
                  ],
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }
}

class _DeliveryGreeting extends StatelessWidget {
  final String greeting, name;
  final int available, assigned;
  const _DeliveryGreeting({
    required this.greeting,
    required this.name,
    required this.available,
    required this.assigned,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [AppTheme.brand.withOpacity(0.07),
                 AppTheme.brand.withOpacity(0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.brand.withOpacity(isDark ? 0.2 : 0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$greeting,',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13)),
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        letterSpacing: -0.3)),
                const SizedBox(height: 8),
                if (available > 0)
                  Row(
                    children: [
                      Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                              color: AppTheme.warning,
                              shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(
                        '$available new request${available > 1 ? 's' : ''} waiting',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.warning),
                      ),
                    ],
                  )
                else if (assigned > 0)
                  Row(
                    children: [
                      Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                              color: AppTheme.info,
                              shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(
                        '$assigned task${assigned > 1 ? 's' : ''} in progress',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.info),
                      ),
                    ],
                  )
                else
                  const Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 14, color: AppTheme.success),
                      SizedBox(width: 6),
                      Text('All caught up!',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.success)),
                    ],
                  ),
              ],
            ),
          ),
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppTheme.brand,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delivery_dining_rounded,
                color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}
