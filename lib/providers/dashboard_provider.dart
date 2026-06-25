import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../models/dashboard.dart';
import '../models/notification_log.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiClient _api;
  DashboardProvider(this._api);

  AdminDashboard? _admin;
  DeliveryDashboard? _delivery;
  List<NotificationLog> _feed = [];
  bool _loading = false;
  String? _error;

  AdminDashboard? get admin => _admin;
  DeliveryDashboard? get delivery => _delivery;
  List<NotificationLog> get feed => _feed;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadAdmin() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('/dashboard/admin') as Map<String, dynamic>;
      _admin = AdminDashboard.fromJson(data);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadDelivery() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data =
          await _api.get('/dashboard/delivery') as Map<String, dynamic>;
      _delivery = DeliveryDashboard.fromJson(data);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadFeed() async {
    try {
      final data = await _api.get('/notifications') as List;
      _feed = data
          .map((e) => NotificationLog.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {}
  }
}
