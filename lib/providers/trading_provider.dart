import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../services/trading_service.dart';

class TradeRequest {
  final String symbol;
  final int quantity;
  final double price;
  final String side; // 'buy' or 'sell'
  final String orderType; // 'market' or 'limit'
  final Map<String, dynamic> fees;

  TradeRequest({
    required this.symbol,
    required this.quantity,
    required this.price,
    required this.side,
    required this.orderType,
    required this.fees,
  });

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'quantity': quantity,
      'price': price,
      'side': side,
      'orderType': orderType,
      'fees': fees,
    };
  }
}

class TradingProvider with ChangeNotifier {
  final TradingService _tradingService = TradingService();
  bool _isLoading = false;
  String _error = '';
  String _successMessage = '';

  // Getters
  bool get isLoading => _isLoading;
  String get error => _error;
  String get successMessage => _successMessage;

  // Clear messages
  void clearMessages() {
    _error = '';
    _successMessage = '';
    notifyListeners();
  }

  // Execute a trade
  Future<bool> executeTrade(TradeRequest request) async {
    _isLoading = true;
    _error = '';
    _successMessage = '';
    notifyListeners();

    try {
      // Add validation logic
      if (request.quantity <= 0) {
        _error = 'Quantity must be greater than zero';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (request.price <= 0) {
        _error = 'Price must be greater than zero';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Execute the trade
      await _tradingService.executeTrade(request.toJson());

      // Set success message
      _successMessage =
          '${request.side.toUpperCase()} order successfully executed for ${request.quantity} shares of ${request.symbol} at ${request.price.toStringAsFixed(2)} ETB';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Calculate trading fees
  Map<String, dynamic> calculateFees(
      Asset asset, int quantity, double price, String side) {
    final tradeValue = quantity * price;

    // Ethiopian Securities Exchange fees (simplified example)
    final exchangeFee = tradeValue * 0.0027; // 0.27% exchange fee
    final taxFee = tradeValue * 0.002; // 0.2% capital gains tax
    final brokerageFee = tradeValue * 0.003; // 0.3% brokerage fee

    final totalFees = exchangeFee + taxFee + brokerageFee;

    return {
      'exchange': exchangeFee,
      'tax': taxFee,
      'brokerage': brokerageFee,
      'total': totalFees,
    };
  }

  // Get estimated trade cost
  double getEstimatedTradeCost(
      Asset asset, int quantity, double price, String side) {
    if (side == 'buy') {
      final fees = calculateFees(asset, quantity, price, side);
      return (quantity * price) + (fees['total'] as double);
    } else {
      final fees = calculateFees(asset, quantity, price, side);
      return (quantity * price) - (fees['total'] as double);
    }
  }

  // Validate trade parameters against market rules
  bool validateTradeParameters(
      Asset asset, int quantity, double price, String side) {
    // Check quantity is valid according to lot size
    if (!asset.isValidTradeQuantity(quantity)) {
      _error = 'Invalid quantity. Must be multiple of ${asset.lotSize}';
      notifyListeners();
      return false;
    }

    // Check price is within daily limits and follows tick size
    if (!asset.isValidTradePrice(price)) {
      _error =
          'Invalid price. Must be between ${asset.minDailyPrice.toStringAsFixed(2)} and ${asset.maxDailyPrice.toStringAsFixed(2)} and follow tick size ${asset.tickSize}';
      notifyListeners();
      return false;
    }

    return true;
  }
}
