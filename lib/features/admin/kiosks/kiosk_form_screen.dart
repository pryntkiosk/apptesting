import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/kiosk.dart';
import '../../../providers/kiosk_provider.dart';

/// Create or edit a kiosk. Pass [existing] to edit.
class KioskFormScreen extends StatefulWidget {
  final Kiosk? existing;
  const KioskFormScreen({super.key, this.existing});

  @override
  State<KioskFormScreen> createState() => _KioskFormScreenState();
}

class _KioskFormScreenState extends State<KioskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _location;
  late final TextEditingController _address;
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  late final TextEditingController _pages;
  late final TextEditingController _capacity;
  late final TextEditingController _ink;
  late final TextEditingController _lowPaper;
  late final TextEditingController _lowInk;
  bool _busy = false;

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final k = widget.existing;
    _name = TextEditingController(text: k?.name ?? '');
    _location = TextEditingController(text: k?.locationName ?? '');
    _address = TextEditingController(text: k?.address ?? '');
    _lat = TextEditingController(text: k?.latitude?.toString() ?? '');
    _lng = TextEditingController(text: k?.longitude?.toString() ?? '');
    _pages = TextEditingController(text: (k?.pagesRemaining ?? 500).toString());
    _capacity =
        TextEditingController(text: (k?.paperCapacity ?? 500).toString());
    _ink = TextEditingController(text: (k?.inkLevel ?? 100).toString());
    _lowPaper =
        TextEditingController(text: (k?.lowPaperThreshold ?? 70).toString());
    _lowInk = TextEditingController(text: (k?.lowInkThreshold ?? 20).toString());
  }

  @override
  void dispose() {
    for (final c in [
      _name, _location, _address, _lat, _lng, _pages,
      _capacity, _ink, _lowPaper, _lowInk
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final payload = {
      'name': _name.text.trim(),
      'location_name': _location.text.trim(),
      'address': _address.text.trim(),
      'latitude': double.tryParse(_lat.text.trim()),
      'longitude': double.tryParse(_lng.text.trim()),
      'pages_remaining': int.tryParse(_pages.text.trim()) ?? 0,
      'paper_capacity': int.tryParse(_capacity.text.trim()) ?? 500,
      'ink_level': int.tryParse(_ink.text.trim()) ?? 100,
      'low_paper_threshold': int.tryParse(_lowPaper.text.trim()) ?? 70,
      'low_ink_threshold': int.tryParse(_lowInk.text.trim()) ?? 20,
    };
    try {
      final p = context.read<KioskProvider>();
      if (isEdit) {
        await p.update(widget.existing!.id, payload);
      } else {
        await p.create(payload);
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? 'Kiosk updated' : 'Kiosk created')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppTheme.danger),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Kiosk' : 'Add Kiosk')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                  labelText: 'Kiosk Name *',
                  prefixIcon: Icon(Icons.badge_outlined)),
              validator: _required,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(
                  labelText: 'College / Location Name *',
                  prefixIcon: Icon(Icons.school_outlined)),
              validator: _required,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _address,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Full Address',
                  prefixIcon: Icon(Icons.location_on_outlined)),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _lat,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: const InputDecoration(labelText: 'Latitude'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lng,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: const InputDecoration(labelText: 'Longitude'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _sectionLabel(context, 'Inventory'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pages,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration:
                        const InputDecoration(labelText: 'Paper (pages)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _capacity,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration:
                        const InputDecoration(labelText: 'Paper capacity'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _ink,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Ink level (%)'),
            ),
            const SizedBox(height: 24),
            _sectionLabel(context, 'Alert Thresholds'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _lowPaper,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                        labelText: 'Low paper (pages)', helperText: 'Default 70'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lowInk,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                        labelText: 'Low ink (%)', helperText: 'Default 20'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(isEdit ? 'Save Changes' : 'Create Kiosk'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) => Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w800),
      );
}
