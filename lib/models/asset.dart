import 'dart:math' as math;
import 'package:intl/intl.dart';

class Asset {
  final String name;
  final String symbol;
  final String sector;
  final String ownership;
  double price;
  double change;
  double changePercent;
  double volume;
  double marketCap;
  final String currency;
  DateTime? lastUpdated;
  double? dayHigh;
  double? dayLow;
  double? openPrice;
  final int lotSize;
  final double tickSize;
  String? description;
  bool isFavorite; // Added property for favorites/starred assets
  double availableBalance; // Added property for trading functionality
  Map<String, dynamic>?
      technicalIndicators; // Added property for technical analysis

  Asset({
    required this.name,
    required this.symbol,
    required this.sector,
    required this.ownership,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.volume,
    required this.marketCap,
    this.currency = 'ETB',
    this.lastUpdated,
    this.dayHigh,
    this.dayLow,
    this.openPrice,
    this.description,
    this.lotSize = 1, // Minimum trading unit
    this.tickSize = 0.05, // Minimum price movement
    this.isFavorite = false, // Default to not favorite
    this.availableBalance = 0.0, // Default to no available balance
    this.technicalIndicators, // Technical indicators
  });

  // Calculate price movement restrictions based on Ethiopian market rules
  double? get maxDailyPrice =>
      openPrice != null ? openPrice! * 1.10 : null; // +10% daily limit
  double? get minDailyPrice =>
      openPrice != null ? openPrice! * 0.90 : null; // -10% daily limit

  // Trading validation methods
  bool isValidTradeQuantity(int quantity) {
    return quantity > 0 && quantity % lotSize == 0;
  }

  bool isValidPrice(double price) {
    if (openPrice == null) return true;
    return price >= minDailyPrice! && price <= maxDailyPrice!;
  }

  // Market statistics
  double get valueTraded => price * volume;
  double? get percentageChange =>
      openPrice != null ? (price - openPrice!) / openPrice! * 100 : null;

  // Toggle favorite status
  void toggleFavorite() {
    isFavorite = !isFavorite;
  }

  // Create a new Asset instance with updated price
  Asset copyWithPrice(double newPrice) {
    return Asset(
      name: name,
      symbol: symbol,
      sector: sector,
      ownership: ownership,
      price: newPrice,
      change: openPrice != null ? newPrice - openPrice! : 0.0,
      changePercent: ((newPrice - price) / price) * 100,
      volume: volume,
      marketCap: marketCap * (newPrice / price),
      currency: currency,
      lastUpdated: DateTime.now(),
      dayHigh: dayHigh != null ? math.max(dayHigh!, newPrice) : newPrice,
      dayLow: dayLow != null ? math.min(dayLow!, newPrice) : newPrice,
      openPrice: openPrice,
      description: description,
      lotSize: lotSize,
      tickSize: tickSize,
      isFavorite: isFavorite, // Preserve favorite status
      availableBalance: availableBalance, // Preserve available balance
      technicalIndicators: technicalIndicators, // Preserve technical indicators
    );
  }

  // Create Asset from map
  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      name: map['name'] ?? '',
      symbol: map['symbol'] ?? '',
      sector: map['sector'] ?? '',
      ownership: map['ownership'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      change: (map['change'] ?? 0.0).toDouble(),
      changePercent: (map['changePercent'] ?? 0.0).toDouble(),
      volume: (map['volume'] ?? 0.0).toDouble(),
      marketCap: (map['marketCap'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'ETB',
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.parse(map['lastUpdated'])
          : DateTime.now(),
      dayHigh: map['dayHigh']?.toDouble(),
      dayLow: map['dayLow']?.toDouble(),
      openPrice: map['openPrice']?.toDouble(),
      description: map['description'],
      lotSize: map['lotSize'] ?? 1,
      tickSize: map['tickSize'] ?? 0.05,
      isFavorite: map['isFavorite'] ?? false, // Load favorite status
      availableBalance:
          (map['availableBalance'] ?? 0.0).toDouble(), // Load available balance
      technicalIndicators: map['technicalIndicators']
          as Map<String, dynamic>?, // Load technical indicators
    );
  }

  // Convert Asset to map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'symbol': symbol,
      'sector': sector,
      'ownership': ownership,
      'price': price,
      'change': change,
      'changePercent': changePercent,
      'volume': volume,
      'marketCap': marketCap,
      'currency': currency,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'dayHigh': dayHigh,
      'dayLow': dayLow,
      'openPrice': openPrice,
      'lotSize': lotSize,
      'tickSize': tickSize,
      'description': description,
      'isFavorite': isFavorite, // Include favorite status in map
      'availableBalance': availableBalance, // Include available balance in map
      'technicalIndicators':
          technicalIndicators, // Include technical indicators in map
    };
  }

  // Format price with currency symbol
  String get formattedPrice {
    final formatter = NumberFormat.currency(
      symbol: sector == 'Ethiopian' ? 'ETB ' : '\$',
      decimalDigits: 2,
    );
    return formatter.format(price);
  }

  // Format change with sign
  String get formattedChange {
    final formatter = NumberFormat('+#,##0.00;-#,##0.00');
    return formatter.format(change);
  }

  // Format change percent with sign and percent symbol
  String get formattedChangePercent {
    final formatter = NumberFormat('+#,##0.00;-#,##0.00');
    return '${formatter.format(changePercent)}%';
  }

  // Format volume with thousands separator
  String get formattedVolume {
    final formatter = NumberFormat('#,###');
    return formatter.format(volume);
  }

  // Format market cap with currency symbol and abbreviation (B, M, K)
  String get formattedMarketCap {
    String symbol = sector == 'Ethiopian' ? 'ETB ' : '\$';

    if (marketCap >= 1000000000) {
      return '$symbol${(marketCap / 1000000000).toStringAsFixed(2)}B';
    } else if (marketCap >= 1000000) {
      return '$symbol${(marketCap / 1000000).toStringAsFixed(2)}M';
    } else if (marketCap >= 1000) {
      return '$symbol${(marketCap / 1000).toStringAsFixed(2)}K';
    } else {
      return '$symbol${marketCap.toStringAsFixed(2)}';
    }
  }

  // Check if asset is up or down
  bool get isUp => change > 0;

  // Get color based on change (green for up, red for down, grey for no change)
  int getChangeColor() {
    if (change > 0) {
      return 0xFF00C853; // Green
    } else if (change < 0) {
      return 0xFFD50000; // Red
    } else {
      return 0xFF757575; // Grey
    }
  }
}
