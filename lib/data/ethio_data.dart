// lib/data/ethio_data.dart

import 'dart:math';

class EthioData {
  static List<Map<String, dynamic>> generateMockEthioMarketData() {
    final random = Random();
    return [
      {'name': 'Ethiopian Electric Power', 'symbol': 'EEP', 'price': 125.50, 'change': random.nextDouble() * 2 - 1},
      {'name': 'Commercial Bank of Ethiopia', 'symbol': 'CBE', 'price': 85.20, 'change': random.nextDouble() * 2 - 1},
      {'name': 'Ethiopian Airlines', 'symbol': 'ETA', 'price': 450.75, 'change': random.nextDouble() * 2 - 1},
      {'name': 'Ethio Telecom', 'symbol': 'ETEL', 'price': 90.00, 'change': random.nextDouble() * 2 - 1},
      {'name': 'Awash Bank', 'symbol': 'AWB', 'price': 78.45, 'change': random.nextDouble() * 2 - 1},
      {'name': 'Dashen Bank', 'symbol': 'DB', 'price': 67.80, 'change': random.nextDouble() * 2 - 1},
      {'name': 'National Bank of Ethiopia', 'symbol': 'NBE', 'price': 220.00, 'change': random.nextDouble() * 2 - 1},
      {'name': 'Ethiopian Coffee', 'symbol': 'ETCOF', 'price': 35.50, 'change': random.nextDouble() * 2 - 1},
      {'name': 'Ethiopian Leather', 'symbol': 'ETLEA', 'price': 42.15, 'change': random.nextDouble() * 2 - 1},
      {'name': 'Ethio Sugar', 'symbol': 'ETS', 'price': 28.90, 'change': random.nextDouble() * 2 - 1},
      {'name': 'United Bank', 'symbol': 'UB', 'price': 55.30, 'change': random.nextDouble() * 2 - 1},
      {'name': 'Abyssinia Bank', 'symbol': 'ABY', 'price': 62.70, 'change': random.nextDouble() * 2 - 1},
      {'name': 'Nib International Bank', 'symbol': 'NIB', 'price': 58.90, 'change': random.nextDouble() * 2 - 1},
    ];
  }


  // Placeholder for language customization
  static Map<String, String> getEthiopicLanguageData() {
    return {
      'hello': 'ሰላም', 
      'goodbye': 'ቻው', 

    };
  }

  // Placeholder for culturally relevant features
  static List<Map<String, String>> getCulturallyRelevantData() {
    return [
      {'feature': 'Feature 1', 'description': 'Description 1'},
      {'feature': 'Feature 2', 'description': 'Description 2'},
    ];
  }
}