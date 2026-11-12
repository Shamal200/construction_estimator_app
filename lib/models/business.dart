import 'package:cloud_firestore/cloud_firestore.dart';

class Business {
  const Business({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.currency,
    required this.defaultTaxRate,
    required this.createdAt,
    required this.ownerId,
    this.website = '',
    this.taxRegistrationNumber = '',
    this.status = 'active',
  });

  final String id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final String website;
  final String taxRegistrationNumber;
  final String currency;
  final double defaultTaxRate;
  final DateTime createdAt;
  final String ownerId;
  final String status;

  bool get isValid {
    return name.trim().isNotEmpty &&
        address.trim().isNotEmpty &&
        phone.trim().isNotEmpty &&
        email.trim().isNotEmpty &&
        currency.trim().isNotEmpty;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'taxRegistrationNumber': taxRegistrationNumber,
      'currency': currency,
      'defaultTaxRate': defaultTaxRate,
      'createdAt': Timestamp.fromDate(createdAt),
      'ownerId': ownerId,
      'status': status,
    };
  }

  factory Business.fromMap(Map<String, dynamic> map, String id) {
    final dynamic createdValue = map['createdAt'];
    final createdAt = createdValue is Timestamp
        ? createdValue.toDate()
        : (createdValue is String
              ? DateTime.tryParse(createdValue)
              : DateTime.now());

    return Business(
      id: id,
      name: map['name'] as String? ?? '',
      address: map['address'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      website: map['website'] as String? ?? '',
      taxRegistrationNumber: map['taxRegistrationNumber'] as String? ?? '',
      currency: map['currency'] as String? ?? '',
      defaultTaxRate: (map['defaultTaxRate'] as num?)?.toDouble() ?? 0,
      createdAt: createdAt ?? DateTime.now(),
      ownerId: map['ownerId'] as String? ?? '',
      status: map['status'] as String? ?? 'active',
    );
  }
}
