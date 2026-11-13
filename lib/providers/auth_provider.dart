import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/business.dart';
import '../models/business_membership.dart';
import '../services/auth_service.dart';
import '../services/business_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _authSubscription = _auth.authStateChanges.listen(_handleAuthStateChange);
  }

  final AuthService _auth = AuthService();
  final BusinessService _businessService = BusinessService();
  StreamSubscription<User?>? _authSubscription;

  User? _user;
  AppUser? _profile;
  List<Business> _businesses = const <Business>[];
  List<BusinessMembership> _memberships = const <BusinessMembership>[];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  User? get user => _user;
  AppUser? get profile => _profile;
  List<Business> get businesses => _businesses;
  List<BusinessMembership> get memberships => _memberships;
  bool get isLoading => _isLoading || _isSubmitting;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get hasBusiness =>
      (_profile?.businessIds.isNotEmpty ?? false) || _businesses.isNotEmpty;
 bool get hasActiveBusiness {
  final activeId = _profile?.activeBusinessId;

  if (activeId == null || activeId.isEmpty) {
    return false;
  }

  return activeBusiness != null &&
      membershipFor(activeId) != null;
}
  BusinessMembership? membershipFor(String businessId) {
    for (final membership in _memberships) {
      if (membership.businessId == businessId && membership.isActive) {
        return membership;
      }
    }
    return null;
  }

  Business? get activeBusiness {
    final activeId = _profile?.activeBusinessId;
    if (activeId == null || activeId.isEmpty) {
      return null;
    }

    try {
      return _businesses.firstWhere((business) => business.id == activeId);
    } catch (_) {
      return null;
    }
  }

  Future<void> initialize() async {
    _user = _auth.currentUser;
    await _refreshSession(createMissingProfile: true);
  }

  Future<void> _handleAuthStateChange(User? user) async {
    _user = user;
    if (user == null) {
      _profile = null;
      _businesses = const <Business>[];
      _memberships = const <BusinessMembership>[];
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    await _refreshSession();
  }

  Future<void> _refreshSession({bool createMissingProfile = false}) async {
    if (_user == null) {
      _profile = null;
      _businesses = const <Business>[];
      _memberships = const <BusinessMembership>[];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _auth.fetchUserProfile(_user!.uid);
      if (_profile == null && createMissingProfile) {
        final fallback = AppUser(
          uid: _user!.uid,
          fullName: _user!.displayName ?? 'User',
          email: _user!.email ?? '',
          createdAt: DateTime.now(),
        );
        await _auth.createUserProfile(fallback);
        _profile = fallback;
      }

      if (_profile != null) {
        final businessIds = _profile!.businessIds;
        _memberships = await _businessService.loadMembershipsForUser(
          _user!.uid,
        );
        _businesses = await _businessService.loadUserBusinesses(businessIds);
      } else {
        _businesses = const <Business>[];
        _memberships = const <BusinessMembership>[];
      }
    } on Exception catch (error) {
      _errorMessage = error is FirebaseException
          ? AuthException.firebaseMessage(error)
          : error.toString();
      if (kDebugMode) {
        print(error);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _user = _auth.currentUser;
      await _refreshSession(createMissingProfile: true);
    } on AuthException catch (error) {
      _errorMessage = error.message;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _auth.registerWithEmailAndPassword(
        fullName: fullName,
        email: email,
        password: password,
      );
      _user = _auth.currentUser;
      await _refreshSession();
    } on AuthException catch (error) {
      _errorMessage = error.message;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _auth.sendPasswordResetEmail(email);
    } on AuthException catch (error) {
      _errorMessage = error.message;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> sendVerificationEmail() async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _auth.sendEmailVerification();
    } on AuthException catch (error) {
      _errorMessage = error.message;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isSubmitting = true;
    notifyListeners();

    try {
      await _auth.signOut();
      _profile = null;
      _businesses = const <Business>[];
      _memberships = const <BusinessMembership>[];
      _errorMessage = null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> selectBusiness(String businessId) async {
    if (_user == null) {
      _errorMessage = 'You must be signed in to switch businesses.';
      notifyListeners();
      return;
    }

    try {
      await _auth.setActiveBusiness(businessId);
      if (_profile != null) {
        _profile = _profile!.copyWith(activeBusinessId: businessId);
      }
      notifyListeners();
    } on AuthException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
