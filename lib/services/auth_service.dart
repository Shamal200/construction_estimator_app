import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;

  static String friendlyMessage(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'weak-password':
        return 'The password is too weak. Please choose a stronger password.';
      case 'email-already-in-use':
        return 'This email already has an account. Please sign in instead.';
      case 'user-not-found':
        return 'No account was found for that email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'requires-recent-login':
        return 'Please sign in again to complete this action.';
      default:
        return 'Authentication failed. Please check your details and try again.';
    }
  }

  static String firebaseMessage(FirebaseException exception) {
    if (exception.code == 'permission-denied') {
      return 'Your account may have been created, but profile setup was denied. '
          'Sign in again to retry setup.';
    }

    return 'Your account may have been created, but your profile could not be '
        'saved. Check your connection and sign in again to retry setup.';
  }
}

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthException(AuthException.friendlyMessage(error));
    }
  }

  Future<UserCredential> registerWithEmailAndPassword({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final normalizedFullName = fullName.trim();
    if (normalizedFullName.isEmpty || normalizedFullName.length > 120) {
      throw const AuthException('Full name must be between 1 and 120 characters.');
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthException('Account creation failed. Please try again.');
      }

      final profile = AppUser(
        uid: user.uid,
        fullName: normalizedFullName,
        email: user.email ?? email.trim(),
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(profile.toMap());

      await user.sendEmailVerification();

      return credential;
    } on FirebaseAuthException catch (error) {
      throw AuthException(AuthException.friendlyMessage(error));
    } on FirebaseException catch (error) {
      throw AuthException(AuthException.firebaseMessage(error));
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw AuthException(AuthException.friendlyMessage(error));
    }
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('You are not signed in.');
    }

    try {
      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on FirebaseAuthException catch (error) {
      throw AuthException(AuthException.friendlyMessage(error));
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<AppUser?> fetchUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      return null;
    }

    return AppUser.fromMap(doc.data() ?? const <String, dynamic>{}, uid);
  }

  Future<void> updateUserProfile(AppUser user) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(user.toMap(), SetOptions(merge: true));
  }

  Future<void> createUserProfile(AppUser user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<void> setActiveBusiness(String businessId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('You must be signed in to select a business.');
    }

    await _firestore.collection('users').doc(user.uid).update({
      'activeBusinessId': businessId,
    });
  }
}
