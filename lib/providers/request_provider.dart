import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../models/service_request.dart';

/// Handles service requests for both admin (all) and delivery (available + mine).
class RequestProvider extends ChangeNotifier {
  final ApiClient _api;
  RequestProvider(this._api);

  // Admin view
  List<ServiceRequest> _all = [];
  // Delivery view
  List<ServiceRequest> _available = [];
  List<ServiceRequest> _assigned = [];

  bool _loading = false;
  String? _error;

  List<ServiceRequest> get all => _all;
  List<ServiceRequest> get available => _available;
  List<ServiceRequest> get assigned => _assigned;
  bool get loading => _loading;
  String? get error => _error;

  List<ServiceRequest> byStatus(String status) =>
      _all.where((r) => r.status == status).toList();

  Future<void> loadForAdmin({String? status}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('/requests',
          query: status != null ? {'status': status} : null) as List;
      _all = data
          .map((e) => ServiceRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadForDelivery() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('/requests') as Map<String, dynamic>;
      _available = ((data['available'] ?? []) as List)
          .map((e) => ServiceRequest.fromJson(e as Map<String, dynamic>))
          .toList();
      _assigned = ((data['assigned'] ?? []) as List)
          .map((e) => ServiceRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// First-come claim. Throws ApiException(409) if already taken.
  Future<ServiceRequest> accept(String id) async {
    final data = await _api.post('/requests/$id/accept') as Map<String, dynamic>;
    await loadForDelivery();
    return ServiceRequest.fromJson(data);
  }

  Future<ServiceRequest> setStatus(String id, String status) async {
    final data = await _api
        .post('/requests/$id/status', body: {'status': status}) as Map<String, dynamic>;
    return ServiceRequest.fromJson(data);
  }

  Future<ServiceRequest> getOne(String id) async {
    final data = await _api.get('/requests/$id') as Map<String, dynamic>;
    return ServiceRequest.fromJson(data);
  }
}
