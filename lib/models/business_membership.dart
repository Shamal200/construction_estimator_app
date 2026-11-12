import 'package:cloud_firestore/cloud_firestore.dart';

enum BusinessRole {
  owner,
  admin,
  estimator,
  employee,
  viewer;

  String get label {
    switch (this) {
      case BusinessRole.owner:
        return 'Owner';
      case BusinessRole.admin:
        return 'Admin';
      case BusinessRole.estimator:
        return 'Estimator';
      case BusinessRole.employee:
        return 'Employee';
      case BusinessRole.viewer:
        return 'Viewer';
    }
  }

  static BusinessRole fromString(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'owner':
        return BusinessRole.owner;
      case 'admin':
        return BusinessRole.admin;
      case 'estimator':
        return BusinessRole.estimator;
      case 'employee':
        return BusinessRole.employee;
      case 'viewer':
      default:
        return BusinessRole.viewer;
    }
  }
}

class BusinessMembership {
  const BusinessMembership({
    required this.userId,
    required this.businessId,
    required this.role,
    required this.joinedAt,
    this.isActive = true,
    this.invitationId,
  });

  final String userId;
  final String businessId;
  final BusinessRole role;
  final DateTime joinedAt;
  final bool isActive;
  final String? invitationId;

  bool get canViewData => true;

  bool get canEditBusiness =>
      role == BusinessRole.owner || role == BusinessRole.admin;

  bool get canManageMembers =>
      role == BusinessRole.owner || role == BusinessRole.admin;

  bool get canCreateQuotations =>
      role == BusinessRole.owner ||
      role == BusinessRole.admin ||
      role == BusinessRole.estimator ||
      role == BusinessRole.employee;

  bool get canEditSettings =>
      role == BusinessRole.owner || role == BusinessRole.admin;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'businessId': businessId,
      'role': role.name,
      'joinedAt': joinedAt.toIso8601String(),
      'isActive': isActive,
      'invitationId': invitationId,
    };
  }

  factory BusinessMembership.fromMap(Map<String, dynamic> map) {
    final joinedAtValue = map['joinedAt'];
    final joinedAt = joinedAtValue is Timestamp
        ? joinedAtValue.toDate()
        : DateTime.tryParse(joinedAtValue as String? ?? '') ?? DateTime.now();

    return BusinessMembership(
      userId: map['userId'] as String? ?? '',
      businessId: map['businessId'] as String? ?? '',
      role: BusinessRole.fromString(map['role'] as String?),
      joinedAt: joinedAt,
      isActive: map['isActive'] as bool? ?? true,
      invitationId: map['invitationId'] as String?,
    );
  }
}
