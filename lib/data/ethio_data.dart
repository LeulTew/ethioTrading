// lib/data/ethio_data.dart

import 'dart:math';

class EthioData {
  static List<Map<String, dynamic>> generateMockEthioMarketData() {
    final random = Random();
    return [
      // Banks
      _createMarketData('Commercial Bank of Ethiopia', 'CBE', 850.20, random,
          'Bank', 'State', 5000000),
      _createMarketData(
          'Awash Bank', 'AWB', 780.45, random, 'Bank', 'Private', 2500000),
      _createMarketData(
          'Dashen Bank', 'DSH', 670.80, random, 'Bank', 'Private', 2000000),
      _createMarketData('Bank of Abyssinia', 'BOA', 620.70, random, 'Bank',
          'Private', 1800000),
      _createMarketData(
          'Wegagen Bank', 'WB', 590.30, random, 'Bank', 'Private', 1500000),

      // State Enterprises
      _createMarketData('Ethiopian Airlines Group', 'EAL', 4500.75, random,
          'Transport', 'State', 10000000),
      _createMarketData(
          'Ethio Telecom', 'ET', 900.00, random, 'Telecom', 'State', 8000000),
      _createMarketData('Ethiopian Electric Power', 'EEP', 1250.50, random,
          'Utility', 'State', 6000000),

      // Manufacturing
      _createMarketData('East African Holdings', 'EAH', 890.30, random,
          'Manufacturing', 'Private', 3000000),
      _createMarketData('Habesha Breweries', 'HAB', 627.00, random,
          'Manufacturing', 'Private', 2200000),
      _createMarketData('National Cement', 'NC', 589.00, random,
          'Manufacturing', 'Private', 2100000),

      // Agricultural
      _createMarketData('Ethiopian Coffee Export', 'ECEX', 355.50, random,
          'Agriculture', 'Private', 1200000),
      _createMarketData('Ethio Sugar Corporation', 'ESC', 289.90, random,
          'Agriculture', 'State', 1800000),
      _createMarketData('ELFORA Agro-Industry', 'EAI', 420.15, random,
          'Agriculture', 'Private', 1400000),
    ];
  }

  static Map<String, dynamic> _createMarketData(
      String name,
      String symbol,
      double basePrice,
      Random random,
      String sector,
      String ownership,
      int baseVolume) {
    // Calculate daily price movement within Ethiopian market rules (+/- 10% max)
    final maxMove = basePrice * 0.10;
    final change = (random.nextDouble() * maxMove * 2) - maxMove;
    final currentPrice = basePrice + change;

    // Generate realistic volume based on company size and price movement
    final volumeMultiplier = 1.0 + (change.abs() / basePrice);
    final volume = (baseVolume * volumeMultiplier).round();

    // Calculate market cap
    final marketCap = currentPrice * volume;

    return {
      'name': name,
      'symbol': symbol,
      'price': currentPrice,
      'change': (change / basePrice) * 100, // Percentage change
      'volume': volume,
      'marketCap': marketCap,
      'sector': sector,
      'ownership': ownership,
      'currency': 'ETB',
      'lastUpdated': DateTime.now().toString(),
      'dayHigh': currentPrice + (random.nextDouble() * maxMove),
      'dayLow': currentPrice - (random.nextDouble() * maxMove),
      'openPrice': basePrice,
      'lotSize': sector == 'Bank' ? 10 : 1, // Banks trade in lots of 10
      'tickSize': 0.05, // 5 cents minimum price movement
    };
  }

  // Market Sectors
  static List<String> getSectors() {
    return [
      'Bank',
      'Transport',
      'Telecom',
      'Utility',
      'Agriculture',
      'Manufacturing'
    ];
  }

  // Ethiopian Calendar Utility
  static Map<String, dynamic> getEthiopianDate() {
    // Add 7 years and 8 months to get approximate Ethiopian date
    final now = DateTime.now();
    final ethYear = now.year + 7;
    final ethMonth = now.month + 8;

    return {
      'year': ethYear,
      'month': ethMonth > 12 ? ethMonth - 12 : ethMonth,
      'day': now.day,
      'monthName': _getEthiopianMonth(ethMonth > 12 ? ethMonth - 12 : ethMonth),
    };
  }

  static String _getEthiopianMonth(int month) {
    final months = [
      'Meskerem',
      'Tikimt',
      'Hidar',
      'Tahsas',
      'Tir',
      'Yekatit',
      'Megabit',
      'Miazia',
      'Ginbot',
      'Sene',
      'Hamle',
      'Nehase',
      'Pagume'
    ];
    return months[month - 1];
  }

  // Amharic Translation Map
  static Map<String, String> getAmharicTranslations() {
    return {
      'market': 'ገበያ',
      'portfolio': 'ポートフォリオ',
      'profile': 'መገለጫ',
      'settings': 'ቅንብሮች',
      'buy': 'ግዛ',
      'sell': 'ሽጥ',
      'price': 'ዋጋ',
      'change': 'ለውጥ',
      'volume': 'መጠን',
      'chart': 'ቻርት',
      'news': 'ዜና',
      'watchlist': 'ዝርዝር',
      'analysis': 'ጥናት',
      'bank': 'ባንክ',
      'agriculture': 'እርሻ',
      'manufacturing': 'ማምረቻ',
      'state': 'መንግስታዊ',
      'private': 'የግል',
    };
  }

  // Market Statistics
  static Map<String, dynamic> getMarketStatistics(
      List<Map<String, dynamic>> marketData) {
    double totalMarketCap = 0;
    double totalVolume = 0;
    int advancers = 0;
    int decliners = 0;
    int unchanged = 0;

    for (final stock in marketData) {
      totalMarketCap += stock['marketCap'];
      totalVolume += stock['volume'];

      if (stock['change'] > 0) {
        advancers++;
      } else if (stock['change'] < 0) {
        decliners++;
      } else {
        unchanged++;
      }
    }

    return {
      'totalMarketCap': totalMarketCap,
      'totalVolume': totalVolume,
      'advancers': advancers,
      'decliners': decliners,
      'unchanged': unchanged,
      'marketBreadth': advancers / (decliners == 0 ? 1 : decliners),
    };
  }

  static Map<String, double> getSectorWeights(
      List<Map<String, dynamic>> marketData) {
    final sectorTotals = <String, double>{};
    double totalMarketCap = 0;

    for (final stock in marketData) {
      final sector = stock['sector'];
      sectorTotals[sector] = (sectorTotals[sector] ?? 0) + stock['marketCap'];
      totalMarketCap += stock['marketCap'];
    }

    return Map.fromEntries(
      sectorTotals.entries.map(
        (entry) => MapEntry(entry.key, (entry.value / totalMarketCap) * 100),
      ),
    );
  }

  // Get sectors with proper Amharic translations
  static Map<String, String> getSectorsWithTranslations() {
    return {
      'Bank': 'ባንክ',
      'Transport': 'ትራንስፖርት',
      'Telecom': 'ቴሌኮም',
      'Utility': 'ኃይል አገልግሎት',
      'Agriculture': 'እርሻ',
      'Manufacturing': 'ማምረቻ',
    };
  }
}
