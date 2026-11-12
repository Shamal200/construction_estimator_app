class BusinessInvitation {
  const BusinessInvitation({
    required this.id,
    required this.businessId,
    required this.email,
    required this.role,
    required this.invitedByUserId,
    required this.createdAt,
    required this.expiresAt,
    this.status = 'pending',
    this.acceptedByUserId,
  });

  final String id;
  final String businessId;
  final String email;
  final String role;
  final String invitedByUserId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String status;
  final String? acceptedByUserId;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'email': email,
      'role': role,
      'invitedByUserId': invitedByUserId,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'status': status,
      'acceptedByUserId': acceptedByUserId,
    };
  }

  factory BusinessInvitation.fromMap(Map<String, dynamic> map) {
    return BusinessInvitation(
      id: map['id'] as String? ?? '',
      businessId: map['businessId'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'employee',
      invitedByUserId: map['invitedByUserId'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      expiresAt:
          DateTime.tryParse(map['expiresAt'] as String? ?? '') ??
          DateTime.now(),
      status: map['status'] as String? ?? 'pending',
      acceptedByUserId: map['acceptedByUserId'] as String?,
    );
  }
}
