import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:logging/logging.dart';
import '../models/asset.dart';
import '../services/api_service.dart';

class MarketProvider with ChangeNotifier {
  final ApiService _apiService;
  final FirebaseDatabase _database;
  final Logger _logger = Logger('MarketProvider');

  List<Asset> _ethiopianAssets = [];
  List<Asset> _internationalAssets = [];
  List<Asset> _searchResults = [];
  bool _isLoading = false;
  bool _isMarketOpen = false;
  DateTime? _lastUpdated;

  // Constructor with dependency injection
  MarketProvider({
    required ApiService apiService,
    required FirebaseDatabase database,
  })  : _apiService = apiService,
        _database = database;

  // Getters
  List<Asset> get ethiopianAssets => _ethiopianAssets;
  List<Asset> get internationalAssets => _internationalAssets;
  List<Asset> get searchResults => _searchResults;
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

  // Fetch Ethiopian market data (mock or from Firebase if available)
  Future<void> _fetchEthiopianMarketData() async {
    try {
      // First try to get data from Firebase
      final snapshot = await _database.ref('ethiopian_market').get();

      if (snapshot.exists && snapshot.value != null) {
        // Use data from Firebase
        final data = snapshot.value as Map<dynamic, dynamic>;
        _ethiopianAssets = data.entries.map((entry) {
          final Map<dynamic, dynamic> assetData = entry.value;
          return Asset.fromMap({
            'symbol': entry.key,
            'name': assetData['name'] ?? 'Unknown',
            'price': assetData['price'] ?? 0.0,
            'change': assetData['change'] ?? 0.0,
            'changePercent': assetData['changePercent'] ?? 0.0,
            'volume': assetData['volume'] ?? 0,
            'marketCap': assetData['marketCap'] ?? 0.0,
            'sector': 'Ethiopian',
            'ownership': assetData['ownership'] ?? 'Government',
          });
        }).toList();
      } else {
        // Generate mock data if Firebase data is not available
        _ethiopianAssets = _generateMockEthiopianData();
      }
    } catch (e) {
      _logger.warning('Error fetching Ethiopian market data: $e');
      // Fallback to mock data
      _ethiopianAssets = _generateMockEthiopianData();
    }
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
    ];
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
        notifyListeners();
      }
    });
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
}
