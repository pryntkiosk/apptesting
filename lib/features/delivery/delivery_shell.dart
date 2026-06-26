import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import 'delivery_dashboard_screen.dart';
import 'delivery_requests_screen.dart';

class DeliveryShell extends StatefulWidget {
  const DeliveryShell({super.key});
  @override
  State<DeliveryShell> createState() => _DeliveryShellState();
}

class _DeliveryShellState extends State<DeliveryShell> {
  int _index = 0;

  static const _pages = [
    DeliveryDashboardScreen(),
    DeliveryRequestsScreen(initialTab: 0),
    DeliveryRequestsScreen(initialTab: 1),
  ];

  static const _titles = ['Home', 'Available', 'My Tasks'];

  @override
  Widget build(BuildContext context) {
    final auth      = context.watch<AuthProvider>();
    final available = context.watch<RequestProvider>().available.length;
    final assigned  = context.watch<RequestProvider>().assigned.length;
    final isDark    = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: AppTheme.brand,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delivery_dining_rounded,
                  color: Colors.white, size: 17),
            ),
            const SizedBox(width: 9),
            Text(_titles[_index]),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(isDark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined),
            onPressed: () => context.read<ThemeProvider>().toggle(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _showAccountSheet(context, auth),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.brand.withOpacity(0.15),
                child: Text(
                  (auth.user?.name ?? 'D')[0].toUpperCase(),
                  style: const TextStyle(
                      color: AppTheme.brand,
                      fontSize: 14,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: available > 0,
              label: Text('$available'),
              child: const Icon(Icons.inbox_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: available > 0,
              label: Text('$available'),
              child: const Icon(Icons.inbox_rounded),
            ),
            label: 'Available',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: assigned > 0,
              label: Text('$assigned'),
              child: const Icon(Icons.task_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: assigned > 0,
              label: Text('$assigned'),
              child: const Icon(Icons.task_rounded),
            ),
            label: 'My Tasks',
          ),
        ],
      ),
    );
  }

  void _showAccountSheet(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(99))),
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.brand.withOpacity(0.15),
                child: Text(
                  (auth.user?.name ?? 'D')[0].toUpperCase(),
                  style: const TextStyle(
                      color: AppTheme.brand,
                      fontSize: 24,
                      fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 10),
              Text(auth.user?.name ?? 'Partner',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              const Text('Delivery Partner',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout,
                      color: AppTheme.danger, size: 20),
                ),
                title: const Text('Sign Out',
                    style: TextStyle(
                        color: AppTheme.danger, fontWeight: FontWeight.w600)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.pop(context);
                  auth.logout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
