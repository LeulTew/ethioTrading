import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user profile data
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data();
    }
    return null;
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
    String username,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': username,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'preferences': {
          'theme': 'system',
          'language': 'am', // Amharic by default
          'notifications': true,
        },
      });

      return userCredential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Update user profile
  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
  }

  // Update user preferences
  Future<void> updateUserPreferences(
      String userId, Map<String, dynamic> preferences) async {
    await _firestore.collection('users').doc(userId).update({
      'preferences': preferences,
    });
  }

  // Password reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Error handling
  String _handleAuthError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'ተጠቃሚው አልተገኘም'; // User not found
        case 'wrong-password':
          return 'የተሳሳተ የይለፍ ቃል'; // Wrong password
        case 'email-already-in-use':
          return 'ኢሜይል አድራሻው ቀድሞ ጥቅም ላይ ውሏል'; // Email already in use
        case 'weak-password':
          return 'ደካማ የይለፍ ቃል'; // Weak password
        case 'invalid-email':
          return 'ልክ ያልሆነ ኢሜይል አድራሻ'; // Invalid email
        default:
          return 'የተሳሳተ ግብዓት'; // Error occurred
      }
    }
    return 'አንድ ስህተት ተከስቷል'; // An error occurred
  }

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
