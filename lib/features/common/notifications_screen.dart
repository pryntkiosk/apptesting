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
    WidgetsBinding.instance
        .addPostFrameCallback((_) => context.read<DashboardProvider>().loadFeed());
  }

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<DashboardProvider>().feed;
    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: feed.isEmpty
          ? const EmptyView(
              icon: Icons.notifications_off_outlined,
              title: 'No notifications yet')
          : RefreshIndicator(
              onRefresh: () =>
                  context.read<DashboardProvider>().loadFeed(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: feed.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final n = feed[i];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.brand.withOpacity(0.12),
                        child: const Icon(Icons.notifications_active_outlined,
                            color: AppTheme.brand),
                      ),
                      title: Text(n.title,
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.body),
                          const SizedBox(height: 2),
                          Text(Fmt.relative(n.createdAt),
                              style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            ),
    );
  }
}
