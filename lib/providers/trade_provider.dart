import 'package:flutter/material.dart';
import '../models/asset.dart';
import 'package:logging/logging.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_provider.dart';

class TradeProvider with ChangeNotifier {
  final Logger _logger = Logger('TradeProvider');
  final NotificationProvider? _notificationProvider;

  // User portfolio and cash balance
  double _cashBalance = 10000.0; // Start with $10,000
  List<Map<String, dynamic>> _portfolio = [];
  List<Map<String, dynamic>> _transactionHistory = [];
  bool _loading = false;

  // Getters
  double get cashBalance => _cashBalance;
  List<Map<String, dynamic>> get portfolio => _portfolio;
  List<Map<String, dynamic>> get transactionHistory => _transactionHistory;
  bool get loading => _loading;

  // Constructor
  TradeProvider({NotificationProvider? notificationProvider})
      : _notificationProvider = notificationProvider {
    _loadUserData();
  }

  // Load user trading data from local storage
  Future<void> _loadUserData() async {
    _loading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load cash balance
      final savedBalance = prefs.getDouble('cashBalance');
      if (savedBalance != null) {
        _cashBalance = savedBalance;
      }

      // Load portfolio
      final savedPortfolio = prefs.getString('portfolio');
      if (savedPortfolio != null) {
        final List<dynamic> decoded = jsonDecode(savedPortfolio);
        _portfolio = decoded.cast<Map<String, dynamic>>();
      }

      // Load transaction history
      final savedHistory = prefs.getString('transactionHistory');
      if (savedHistory != null) {
        final List<dynamic> decoded = jsonDecode(savedHistory);
        _transactionHistory = decoded.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      _logger.severe('Error loading user trading data: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Save user trading data to local storage
  Future<void> _saveUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save cash balance
      await prefs.setDouble('cashBalance', _cashBalance);

      // Save portfolio
      final portfolioJson = jsonEncode(_portfolio);
      await prefs.setString('portfolio', portfolioJson);

      // Save transaction history
      final historyJson = jsonEncode(_transactionHistory);
      await prefs.setString('transactionHistory', historyJson);
    } catch (e) {
      _logger.severe('Error saving user trading data: $e');
    }
  }

  // Buy an asset
  Future<bool> buyAsset(Asset asset, int shares) async {
    final totalCost = asset.price * shares;

    // Check if user has enough cash
    if (_cashBalance < totalCost) {
      _logger.warning('Insufficient funds for purchase: $totalCost');
      return false;
    }

    try {
      // Update cash balance
      _cashBalance -= totalCost;

      // Add to portfolio or update existing holding
      final existingIndex =
          _portfolio.indexWhere((item) => item['symbol'] == asset.symbol);

      if (existingIndex >= 0) {
        // Update existing position
        final existingPosition = _portfolio[existingIndex];
        final existingShares = existingPosition['shares'] as int;
        final existingCost = existingPosition['costBasis'] as double;

        // Calculate new average cost basis
        final newShares = existingShares + shares;
        final newCostBasis =
            ((existingCost * existingShares) + totalCost) / newShares;

        _portfolio[existingIndex] = {
          'symbol': asset.symbol,
          'name': asset.name,
          'shares': newShares,
          'costBasis': newCostBasis,
          'currentPrice': asset.price,
          'lastUpdated': DateTime.now().toIso8601String(),
        };
      } else {
        // Add new position
        _portfolio.add({
          'symbol': asset.symbol,
          'name': asset.name,
          'shares': shares,
          'costBasis': asset.price,
          'currentPrice': asset.price,
          'lastUpdated': DateTime.now().toIso8601String(),
        });
      }

      // Add to transaction history
      _transactionHistory.add({
        'type': 'buy',
        'symbol': asset.symbol,
        'name': asset.name,
        'shares': shares,
        'price': asset.price,
        'total': totalCost,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Save changes
      await _saveUserData();

      // Send notification if available
      if (_notificationProvider != null) {
        await _notificationProvider!
            .addTradeNotification('buy', asset, shares, asset.price);
      }

      notifyListeners();

      _logger
          .info('Purchased $shares shares of ${asset.symbol} for $totalCost');
      return true;
    } catch (e) {
      _logger.severe('Error buying asset: $e');
      return false;
    }
  }

  // Sell an asset
  Future<bool> sellAsset(Asset asset, int shares) async {
    // Check if user owns the asset and has enough shares
    final existingIndex =
        _portfolio.indexWhere((item) => item['symbol'] == asset.symbol);

    if (existingIndex < 0) {
      _logger.warning('Asset ${asset.symbol} not found in portfolio');
      return false;
    }

    final existingShares = _portfolio[existingIndex]['shares'] as int;

    if (existingShares < shares) {
      _logger.warning('Not enough shares to sell: $existingShares < $shares');
      return false;
    }

    try {
      // Calculate proceeds
      final totalProceeds = asset.price * shares;

      // Update cash balance
      _cashBalance += totalProceeds;

      // Update portfolio
      if (existingShares == shares) {
        // Remove position entirely
        _portfolio.removeAt(existingIndex);
      } else {
        // Update existing position
        _portfolio[existingIndex]['shares'] = existingShares - shares;
      }

      // Add to transaction history
      _transactionHistory.add({
        'type': 'sell',
        'symbol': asset.symbol,
        'name': asset.name,
        'shares': shares,
        'price': asset.price,
        'total': totalProceeds,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Save changes
      await _saveUserData();

      // Send notification if available
      if (_notificationProvider != null) {
        await _notificationProvider!
            .addTradeNotification('sell', asset, shares, asset.price);
      }

      notifyListeners();

      _logger.info('Sold $shares shares of ${asset.symbol} for $totalProceeds');
      return true;
    } catch (e) {
      _logger.severe('Error selling asset: $e');
      return false;
    }
  }

  // Update portfolio prices
  void updatePortfolioPrices(List<Asset> marketAssets) {
    for (var position in _portfolio) {
      final symbol = position['symbol'] as String;
      final matchingAsset = marketAssets.firstWhere(
        (asset) => asset.symbol == symbol,
        orElse: () => Asset(
          symbol: symbol,
          name: position['name'],
          price: position['currentPrice'],
          change: 0,
          changePercent: 0,
          volume: 0,
          marketCap: 0,
          sector: '',
          ownership: '',
        ),
      );

      // Update current price
      position['currentPrice'] = matchingAsset.price;
      position['lastUpdated'] = DateTime.now().toIso8601String();
    }

    notifyListeners();
  }

  // Calculate portfolio metrics
  Map<String, dynamic> getPortfolioMetrics() {
    double totalValue = 0;
    double totalCost = 0;
    double totalGainLoss = 0;

    for (var position in _portfolio) {
      final shares = position['shares'] as int;
      final currentPrice = position['currentPrice'] as double;
      final costBasis = position['costBasis'] as double;

      final positionValue = shares * currentPrice;
      final positionCost = shares * costBasis;

      totalValue += positionValue;
      totalCost += positionCost;
      totalGainLoss += (positionValue - positionCost);
    }

    final percentGainLoss =
        totalCost > 0 ? (totalGainLoss / totalCost) * 100 : 0;

    return {
      'totalValue': totalValue,
      'totalCost': totalCost,
      'totalGainLoss': totalGainLoss,
      'percentGainLoss': percentGainLoss,
      'cashBalance': _cashBalance,
      'grandTotal': totalValue + _cashBalance,
    };
  }

  // Add funds to account
  Future<void> addFunds(double amount) async {
    _cashBalance += amount;

    _transactionHistory.add({
      'type': 'deposit',
      'amount': amount,
      'timestamp': DateTime.now().toIso8601String(),
    });

    await _saveUserData();
    notifyListeners();

    _logger.info('Added \$${amount.toStringAsFixed(2)} to account');
  }

  // Clear portfolio (for testing/reset)
  Future<void> resetPortfolio() async {
    _cashBalance = 10000.0;
    _portfolio = [];
    _transactionHistory = [];

    await _saveUserData();
    notifyListeners();

    _logger.info('Portfolio reset to initial state');
  }
}
