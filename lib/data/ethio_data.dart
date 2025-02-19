// lib/data/ethio_data.dart

import 'dart:math';

class EthioData {
  static List<Map<String, dynamic>> generateMockEthioMarketData() {
    final random = Random();
    return [
      // Banks
      _createMarketData('Commercial Bank of Ethiopia', 'CBE', 850.20, random,
          'Bank', 'State'),
      _createMarketData('Awash Bank', 'AWB', 780.45, random, 'Bank', 'Private'),
      _createMarketData(
          'Dashen Bank', 'DSH', 670.80, random, 'Bank', 'Private'),
      _createMarketData(
          'Bank of Abyssinia', 'BOA', 620.70, random, 'Bank', 'Private'),

      // State Enterprises
      _createMarketData('Ethiopian Airlines Group', 'EAL', 4500.75, random,
          'Transport', 'State'),
      _createMarketData(
          'Ethio Telecom', 'ET', 900.00, random, 'Telecom', 'State'),
      _createMarketData('Ethiopian Electric Power', 'EEP', 1250.50, random,
          'Utility', 'State'),

      // Agricultural
      _createMarketData('Ethiopian Coffee Export', 'ECEX', 355.50, random,
          'Agriculture', 'Private'),
      _createMarketData('Ethio Sugar Corporation', 'ESC', 289.90, random,
          'Agriculture', 'State'),
      _createMarketData('ELFORA Agro-Industry', 'EAI', 420.15, random,
          'Agriculture', 'Private'),

      // Manufacturing
      _createMarketData('East African Holdings', 'EAH', 890.30, random,
          'Manufacturing', 'Private'),
      _createMarketData('Habesha Breweries', 'HAB', 627.00, random,
          'Manufacturing', 'Private'),
      _createMarketData(
          'National Cement', 'NC', 589.00, random, 'Manufacturing', 'Private'),
    ];
  }

  static Map<String, dynamic> _createMarketData(String name, String symbol,
      double basePrice, Random random, String sector, String ownership) {
    final change = (random.nextDouble() * 10 - 5); // -5% to +5%
    final volume = random.nextInt(100000) + 10000;
    final marketCap = basePrice * volume;

    return {
      'name': name,
      'symbol': symbol,
      'price': basePrice + (basePrice * change / 100),
      'change': change,
      'volume': volume,
      'marketCap': marketCap,
      'sector': sector,
      'ownership': ownership,
      'currency': 'ETB',
      'lastUpdated': DateTime.now().toString(),
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
}
