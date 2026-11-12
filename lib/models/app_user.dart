import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.createdAt,
    this.activeBusinessId,
    this.businessIds = const [],
    this.subscriptionPlan = 'free',
    this.subscriptionStatus = 'active',
  });

  final String uid;
  final String fullName;
  final String email;
  final DateTime createdAt;
  final String? activeBusinessId;
  final List<String> businessIds;
  final String subscriptionPlan;
  final String subscriptionStatus;

  bool get hasActiveBusiness => (activeBusinessId ?? '').isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'activeBusinessId': activeBusinessId,
      'businessIds': businessIds,
      'subscriptionPlan': subscriptionPlan,
      'subscriptionStatus': subscriptionStatus,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    final dynamic createdValue = map['createdAt'];
    final createdAt = createdValue is Timestamp
        ? createdValue.toDate()
        : (createdValue is String
              ? DateTime.tryParse(createdValue)
              : DateTime.now());

    return AppUser(
      uid: uid,
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      createdAt: createdAt ?? DateTime.now(),
      activeBusinessId: map['activeBusinessId'] as String?,
      businessIds: List<String>.from(
        map['businessIds'] as List? ?? const <String>[],
      ),
      subscriptionPlan: map['subscriptionPlan'] as String? ?? 'free',
      subscriptionStatus: map['subscriptionStatus'] as String? ?? 'active',
    );
  }

  AppUser copyWith({
    String? uid,
    String? fullName,
    String? email,
    DateTime? createdAt,
    String? activeBusinessId,
    List<String>? businessIds,
    String? subscriptionPlan,
    String? subscriptionStatus,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      activeBusinessId: activeBusinessId ?? this.activeBusinessId,
      businessIds: businessIds ?? this.businessIds,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
    );
  }
}
