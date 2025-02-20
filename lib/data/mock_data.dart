import 'dart:math';
import '../models/asset.dart';
import '../models/user_profile.dart';

List<Asset> generateMockAssets() {
  final random = Random();
  final sectors = [
    'Bank',
    'Transport',
    'Telecom',
    'Utility',
    'Agriculture',
    'Manufacturing'
  ];
  final ownership = ['State', 'Private'];

  return List.generate(10, (index) {
    final basePrice = 100 + random.nextDouble() * 900;
    final change = (random.nextDouble() - 0.5) * 5; // Max 5% change
    final openPrice = basePrice / (1 + (change / 100));
    final volume = random.nextInt(10000) + 1000;
    final marketCap = basePrice * volume;

    return Asset(
      name: 'Asset ${index + 1}',
      symbol: 'A${index + 1}',
      sector: sectors[random.nextInt(sectors.length)],
      ownership: ownership[random.nextInt(ownership.length)],
      price: basePrice,
      change: change,
      volume: volume.toDouble(),
      marketCap: marketCap,
      lastUpdated: DateTime.now(),
      dayHigh: basePrice * (1 + random.nextDouble() * 0.05),
      dayLow: basePrice * (1 - random.nextDouble() * 0.05),
      openPrice: openPrice,
      lotSize: 1,
      tickSize: 0.05,
    );
  });
}

UserProfile generateMockUserProfile() {
  return UserProfile(
    userId: 'user123',
    username: 'EthioTrader',
    email: 'ethiotrader@example.com',
    profilePictureUrl: 'https://example.com/profile.jpg',
  );
}

class MockPortfolio {
  static Map<String, dynamic> generateMockPortfolioData() {
    final random = Random();
    final assets = generateMockAssets();
    double totalValue = 0;
    double totalGain = 0;

    final holdings = assets.take(5).map((asset) {
      final quantity = (10 + random.nextInt(90)).toDouble();
      final value = quantity * asset.price;
      final avgPrice = asset.price * (1 - (random.nextDouble() * 0.1));
      final gain = (asset.price - avgPrice) * quantity;

      totalValue += value;
      totalGain += gain;

      return {
        'asset': asset,
        'quantity': quantity,
        'value': value,
        'avgPrice': avgPrice,
        'gain': gain,
      };
    }).toList();

    final transactions = List.generate(10, (index) {
      final asset = assets[random.nextInt(assets.length)];
      final isRecent = random.nextBool();

      return {
        'asset': asset,
        'type': index % 2 == 0 ? 'buy' : 'sell',
        'quantity': (10 + random.nextInt(50)).toDouble(),
        'price': asset.price * (1 + (random.nextDouble() - 0.5) * 0.1),
        'timestamp': DateTime.now().subtract(
          Duration(
            days: isRecent ? random.nextInt(7) : random.nextInt(30) + 7,
            hours: random.nextInt(24),
            minutes: random.nextInt(60),
          ),
        ),
      };
    });

    return {
      'holdings': holdings,
      'transactions': transactions,
      'totalValue': totalValue,
      'totalGain': totalGain,
      'todayGain': totalGain * (random.nextDouble() * 0.2),
    };
  }
}
