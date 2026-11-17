
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
    this.businessRegistrationNumber = '',
    this.taxRegistrationNumber = '',
    this.status = 'active',

    // Company branding
    this.logoBase64 = '',
    this.defaultQuotationTemplate = 'standard_blue',

    // Company bank details
    this.bankName = '',
    this.bankAccountName = '',
    this.bankAccountNumber = '',
    this.bankBranch = '',
    this.bankBranchCode = '',
    this.paymentInstructions = '',
  });

  final String id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final String website;
  final String businessRegistrationNumber;
  final String taxRegistrationNumber;
  final String currency;
  final double defaultTaxRate;
  final DateTime createdAt;
  final String ownerId;
  final String status;

  // Company branding
  final String logoBase64;
  final String defaultQuotationTemplate;

  // Company bank details
  final String bankName;
  final String bankAccountName;
  final String bankAccountNumber;
  final String bankBranch;
  final String bankBranchCode;
  final String paymentInstructions;

  bool get isValid {
    return name.trim().isNotEmpty &&
        address.trim().isNotEmpty &&
        phone.trim().isNotEmpty &&
        email.trim().isNotEmpty &&
        currency.trim().isNotEmpty &&
        defaultTaxRate >= 0 &&
        defaultTaxRate <= 100;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'businessRegistrationNumber': businessRegistrationNumber,
      'taxRegistrationNumber': taxRegistrationNumber,
      'currency': currency,
      'defaultTaxRate': defaultTaxRate,
      'createdAt': Timestamp.fromDate(createdAt),
      'ownerId': ownerId,
      'status': status,

      // Company branding
      'logoBase64': logoBase64,
      'defaultQuotationTemplate': defaultQuotationTemplate,

      // Company bank details
      'bankName': bankName,
      'bankAccountName': bankAccountName,
      'bankAccountNumber': bankAccountNumber,
      'bankBranch': bankBranch,
      'bankBranchCode': bankBranchCode,
      'paymentInstructions': paymentInstructions,
    };
  }

  factory Business.fromMap(Map<String, dynamic> map, String id) {
    final createdValue = map['createdAt'];

    final DateTime createdAt;

    if (createdValue is Timestamp) {
      createdAt = createdValue.toDate();
    } else if (createdValue is String) {
      createdAt = DateTime.tryParse(createdValue) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return Business(
      id: id,
      name: map['name'] as String? ?? '',
      address: map['address'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      website: map['website'] as String? ?? '',
      businessRegistrationNumber:
          map['businessRegistrationNumber'] as String? ?? '',
      taxRegistrationNumber:
          map['taxRegistrationNumber'] as String? ?? '',
      currency: map['currency'] as String? ?? '',
      defaultTaxRate:
          (map['defaultTaxRate'] as num?)?.toDouble() ?? 0,
      createdAt: createdAt,
      ownerId: map['ownerId'] as String? ?? '',
      status: map['status'] as String? ?? 'active',

      // Company branding
      logoBase64: map['logoBase64'] as String? ?? '',
      defaultQuotationTemplate:
          map['defaultQuotationTemplate'] as String? ??
              'standard_blue',

      // Company bank details
      bankName: map['bankName'] as String? ?? '',
      bankAccountName: map['bankAccountName'] as String? ?? '',
      bankAccountNumber: map['bankAccountNumber'] as String? ?? '',
      bankBranch: map['bankBranch'] as String? ?? '',
      bankBranchCode: map['bankBranchCode'] as String? ?? '',
      paymentInstructions:
          map['paymentInstructions'] as String? ?? '',
    );
  }
}