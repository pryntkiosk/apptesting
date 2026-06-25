import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../models/kiosk.dart';
import '../../../providers/kiosk_provider.dart';
import 'kiosk_detail_screen.dart';
import 'kiosk_form_screen.dart';

class KioskListScreen extends StatefulWidget {
  const KioskListScreen({super.key});

  @override
  State<KioskListScreen> createState() => _KioskListScreenState();
}

class _KioskListScreenState extends State<KioskListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => context.read<KioskProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<KioskProvider>();

    return Scaffold(
      body: Builder(builder: (_) {
        if (p.loading && p.kiosks.isEmpty) return const LoadingView();
        if (p.error != null && p.kiosks.isEmpty) {
          return ErrorView(message: p.error!, onRetry: p.load);
        }
        if (p.kiosks.isEmpty) {
          return const EmptyView(
            icon: Icons.print_disabled_outlined,
            title: 'No kiosks yet',
            subtitle: 'Tap + to add your first kiosk.',
          );
        }
        return RefreshIndicator(
          onRefresh: p.load,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: p.kiosks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _KioskCard(kiosk: p.kiosks[i]),
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const KioskFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Kiosk'),
      ),
    );
  }
}

class _KioskCard extends StatelessWidget {
  final Kiosk kiosk;
  const _KioskCard({required this.kiosk});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => KioskDetailScreen(kioskId: kiosk.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(kiosk.name,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(kiosk.locationName,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      ],
                    ),
                  ),
                  StatusChip(
                    label: kiosk.isOnline ? 'Online' : 'Offline',
                    color: kiosk.isOnline ? AppTheme.success : Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LevelBar(
                  label: 'Paper (${kiosk.pagesRemaining} pages)',
                  percent: kiosk.paperLevelPct,
                  icon: Icons.description_outlined,
                  low: kiosk.lowPaper),
              const SizedBox(height: 10),
              LevelBar(
                  label: 'Ink',
                  percent: kiosk.inkLevel,
                  icon: Icons.water_drop_outlined,
                  low: kiosk.lowInk),
              if (kiosk.lowPaper || kiosk.lowInk) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 16, color: AppTheme.danger),
                      const SizedBox(width: 6),
                      Text(
                        kiosk.lowPaper && kiosk.lowInk
                            ? 'Low paper & ink'
                            : kiosk.lowPaper
                                ? 'Low paper'
                                : 'Low ink',
                        style: const TextStyle(
                            color: AppTheme.danger,
                            fontWeight: FontWeight.w700,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
