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
          return EmptyView(
            icon: Icons.people_outline,
            title: 'No delivery partners',
            subtitle: 'Add a partner so they can receive alerts and accept requests.',
            action: FilledButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PartnerFormScreen())),
              icon: const Icon(Icons.person_add_alt, size: 18),
              label: const Text('Add Partner'),
            ),
          );
        }

        final active   = p.partners.where((p) => p.isActive).length;
        final inactive = p.partners.length - active;

        return RefreshIndicator(
          onRefresh: p.load,
          color: AppTheme.brand,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              // Summary strip
              Row(
                children: [
                  _Pill(label: '${p.partners.length} Total', color: AppTheme.info),
                  const SizedBox(width: 8),
                  _Pill(label: '$active Active', color: AppTheme.success),
                  if (inactive > 0) ...[
                    const SizedBox(width: 8),
                    _Pill(label: '$inactive Inactive', color: Colors.grey),
                  ],
                ],
              ),
              const SizedBox(height: 14),

              ...p.partners.map((partner) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PartnerCard(partner: partner),
              )),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.brand,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PartnerFormScreen()),
        ),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add Partner',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      );
}

class _PartnerCard extends StatelessWidget {
  final DeliveryPartner partner;
  const _PartnerCard({required this.partner});

  @override
  Widget build(BuildContext context) {
    final prov  = context.read<PartnerProvider>();
    final color = partner.isActive ? AppTheme.success : Colors.grey;

    return PryntCard(
      child: Row(
        children: [
          // Avatar
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                partner.name.isNotEmpty
                    ? partner.name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                    color: color,
                    fontSize: 19,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Info
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
                      color: color,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(partner.email,
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Icon(Icons.phone_outlined,
                        size: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(partner.phone,
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            onSelected: (v) async {
              switch (v) {
                case 'edit':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PartnerFormScreen(existing: partner)),
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
                      title: const Text('Remove partner?'),
                      content: Text(
                          'Are you sure you want to delete ${partner.name}? '
                          'This cannot be undone.'),
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
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Edit'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'toggle',
                child: ListTile(
                  leading: Icon(partner.isActive
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline),
                  title: Text(partner.isActive ? 'Deactivate' : 'Activate'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'call',
                child: ListTile(
                  leading: Icon(Icons.call_outlined),
                  title: Text('Call'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: const Icon(Icons.delete_outline,
                      color: AppTheme.danger),
                  title: const Text('Delete',
                      style: TextStyle(color: AppTheme.danger)),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
