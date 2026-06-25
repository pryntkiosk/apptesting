import 'service_request.dart';

/// Admin dashboard aggregate.
class AdminDashboard {
  final int totalKiosks;
  final int onlineKiosks;
  final int offlineKiosks;
  final int activeAlerts;
  final int pendingRequests;
  final int acceptedRequests;
  final int inProgressRequests;
  final int completedRequests;
  final List<ServiceRequest> recentActivity;

  AdminDashboard({
    required this.totalKiosks,
    required this.onlineKiosks,
    required this.offlineKiosks,
    required this.activeAlerts,
    required this.pendingRequests,
    required this.acceptedRequests,
    required this.inProgressRequests,
    required this.completedRequests,
    required this.recentActivity,
  });

  static int _i(dynamic v) => v == null ? 0 : (v as num).toInt();

  factory AdminDashboard.fromJson(Map<String, dynamic> j) => AdminDashboard(
        totalKiosks: _i(j['total_kiosks']),
        onlineKiosks: _i(j['online_kiosks']),
        offlineKiosks: _i(j['offline_kiosks']),
        activeAlerts: _i(j['active_alerts']),
        pendingRequests: _i(j['pending_requests']),
        acceptedRequests: _i(j['accepted_requests']),
        inProgressRequests: _i(j['in_progress_requests']),
        completedRequests: _i(j['completed_requests']),
        recentActivity: ((j['recent_activity'] ?? []) as List)
            .map((e) => ServiceRequest.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Delivery partner dashboard aggregate.
class DeliveryDashboard {
  final int availableRequests;
  final int assignedRequests;
  final int completedRequests;

  DeliveryDashboard({
    required this.availableRequests,
    required this.assignedRequests,
    required this.completedRequests,
  });

  static int _i(dynamic v) => v == null ? 0 : (v as num).toInt();

  factory DeliveryDashboard.fromJson(Map<String, dynamic> j) =>
      DeliveryDashboard(
        availableRequests: _i(j['available_requests']),
        assignedRequests: _i(j['assigned_requests']),
        completedRequests: _i(j['completed_requests']),
      );
}
