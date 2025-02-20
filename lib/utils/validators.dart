class PasswordValidator {
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
}

class TradeValidator {
  static String? validateQuantity(String? value, double maxQuantity) {
    if (value == null || value.isEmpty) {
      return 'Please enter a quantity';
    }
    final quantity = double.tryParse(value);
    if (quantity == null) {
      return 'Please enter a valid number';
    }
    if (quantity <= 0) {
      return 'Quantity must be greater than 0';
    }
    if (quantity > maxQuantity) {
      return 'Quantity cannot exceed $maxQuantity';
    }
    return null;
  }

  static String? validatePrice(String? value, double currentPrice) {
    if (value == null || value.isEmpty) {
      return 'Please enter a price';
    }
    final price = double.tryParse(value);
    if (price == null) {
      return 'Please enter a valid price';
    }
    if (price <= 0) {
      return 'Price must be greater than 0';
    }
    // Allow 10% price movement from current price
    final maxPrice = currentPrice * 1.1;
    final minPrice = currentPrice * 0.9;
    if (price < minPrice || price > maxPrice) {
      return 'Price must be within 10% of current market price';
    }
    return null;
  }

  static String? validateTotal(String? value, double availableBalance) {
    if (value == null || value.isEmpty) {
      return 'Please enter a total amount';
    }
    final total = double.tryParse(value);
    if (total == null) {
      return 'Please enter a valid amount';
    }
    if (total <= 0) {
      return 'Total must be greater than 0';
    }
    if (total > availableBalance) {
      return 'Insufficient funds. Available balance: $availableBalance';
    }
    return null;
  }
}
