import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Login with email and password
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // Sign in with Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get user role from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        return {'success': false, 'message': 'User data not found.'};
      }

      String role = userDoc['role'];

      // Register FCM token in background — does not block login
      _registerFcmToken();

      return {'success': true, 'role': role};

    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'user-not-found') {
        message = 'No user found with this email.';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address.';
      } else {
        message = 'Login failed. Please try again.';
      }
      return {'success': false, 'message': message};
    }
  }

  // Logout — clears FCM token before signing out
  Future<void> logout() async {
    await NotificationService.clearToken();
    await _auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // ─── FCM Token Registration ───────────────────────────────────────────────

  /// Requests notification permission (required on iOS and web),
  /// then fetches the FCM token and saves it to Firestore.
  /// Silently skips if permission is denied or token fetch fails.
  Future<void> _registerFcmToken() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request permission — required for iOS and web browsers
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Only proceed if permission was granted or already provisional
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      // Get the FCM token for this device/browser
      final token = await messaging.getToken();
      if (token == null) return;

      // Save token to Firestore via NotificationService
      await NotificationService.saveToken(token);

      // Listen for token refresh and update Firestore accordingly
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        NotificationService.saveToken(newToken);
      });

    } catch (_) {
      // Silently ignore — FCM failure should never block login
    }
  }
}