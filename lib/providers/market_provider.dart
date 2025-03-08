import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/asset.dart';
import '../services/api_service.dart';

class MarketProvider with ChangeNotifier {
  final ApiService _apiService;
  final FirebaseDatabase _database;
  final Logger _logger = Logger('MarketProvider');

  List<Asset> _ethiopianAssets = [];
  List<Asset> _internationalAssets = [];
  List<Asset> _searchResults = [];
  List<Asset> _favoriteAssets = []; // Added for storing favorite assets
  bool _isLoading = false;
  bool _isMarketOpen = false;
  DateTime? _lastUpdated;

  // Constructor with dependency injection
  MarketProvider({
    required ApiService apiService,
    required FirebaseDatabase database,
  })  : _apiService = apiService,
        _database = database {
    // Load favorites when provider is initialized
    _loadFavorites();
  }

  // Getters
  List<Asset> get ethiopianAssets => _ethiopianAssets;
  List<Asset> get internationalAssets => _internationalAssets;
  List<Asset> get searchResults => _searchResults;
  List<Asset> get favoriteAssets => _favoriteAssets; // New getter for favorites
  bool get isLoading => _isLoading;
  bool get isMarketOpen => _isMarketOpen;
  DateTime? get lastUpdated => _lastUpdated;

  String get formattedLastUpdated {
    if (_lastUpdated == null) return '';
    return DateFormat('MMM d, yyyy HH:mm:ss').format(_lastUpdated!);
  }

  // Fetch market data from API and Firebase
  Future<void> fetchMarketData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch international market data from real API
      final internationalData =
          await _apiService.fetchInternationalMarketData();
      _internationalAssets = internationalData;

      // Always use mock data for Ethiopian market
      _ethiopianAssets = _generateMockEthiopianData();

      // Apply favorites status to assets
      await _applyFavoritesToAssets();

      // Update market status
      _updateMarketStatus();

      _lastUpdated = DateTime.now();
      _isLoading = false;
      notifyListeners();

      // Set up real-time listeners for updates, but only for international markets
      _setupRealtimeListenersForInternational();
    } catch (e) {
      _logger.severe('Error fetching market data: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set up real-time listeners for market updates (international only)
  void _setupRealtimeListenersForInternational() {
    // Listen for international market updates
    _database.ref('international_market').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;

        // Update existing assets with new data
        for (var asset in _internationalAssets) {
          if (data.containsKey(asset.symbol)) {
            final assetData = data[asset.symbol] as Map<dynamic, dynamic>;
            asset.price = assetData['price'] ?? asset.price;
            asset.change = assetData['change'] ?? asset.change;
            asset.changePercent =
                assetData['changePercent'] ?? asset.changePercent;
            asset.volume = assetData['volume'] ?? asset.volume;
          }
        }

        _lastUpdated = DateTime.now();
        // Update favorites as well if they contain international assets
        _updateFavoriteAssets();
        notifyListeners();
      }
    });
  }

  // Toggle favorite status for an asset
  Future<void> toggleFavorite(Asset asset) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorites') ?? [];

    if (asset.isFavorite) {
      favorites.remove(asset.symbol);
    } else {
      favorites.add(asset.symbol);
    }

    asset.toggleFavorite();

    await prefs.setStringList('favorites', favorites);
    _updateFavoriteAssets();
    notifyListeners();
  }

  // Load favorites from SharedPreferences
  Future<void> _loadFavorites() async {
    try {
      await _applyFavoritesToAssets();
      _updateFavoriteAssets();
    } catch (e) {
      _logger.severe('Error loading favorites: $e');
    }
  }

  // Apply favorite status to assets based on saved favorites
  Future<void> _applyFavoritesToAssets() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorites') ?? [];

    // Mark assets as favorites based on saved list
    for (var asset in [..._ethiopianAssets, ..._internationalAssets]) {
      asset.isFavorite = favorites.contains(asset.symbol);
    }
  }

  // Update the _favoriteAssets list based on current favorites
  void _updateFavoriteAssets() {
    _favoriteAssets = [
      ..._ethiopianAssets.where((asset) => asset.isFavorite),
      ..._internationalAssets.where((asset) => asset.isFavorite),
    ];
  }

  // Find asset by symbol
  Asset? findAssetBySymbol(String symbol) {
    // Search in Ethiopian assets
    final ethiopianMatch =
        _ethiopianAssets.where((asset) => asset.symbol == symbol).toList();
    if (ethiopianMatch.isNotEmpty) return ethiopianMatch.first;

    // Search in international assets
    final internationalMatch =
        _internationalAssets.where((asset) => asset.symbol == symbol).toList();
    if (internationalMatch.isNotEmpty) return internationalMatch.first;

    return null;
  }

  // Update market open/closed status
  void _updateMarketStatus() {
    final now = DateTime.now();
    final weekday = now.weekday;

    // Markets are closed on weekends (Saturday and Sunday)
    if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
      _isMarketOpen = false;
      return;
    }

    // Check if current time is within market hours (9:00 AM - 4:00 PM)
    final hour = now.hour;
    _isMarketOpen = hour >= 9 && hour < 16;

    notifyListeners();
  }

  // Search assets by symbol or name
  void searchAssets(String query) {
    if (query.isEmpty) {
      _searchResults = [];
    } else {
      final lowercaseQuery = query.toLowerCase();
      _searchResults = [
        ..._ethiopianAssets,
        ..._internationalAssets,
      ].where((asset) {
        return asset.symbol.toLowerCase().contains(lowercaseQuery) ||
            asset.name.toLowerCase().contains(lowercaseQuery);
      }).toList();
    }
    notifyListeners();
  }

  // Clear search results
  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  // Get count of gainers (assets with positive change)
  int getGainersCount(bool isEthiopian) {
    final assets = isEthiopian ? _ethiopianAssets : _internationalAssets;
    return assets.where((asset) => asset.changePercent > 0).length;
  }

  // Get count of losers (assets with negative change)
  int getLosersCount(bool isEthiopian) {
    final assets = isEthiopian ? _ethiopianAssets : _internationalAssets;
    return assets.where((asset) => asset.changePercent < 0).length;
  }

  // Get total trading volume
  double getTotalVolume(bool isEthiopian) {
    final assets = isEthiopian ? _ethiopianAssets : _internationalAssets;
    return assets.fold(0, (sum, asset) => sum + asset.volume);
  }

  // Generate mock Ethiopian market data
  List<Asset> _generateMockEthiopianData() {
    return [
      Asset(
        symbol: 'EABL',
        name: 'Ethiopian Airlines',
        price: 1250.75,
        change: 25.50,
        changePercent: 2.08,
        volume: 125000,
        marketCap: 45000000000,
        sector: 'Ethiopian',
        ownership: 'Government',
      ),
      Asset(
        symbol: 'ECBC',
        name: 'Commercial Bank of Ethiopia',
        price: 875.25,
        change: -12.75,
        changePercent: -1.44,
        volume: 98500,
        marketCap: 32500000000,
        sector: 'Ethiopian',
        ownership: 'Government',
      ),
      Asset(
        symbol: 'ETLC',
        name: 'Ethio Telecom',
        price: 425.00,
        change: 8.25,
        changePercent: 1.98,
        volume: 215000,
        marketCap: 28750000000,
        sector: 'Ethiopian',
        ownership: 'Government',
      ),
      Asset(
        symbol: 'EMSC',
        name: 'Ethiopian Mining Corp',
        price: 325.50,
        change: -5.25,
        changePercent: -1.59,
        volume: 78500,
        marketCap: 12500000000,
        sector: 'Ethiopian',
        ownership: 'Government',
      ),
      Asset(
        symbol: 'ESGC',
        name: 'Ethiopian Sugar Corp',
        price: 175.25,
        change: 3.75,
        changePercent: 2.19,
        volume: 45000,
        marketCap: 8750000000,
        sector: 'Ethiopian',
        ownership: 'Government',
      ),
      Asset(
        symbol: 'ECMC',
        name: 'Ethiopian Cement Manufacturing',
        price: 225.00,
        change: -2.50,
        changePercent: -1.10,
        volume: 65000,
        marketCap: 9500000000,
        sector: 'Ethiopian',
        ownership: 'Private',
      ),
      Asset(
        symbol: 'EDBC',
        name: 'Development Bank of Ethiopia',
        price: 450.75,
        change: 7.25,
        changePercent: 1.63,
        volume: 85000,
        marketCap: 18500000000,
        sector: 'Ethiopian',
        ownership: 'Government',
      ),
      Asset(
        symbol: 'ENIC',
        name: 'Ethiopian Insurance Corp',
        price: 275.50,
        change: 4.25,
        changePercent: 1.57,
        volume: 55000,
        marketCap: 11250000000,
        sector: 'Ethiopian',
        ownership: 'Private',
      ),
      // Add more Ethiopian tradable assets
      Asset(
        symbol: 'EEPC',
        name: 'Ethiopian Electric Power',
        price: 320.00,
        change: 12.50,
        changePercent: 4.06,
        volume: 92000,
        marketCap: 16800000000,
        sector: 'Ethiopian',
        ownership: 'Government',
      ),
      Asset(
        symbol: 'ASHB',
        name: 'Awash Bank',
        price: 750.25,
        change: -8.75,
        changePercent: -1.15,
        volume: 45000,
        marketCap: 15500000000,
        sector: 'Ethiopian',
        ownership: 'Private',
      ),
      Asset(
        symbol: 'DSHB',
        name: 'Dashen Bank',
        price: 680.00,
        change: 15.20,
        changePercent: 2.29,
        volume: 38000,
        marketCap: 14200000000,
        sector: 'Ethiopian',
        ownership: 'Private',
      ),
      Asset(
        symbol: 'HABR',
        name: 'Habesha Breweries',
        price: 185.50,
        change: -4.30,
        changePercent: -2.27,
        volume: 65000,
        marketCap: 7800000000,
        sector: 'Ethiopian',
        ownership: 'Private',
      ),
      Asset(
        symbol: 'MTGR',
        name: 'Meta Abo Brewery',
        price: 210.75,
        change: 5.25,
        changePercent: 2.55,
        volume: 48000,
        marketCap: 8500000000,
        sector: 'Ethiopian',
        ownership: 'Private',
      ),
      Asset(
        symbol: 'WEGB',
        name: 'Wegagen Bank',
        price: 550.00,
        change: -7.50,
        changePercent: -1.35,
        volume: 32000,
        marketCap: 12400000000,
        sector: 'Ethiopian',
        ownership: 'Private',
      ),
      Asset(
        symbol: 'ABSY',
        name: 'Bank of Abyssinia',
        price: 620.25,
        change: 8.75,
        changePercent: 1.43,
        volume: 29000,
        marketCap: 13100000000,
        sector: 'Ethiopian',
        ownership: 'Private',
      ),
      Asset(
        symbol: 'BIBC',
        name: 'Berhan International Bank',
        price: 390.00,
        change: 2.25,
        changePercent: 0.58,
        volume: 18500,
        marketCap: 7600000000,
        sector: 'Ethiopian',
        ownership: 'Private',
      ),
      Asset(
        symbol: 'EHCM',
        name: 'East African Holdings',
        price: 475.50,
        change: 12.25,
        changePercent: 2.64,
        volume: 54000,
        marketCap: 9800000000,
        sector: 'Ethiopian',
        ownership: 'Private',
      ),
      Asset(
        symbol: 'ELFT',
        name: 'ELFORA Agro Industries',
        price: 180.75,
        change: -3.25,
        changePercent: -1.77,
        volume: 42000,
        marketCap: 5200000000,
        sector: 'Ethiopian',
        ownership: 'Private',
      ),
      Asset(
        symbol: 'MIDR',
        name: 'Midroc Ethiopia',
        price: 585.00,
        change: 10.50,
        changePercent: 1.83,
        volume: 72000,
        marketCap: 18900000000,
        sector: 'Ethiopian',
        ownership: 'Private',
      ),
      Asset(
        symbol: 'AMCE',
        name: 'Automotive Manufacturing Co',
        price: 210.25,
        change: -5.75,
        changePercent: -2.66,
        volume: 38000,
        marketCap: 6300000000,
        sector: 'Ethiopian',
        ownership: 'Private',
      ),
      Asset(
        symbol: 'NCEM',
        name: 'National Cement Share Company',
        price: 345.00,
        change: 7.25,
        changePercent: 2.15,
        volume: 51000,
        marketCap: 8900000000,
        sector: 'Ethiopian',
        ownership: 'Private',
      ),
      Asset(
        symbol: 'MOHA',
        name: 'Moha Soft Drinks Industry',
        price: 295.50,
        change: 4.25,
        changePercent: 1.46,
        volume: 47000,
        marketCap: 7100000000,
        sector: 'Ethiopian',
        ownership: 'Private',
      ),
      Asset(
        symbol: 'ETUR',
        name: 'Ethiopian Tourism Organization',
        price: 155.25,
        change: -2.75,
        changePercent: -1.74,
        volume: 28000,
        marketCap: 4200000000,
        sector: 'Ethiopian',
        ownership: 'Government',
      ),
      Asset(
        symbol: 'ECFE',
        name: 'Ethiopian Coffee Exporters Association',
        price: 230.00,
        change: 8.50,
        changePercent: 3.84,
        volume: 65000,
        marketCap: 6800000000,
        sector: 'Ethiopian',
        ownership: 'Private',
      ),
    ];
  }
}
