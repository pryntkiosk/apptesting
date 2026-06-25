/// Authenticated user (Admin or Delivery Partner).
class AppUser {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String role; // 'main' | 'regular' | 'delivery'
  final String userType; // 'admin' | 'delivery'

  AppUser({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.role,
    required this.userType,
  });

  bool get isAdmin => userType == 'admin';
  bool get isMainAdmin => role == 'main';
  bool get isDelivery => userType == 'delivery';

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] ?? '',
        name: (j['name'] ?? j['username'] ?? '').toString(),
        email: j['email']?.toString(),
        phone: j['phone']?.toString(),
        role: (j['role'] ?? 'regular').toString(),
        userType: (j['user_type'] ?? 'admin').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'user_type': userType,
      };
}
