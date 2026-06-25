/// A service request created by an alert (auto or manual).
class ServiceRequest {
  final String id;
  final String requestNumber;
  final String kioskId;
  final String kioskName;
  final String locationName;
  final String address;
  final double? latitude;
  final double? longitude;
  final String alertType; // 'paper' | 'ink'
  final dynamic levelValue;
  final String status; // pending | accepted | in_progress | completed
  final String? assignedTo;
  final String? assignedName;
  final String source; // 'auto' | 'manual'
  final String? createdAt;
  final String? acceptedAt;
  final String? completedAt;

  ServiceRequest({
    required this.id,
    required this.requestNumber,
    required this.kioskId,
    required this.kioskName,
    required this.locationName,
    required this.address,
    this.latitude,
    this.longitude,
    required this.alertType,
    this.levelValue,
    required this.status,
    this.assignedTo,
    this.assignedName,
    required this.source,
    this.createdAt,
    this.acceptedAt,
    this.completedAt,
  });

  bool get hasCoordinates => latitude != null && longitude != null;
  bool get isPaper => alertType == 'paper';
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';

  static double? _toDouble(dynamic v) =>
      v == null ? null : (v as num).toDouble();

  factory ServiceRequest.fromJson(Map<String, dynamic> j) => ServiceRequest(
        id: j['id'] ?? '',
        requestNumber: (j['request_number'] ?? '').toString(),
        kioskId: (j['kiosk_id'] ?? '').toString(),
        kioskName: (j['kiosk_name'] ?? 'Kiosk').toString(),
        locationName: (j['location_name'] ?? '').toString(),
        address: (j['address'] ?? '').toString(),
        latitude: _toDouble(j['latitude']),
        longitude: _toDouble(j['longitude']),
        alertType: (j['alert_type'] ?? 'paper').toString(),
        levelValue: j['level_value'],
        status: (j['status'] ?? 'pending').toString(),
        assignedTo: j['assigned_to']?.toString(),
        assignedName: j['assigned_name']?.toString(),
        source: (j['source'] ?? 'auto').toString(),
        createdAt: j['created_at']?.toString(),
        acceptedAt: j['accepted_at']?.toString(),
        completedAt: j['completed_at']?.toString(),
      );
}
