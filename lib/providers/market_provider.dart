import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import '../models/asset.dart';
import '../services/api_service.dart';
import '../data/ethio_data.dart'; // Import Ethiopian data

class MarketProvider with ChangeNotifier {
  final ApiService _apiService;
  final FirebaseDatabase _database;
  final Logger _logger = Logger('MarketProvider');

  List<Asset> _ethiopianAssets = [];
  List<Asset> _internationalAssets = [];
  final List<Asset> _searchResults = [];
  List<Asset> _favoriteAssets = [];
  List<Map<String, dynamic>> _chartData = [];
  bool _isLoading = false;
  bool _isMarketOpen = false;
  DateTime? _lastUpdated;
  Timer? _refreshTimer;
  StreamSubscription? _ethioDataSubscription;

  // Constructor with dependency injection
  MarketProvider({
    required ApiService apiService,
    required FirebaseDatabase database,
  })  : _apiService = apiService,
        _database = database {
    _loadFavorites();

    // Set up periodic refresh timer (every 5 minutes)
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      fetchMarketData(useCache: true);
    });

    // Start the EthioData market stream and listen to real-time updates
    EthioData.startMarketDataStream();
    _subscribeToEthioMarketData();

    // Immediately load market data on initialization
    fetchMarketData();
  }

  void _subscribeToEthioMarketData() {
    _ethioDataSubscription = EthioData.marketDataStream.listen((marketData) {
      _logger.info(
          'Received Ethiopian market data stream update with ${marketData.length} assets');
      _updateEthiopianAssets(marketData);
    });
  }

  void _updateEthiopianAssets(List<Map<String, dynamic>> marketData) {
    try {
      _ethiopianAssets = marketData
          .map((data) => Asset(
                name: data['name'] as String? ?? 'Unknown',
                symbol: data['symbol'] as String? ?? 'UNKNOWN',
                price: (data['price'] as num?)?.toDouble() ?? 0.0,
                change: (data['change'] as num?)?.toDouble() ?? 0.0,
                changePercent:
                    (data['changePercent'] as num?)?.toDouble() ?? 0.0,
                volume: (data['volume'] as num?)?.toDouble() ?? 0.0,
                sector: data['sector'] as String? ?? 'Unknown',
                ownership: data['ownership'] as String? ?? 'Unknown',
                marketCap: (data['marketCap'] as num?)?.toDouble() ?? 0.0,
                lastUpdated: DateTime.now(),
                dayHigh: (data['dayHigh'] as num?)?.toDouble() ?? 0.0,
                dayLow: (data['dayLow'] as num?)?.toDouble() ?? 0.0,
                openPrice: (data['openPrice'] as num?)?.toDouble() ?? 0.0,
                lotSize: (data['lotSize'] as int?) ?? 1,
                tickSize: (data['tickSize'] as num?)?.toDouble() ?? 0.05,
              ))
          .toList();

      _logger.info('Updated Ethiopian assets: ${_ethiopianAssets.length}');
      _applyFavoritesToAssets();
      _updateFavoriteAssets();
      notifyListeners();
    } catch (e) {
      _logger.severe('Error updating Ethiopian assets: $e');
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _ethioDataSubscription?.cancel();
    EthioData.stopMarketDataStream();
    super.dispose();
  }

  // Getters
  List<Asset> get ethiopianAssets => _ethiopianAssets;
  List<Asset> get internationalAssets => _internationalAssets;
  List<Asset> get searchResults => _searchResults;
  List<Asset> get favoriteAssets => _favoriteAssets;
  List<Map<String, dynamic>> get chartData => _chartData;
  bool get isLoading => _isLoading;
  bool get isMarketOpen => _isMarketOpen;
  DateTime? get lastUpdated => _lastUpdated;

  // Format for display
  String get formattedLastUpdated {
    return _lastUpdated != null
        ? '${_lastUpdated!.hour}:${_lastUpdated!.minute.toString().padLeft(2, '0')}'
        : '';
  }

  // Fetch market data with the right sources for each type
  Future<void> fetchMarketData({bool useCache = true}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // For international markets, only use API (no mock data)
      _internationalAssets = await _apiService.fetchInternationalMarketData();

      // For Ethiopian markets, use EthioData and explicitly generate mock data
      try {
        final ethiopianData = EthioData.generateMockEthioMarketData();
        _ethiopianAssets = ethiopianData
            .map((data) => Asset(
                  name: data['name'] as String? ?? 'Unknown',
                  symbol: data['symbol'] as String? ?? 'UNKNOWN',
                  price: (data['price'] as num?)?.toDouble() ?? 0.0,
                  change: (data['change'] as num?)?.toDouble() ?? 0.0,
                  changePercent:
                      (data['changePercent'] as num?)?.toDouble() ?? 0.0,
                  volume: (data['volume'] as num?)?.toDouble() ?? 0.0,
                  sector: data['sector'] as String? ?? 'Unknown',
                  ownership: data['ownership'] as String? ?? 'Unknown',
                  marketCap: (data['marketCap'] as num?)?.toDouble() ?? 0.0,
                  lastUpdated: DateTime.now(),
                  dayHigh: (data['dayHigh'] as num?)?.toDouble() ?? 0.0,
                  dayLow: (data['dayLow'] as num?)?.toDouble() ?? 0.0,
                  openPrice: (data['openPrice'] as num?)?.toDouble() ?? 0.0,
                  lotSize: (data['lotSize'] as int?) ?? 1,
                  tickSize: (data['tickSize'] as num?)?.toDouble() ?? 0.05,
                ))
            .toList();

        _logger.info('Loaded ${_ethiopianAssets.length} Ethiopian assets');
      } catch (e) {
        _logger.severe('Error loading Ethiopian assets: $e');
      }

      _logger
          .info('Loaded ${_internationalAssets.length} International assets');

      // Fetch chart data
      _chartData = await _apiService.getMarketChartData();

      // Apply favorites status
      await _applyFavoritesToAssets();

      _lastUpdated = DateTime.now();
      _updateMarketStatus();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _logger.severe('Error fetching market data: $e');

      // If we fail to fetch international data, at least ensure Ethiopian data is loaded
      if (_ethiopianAssets.isEmpty) {
        try {
          final ethiopianData = EthioData.generateMockEthioMarketData();
          _ethiopianAssets = ethiopianData
              .map((data) => Asset(
                    name: data['name'] as String? ?? 'Unknown',
                    symbol: data['symbol'] as String? ?? 'UNKNOWN',
                    price: (data['price'] as num?)?.toDouble() ?? 0.0,
                    change: (data['change'] as num?)?.toDouble() ?? 0.0,
                    changePercent:
                        (data['changePercent'] as num?)?.toDouble() ?? 0.0,
                    volume: (data['volume'] as num?)?.toDouble() ?? 0.0,
                    sector: data['sector'] as String? ?? 'Unknown',
                    ownership: data['ownership'] as String? ?? 'Unknown',
                    marketCap: (data['marketCap'] as num?)?.toDouble() ?? 0.0,
                    lastUpdated: DateTime.now(),
                    dayHigh: (data['dayHigh'] as num?)?.toDouble() ?? 0.0,
                    dayLow: (data['dayLow'] as num?)?.toDouble() ?? 0.0,
                    openPrice: (data['openPrice'] as num?)?.toDouble() ?? 0.0,
                    lotSize: (data['lotSize'] as int?) ?? 1,
                    tickSize: (data['tickSize'] as num?)?.toDouble() ?? 0.05,
                  ))
              .toList();

          _logger.info(
              'Loaded ${_ethiopianAssets.length} Ethiopian assets after error');
        } catch (ethioError) {
          _logger.severe(
              'Error loading Ethiopian assets after API failure: $ethioError');
          _ethiopianAssets = []; // Ensure we have at least an empty list
        }
      }

      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle favorite status with Firebase persistence
  Future<void> toggleFavorite(Asset asset) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        // Set the local state but inform the user they need to log in for persistence
        asset.isFavorite = !asset.isFavorite;
        _updateFavoriteAssets();
        notifyListeners();
        throw Exception('You must be logged in to save favorites permanently');
      }

      final ref = _database.ref('users/$userId/favorites/${asset.symbol}');

      if (asset.isFavorite) {
        // Remove from favorites
        await ref.remove();
        asset.isFavorite = false;
        _logger.info('Removed ${asset.symbol} from favorites');
      } else {
        // Add to favorites with more data for better UI display
        await ref.set({
          'timestamp': ServerValue.timestamp,
          'symbol': asset.symbol,
          'name': asset.name,
          'sector': asset.sector,
          'price': asset.price,
          'change': asset.change,
          'lastUpdated': DateTime.now().toIso8601String(),
        });
        asset.isFavorite = true;
        _logger.info('Added ${asset.symbol} to favorites');
      }

      _updateFavoriteAssets();
      notifyListeners();
    } catch (e) {
      _logger.warning('Error toggling favorite: $e');
    }
  }

  // Load favorites from Firebase with improved error handling
  Future<void> _loadFavorites() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        _logger.info('No user logged in, skipping favorites load');
        return;
      }

      _logger.info('Loading favorites for user $userId');
      final snapshot = await _database.ref('users/$userId/favorites').get();

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final favorites = data.keys.cast<String>().toSet();
        _logger.info('Found ${favorites.length} favorites for user');

        // Apply to both Ethiopian and international assets
        for (var asset in [..._ethiopianAssets, ..._internationalAssets]) {
          asset.isFavorite = favorites.contains(asset.symbol);
        }

        _updateFavoriteAssets();
        notifyListeners();
      } else {
        _logger.info('No favorites found for user');
      }
    } catch (e) {
      _logger.warning('Error loading favorites: $e');
    }
  }

  // Apply favorite status to assets
  Future<void> _applyFavoritesToAssets() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await _database.ref('users/$userId/favorites').get();
      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final favorites = data.keys.cast<String>().toSet();

        // Mark assets as favorites
        for (var asset in [..._ethiopianAssets, ..._internationalAssets]) {
          asset.isFavorite = favorites.contains(asset.symbol);
        }
      }

      _updateFavoriteAssets();
    } catch (e) {
      _logger.warning('Error applying favorites: $e');
    }
  }

  // Update the favorites list
  void _updateFavoriteAssets() {
    _favoriteAssets = [
      ..._ethiopianAssets.where((asset) => asset.isFavorite),
      ..._internationalAssets.where((asset) => asset.isFavorite),
    ];
  }

  // Update market open/closed status
  void _updateMarketStatus() {
    _isMarketOpen = EthiopianMarketHours.isMarketOpen();
  }

  // Statistics helpers
  int getGainersCount(bool isEthiopian) {
    final assets = isEthiopian ? _ethiopianAssets : _internationalAssets;
    return assets.where((asset) => asset.change > 0).length;
  }

  int getLosersCount(bool isEthiopian) {
    final assets = isEthiopian ? _ethiopianAssets : _internationalAssets;
    return assets.where((asset) => asset.change < 0).length;
  }

  double getTotalVolume(bool isEthiopian) {
    final assets = isEthiopian ? _ethiopianAssets : _internationalAssets;
    return assets.fold(0, (sum, asset) => sum + asset.volume);
  }

  // Search functionality
  void searchAssets(String query) {
    if (query.isEmpty) {
      _searchResults.clear();
      notifyListeners();
      return;
    }

    final lowercaseQuery = query.toLowerCase();
    _searchResults.clear();
    _searchResults.addAll([
      ..._ethiopianAssets.where((asset) =>
          asset.symbol.toLowerCase().contains(lowercaseQuery) ||
          asset.name.toLowerCase().contains(lowercaseQuery)),
      ..._internationalAssets.where((asset) =>
          asset.symbol.toLowerCase().contains(lowercaseQuery) ||
          asset.name.toLowerCase().contains(lowercaseQuery))
    ]);

    notifyListeners();
  }
}
