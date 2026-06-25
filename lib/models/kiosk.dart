/// A printing kiosk with location and inventory levels.
class Kiosk {
  final String id;
  final String name;
  final String locationName;
  final String address;
  final String city;
  final double? latitude;
  final double? longitude;
  final int pagesRemaining;
  final int paperCapacity;
  final int paperLevelPct;
  final int inkLevel;
  final int lowPaperThreshold;
  final int lowInkThreshold;
  final bool isActive;
  final bool isOnline;
  final String status; // 'online' | 'offline'
  final String? lastUpdated;
  final String? lastSeen;

  Kiosk({
    required this.id,
    required this.name,
    required this.locationName,
    required this.address,
    required this.city,
    this.latitude,
    this.longitude,
    required this.pagesRemaining,
    required this.paperCapacity,
    required this.paperLevelPct,
    required this.inkLevel,
    required this.lowPaperThreshold,
    required this.lowInkThreshold,
    required this.isActive,
    required this.isOnline,
    required this.status,
    this.lastUpdated,
    this.lastSeen,
  });

  bool get hasCoordinates => latitude != null && longitude != null;
  bool get lowPaper => pagesRemaining < lowPaperThreshold;
  bool get lowInk => inkLevel < lowInkThreshold;

  static double? _toDouble(dynamic v) =>
      v == null ? null : (v as num).toDouble();
  static int _toInt(dynamic v, [int def = 0]) =>
      v == null ? def : (v as num).toInt();

  factory Kiosk.fromJson(Map<String, dynamic> j) => Kiosk(
        id: j['id'] ?? '',
        name: (j['name'] ?? '').toString(),
        locationName: (j['location_name'] ?? j['city'] ?? '').toString(),
        address: (j['address'] ?? '').toString(),
        city: (j['city'] ?? '').toString(),
        latitude: _toDouble(j['latitude']),
        longitude: _toDouble(j['longitude']),
        pagesRemaining: _toInt(j['pages_remaining']),
        paperCapacity: _toInt(j['paper_capacity'], 500),
        paperLevelPct: _toInt(j['paper_level_pct']),
        inkLevel: _toInt(j['ink_level'], 100),
        lowPaperThreshold: _toInt(j['low_paper_threshold'], 70),
        lowInkThreshold: _toInt(j['low_ink_threshold'], 20),
        isActive: j['is_active'] ?? true,
        isOnline: j['is_online'] ?? false,
        status: (j['status'] ?? 'offline').toString(),
        lastUpdated: j['last_updated']?.toString(),
        lastSeen: j['last_seen']?.toString(),
      );
}
