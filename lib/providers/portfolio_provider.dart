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

class PortfolioProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<PortfolioItem> _portfolioItems = [];
  double _cashBalance = 0.0;
  bool _isLoading = false;
  String _error = '';

  // Getters
  List<PortfolioItem> get portfolioItems => _portfolioItems;
  double get cashBalance => _cashBalance;
  bool get isLoading => _isLoading;
  String get error => _error;

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

      // Get cash balance
      _cashBalance = (userData['balance'] as num?)?.toDouble() ?? 0.0;

      // Get portfolio items
      final portfolio =
          List<Map<String, dynamic>>.from(userData['portfolio'] ?? []);
      _portfolioItems = portfolio.map((item) {
        final symbol = item['symbol'] as String;
        final asset = marketAssets[symbol];
        return PortfolioItem.fromMap(item, asset!);
      }).toList();

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
}
