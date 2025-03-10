import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/asset.dart';

class PortfolioItem {
  final String symbol;
  final String name;
  final double quantity;
  final double avgPrice;
  final double currentPrice;
  final double currentValue;
  final double totalReturn;
  final double totalReturnPercentage;
  final double dayChange;
  final double dayChangePercentage;

  PortfolioItem({
    required this.symbol,
    required this.name,
    required this.quantity,
    required this.avgPrice,
    required this.currentPrice,
    required this.currentValue,
    required this.totalReturn,
    required this.totalReturnPercentage,
    required this.dayChange,
    required this.dayChangePercentage,
  });

  double get costBasis => quantity * avgPrice;

  // Calculate profit/loss
  double get profitLoss => currentValue - costBasis;

  // Calculate profit/loss percentage
  double get profitLossPercent =>
      costBasis > 0 ? (profitLoss / costBasis) * 100 : 0;

  // Create from Firestore data
  factory PortfolioItem.fromMap(Map<String, dynamic> map, Asset asset) {
    final quantity = map['quantity'] ?? 0.0;
    final avgPrice = map['avgPrice'] ?? 0.0;
    final currentPrice = asset.price;
    final currentValue = quantity * currentPrice;
    final totalReturn = currentValue - (quantity * avgPrice);
    final totalReturnPercentage =
        avgPrice > 0 ? (totalReturn / (quantity * avgPrice)) * 100 : 0.0;
    final dayChange =
        quantity * (currentPrice - (asset.openPrice ?? currentPrice));
    final dayChangePercentage = (asset.openPrice ?? currentPrice) > 0
        ? ((currentPrice - (asset.openPrice ?? currentPrice)) /
                (asset.openPrice ?? currentPrice)) *
            100
        : 0.0;

    return PortfolioItem(
      symbol: asset.symbol,
      name: asset.name,
      quantity: quantity.toDouble(),
      avgPrice: avgPrice.toDouble(),
      currentPrice: currentPrice,
      currentValue: currentValue,
      totalReturn: totalReturn,
      totalReturnPercentage: totalReturnPercentage,
      dayChange: dayChange,
      dayChangePercentage: dayChangePercentage,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'quantity': quantity,
      'avgPrice': avgPrice,
    };
  }
}

class PortfolioSummary {
  final double totalValue;
  final double totalReturn;
  final double totalReturnPercentage;
  final double dayChange;
  final double dayChangePercentage;
  final int numberOfAssets;
  final double cashBalance;
  final double totalAccountValue;

  PortfolioSummary({
    required this.totalValue,
    required this.totalReturn,
    required this.totalReturnPercentage,
    required this.dayChange,
    required this.dayChangePercentage,
    required this.numberOfAssets,
    required this.cashBalance,
    required this.totalAccountValue,
  });
}

class PortfolioHolding {
  final Asset asset;
  final double quantity;
  final double value;
  final double gain;
  final double gainPercent;

  PortfolioHolding({
    required this.asset,
    required this.quantity,
    required this.value,
    required this.gain,
    required this.gainPercent,
  });
}

class Transaction {
  final Asset asset;
  final String type; // 'buy' or 'sell'
  final double quantity;
  final double price;
  final DateTime timestamp;

  Transaction({
    required this.asset,
    required this.type,
    required this.quantity,
    required this.price,
    required this.timestamp,
  });
}

class PortfolioProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<PortfolioItem> _portfolioItems = [];
  double _cashBalance = 0.0;
  bool _isLoading = false;
  String _error = '';

  List<PortfolioHolding> _holdings = [];
  List<Asset> _purchasedAssets = [];
  List<Transaction> _transactions = [];
  double _totalValue = 0;
  double _todayGain = 0;
  double _totalGain = 0;

  // Getters
  List<PortfolioItem> get portfolioItems => _portfolioItems;
  double get cashBalance => _cashBalance;
  bool get isLoading => _isLoading;
  String get error => _error;

  List<PortfolioHolding> get holdings => _holdings;
  List<Asset> get purchasedAssets => _purchasedAssets;
  List<Transaction> get transactions => _transactions;
  double get totalValue => _totalValue;
  double get todayGain => _todayGain;
  double get totalGain => _totalGain;

  // Initialize portfolio data
  Future<void> fetchPortfolio(
      {required Map<String, Asset> marketAssets}) async {
    final user = _auth.currentUser;
    if (user == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final docSnapshot =
          await _firestore.collection('users').doc(user.uid).get();

      if (!docSnapshot.exists) {
        _error = 'User profile not found';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final userData = docSnapshot.data()!;

      // Get cash balance with explicit conversion to double
      _cashBalance = (userData['balance'] as num?)?.toDouble() ?? 0.0;

      // Get portfolio items
      final portfolio =
          List<Map<String, dynamic>>.from(userData['portfolio'] ?? []);
      _portfolioItems = portfolio.map((item) {
        final symbol = item['symbol'] as String;
        final asset = marketAssets[symbol];
        return PortfolioItem.fromMap(item, asset!);
      }).toList();

      final transactions =
          List<Map<String, dynamic>>.from(userData['transactions'] ?? []);

      // Process portfolio holdings
      _holdings = [];
      _purchasedAssets = [];
      _totalValue = 0;
      _todayGain = 0;
      _totalGain = 0;

      for (final item in portfolio) {
        final symbol = item['symbol'] as String;
        final asset = marketAssets[symbol];
        if (asset != null) {
          // Explicit conversion of num to double
          final quantity = (item['quantity'] as num).toDouble();
          final avgPrice = (item['avgPrice'] as num).toDouble();
          final value = quantity * asset.price;
          final gain = value - (quantity * avgPrice);
          final gainPercent =
              avgPrice > 0 ? (gain / (quantity * avgPrice)) * 100 : 0.0;

          _holdings.add(PortfolioHolding(
            asset: asset,
            quantity: quantity,
            value: value,
            gain: gain,
            gainPercent: gainPercent,
          ));

          _purchasedAssets.add(asset);
          _totalValue += value;
          _todayGain +=
              quantity * (asset.price - (asset.openPrice ?? asset.price));
          _totalGain += gain;
        }
      }

      // Process transactions with explicit double conversions
      _transactions = transactions.map((t) {
        final symbol = t['symbol'] as String;
        final asset = marketAssets[symbol];
        if (asset == null) throw Exception('Asset not found: $symbol');

        return Transaction(
          asset: asset,
          type: t['type'] as String,
          quantity: (t['quantity'] as num).toDouble(),
          price: (t['price'] as num).toDouble(),
          timestamp: (t['timestamp'] as Timestamp).toDate(),
        );
      }).toList();

      // Sort transactions by date
      _transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load portfolio: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update portfolio with latest market data
  void updateWithMarketData(Map<String, Asset> marketAssets) {
    for (int i = 0; i < _portfolioItems.length; i++) {
      final item = _portfolioItems[i];
      final asset = marketAssets[item.symbol];

      if (asset != null) {
        _portfolioItems[i] = PortfolioItem(
          symbol: item.symbol,
          name: asset.name,
          quantity: item.quantity,
          avgPrice: item.avgPrice,
          currentPrice: asset.price,
          currentValue: item.currentValue,
          totalReturn: item.totalReturn,
          totalReturnPercentage: item.totalReturnPercentage,
          dayChange: item.dayChange,
          dayChangePercentage: item.dayChangePercentage,
        );
      }
    }

    notifyListeners();
  }

  // Update holdings with latest market prices
  void updateWithMarketPrices(Map<String, Asset> marketAssets) {
    for (final holding in _holdings) {
      final asset = marketAssets[holding.asset.symbol];
      if (asset != null) {
        final newValue = holding.quantity * asset.price;
        _todayGain +=
            holding.quantity * (asset.price - (asset.openPrice ?? asset.price));
        _totalValue = _totalValue - holding.value + newValue;
      }
    }
    notifyListeners();
  }

  // Get portfolio summary
  PortfolioSummary getPortfolioSummary() {
    double totalValue = 0.0;
    double totalReturn = 0.0;

    for (final item in _portfolioItems) {
      totalValue += item.currentValue;
      totalReturn += item.totalReturn;
    }

    final double totalReturnPercentage =
        (totalValue > 0.0 ? ((totalReturn / totalValue) * 100.0) : 0.0)
            .toDouble();

    return PortfolioSummary(
      totalValue: totalValue,
      totalReturn: totalReturn,
      totalReturnPercentage: totalReturnPercentage,
      dayChange: 0.0,
      dayChangePercentage: 0.0,
      numberOfAssets: _portfolioItems.length,
      cashBalance: _cashBalance,
      totalAccountValue: totalValue + _cashBalance,
    );
  }

  // Get portfolio item by symbol
  PortfolioItem? getPortfolioItemBySymbol(String symbol) {
    try {
      return _portfolioItems.firstWhere((item) => item.symbol == symbol);
    } catch (e) {
      return null;
    }
  }

  // Refresh portfolio data
  Future<void> refreshPortfolio(
      {required Map<String, Asset> marketAssets}) async {
    await fetchPortfolio(marketAssets: marketAssets);
  }

  // Sort portfolio by different criteria
  List<PortfolioItem> getSortedPortfolio({
    required String sortBy,
    bool ascending = true,
  }) {
    final sortedList = List<PortfolioItem>.from(_portfolioItems);

    sortedList.sort((a, b) {
      int result;
      switch (sortBy) {
        case 'symbol':
          result = a.symbol.compareTo(b.symbol);
          break;
        case 'name':
          result = a.name.compareTo(b.name);
          break;
        case 'quantity':
          result = a.quantity.compareTo(b.quantity);
          break;
        case 'currentValue':
          result = a.currentValue.compareTo(b.currentValue);
          break;
        case 'avgPrice':
          result = a.avgPrice.compareTo(b.avgPrice);
          break;
        case 'profitLoss':
          result = a.profitLoss.compareTo(b.profitLoss);
          break;
        case 'profitLossPercent':
          result = a.profitLossPercent.compareTo(b.profitLossPercent);
          break;
        default:
          result = a.currentValue.compareTo(b.currentValue);
      }

      return ascending ? result : -result;
    });

    return sortedList;
  }

  // Helper method to calculate sector distribution
  Map<String, double> getSectorDistribution() {
    final sectors = <String, double>{};
    for (final holding in _holdings) {
      final sector = holding.asset.sector;
      sectors[sector] = (sectors[sector] ?? 0) + holding.value;
    }
    return sectors;
  }
}
