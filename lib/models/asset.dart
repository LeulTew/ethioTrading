import 'dart:math' as math;

class Asset {
  final String name;
  final String symbol;
  final String sector;
  final String ownership;
  final double price;
  final double change;
  final double volume;
  final double marketCap;
  final String currency;
  final DateTime lastUpdated;
  final double dayHigh;
  final double dayLow;
  final double openPrice;
  final int lotSize;
  final double tickSize;

  Asset({
    required this.name,
    required this.symbol,
    required this.sector,
    required this.ownership,
    required this.price,
    required this.change,
    required this.volume,
    required this.marketCap,
    this.currency = 'ETB',
    required this.lastUpdated,
    required this.dayHigh,
    required this.dayLow,
    required this.openPrice,
    this.lotSize = 1, // Minimum trading unit
    this.tickSize = 0.05, // Minimum price movement
  });

  // Calculate price movement restrictions based on Ethiopian market rules
  double get maxDailyPrice => openPrice * 1.10; // +10% daily limit
  double get minDailyPrice => openPrice * 0.90; // -10% daily limit

  // Trading validation methods
  bool isValidTradeQuantity(int quantity) {
    return quantity > 0 && quantity % lotSize == 0;
  }

  bool isValidTradePrice(double tradePrice) {
    // Check if price is within daily limits and follows tick size
    if (tradePrice < minDailyPrice || tradePrice > maxDailyPrice) {
      return false;
    }
    return (tradePrice / tickSize).round() * tickSize == tradePrice;
  }

  // Market statistics
  double get valueTraded => price * volume;
  double get percentageChange => (price - openPrice) / openPrice * 100;

  // Create a new Asset instance with updated price
  Asset updatePrice(double newPrice) {
    return Asset(
      name: name,
      symbol: symbol,
      sector: sector,
      ownership: ownership,
      price: newPrice,
      change: ((newPrice - openPrice) / openPrice) * 100,
      volume: volume,
      marketCap: marketCap * (newPrice / price),
      lastUpdated: DateTime.now(),
      dayHigh: math.max(dayHigh, newPrice),
      dayLow: math.min(dayLow, newPrice),
      openPrice: openPrice,
    );
  }
}
