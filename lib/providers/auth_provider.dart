import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  AuthProvider() {
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

  Future<void> _loadUserData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _userData = await _authService.getCurrentUser();
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signInWithEmailAndPassword(email, password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
    notifyListeners();

    try {
      await _authService.registerWithEmailAndPassword(
          email, password, username);
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
