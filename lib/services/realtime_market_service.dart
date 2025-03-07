import 'dart:async';
import '../models/asset.dart';
import '../utils/mock_db.dart';

class RealtimeMarketService {
  final _mockService = MockRealtimeMarketService(
    onStockUpdate: (asset) {},
    onMarketStatusChange: (isOpen) {},
  );

  // Callback for when stock data is updated
  Function(Asset) onStockUpdate;

  // Callback for when market status changes
  Function(bool) onMarketStatusChange;

  RealtimeMarketService({
    required this.onStockUpdate,
    required this.onMarketStatusChange,
  }) {
    _mockService.onStockUpdate = onStockUpdate;
    _mockService.onMarketStatusChange = onMarketStatusChange;
  }

  // Initialize real-time market data
  Future<void> initializeMarketData(List<Asset> initialAssets) async {
    await _mockService.initializeMarketData(initialAssets);
  }

  // Subscribe to specific stock updates
  void subscribeToStock(String symbol) {
    _mockService.subscribeToStock(symbol);
  }

  // Unsubscribe from specific stock updates
  void unsubscribeFromStock(String symbol) {
    _mockService.unsubscribeFromStock(symbol);
  }

  // Subscribe to all stocks
  void subscribeToAllStocks() {
    _mockService.subscribeToAllStocks();
  }

  // Clean up all subscriptions
  void dispose() {
    _mockService.dispose();
  }
}
