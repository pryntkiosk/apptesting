import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../providers/dashboard_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<DashboardProvider>().loadFeed());
  }

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<DashboardProvider>().feed;
    return Scaffold(
      appBar: AppBar(title: const Text('Activity Feed')),
      body: feed.isEmpty
          ? const EmptyView(
              icon: Icons.notifications_off_outlined,
              title: 'No notifications yet',
              subtitle: 'Alerts and request updates will appear here.')
          : RefreshIndicator(
              onRefresh: () =>
                  context.read<DashboardProvider>().loadFeed(),
              color: AppTheme.brand,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: feed.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final n = feed[i];
                  final isAlert = n.title.toLowerCase().contains('alert');
                  final color = isAlert ? AppTheme.danger : AppTheme.info;
                  return PryntCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isAlert
                                ? Icons.warning_amber_rounded
                                : Icons.notifications_active_rounded,
                            color: color, size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(n.title,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14)),
                                  ),
                                  Text(Fmt.relative(n.createdAt),
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant)),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(n.body,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      height: 1.4)),
                              const SizedBox(height: 4),
                              // Audience badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.brand.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  'Sent to ${n.audience} · ${n.sent} delivered',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.brand,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
