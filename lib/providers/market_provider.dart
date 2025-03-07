import 'package:flutter/material.dart';
import 'dart:collection';
import '../models/asset.dart';
import '../services/realtime_market_service.dart';
import '../data/ethio_data.dart';

class MarketProvider with ChangeNotifier {
  final RealtimeMarketService _realtimeService;
  bool _initialized = false;
  bool _isMarketOpen = false;
  final Map<String, Asset> _assets = {};

  // Constructor
  MarketProvider()
      : _realtimeService = RealtimeMarketService(
          onStockUpdate: (asset) {}, // Will be set in init
          onMarketStatusChange: (isOpen) {}, // Will be set in init
        );

  // Initialize the provider
  Future<void> initialize() async {
    if (_initialized) return;

    // Set callbacks
    _realtimeService.onStockUpdate = _handleStockUpdate;
    _realtimeService.onMarketStatusChange = _handleMarketStatusChange;

    // Generate initial mock data and initialize
    final initialAssets = EthioData.generateMockEthioMarketData()
        .map((data) => Asset(
              name: data['name'],
              symbol: data['symbol'],
              sector: data['sector'],
              ownership: data['ownership'],
              price: data['price'].toDouble(),
              change: data['change'].toDouble(),
              volume: data['volume'].toDouble(),
              marketCap: data['marketCap'].toDouble(),
              lastUpdated: DateTime.now(),
              dayHigh: data['dayHigh'].toDouble(),
              dayLow: data['dayLow'].toDouble(),
              openPrice: data['openPrice'].toDouble(),
            ))
        .toList();

    // Add to local cache
    for (var asset in initialAssets) {
      _assets[asset.symbol] = asset;
    }

    // Initialize real-time service with data
    await _realtimeService.initializeMarketData(initialAssets);

    // Subscribe to all stocks for updates
    _realtimeService.subscribeToAllStocks();

    _initialized = true;
    notifyListeners();
  }

  // Get all assets
  UnmodifiableListView<Asset> get assets =>
      UnmodifiableListView(_assets.values.toList());

  // Get asset by symbol
  Asset? getAssetBySymbol(String symbol) => _assets[symbol];

  // Get market status
  bool get isMarketOpen => _isMarketOpen;

  // Handle stock updates
  void _handleStockUpdate(Asset asset) {
    _assets[asset.symbol] = asset;
    notifyListeners();
  }

  // Handle market status change
  void _handleMarketStatusChange(bool isOpen) {
    _isMarketOpen = isOpen;
    notifyListeners();
  }

  // Subscribe to specific stock updates
  void subscribeToStock(String symbol) {
    _realtimeService.subscribeToStock(symbol);
  }

  // Unsubscribe from specific stock updates
  void unsubscribeFromStock(String symbol) {
    _realtimeService.unsubscribeFromStock(symbol);
  }

  // Sort assets by different criteria
  List<Asset> getSortedAssets({
    required String sortBy,
    bool ascending = true,
    String? sectorFilter,
    String? searchQuery,
  }) {
    List<Asset> filteredList = _assets.values.toList();

    // Apply sector filter
    if (sectorFilter != null && sectorFilter != 'All') {
      filteredList =
          filteredList.where((asset) => asset.sector == sectorFilter).toList();
    }

    // Apply search query
    if (searchQuery != null && searchQuery.isNotEmpty) {
      filteredList = filteredList
          .where((asset) =>
              asset.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              asset.symbol.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    // Sort list
    filteredList.sort((a, b) {
      int result;
      switch (sortBy) {
        case 'name':
          result = a.name.compareTo(b.name);
          break;
        case 'symbol':
          result = a.symbol.compareTo(b.symbol);
          break;
        case 'price':
          result = a.price.compareTo(b.price);
          break;
        case 'change':
          result = a.change.compareTo(b.change);
          break;
        case 'volume':
          result = a.volume.compareTo(b.volume);
          break;
        case 'marketCap':
          result = a.marketCap.compareTo(b.marketCap);
          break;
        default:
          result = a.symbol.compareTo(b.symbol);
      }

      return ascending ? result : -result;
    });

    return filteredList;
  }

  // Get sectors
  List<String> getAvailableSectors() {
    final sectors =
        _assets.values.map((asset) => asset.sector).toSet().toList();
    sectors.sort();
    return ['All', ...sectors];
  }

  // Clean up
  @override
  void dispose() {
    _realtimeService.dispose();
    super.dispose();
  }
}
