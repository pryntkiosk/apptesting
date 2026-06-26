import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';
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
  void dispose() { _poll?.cancel(); super.dispose(); }

  Future<void> _refresh() async {
    final p = context.read<DashboardProvider>();
    await p.loadAdmin();
  }

  @override
  Widget build(BuildContext context) {
    final p    = context.watch<DashboardProvider>();
    final d    = p.admin;
    final user = context.read<AuthProvider>().user;

    if (d == null && p.loading) return const LoadingView();
    if (d == null && p.error != null) {
      return ErrorView(message: p.error!, onRetry: _refresh);
    }
    if (d == null) return const SizedBox.shrink();

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppTheme.brand,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // ── Greeting ──────────────────────────────────
          _GreetingBanner(
            greeting: greeting,
            name: user?.name ?? 'Admin',
            pending: d.pendingRequests,
            alerts: d.activeAlerts,
          ),
          const SizedBox(height: 20),

          // ── Kiosk stat row ────────────────────────────
          const SectionHeader(title: 'Kiosk Fleet'),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Total',
                  value: '${d.totalKiosks}',
                  icon: Icons.print_rounded,
                  color: AppTheme.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Online',
                  value: '${d.onlineKiosks}',
                  icon: Icons.wifi_rounded,
                  color: AppTheme.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Offline',
                  value: '${d.offlineKiosks}',
                  icon: Icons.wifi_off_rounded,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Requests overview ─────────────────────────
          const SectionHeader(title: 'Service Requests'),
          _RequestsGrid(
            pending: d.pendingRequests,
            accepted: d.acceptedRequests,
            inProgress: d.inProgressRequests,
            completed: d.completedRequests,
          ),
          const SizedBox(height: 20),

          // ── Active alerts banner ──────────────────────
          if (d.activeAlerts > 0) ...[
            _AlertBanner(count: d.activeAlerts),
            const SizedBox(height: 20),
          ],

          // ── Recent activity ───────────────────────────
          const SectionHeader(title: 'Recent Activity'),
          if (d.recentActivity.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: EmptyView(
                icon: Icons.history_rounded,
                title: 'No activity yet',
                subtitle: 'Service requests will appear here.',
              ),
            )
          else
            ...d.recentActivity.map((r) {
              final color = statusColor(r.status);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PryntCard(
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          r.isPaper
                              ? Icons.description_rounded
                              : Icons.water_drop_rounded,
                          color: color, size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.kioskName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(
                              '${r.requestNumber} · ${Fmt.titleCase(r.alertType)} · ${Fmt.relative(r.createdAt)}',
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
                          label: Fmt.titleCase(r.status), color: color),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ── Greeting banner ──────────────────────────────────────────────────────────

class _GreetingBanner extends StatelessWidget {
  final String greeting;
  final String name;
  final int pending;
  final int alerts;
  const _GreetingBanner({
    required this.greeting,
    required this.name,
    required this.pending,
    required this.alerts,
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
              : [AppTheme.brand.withOpacity(0.06),
                 AppTheme.brand.withOpacity(0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.brand.withOpacity(isDark ? 0.2 : 0.12),
        ),
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
                if (pending > 0)
                  Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('$pending pending request${pending > 1 ? 's' : ''}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: AppTheme.warning)),
                    ],
                  )
                else
                  const Text('All requests up to date ✓',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500,
                          color: AppTheme.success)),
              ],
            ),
          ),
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppTheme.brand,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.dashboard_rounded,
                color: Colors.white, size: 26),
          ),
        ],
      ),
    );
  }
}

// ── Requests grid ─────────────────────────────────────────────────────────────

class _RequestsGrid extends StatelessWidget {
  final int pending, accepted, inProgress, completed;
  const _RequestsGrid({
    required this.pending,
    required this.accepted,
    required this.inProgress,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: [
        StatCard(label: 'Pending',     value: '$pending',    icon: Icons.hourglass_top_rounded,     color: AppTheme.warning),
        StatCard(label: 'Accepted',    value: '$accepted',   icon: Icons.thumb_up_rounded,          color: AppTheme.info),
        StatCard(label: 'In Progress', value: '$inProgress', icon: Icons.directions_run_rounded,    color: AppTheme.purple),
        StatCard(label: 'Completed',   value: '$completed',  icon: Icons.check_circle_rounded,      color: AppTheme.success),
      ],
    );
  }
}

// ── Alert banner ──────────────────────────────────────────────────────────────

class _AlertBanner extends StatelessWidget {
  final int count;
  const _AlertBanner({required this.count});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.danger.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppTheme.danger, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$count active alert${count > 1 ? 's' : ''} — delivery partners have been notified',
                style: const TextStyle(
                    color: AppTheme.danger,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ),
          ],
        ),
      );
}
