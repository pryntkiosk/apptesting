/// A delivery partner managed by an admin.
class DeliveryPartner {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String status; // 'active' | 'inactive'
  final String? createdAt;

  DeliveryPartner({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.status,
    this.createdAt,
  });

  bool get isActive => status == 'active';

  factory DeliveryPartner.fromJson(Map<String, dynamic> j) => DeliveryPartner(
        id: j['id'] ?? '',
        name: (j['name'] ?? '').toString(),
        phone: (j['phone'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        status: (j['status'] ?? 'active').toString(),
        createdAt: j['created_at']?.toString(),
      );
}
