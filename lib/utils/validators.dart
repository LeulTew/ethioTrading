import 'package:intl/intl.dart';
import 'dart:core';
import '../providers/language_provider.dart';

class PasswordValidator {
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    return null;
  }
}

class EmailValidator {
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an email address';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }
}

class PhoneNumberValidator {
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a phone number';
    }
    // Ethiopian phone number format: +251 9X XXX XXXX
    final phoneRegex = RegExp(r'^\+251[97]\d{8}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'\s+'), ''))) {
      return 'Please enter a valid Ethiopian phone number (+251 9X XXX XXXX)';
    }
    return null;
  }

  static String format(String value) {
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length >= 12) {
      return '+${cleaned.substring(0, 3)} ${cleaned.substring(3, 4)} '
          '${cleaned.substring(4, 7)} ${cleaned.substring(7)}';
    }
    return value;
  }
}

class TradeValidator {
  static String? validateQuantity(
    String value, {
    required int lotSize,
    required num availableBalance, // Changed from double to num
    required num price, // Changed from double to num
    num? maxDailyTradeValue = 1000000, // Changed from double? to num?
  }) {
    try {
      final quantity = int.parse(value);

      // Basic validation
      if (quantity <= 0) {
        return 'quantity_must_be_positive';
      }

      // Lot size validation
      if (quantity % lotSize != 0) {
        return 'invalid_lot_size';
      }

      // Calculate total order value
      final totalValue = quantity * price;

      // Available balance validation
      if (totalValue > availableBalance) {
        return 'insufficient_funds';
      }

      // Daily trade limit validation
      if (maxDailyTradeValue != null && totalValue > maxDailyTradeValue) {
        return 'exceeds_daily_limit';
      }

      return null;
    } catch (e) {
      return 'invalid_quantity';
    }
  }

  static String? validatePrice(
    String value, {
    required double basePrice,
    required double tickSize,
    double maxDeviation = 0.10, // Ethiopian market's 10% daily limit
  }) {
    try {
      final price = double.parse(value);

      // Basic validation
      if (price <= 0) {
        return 'price_must_be_positive';
      }

      // Tick size validation
      final ticksCount = price / tickSize;
      if ((ticksCount - ticksCount.round()).abs() > 0.00001) {
        return 'invalid_tick_size';
      }

      // Price range validation based on Ethiopian market rules
      final minPrice = basePrice * (1 - maxDeviation);
      final maxPrice = basePrice * (1 + maxDeviation);

      if (price < minPrice || price > maxPrice) {
        return 'price_out_of_range';
      }

      return null;
    } catch (e) {
      return 'invalid_price';
    }
  }

  static String? validateBank(String value) {
    if (value.isEmpty) {
      return 'bank_required';
    }
    return null;
  }

  static String? validateAccountNumber(String value) {
    if (value.isEmpty) {
      return 'account_number_required';
    }

    // Ethiopian bank account number format validation (basic)
    if (value.length < 10 || value.length > 16) {
      return 'invalid_account_number_length';
    }

    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'account_number_must_be_numeric';
    }

    return null;
  }

  static String? validateTradeType(String? value) {
    if (value == null || value.isEmpty) {
      return 'trade_type_required';
    }

    if (!['market', 'limit'].contains(value.toLowerCase())) {
      return 'invalid_trade_type';
    }

    return null;
  }

  static String? validateOrderSide(String? value) {
    if (value == null || value.isEmpty) {
      return 'order_side_required';
    }

    if (!['buy', 'sell'].contains(value.toLowerCase())) {
      return 'invalid_order_side';
    }

    return null;
  }

  static Map<String, dynamic> canTrade({
    required Map<String, dynamic> userProfile,
  }) {
    // Check if user profile exists
    if (userProfile.isEmpty) {
      return {'canTrade': false, 'reason': 'profile_not_found'};
    }

    // Check if user is verified
    final isVerified = userProfile['isVerified'] as bool? ?? false;
    if (!isVerified) {
      return {'canTrade': false, 'reason': 'account_not_verified'};
    }

    // Check if trading is enabled for user
    final isTradingEnabled = userProfile['isTradingEnabled'] as bool? ?? false;
    if (!isTradingEnabled) {
      return {'canTrade': false, 'reason': 'trading_disabled'};
    }

    return {'canTrade': true, 'reason': null};
  }

  static String getFormattedError(String errorCode, LanguageProvider lang) {
    return lang.translate(errorCode);
  }

  static Map<String, dynamic> validateTrade({
    required String quantity,
    required String price,
    required String tradeType,
    required String orderSide,
    required Map<String, dynamic> stockData,
    required Map<String, dynamic> userProfile,
  }) {
    final qty = int.tryParse(quantity);
    final prc = double.tryParse(price);

    // Basic validation first
    if (qty == null || qty <= 0) {
      return {'isValid': false, 'error': 'invalid_quantity'};
    }
    if (prc == null || prc <= 0) {
      return {'isValid': false, 'error': 'invalid_price'};
    }

    // Check if user can trade
    final canTradeResult = canTrade(userProfile: userProfile);
    if (!canTradeResult['canTrade']!) {
      return {'isValid': false, 'error': canTradeResult['reason']};
    }

    // Validate trading limits
    final totalValue = qty * prc;
    final tradingLimit =
        (userProfile['tradingLimit'] as num?)?.toDouble() ?? 0.0;
    if (orderSide == 'buy' && totalValue > tradingLimit) {
      return {'isValid': false, 'error': 'trading_limit_exceeded'};
    }

    // Check available balance for buy orders
    if (orderSide == 'buy') {
      final availableBalance =
          (userProfile['balance'] as num?)?.toDouble() ?? 0.0;
      if (totalValue > availableBalance) {
        return {'isValid': false, 'error': 'insufficient_funds'};
      }
    }

    // Check available shares for sell orders
    if (orderSide == 'sell') {
      final portfolio = userProfile['portfolio'] as List? ?? [];
      final position = portfolio.firstWhere(
        (p) => p['symbol'] == stockData['symbol'],
        orElse: () => {'quantity': 0},
      );
      if (qty > (position['quantity'] as int? ?? 0)) {
        return {'isValid': false, 'error': 'insufficient_shares'};
      }
    }

    return {'isValid': true, 'error': null};
  }
}

class BankAccountValidator {
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a bank account number';
    }

    // Ethiopian bank account format: XXX-XXXX-XXXXXXX (13 digits)
    final accountRegex = RegExp(r'^\d{3}-?\d{4}-?\d{7}$');
    if (!accountRegex.hasMatch(value.replaceAll(RegExp(r'\s+'), ''))) {
      return 'Please enter a valid Ethiopian bank account number (XXX-XXXX-XXXXXXX)';
    }

    return null;
  }

  static String format(String value) {
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length >= 14) {
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 7)}-'
          '${cleaned.substring(7, 14)}';
    }
    return value;
  }
}

class CurrencyValidator {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'am_ET',
    symbol: 'ETB',
    decimalDigits: 2,
  );

  static String? validate(String? value, {double? maxAmount}) {
    if (value == null || value.isEmpty) {
      return 'Please enter an amount';
    }

    try {
      final amount = _currencyFormat.parse(value);
      if (amount <= 0) {
        return 'Amount must be greater than 0';
      }
      if (maxAmount != null && amount > maxAmount) {
        return 'Amount cannot exceed ${_currencyFormat.format(maxAmount)}';
      }
    } catch (e) {
      return 'Please enter a valid amount';
    }

    return null;
  }

  static String format(double value) {
    return _currencyFormat.format(value);
  }

  static double parse(String value) {
    return _currencyFormat.parse(value).toDouble();
  }
}
