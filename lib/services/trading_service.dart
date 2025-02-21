import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TradingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> executeTrade(Map<String, dynamic> tradeData) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated';

    // Start a transaction for atomic operation
    return _firestore.runTransaction((transaction) async {
      // Get user document
      final userDoc = _firestore.collection('users').doc(user.uid);
      final userSnapshot = await transaction.get(userDoc);
      
      if (!userSnapshot.exists) {
        throw 'User profile not found';
      }

      final userData = userSnapshot.data()!;
      final balance = (userData['balance'] as num?)?.toDouble() ?? 0.0;
      final portfolio = List<Map<String, dynamic>>.from(userData['portfolio'] ?? []);
      
      // Calculate total cost including fees
      final totalCost = (tradeData['quantity'] as int) * 
                       (tradeData['price'] as num) +
                       (tradeData['fees']['total'] as num);

      // Validate balance for buy orders
      if (tradeData['side'] == 'buy' && totalCost > balance) {
        throw 'Insufficient funds';
      }

      // Update portfolio
      if (tradeData['side'] == 'buy') {
        _updatePortfolioForBuy(portfolio, tradeData);
        userData['balance'] = balance - totalCost;
      } else {
        _updatePortfolioForSell(portfolio, tradeData);
        userData['balance'] = balance + totalCost;
      }

      // Create trade record
      final tradeDoc = _firestore.collection('trades').doc();
      transaction.set(tradeDoc, {
        ...tradeData,
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'executed',
      });

      // Update user data
      transaction.update(userDoc, {
        'portfolio': portfolio,
        'balance': userData['balance'],
        'lastTradeAt': FieldValue.serverTimestamp(),
      });

      // Create notification
      final notificationDoc = _firestore.collection('notifications').doc();
      transaction.set(notificationDoc, {
        'userId': user.uid,
        'type': 'trade',
        'title': '${tradeData['side'] == 'buy' ? 'Buy' : 'Sell'} Order Executed',
        'description': 'Your ${tradeData['side']} order for ${tradeData['quantity']} shares of ${tradeData['symbol']} has been executed at ${tradeData['price']}',
        'timestamp': FieldValue.serverTimestamp(),
        'tradeDetails': tradeData,
        'status': 'unread',
      });
    });
  }

  void _updatePortfolioForBuy(List<Map<String, dynamic>> portfolio, Map<String, dynamic> tradeData) {
    final existingPosition = portfolio.firstWhere(
      (p) => p['symbol'] == tradeData['symbol'],
      orElse: () => {'symbol': tradeData['symbol'], 'quantity': 0, 'avgPrice': 0.0},
    );

    if (existingPosition['quantity'] == 0) {
      existingPosition['quantity'] = tradeData['quantity'];
      existingPosition['avgPrice'] = tradeData['price'];
      portfolio.add(existingPosition);
    } else {
      final totalQuantity = existingPosition['quantity'] + tradeData['quantity'];
      final totalCost = (existingPosition['quantity'] * existingPosition['avgPrice']) +
                       (tradeData['quantity'] * tradeData['price']);
      existingPosition['quantity'] = totalQuantity;
      existingPosition['avgPrice'] = totalCost / totalQuantity;
    }
  }

  void _updatePortfolioForSell(List<Map<String, dynamic>> portfolio, Map<String, dynamic> tradeData) {
    final position = portfolio.firstWhere(
      (p) => p['symbol'] == tradeData['symbol'],
      orElse: () => throw 'Position not found',
    );

    if (position['quantity'] < tradeData['quantity']) {
      throw 'Insufficient shares';
    }

    position['quantity'] -= tradeData['quantity'];
    if (position['quantity'] == 0) {
      portfolio.remove(position);
    }
  }
}
