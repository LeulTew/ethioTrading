import 'dart:math';
import 'package:ethio_trading_app/models/asset.dart';
import 'package:ethio_trading_app/models/user_profile.dart';

List<Asset> generateMockAssets() {
  final random = Random();
  return List.generate(10, (index) {
    final double price = 100 + random.nextDouble() * 900;
    final double change = (random.nextDouble() - 0.5) * 10;
    final int volume = random.nextInt(10000) + 1000;

      return Asset(
          name: 'Asset ${index + 1}',
          symbol: 'A${index + 1}',
          price: price,
          change: change,
          volume: volume,
      );
    });
}

UserProfile generateMockUserProfile() {
    return UserProfile(userId: 'user123', username: 'EthioTrader', email: 'ethiotrader@example.com', profilePictureUrl: 'https://example.com/profile.jpg');
}