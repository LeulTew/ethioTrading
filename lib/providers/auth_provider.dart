import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  String? _error;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    _authService.authStateChanges.listen((user) {
      _user = user;
      if (user != null) {
        _loadUserData();
      } else {
        _userData = null;
      }
      notifyListeners();
    });
  }

  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;

  Future<void> _loadUserData() async {
    if (_user == null) return;

    try {
      _userData = await _authService.getCurrentUser();
    } catch (e) {
      _error = _getTranslatedError(e);
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signInWithEmailAndPassword(email, password);
      await _loadUserData();
    } catch (e) {
      _error = _getTranslatedError(e);
      throw Exception(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _getTranslatedError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
        case 'wrong-password':
          return 'invalid_credentials';
        case 'invalid-email':
          return 'enter_valid_email';
        case 'user-disabled':
          return 'account_disabled';
        case 'network-request-failed':
          return 'network_error';
        default:
          return 'server_error';
      }
    }
    return 'server_error';
  }

  Future<void> register(String email, String password, String username) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // First check if email already exists
      final emailExists = await _authService.isEmailRegistered(email);
      if (emailExists) {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'This email address is already in use.',
        );
      }

      // Proceed with registration
      final credential = await _authService.registerWithEmailAndPassword(
        email,
        password,
        username,
      );

      // Auto sign-in after registration
      _user = credential.user;
      await _loadUserData();
    } catch (e) {
      _error = _getTranslatedError(e);
      throw Exception(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _authService.updateUserProfile(_user!.uid, data);
      await _loadUserData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> executeTrade(Map<String, dynamic> tradeData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User not authenticated';

      // Start a batch write
      final batch = FirebaseFirestore.instance.batch();

      // Get user document reference
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      // Get current user data
      final userData = (await userRef.get()).data() ?? {};

      // Update user's portfolio
      final portfolio = (userData['portfolio'] as List?) ?? [];
      final existingPosition = portfolio.firstWhere(
        (p) => p['symbol'] == tradeData['symbol'],
        orElse: () => null,
      );

      if (tradeData['side'] == 'buy') {
        if (existingPosition == null) {
          portfolio.add({
            'symbol': tradeData['symbol'],
            'quantity': tradeData['quantity'],
            'avgPrice': tradeData['price'],
          });
        } else {
          final totalQuantity =
              existingPosition['quantity'] + tradeData['quantity'];
          final totalCost =
              (existingPosition['quantity'] * existingPosition['avgPrice']) +
                  (tradeData['quantity'] * tradeData['price']);
          existingPosition['quantity'] = totalQuantity;
          existingPosition['avgPrice'] = totalCost / totalQuantity;
        }
      }

      // Update user's cash balance
      final totalCost = tradeData['quantity'] * tradeData['price'] +
          tradeData['fees']['total'];
      if (tradeData['side'] == 'buy') {
        userData['balance'] = (userData['balance'] ?? 0.0) - totalCost;
      } else {
        userData['balance'] = (userData['balance'] ?? 0.0) + totalCost;
      }

      // Add trade to history
      final tradeRef = FirebaseFirestore.instance.collection('trades').doc();
      batch.set(tradeRef, {
        ...tradeData,
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update user data
      batch.update(userRef, {
        'portfolio': portfolio,
        'balance': userData['balance'],
      });

      // Commit the batch
      await batch.commit();
      notifyListeners();
    } catch (e) {
      throw 'Failed to execute trade: $e';
    }
  }

  Future<void> verifyAccount(Map<String, dynamic> verificationData) async {
    if (_user == null) throw 'User not authenticated';

    _isLoading = true;
    notifyListeners();

    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(_user!.uid);

      await userRef.update({
        'verificationStatus': 'pending',
        'verificationData': {
          ...verificationData,
          'submittedAt': FieldValue.serverTimestamp(),
        },
      });

      // For testing purposes, auto-approve verification
      await Future.delayed(const Duration(seconds: 2));
      await userRef.update({
        'isVerified': true,
        'verificationStatus': 'approved',
        'tradingEnabled': true,
        'tradingLimit': 1000000, // 1M ETB initial limit
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _loadUserData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
