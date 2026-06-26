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
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => context.read<KioskProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<KioskProvider>();
    final kiosks = _search.isEmpty
        ? p.kiosks
        : p.kiosks
            .where((k) =>
                k.name.toLowerCase().contains(_search.toLowerCase()) ||
                k.locationName.toLowerCase().contains(_search.toLowerCase()))
            .toList();

    return Scaffold(
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search kiosks…',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _search = ''),
                      )
                    : null,
                isDense: true,
              ),
            ),
          ),

          // Stats strip
          if (p.kiosks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  _StatPill(
                      label: '${p.kiosks.length} Total',
                      color: AppTheme.info),
                  const SizedBox(width: 8),
                  _StatPill(
                      label:
                          '${p.kiosks.where((k) => k.isOnline).length} Online',
                      color: AppTheme.success),
                  const SizedBox(width: 8),
                  _StatPill(
                      label:
                          '${p.kiosks.where((k) => k.lowPaper || k.lowInk).length} Alerts',
                      color: AppTheme.danger),
                ],
              ),
            ),

          // List
          Expanded(
            child: Builder(builder: (_) {
              if (p.loading && p.kiosks.isEmpty) return const LoadingView();
              if (p.error != null && p.kiosks.isEmpty) {
                return ErrorView(message: p.error!, onRetry: p.load);
              }
              if (p.kiosks.isEmpty) {
                return EmptyView(
                  icon: Icons.print_disabled_outlined,
                  title: 'No kiosks yet',
                  subtitle: 'Tap + to add your first kiosk.',
                  action: FilledButton.icon(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const KioskFormScreen())),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Kiosk'),
                  ),
                );
              }
              if (kiosks.isEmpty) {
                return const EmptyView(
                  icon: Icons.search_off,
                  title: 'No results',
                  subtitle: 'Try a different search term.',
                );
              }
              return RefreshIndicator(
                onRefresh: p.load,
                color: AppTheme.brand,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: kiosks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _KioskCard(kiosk: kiosks[i]),
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.brand,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const KioskFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Kiosk',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(label,
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
      );
}

class _KioskCard extends StatelessWidget {
  final Kiosk kiosk;
  const _KioskCard({required this.kiosk});

  @override
  Widget build(BuildContext context) {
    final hasAlert = kiosk.lowPaper || kiosk.lowInk;
    return PryntCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => KioskDetailScreen(kioskId: kiosk.id)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Icon container
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: kiosk.isOnline
                      ? AppTheme.success.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.print_rounded,
                  color: kiosk.isOnline ? AppTheme.success : Colors.grey,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kiosk.name,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 1),
                    Text(kiosk.locationName,
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusChip(
                    label: kiosk.isOnline ? 'Online' : 'Offline',
                    color: kiosk.isOnline ? AppTheme.success : Colors.grey,
                  ),
                  if (hasAlert) ...[
                    const SizedBox(height: 4),
                    StatusChip(
                        label: 'Low ${kiosk.lowPaper ? "Paper" : "Ink"}',
                        color: AppTheme.danger),
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Level bars
          LevelBar(
            label: 'Paper  ${kiosk.pagesRemaining}/${kiosk.paperCapacity} pages',
            percent: kiosk.paperLevelPct,
            icon: Icons.description_rounded,
            low: kiosk.lowPaper,
          ),
          const SizedBox(height: 10),
          LevelBar(
            label: 'Ink',
            percent: kiosk.inkLevel,
            icon: Icons.water_drop_rounded,
            low: kiosk.lowInk,
          ),

          // Tap hint
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Tap to manage',
                  style: TextStyle(
                      color: AppTheme.brand.withOpacity(0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded,
                  size: 13, color: AppTheme.brand.withOpacity(0.7)),
            ],
          ),
        ],
      ),
    );
  }
}
