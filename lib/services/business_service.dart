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
    required String businessRegistrationNumber,
    required String taxRegistrationNumber,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw const FormatException(
        'You must be signed in to create a business.',
      );
    }

    final cleanName = name.trim();
    final cleanAddress = address.trim();
    final cleanPhone = phone.trim();
    final cleanEmail = email.trim();
    final cleanCurrency = currency.trim().toUpperCase();

    if (cleanName.isEmpty ||
        cleanAddress.isEmpty ||
        cleanPhone.isEmpty ||
        cleanEmail.isEmpty ||
        cleanCurrency.length != 3) {
      throw const FormatException('Please provide valid business details.');
    }

    if (!defaultTaxRate.isFinite ||
        defaultTaxRate < 0 ||
        defaultTaxRate > 100) {
      throw const FormatException(
        'The default tax percentage must be between 0 and 100.',
      );
    }

    final userRef = _firestore.collection('users').doc(user.uid);
    final businessRef = _firestore.collection('businesses').doc();
    final memberRef = businessRef.collection('members').doc(user.uid);

    final business = Business(
      id: businessRef.id,
      name: cleanName,
      address: cleanAddress,
      phone: cleanPhone,
      email: cleanEmail,
      website: website.trim(),
      businessRegistrationNumber: businessRegistrationNumber.trim(),
      taxRegistrationNumber: taxRegistrationNumber.trim(),
      currency: cleanCurrency,
      defaultTaxRate: defaultTaxRate,
      createdAt: DateTime.now(),
      ownerId: user.uid,
    );

    final batch = _firestore.batch();

    batch.set(businessRef, {
      'id': businessRef.id,
      'name': business.name,
      'address': business.address,
      'phone': business.phone,
      'email': business.email,
      'website': business.website,
      'businessRegistrationNumber': business.businessRegistrationNumber,
      'taxRegistrationNumber': business.taxRegistrationNumber,
      'currency': business.currency,
      'defaultTaxRate': business.defaultTaxRate,
      'createdAt': FieldValue.serverTimestamp(),
      'ownerId': user.uid,
      'status': 'active',
    });

    batch.set(memberRef, {
      'userId': user.uid,
      'businessId': businessRef.id,
      'role': 'owner',
      'joinedAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'invitationId': null,
    });

    batch.update(userRef, {
      'businessIds': FieldValue.arrayUnion([businessRef.id]),
      'activeBusinessId': businessRef.id,
    });

    await batch.commit();

    return business;
  }

  Future<BusinessInvitation> createInvitation({
    required String businessId,
    required String email,
    required String role,
    required DateTime expiresAt,
  }) async {
    throw UnsupportedError(
      'Business invitations will be implemented in the next module.',
    );
  }

  Future<void> acceptInvitation({
    required String invitationId,
    required String businessId,
    required String email,
  }) async {
    throw UnsupportedError(
      'Invitation acceptance will be implemented in the next module.',
    );
  }

  Future<void> revokeInvitation({required String invitationId}) async {
    throw UnsupportedError(
      'Invitation management will be implemented in the next module.',
    );
  }
}
