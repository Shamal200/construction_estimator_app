import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../models/business.dart';
import '../models/business_invitation.dart';
import '../models/business_membership.dart';

class BusinessService {
  BusinessService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<AppUser?> loadUserProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) {
      return null;
    }

    return AppUser.fromMap(doc.data() ?? const <String, dynamic>{}, userId);
  }

  Future<List<Business>> loadUserBusinesses(List<String> businessIds) async {
    if (businessIds.isEmpty) {
      return const <Business>[];
    }

    final futures = businessIds.map((businessId) async {
      final doc = await _firestore
          .collection('businesses')
          .doc(businessId)
          .get();
      if (!doc.exists) {
        return null;
      }
      return Business.fromMap(
        doc.data() ?? const <String, dynamic>{},
        businessId,
      );
    }).toList();

    final businesses = await Future.wait(futures);
    return businesses.whereType<Business>().toList();
  }

  Future<List<BusinessMembership>> loadMembershipsForUser(String userId) async {
    final user = await _firestore.collection('users').doc(userId).get();
    final businessIds = List<String>.from(
      user.data()?['businessIds'] as List? ?? const <String>[],
    );

    final memberships = <BusinessMembership>[];
    for (final businessId in businessIds) {
      final doc = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('members')
          .doc(userId)
          .get();

      if (doc.exists) {
        memberships.add(
          BusinessMembership.fromMap(doc.data() ?? const <String, dynamic>{}),
        );
      }
    }

    return memberships;
  }

  Future<void> setActiveBusiness(String userId, String businessId) async {
    await _firestore.collection('users').doc(userId).update({
      'activeBusinessId': businessId,
    });
  }

  Future<Business> createBusiness({
    required String name,
    required String address,
    required String phone,
    required String email,
    required String currency,
    required double defaultTaxRate,
    required String website,
    required String taxRegistrationNumber,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const FormatException(
        'A signed-in user is required to create a business.',
      );
    }

    throw UnsupportedError(
      'Creating a business requires trusted backend logic. It is intentionally unavailable on the Spark cloud project; use the local Firebase emulators for development.',
    );
  }

  Future<BusinessInvitation> createInvitation({
    required String businessId,
    required String email,
    required String role,
    required DateTime expiresAt,
  }) async {
    throw UnsupportedError(
      'Creating invitations requires trusted backend logic. It is pending deployment; direct Firestore invitation writes are disabled.',
    );
  }

  Future<void> acceptInvitation({
    required String invitationId,
    required String businessId,
    required String email,
  }) async {
    throw UnsupportedError(
      'Accepting invitations requires trusted backend logic that verifies the authenticated email and invitation expiry. It is pending backend deployment.',
    );
  }

  Future<void> revokeInvitation({required String invitationId}) async {
    throw UnsupportedError(
      'Revoking invitations requires trusted backend membership checks. It is pending backend deployment.',
    );
  }
}
