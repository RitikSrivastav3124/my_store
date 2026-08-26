import 'app_user.dart';

class StoreCustomer {
  const StoreCustomer({
    required this.id,
    required this.user,
    required this.creditLimit,
    required this.currentDue,
    this.ownerId,
    this.notes,
    this.updatedAt,
  });

  final String id;
  final String? ownerId;
  final AppUser user;
  final double creditLimit;
  final double currentDue;
  final String? notes;
  final DateTime? updatedAt;

  factory StoreCustomer.fromJson(Map<String, dynamic> json) {
    final userJson = json['userId'] is Map<String, dynamic>
        ? json['userId'] as Map<String, dynamic>
        : <String, dynamic>{
            '_id': json['userId']?.toString() ?? json['_id']?.toString(),
            'name': json['name']?.toString() ?? '',
            'phone': json['phone']?.toString() ?? '',
            'email': json['email']?.toString(),
            'role': 'customer',
            'status': json['status']?.toString() ?? 'active',
          };
    return StoreCustomer(
      id: json['_id']?.toString() ?? '',
      ownerId: json['ownerId']?.toString(),
      user: AppUser.fromJson(userJson),
      creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 0,
      currentDue: (json['currentDue'] as num?)?.toDouble() ?? 0,
      notes: json['notes']?.toString(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}
