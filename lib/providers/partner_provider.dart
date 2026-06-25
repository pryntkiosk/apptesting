import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../models/delivery_partner.dart';

class PartnerProvider extends ChangeNotifier {
  final ApiClient _api;
  PartnerProvider(this._api);

  List<DeliveryPartner> _partners = [];
  bool _loading = false;
  String? _error;

  List<DeliveryPartner> get partners => _partners;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('/partners') as List;
      _partners = data
          .map((e) => DeliveryPartner.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> create(Map<String, dynamic> payload) async {
    await _api.post('/partners', body: payload);
    await load();
  }

  Future<void> update(String id, Map<String, dynamic> payload) async {
    await _api.put('/partners/$id', body: payload);
    await load();
  }

  Future<void> toggleStatus(DeliveryPartner p) async {
    await _api.put('/partners/${p.id}',
        body: {'status': p.isActive ? 'inactive' : 'active'});
    await load();
  }

  Future<void> remove(String id) async {
    await _api.delete('/partners/$id');
    _partners.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}
