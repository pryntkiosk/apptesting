import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/maps_launcher.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../models/delivery_partner.dart';
import '../../../providers/partner_provider.dart';
import 'partner_form_screen.dart';

class PartnerListScreen extends StatefulWidget {
  const PartnerListScreen({super.key});

  @override
  State<PartnerListScreen> createState() => _PartnerListScreenState();
}

class _PartnerListScreenState extends State<PartnerListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => context.read<PartnerProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PartnerProvider>();
    return Scaffold(
      body: Builder(builder: (_) {
        if (p.loading && p.partners.isEmpty) return const LoadingView();
        if (p.error != null && p.partners.isEmpty) {
          return ErrorView(message: p.error!, onRetry: p.load);
        }
        if (p.partners.isEmpty) {
          return const EmptyView(
            icon: Icons.people_outline,
            title: 'No delivery partners',
            subtitle: 'Tap + to add a partner account.',
          );
        }
        return RefreshIndicator(
          onRefresh: p.load,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: p.partners.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _PartnerCard(partner: p.partners[i]),
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PartnerFormScreen()),
        ),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add Partner'),
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  final DeliveryPartner partner;
  const _PartnerCard({required this.partner});

  @override
  Widget build(BuildContext context) {
    final prov = context.read<PartnerProvider>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  (partner.isActive ? AppTheme.success : Colors.grey)
                      .withOpacity(0.15),
              child: Text(
                partner.name.isNotEmpty ? partner.name[0].toUpperCase() : '?',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: partner.isActive ? AppTheme.success : Colors.grey),
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
                        child: Text(partner.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 15)),
                      ),
                      StatusChip(
                        label: partner.isActive ? 'Active' : 'Inactive',
                        color:
                            partner.isActive ? AppTheme.success : Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(partner.email,
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13)),
                  Text(partner.phone,
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13)),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) async {
                switch (v) {
                  case 'edit':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              PartnerFormScreen(existing: partner)),
                    );
                    break;
                  case 'toggle':
                    await prov.toggleStatus(partner);
                    break;
                  case 'call':
                    MapsLauncher.dialPhone(partner.phone);
                    break;
                  case 'delete':
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete partner?'),
                        content: Text('Remove ${partner.name}?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel')),
                          FilledButton(
                            style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.danger),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) await prov.remove(partner.id);
                    break;
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(
                    value: 'toggle',
                    child: Text(partner.isActive ? 'Disable' : 'Enable')),
                const PopupMenuItem(value: 'call', child: Text('Call')),
                const PopupMenuItem(
                    value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
