class Customer {
  const Customer({
    required this.id,
    required this.fullName,
    this.customerNumber = '',
    this.companyName = '',
    this.phoneNumber = '',
    this.email = '',
    this.address = '',
    this.notes = '',
    required this.createdAt,
  });

  final String id;
  final String customerNumber;
  final String fullName;
  final String companyName;
  final String phoneNumber;
  final String email;
  final String address;
  final String notes;
  final DateTime createdAt;

  factory Customer.empty() {
    return Customer(
      id: '',
      fullName: '',
      createdAt: DateTime.now(),
    );
  }

  Customer copyWith({
    String? id,
    String? customerNumber,
    String? fullName,
    String? companyName,
    String? phoneNumber,
    String? email,
    String? address,
    String? notes,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      customerNumber: customerNumber ?? this.customerNumber,
      fullName: fullName ?? this.fullName,
      companyName: companyName ?? this.companyName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerNumber': customerNumber,
      'fullName': fullName,
      'companyName': companyName,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String? ?? '',
      customerNumber: map['customerNumber'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      companyName: map['companyName'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      email: map['email'] as String? ?? '',
      address: map['address'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }
}