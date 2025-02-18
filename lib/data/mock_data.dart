import 'dart:math';
import 'package:ethio_trading_app/models/asset.dart';
import 'package:ethio_trading_app/models/user_profile.dart';

List<Asset> generateMockAssets() {
  final random = Random();
  final List<Asset> assets = [];
  for (int i = 0; i < 10; i++) {
    final double price = 100 + random.nextDouble() * 900;
    final double change = (random.nextDouble() - 0.5) * 10;
    final double volume = 1000 + random.nextDouble() * 9000;
    assets.add(
      Asset(
        name: 'Asset ${i + 1}',
        symbol: 'A${i + 1}',
        price: double.parse(price.toStringAsFixed(2)),
        change: double.parse(change.toStringAsFixed(2)),
        volume: double.parse(volume.toStringAsFixed(2)),
      ),
    );
  }
  return assets;
}

UserProfile generateMockUserProfile() {
  return UserProfile(
    userId: 'user123',
    username: 'EthioTrader',
    email: 'ethiotrader@example.com',
    profilePictureUrl: 'https://example.com/profile.jpg',
  );
}