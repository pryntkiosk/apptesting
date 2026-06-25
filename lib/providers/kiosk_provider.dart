import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../models/kiosk.dart';

class KioskProvider extends ChangeNotifier {
  final ApiClient _api;
  KioskProvider(this._api);

  List<Kiosk> _kiosks = [];
  bool _loading = false;
  String? _error;

  List<Kiosk> get kiosks => _kiosks;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('/kiosks') as List;
      _kiosks =
          data.map((e) => Kiosk.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Kiosk> getOne(String id) async {
    final data = await _api.get('/kiosks/$id') as Map<String, dynamic>;
    return Kiosk.fromJson(data);
  }

  Future<void> create(Map<String, dynamic> payload) async {
    await _api.post('/kiosks', body: payload);
    await load();
  }

  Future<void> update(String id, Map<String, dynamic> payload) async {
    await _api.put('/kiosks/$id', body: payload);
    await load();
  }

  Future<void> updateLevels(String id, {int? pages, int? ink}) async {
    await _api.post('/kiosks/$id/levels', body: {
      if (pages != null) 'pages_remaining': pages,
      if (ink != null) 'ink_level': ink,
    });
    await load();
  }

  Future<void> remove(String id) async {
    await _api.delete('/kiosks/$id');
    _kiosks.removeWhere((k) => k.id == id);
    notifyListeners();
  }

  /// Manual refill alert. Returns the created request map.
  Future<void> sendAlert(String id, String alertType) async {
    await _api.post('/kiosks/$id/alert', body: {'alert_type': alertType});
  }
}
