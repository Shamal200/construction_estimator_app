import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
    } on FirebaseException catch (error) {
      debugPrint('Firebase configuration not ready: $error');
    } catch (error) {
      debugPrint('Firebase initialization failed: $error');
    }
  }
}
