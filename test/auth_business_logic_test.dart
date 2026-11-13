import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:construction_estimator_app/models/app_user.dart';
import 'package:construction_estimator_app/models/business.dart';
import 'package:construction_estimator_app/models/business_membership.dart';
import 'package:construction_estimator_app/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Firestore permission errors receive an actionable message', () {
    final message = AuthException.firebaseMessage(
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
    );

    expect(message, contains('profile setup was denied'));
    expect(message, contains('Sign in again'));
  });

  group('business permissions', () {
    test('owner can manage all business membership operations', () {
      final membership = BusinessMembership(
        userId: 'uid-1',
        businessId: 'business-1',
        role: BusinessRole.owner,
        joinedAt: DateTime.now(),
      );

      expect(membership.canManageMembers, isTrue);
      expect(membership.canEditBusiness, isTrue);
      expect(membership.canViewData, isTrue);
    });

    test('viewer can read but cannot modify membership or settings', () {
      final membership = BusinessMembership(
        userId: 'uid-2',
        businessId: 'business-1',
        role: BusinessRole.viewer,
        joinedAt: DateTime.now(),
      );

      expect(membership.canViewData, isTrue);
      expect(membership.canManageMembers, isFalse);
      expect(membership.canEditBusiness, isFalse);
    });

    test('membership parses Firestore timestamps and assigned role', () {
      final joinedAt = DateTime.utc(2026, 11, 12);
      final membership = BusinessMembership.fromMap({
        'userId': 'uid-4',
        'businessId': 'business-2',
        'role': 'estimator',
        'joinedAt': Timestamp.fromDate(joinedAt),
        'isActive': true,
      });

      expect(membership.role, BusinessRole.estimator);
      expect(membership.joinedAt.isAtSameMomentAs(joinedAt), isTrue);
    });

    test('active business selection is stored on user profile', () {
      final profile = AppUser(
        uid: 'uid-3',
        fullName: 'John Builder',
        email: 'john@example.com',
        createdAt: DateTime.now(),
        activeBusinessId: 'business-1',
        businessIds: const ['business-1'],
      );

      expect(profile.activeBusinessId, 'business-1');
      expect(profile.businessIds, contains('business-1'));
    });
  });

  group('business validation', () {
    test('business requires a valid company name and currency', () {
      final business = Business(
        id: 'biz-1',
        name: 'BuildCalc Pro',
        address: '1 Main Street',
        phone: '+123456789',
        email: 'hello@example.com',
        currency: 'USD',
        defaultTaxRate: 10,
        createdAt: DateTime.now(),
        ownerId: 'uid-1',
      );

      expect(business.name.trim().isNotEmpty, isTrue);
      expect(business.currency.trim().isNotEmpty, isTrue);
      expect(business.isValid, isTrue);
    });
  });
}
