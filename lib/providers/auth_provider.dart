import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

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
      _userData = null;
    }
    notifyListeners();
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

  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    final credential =
        await _authService.signInWithEmailAndPassword(email, password);
    _user = credential.user;
    notifyListeners();
    return credential;
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

  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password, String username) async {
    final credential = await _authService.registerWithEmailAndPassword(
        email, password, username);
    _user = credential.user;
    notifyListeners();
    return credential;
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

  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    if (_user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _authService.updateUserPreferences(_user!.uid, preferences);
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
}
