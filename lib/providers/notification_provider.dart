import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:logging/logging.dart';
import '../models/asset.dart';

class NotificationProvider with ChangeNotifier {
  final Logger _logger = Logger('NotificationProvider');
  final FirebaseDatabase _database;

  List<Map<String, dynamic>> _notifications = [];
  bool _loading = false;

  // Constructor with dependency injection
  NotificationProvider({required FirebaseDatabase database})
      : _database = database {
    _loadNotifications();
    _setupRealtimeListeners();
  }

  // Getters
  List<Map<String, dynamic>> get notifications => _notifications;
  bool get loading => _loading;
  int get unreadCount =>
      _notifications.where((n) => !(n['read'] as bool)).length;

  // Get notifications
  Future<void> _loadNotifications() async {
    _loading = true;
    notifyListeners();

    try {
      // Try to load from local storage first
      final prefs = await SharedPreferences.getInstance();
      final savedNotifications = prefs.getString('notifications');

      if (savedNotifications != null) {
        final decoded = jsonDecode(savedNotifications) as List;
        _notifications = decoded.cast<Map<String, dynamic>>();
      }

      // Then try to fetch from Firebase if available
      final snapshot = await _database.ref('notifications').get();

      if (snapshot.exists && snapshot.value != null) {
        // Merge with local notifications
        final data = snapshot.value as Map<dynamic, dynamic>;

        data.forEach((key, value) {
          // Check if notification already exists locally
          final exists = _notifications.any((n) => n['id'] == key);

          if (!exists) {
            final Map<String, dynamic> notification = {
              'id': key,
              'type': value['type'] ?? 'system',
              'title': value['title'] ?? 'Notification',
              'description': value['description'] ?? '',
              'timestamp': DateTime.parse(
                  value['timestamp'] ?? DateTime.now().toIso8601String()),
              'read': value['read'] ?? false,
              'data': value['data'] ?? {},
            };

            _notifications.add(notification);
          }
        });

        // Sort by timestamp (newest first)
        _notifications.sort((a, b) {
          final aTime = a['timestamp'] as DateTime;
          final bTime = b['timestamp'] as DateTime;
          return bTime.compareTo(aTime);
        });

        await _saveNotifications();
      }
    } catch (e) {
      _logger.severe('Error loading notifications: $e');

      // If both sources fail, initialize with default empty list
      if (_notifications.isEmpty) {
        _createSampleNotifications();
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Save notifications to local storage
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_notifications);
      await prefs.setString('notifications', jsonString);
    } catch (e) {
      _logger.severe('Error saving notifications: $e');
    }
  }

  // Setup real-time listeners for new notifications
  void _setupRealtimeListeners() {
    _database.ref('notifications').onChildAdded.listen((event) {
      if (event.snapshot.value != null) {
        // Check if notification already exists
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final id = event.snapshot.key;

        // Skip if notification already exists
        if (_notifications.any((n) => n['id'] == id)) {
          return;
        }

        // Add new notification
        final notification = {
          'id': id,
          'type': data['type'] ?? 'system',
          'title': data['title'] ?? 'Notification',
          'description': data['description'] ?? '',
          'timestamp': DateTime.parse(
              data['timestamp'] ?? DateTime.now().toIso8601String()),
          'read': data['read'] ?? false,
          'data': data['data'] ?? {},
        };

        _notifications.insert(0, notification);
        _saveNotifications();
        notifyListeners();
      }
    });
  }

  // Mark notification as read
  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n['id'] == id);

    if (index >= 0) {
      _notifications[index]['read'] = true;

      // Update in Firebase if possible
      try {
        await _database.ref('notifications/$id').update({'read': true});
      } catch (e) {
        _logger.warning(
            'Could not update notification read status in Firebase: $e');
      }

      await _saveNotifications();
      notifyListeners();
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i]['read'] = true;

      // Update in Firebase if possible
      try {
        final id = _notifications[i]['id'];
        await _database.ref('notifications/$id').update({'read': true});
      } catch (e) {
        _logger.warning(
            'Could not update all notification read status in Firebase: $e');
      }
    }

    await _saveNotifications();
    notifyListeners();
  }

  // Delete notification
  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n['id'] == id);

    // Delete from Firebase if possible
    try {
      await _database.ref('notifications/$id').remove();
    } catch (e) {
      _logger.warning('Could not delete notification from Firebase: $e');
    }

    await _saveNotifications();
    notifyListeners();
  }

  // Clear all notifications
  Future<void> clearAll() async {
    _notifications.clear();

    // Clear from Firebase if possible
    try {
      await _database.ref('notifications').remove();
    } catch (e) {
      _logger.warning('Could not clear all notifications from Firebase: $e');
    }

    await _saveNotifications();
    notifyListeners();
  }

  // Add a notification about a market update
  Future<void> addMarketAlert(String title, String description) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final notification = {
      'id': id,
      'type': 'alert',
      'title': title,
      'description': description,
      'timestamp': DateTime.now(),
      'read': false,
      'data': {},
    };

    _notifications.insert(0, notification);

    // Save to Firebase if possible
    try {
      await _database.ref('notifications/$id').set({
        'type': 'alert',
        'title': title,
        'description': description,
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
        'data': {},
      });
    } catch (e) {
      _logger.warning('Could not save market alert to Firebase: $e');
    }

    await _saveNotifications();
    notifyListeners();
  }

  // Add a notification about a trade
  Future<void> addTradeNotification(
      String action, Asset asset, int shares, double price) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final title =
        action == 'buy' ? 'Buy Order Executed' : 'Sell Order Executed';

    final description = action == 'buy'
        ? 'You successfully purchased $shares shares of ${asset.symbol} at \$${price.toStringAsFixed(2)} per share.'
        : 'You successfully sold $shares shares of ${asset.symbol} at \$${price.toStringAsFixed(2)} per share.';

    final notification = {
      'id': id,
      'type': 'trade',
      'title': title,
      'description': description,
      'timestamp': DateTime.now(),
      'read': false,
      'data': {
        'action': action,
        'symbol': asset.symbol,
        'name': asset.name,
        'shares': shares,
        'price': price,
        'total': price * shares,
      },
    };

    _notifications.insert(0, notification);

    // Save to Firebase if possible
    try {
      await _database.ref('notifications/$id').set({
        'type': 'trade',
        'title': title,
        'description': description,
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
        'data': {
          'action': action,
          'symbol': asset.symbol,
          'name': asset.name,
          'shares': shares,
          'price': price,
          'total': price * shares,
        },
      });
    } catch (e) {
      _logger.warning('Could not save trade notification to Firebase: $e');
    }

    await _saveNotifications();
    notifyListeners();
  }

  // Add a price alert notification
  Future<void> addPriceAlert(
      Asset asset, double targetPrice, bool isAbove) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final title = isAbove
        ? '${asset.symbol} Price Above Target'
        : '${asset.symbol} Price Below Target';

    final description = isAbove
        ? '${asset.symbol} has risen above your target price of \$${targetPrice.toStringAsFixed(2)}. Current price: \$${asset.price.toStringAsFixed(2)}'
        : '${asset.symbol} has fallen below your target price of \$${targetPrice.toStringAsFixed(2)}. Current price: \$${asset.price.toStringAsFixed(2)}';

    final notification = {
      'id': id,
      'type': 'alert',
      'title': title,
      'description': description,
      'timestamp': DateTime.now(),
      'read': false,
      'data': {
        'symbol': asset.symbol,
        'name': asset.name,
        'targetPrice': targetPrice,
        'currentPrice': asset.price,
        'isAbove': isAbove,
      },
    };

    _notifications.insert(0, notification);

    // Save to Firebase if possible
    try {
      await _database.ref('notifications/$id').set({
        'type': 'alert',
        'title': title,
        'description': description,
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
        'data': {
          'symbol': asset.symbol,
          'name': asset.name,
          'targetPrice': targetPrice,
          'currentPrice': asset.price,
          'isAbove': isAbove,
        },
      });
    } catch (e) {
      _logger.warning('Could not save price alert to Firebase: $e');
    }

    await _saveNotifications();
    notifyListeners();
  }

  // Add a system notification
  Future<void> addSystemNotification(String title, String description) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final notification = {
      'id': id,
      'type': 'system',
      'title': title,
      'description': description,
      'timestamp': DateTime.now(),
      'read': false,
      'data': {},
    };

    _notifications.insert(0, notification);

    // Save to Firebase if possible
    try {
      await _database.ref('notifications/$id').set({
        'type': 'system',
        'title': title,
        'description': description,
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
        'data': {},
      });
    } catch (e) {
      _logger.warning('Could not save system notification to Firebase: $e');
    }

    await _saveNotifications();
    notifyListeners();
  }

  // Create sample notifications for new users
  void _createSampleNotifications() {
    final now = DateTime.now();

    _notifications = [
      {
        'id': '1',
        'type': 'system',
        'title': 'Welcome to the Ethiopian Trading App',
        'description':
            'Start exploring the market and build your portfolio. Tap here to learn more.',
        'timestamp': now,
        'read': false,
        'data': {},
      },
      {
        'id': '2',
        'type': 'alert',
        'title': 'Market is Open',
        'description':
            'The Ethiopian market is now open for trading. Happy trading!',
        'timestamp': now.subtract(const Duration(hours: 1)),
        'read': false,
        'data': {},
      },
      {
        'id': '3',
        'type': 'trade',
        'title': 'First Trade Bonus',
        'description':
            'Complete your first trade today and receive a special bonus!',
        'timestamp': now.subtract(const Duration(days: 1)),
        'read': true,
        'data': {},
      },
    ];

    _saveNotifications();
  }
}
