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

  // Add global navigator key to access context
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  // Getter for the navigator key
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  List<Asset> _ethiopianAssets = [];
  List<Asset> _internationalAssets = [];
  final List<Asset> _searchResults = [];
  List<Asset> _favoriteAssets = [];
  List<Map<String, dynamic>> _chartData = [];
  bool _isLoading = false;
  bool _isInternationalError = false;
  String _internationalErrorMessage = '';
  String _apiSource = 'Unknown'; // Track which API succeeded
  bool _isFinnhubError = false;
  bool _isAlphaVantageError = false;
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
  bool get hasInternationalError => _isInternationalError;
  String get internationalErrorMessage => _internationalErrorMessage;
  String get apiSource => _apiSource;
  bool get hasFinnhubError => _isFinnhubError;
  bool get hasAlphaVantageError => _isAlphaVantageError;

  String get detailedErrorMessage {
    List<String> errors = [];

    if (_isFinnhubError) {
      errors.add("Finnhub API: Connection error");
    }

    if (_isAlphaVantageError) {
      errors.add("Alpha Vantage API: Connection error");
    }

    if (errors.isEmpty) {
      return _internationalErrorMessage;
    } else {
      return "${errors.join(" and ")}. $_internationalErrorMessage";
    }
  }

  // Format for display
  String get formattedLastUpdated {
    return _lastUpdated != null
        ? '${_lastUpdated!.hour}:${_lastUpdated!.minute.toString().padLeft(2, '0')}'
        : '';
  }

  // Fetch market data with comprehensive error handling for both APIs
  Future<void> fetchMarketData({bool useCache = true}) async {
    _isLoading = true;
    // Reset error flags
    _isInternationalError = false;
    _internationalErrorMessage = '';
    _isFinnhubError = false;
    _isAlphaVantageError = false;
    _apiSource = 'Unknown';
    notifyListeners();

    try {
      // Preload Ethiopian assets immediately from local data to ensure they're always available fast
      _preloadEthiopianAssets();

      // For international markets, use combined API approach with detailed error handling
      try {
        final internationalAssets =
            await _apiService.fetchInternationalMarketData();

        // Check which API was used (if available in the response)
        if (internationalAssets.isNotEmpty) {
          // Try to determine which API provided the data by checking the asset source
          if (internationalAssets.first.ownership.contains('Finnhub')) {
            _apiSource = 'Finnhub';
          } else if (internationalAssets.first.ownership
              .contains('Alpha Vantage')) {
            _apiSource = 'Alpha Vantage';
          } else {
            _apiSource = 'Combined APIs';
          }

          _internationalAssets = internationalAssets;
          _logger.info(
              'Loaded ${_internationalAssets.length} international assets from $_apiSource');
        } else {
          _isInternationalError = true;
          _internationalErrorMessage =
              'No international market data available from any API';
          _logger.warning(_internationalErrorMessage);
        }
      } catch (e) {
        _isInternationalError = true;

        // Try to determine which API failed based on the error message
        if (e.toString().toLowerCase().contains('finnhub')) {
          _isFinnhubError = true;
          _internationalErrorMessage = 'Finnhub API error: ${e.toString()}';
        } else if (e.toString().toLowerCase().contains('alpha') ||
            e.toString().toLowerCase().contains('vantage')) {
          _isAlphaVantageError = true;
          _internationalErrorMessage =
              'Alpha Vantage API error: ${e.toString()}';
        } else {
          _internationalErrorMessage = 'API error: ${e.toString()}';
          // If we can't determine which API failed, assume both did
          _isFinnhubError = true;
          _isAlphaVantageError = true;
        }

        _logger.severe(_internationalErrorMessage);
      }

      // Fetch chart data
      _chartData = await _apiService.getMarketChartData();

      // Apply favorites status
      await _applyFavoritesToAssets();

      _lastUpdated = DateTime.now();
      _updateMarketStatus();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _logger.severe('Error in fetchMarketData: $e');
      _isLoading = false;

      // Ensure Ethiopian assets are always available even if overall fetch fails
      if (_ethiopianAssets.isEmpty) {
        _preloadEthiopianAssets();
      }

      notifyListeners();
    }
  }

  // Preload Ethiopian assets synchronously from local data for instant access
  void _preloadEthiopianAssets() {
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
          'Pre-loaded ${_ethiopianAssets.length} Ethiopian assets immediately');

      // Store to cache in background for faster future loads
      _apiService.saveEthiopianAssetsToCache(_ethiopianAssets);
    } catch (e) {
      _logger.severe('Error pre-loading Ethiopian assets: $e');
      // If even direct generation fails, try to use empty list but prevent app crash
      if (_ethiopianAssets.isEmpty) {
        _ethiopianAssets = [];
      }
    }
  }

  // Toggle favorite status with Firebase persistence
  Future<void> toggleFavorite(Asset asset) async {
    try {
      // Create loading indicator
      if (_navigatorKey.currentContext != null) {
        final scaffoldMessenger =
            ScaffoldMessenger.of(_navigatorKey.currentContext!);
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Row(
            children: [
              const CircularProgressIndicator(strokeWidth: 2),
              const SizedBox(width: 16),
              Text(asset.isFavorite
                  ? 'Removing from favorites...'
                  : 'Adding to favorites...')
            ],
          ),
          duration: const Duration(milliseconds: 800),
        ));
      }

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        // Set the local state but inform the user they need to log in for persistence
        asset.isFavorite = !asset.isFavorite;
        _updateFavoriteAssets();
        notifyListeners();

        if (_navigatorKey.currentContext != null) {
          ScaffoldMessenger.of(_navigatorKey.currentContext!)
              .showSnackBar(const SnackBar(
            content:
                Text('You must be logged in to save favorites permanently'),
            duration: Duration(seconds: 3),
          ));
        }
        return;
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

      // Show success message
      if (_navigatorKey.currentContext != null) {
        final scaffoldMessenger =
            ScaffoldMessenger.of(_navigatorKey.currentContext!);
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(asset.isFavorite
              ? '${asset.symbol} added to favorites'
              : '${asset.symbol} removed from favorites'),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      _logger.warning('Error toggling favorite: $e');
      if (_navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(_navigatorKey.currentContext!)
            .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
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

  // Manually retry loading international market data
  Future<void> retryInternationalData() async {
    _logger.info('Manually retrying international market data fetch');
    _isLoading = true;
    _isInternationalError = false;
    _internationalErrorMessage = '';
    notifyListeners();

    try {
      // When retrying, specify which API to prioritize based on previous errors
      bool prioritizeAlphaVantage = _isFinnhubError && !_isAlphaVantageError;
      _logger.info(
          'Retrying with ${prioritizeAlphaVantage ? "Alpha Vantage" : "Finnhub"} priority');

      // Pass retry information to the ApiService
      final internationalAssets =
          await _apiService.fetchInternationalMarketData(
              prioritizeAlphaVantage: prioritizeAlphaVantage);

      if (internationalAssets.isNotEmpty) {
        _internationalAssets = internationalAssets;
        _isInternationalError = false;
        _isFinnhubError = false;
        _isAlphaVantageError = false;
        _logger.info(
            'Successfully loaded ${_internationalAssets.length} international assets after retry');
      } else {
        _isInternationalError = true;
        _internationalErrorMessage =
            'No international market data available after retry';
        _logger.warning(_internationalErrorMessage);
      }
    } catch (e) {
      _isInternationalError = true;
      _internationalErrorMessage =
          'Failed to fetch international market data after retry: ${e.toString()}';
      _logger.severe(_internationalErrorMessage);
    } finally {
      _lastUpdated = DateTime.now();
      _isLoading = false;
      notifyListeners();
    }
  }
}
