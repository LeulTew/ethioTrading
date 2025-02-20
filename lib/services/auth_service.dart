import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
    String username,
  ) async {
    try {
      // Create the user account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile in Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'username': username,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'tradingLevel': 'beginner',
        'isVerified': false,
      });

      // Sign in the user immediately after registration
      await signInWithEmailAndPassword(email, password);

      return credential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<bool> isEmailRegistered(String email) async {
    try {
      // Use a try-catch with createUserWithEmailAndPassword instead of the deprecated method
      bool exists = true;
      try {
        // Try to create a temporary user
        final credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: DateTime.now().toString(), // Temporary random password
        );
        // If successful, the email is not registered
        // Delete the temporary user immediately
        await credential.user?.delete();
        exists = false;
      } on FirebaseAuthException catch (e) {
        // If we get 'email-already-in-use', the email exists
        if (e.code == 'email-already-in-use') {
          exists = true;
        } else {
          rethrow;
        }
      }
      return exists;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) throw Exception('User profile not found');

    return {
      'uid': user.uid,
      'email': user.email,
      ...doc.data()!,
    };
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw Exception('Error updating profile: ${e.toString()}');
    }
  }

  Future<void> updateUserPreferences(
      String uid, Map<String, dynamic> preferences) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'preferences': preferences,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating preferences: ${e.toString()}');
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');
      await user.updatePassword(newPassword);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Delete user data from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete the authentication account
      await user.delete();
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<bool> verifyPhoneNumber(String phoneNumber) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      bool verificationCompleted = false;
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await user.updatePhoneNumber(credential);
          verificationCompleted = true;
        },
        verificationFailed: (FirebaseAuthException e) {
          throw _handleAuthException(e);
        },
        codeSent: (String verificationId, int? resendToken) {},
        codeAutoRetrievalTimeout: (String verificationId) {},
      );

      return verificationCompleted;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Exception _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return Exception('No user found with this email');
        case 'wrong-password':
          return Exception('Invalid password');
        case 'email-already-in-use':
          return Exception('Email is already registered');
        case 'invalid-email':
          return Exception('Invalid email address');
        case 'operation-not-allowed':
          return Exception('Operation not allowed');
        case 'weak-password':
          return Exception('Password is too weak');
        case 'user-disabled':
          return Exception('This account has been disabled');
        case 'too-many-requests':
          return Exception('Too many attempts. Please try again later');
        case 'network-request-failed':
          return Exception('Network error. Please check your connection');
        default:
          return Exception('Authentication error: ${e.message}');
      }
    }
    return Exception('An unexpected error occurred');
  }
}
