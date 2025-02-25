import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart' as loc;
import 'package:geolocator/geolocator.dart';
import 'package:logging/logging.dart';

class ProfileService {
  final _logger = Logger('ProfileService');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final loc.Location _location = loc.Location();

  Future<void> updateProfile(Map<String, dynamic> profileData) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated';

    // Get location if permission is granted
    if (profileData['includeLocation'] == true) {
      try {
        final locationData = await _getLocation();
        if (locationData != null) {
          profileData['location'] = {
            'latitude': locationData.latitude,
            'longitude': locationData.longitude,
            'timestamp': FieldValue.serverTimestamp(),
            'accuracy': locationData is Position ? locationData.accuracy : null,
          };
        }
      } catch (e) {
        _logger.warning('Location error: $e');
        // Continue without location if there's an error
      }
    }

    // Remove temporary flags
    profileData.remove('includeLocation');

    // Update profile
    await _firestore.collection('users').doc(user.uid).update({
      ...profileData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<dynamic> _getLocation() async {
    // Try primary location service first
    try {
      final hasPermission = await _location.hasPermission();
      if (hasPermission == loc.PermissionStatus.granted) {
        return await _location.getLocation();
      }

      final permissionStatus = await _location.requestPermission();
      if (permissionStatus == loc.PermissionStatus.granted) {
        return await _location.getLocation();
      }
    } catch (e) {
      _logger.warning('Primary location service failed: $e');
    }

    // Fall back to Geolocator if primary service fails
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requestPermission = await Geolocator.requestPermission();
        if (requestPermission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      _logger.warning('Backup location service failed: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getProfileData() async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated';

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data() ?? {};
  }

  Future<bool> updateVerificationStatus(String userId, String status) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'verificationStatus': status,
        'isVerified': status == 'approved',
        'verificationUpdatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _logger.severe('Error updating verification status: $e');
      return false;
    }
  }

  Future<void> updateLocationSettings(bool enabled) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated';

    await _firestore.collection('users').doc(user.uid).update({
      'locationEnabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePrivacySettings(Map<String, bool> settings) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated';

    await _firestore.collection('users').doc(user.uid).update({
      'privacySettings': settings,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
