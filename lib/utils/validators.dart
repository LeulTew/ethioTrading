import 'package:intl/intl.dart';

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
    required num lotSize,
    required num availableBalance,
    required num price,
  }) {
    if (value.isEmpty) {
      return 'Quantity is required';
    }

    final quantity = int.tryParse(value);
    if (quantity == null) {
      return 'Please enter a valid number';
    }

    if (quantity <= 0) {
      return 'Quantity must be greater than 0';
    }

    if (quantity % lotSize != 0) {
      return 'Quantity must be a multiple of $lotSize';
    }

    final totalCost = quantity * price;
    if (totalCost > availableBalance) {
      return 'Insufficient balance for this trade';
    }

    return null;
  }

  static String? validatePrice(
    String value, {
    required num basePrice,
    required num tickSize,
  }) {
    if (value.isEmpty) {
      return 'Price is required';
    }

    final price = double.tryParse(value);
    if (price == null) {
      return 'Please enter a valid price';
    }

    if (price <= 0) {
      return 'Price must be greater than 0';
    }

    if ((price / tickSize).round() * tickSize != price) {
      return 'Price must be a multiple of $tickSize';
    }

    // Maximum daily price movement (10%)
    const maxPriceChange = 0.10;
    final maxPrice = basePrice * (1 + maxPriceChange);
    final minPrice = basePrice * (1 - maxPriceChange);

    if (price > maxPrice) {
      return 'Price cannot be more than 10% above base price';
    }

    if (price < minPrice) {
      return 'Price cannot be more than 10% below base price';
    }

    return null;
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
