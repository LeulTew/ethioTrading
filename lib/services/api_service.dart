import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/asset.dart';
import '../data/ethio_data.dart';
import '../config/env.dart';
import 'package:logging/logging.dart';
import '../data/mock_data.dart';

class ApiService {
  final FirebaseDatabase _database;
  final FirebaseAuth _auth;
  final Logger _logger = Logger('ApiService');
  final String _cachedAssetsKey = 'cached_ethiopian_assets';
  final String _lastUpdateTimeKey = 'last_update_time';

  ApiService({
    required FirebaseDatabase database,
    required FirebaseAuth auth,
  })  : _database = database,
        _auth = auth;

  // Fetch international market data using the market data service
  Future<List<Asset>> fetchInternationalMarketData() async {
    _logger.info('Fetching international market data');
    List<Asset> assets = [];

    try {
      // First check for cached data to prevent CORS issues on web
      final sharedPrefs = await SharedPreferences.getInstance();
      final cachedData = sharedPrefs.getString('cached_international_assets');
      final lastUpdate =
          sharedPrefs.getInt('international_last_update_time') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Use cached data if it's less than 30 minutes old
      if (cachedData != null && now - lastUpdate < 1800000) {
        _logger.info('Using cached international market data');
        final List<dynamic> decoded = json.decode(cachedData);
        assets = decoded.map((item) => Asset.fromJson(item)).toList();
        return assets;
      }

      // If no valid cache, try to fetch from API with error handling for CORS
      try {
        // Use a proxy endpoint to avoid CORS issues in web
        const url = '${Env.apiProxyUrl}/market/stocks';
        final response = await http.get(
          Uri.parse(url),
          headers: {'X-API-Key': Env.apiKey},
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          assets = (data['stocks'] as List)
              .map((item) => Asset.fromJson(item))
              .toList();

          // Cache the fetched data
          sharedPrefs.setString('cached_international_assets',
              json.encode(assets.map((a) => a.toJson()).toList()));
          sharedPrefs.setInt('international_last_update_time', now);

          _logger.info(
              'Successfully fetched ${assets.length} international stocks');
        } else {
          throw Exception(
              'API request failed with status: ${response.statusCode}');
        }
      } catch (e) {
        _logger.warning('API request failed: $e, generating fallback data');
        // If API request fails, generate fallback data
        assets = _generateFallbackInternationalAssets();

        // Cache the fallback data
        sharedPrefs.setString('cached_international_assets',
            json.encode(assets.map((a) => a.toJson()).toList()));
        sharedPrefs.setInt('international_last_update_time', now);
      }
    } catch (e) {
      _logger.severe('Error in fetchInternationalMarketData: $e');
      assets = _generateFallbackInternationalAssets();
    }

    return assets;
  }

  // Helper method to generate fallback international data
  List<Asset> _generateFallbackInternationalAssets() {
    _logger.info('Generating fallback international market data');
    final stocks = [
      {
        'name': 'Apple Inc.',
        'symbol': 'AAPL',
        'price': 175.0 + (DateTime.now().millisecondsSinceEpoch % 10) - 5,
        'change': 1.2,
        'volume': 36500000,
        'sector': 'Technology'
      },
      {
        'name': 'Microsoft Corporation',
        'symbol': 'MSFT',
        'price': 350.0 + (DateTime.now().millisecondsSinceEpoch % 10) - 5,
        'change': 0.8,
        'volume': 22000000,
        'sector': 'Technology'
      },
      {
        'name': 'Amazon.com Inc.',
        'symbol': 'AMZN',
        'price': 140.0 + (DateTime.now().millisecondsSinceEpoch % 10) - 5,
        'change': -0.5,
        'volume': 28000000,
        'sector': 'Consumer Cyclical'
      },
      {
        'name': 'Tesla Inc.',
        'symbol': 'TSLA',
        'price': 220.0 + (DateTime.now().millisecondsSinceEpoch % 15) - 7,
        'change': -1.3,
        'volume': 95000000,
        'sector': 'Automotive'
      },
      {
        'name': 'Alphabet Inc.',
        'symbol': 'GOOGL',
        'price': 130.0 + (DateTime.now().millisecondsSinceEpoch % 8) - 4,
        'change': 0.6,
        'volume': 19000000,
        'sector': 'Technology'
      },
    ];

    return stocks
        .map((item) => Asset(
              name: item['name'] as String,
              symbol: item['symbol'] as String,
              price: item['price'] as double,
              change: item['change'] as double,
              changePercent:
                  (item['change'] as double) * 100 / (item['price'] as double),
              volume: item['volume'] as double,
              sector: item['sector'] as String,
              ownership: 'Public',
              marketCap:
                  (item['price'] as double) * (item['volume'] as double) * 10,
              lastUpdated: DateTime.now(),
              dayHigh: (item['price'] as double) +
                  ((item['price'] as double) * 0.02),
              dayLow: (item['price'] as double) -
                  ((item['price'] as double) * 0.02),
              openPrice: (item['price'] as double) - (item['change'] as double),
              lotSize: 1,
              tickSize: 0.01,
            ))
        .toList();
  }

  // Cache Ethiopian assets to shared preferences
  Future<void> saveEthiopianAssetsToCache(List<Asset> assets) async {
    _logger.info('Caching ${assets.length} Ethiopian assets locally');
    try {
      final sharedPrefs = await SharedPreferences.getInstance();
      final jsonData = json.encode(assets.map((a) => a.toJson()).toList());
      await sharedPrefs.setString(_cachedAssetsKey, jsonData);
      await sharedPrefs.setInt(
          _lastUpdateTimeKey, DateTime.now().millisecondsSinceEpoch);

      // Also save to Firebase if user is logged in
      await _saveEthiopianAssetsToFirebase(assets);
    } catch (e) {
      _logger.warning('Error caching Ethiopian assets: $e');
    }
  }

  // Save Ethiopian assets to Firebase for all users
  Future<void> _saveEthiopianAssetsToFirebase(List<Asset> assets) async {
    try {
      // Check if user is authenticated
      final user = _auth.currentUser;
      if (user == null) {
        _logger.info('No user logged in, skipping Firebase save');
        return;
      }

      _logger.info('Saving Ethiopian assets to Firebase');
      final dbRef = _database.ref('market_data/ethiopian_assets');

      // Convert assets to JSON format
      final dataToSave = {
        'lastUpdated': ServerValue.timestamp,
        'assets': assets.map((a) => a.toJson()).toList(),
      };

      // Save to Firebase
      await dbRef.set(dataToSave);
      _logger.info('Successfully saved Ethiopian assets to Firebase');
    } catch (e) {
      _logger.warning('Error saving Ethiopian assets to Firebase: $e');
    }
  }

  // Get cached Ethiopian assets from shared preferences
  Future<List<Asset>> getCachedEthiopianAssets() async {
    _logger.info('Getting cached Ethiopian assets');
    try {
      final sharedPrefs = await SharedPreferences.getInstance();
      final cachedData = sharedPrefs.getString(_cachedAssetsKey);
      final lastUpdate = sharedPrefs.getInt(_lastUpdateTimeKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // If cache is valid (less than 1 hour old)
      if (cachedData != null && now - lastUpdate < 3600000) {
        _logger.info('Found valid cached Ethiopian assets');
        final List<dynamic> decoded = json.decode(cachedData);
        return decoded.map((item) => Asset.fromJson(item)).toList();
      }

      // If local cache is not valid, try retrieving from Firebase
      return await _getEthiopianAssetsFromFirebase();
    } catch (e) {
      _logger.warning('Error getting cached Ethiopian assets: $e');
      return [];
    }
  }

  // Get Ethiopian assets from Firebase
  Future<List<Asset>> _getEthiopianAssetsFromFirebase() async {
    _logger.info('Getting Ethiopian assets from Firebase');
    try {
      final dbRef = _database.ref('market_data/ethiopian_assets');
      final snapshot = await dbRef.get();

      if (snapshot.exists) {
        _logger.info('Found Ethiopian assets in Firebase');
        final data = snapshot.value as Map<dynamic, dynamic>;
        final assetsList = (data['assets'] as List<dynamic>);

        final assets = assetsList.map((item) {
          final jsonItem = Map<String, dynamic>.from(item as Map);
          return Asset.fromJson(jsonItem);
        }).toList();

        // Update local cache
        final sharedPrefs = await SharedPreferences.getInstance();
        await sharedPrefs.setString(_cachedAssetsKey,
            json.encode(assets.map((a) => a.toJson()).toList()));
        await sharedPrefs.setInt(
            _lastUpdateTimeKey, DateTime.now().millisecondsSinceEpoch);

        return assets;
      }

      _logger.info('No Ethiopian assets found in Firebase');
      return [];
    } catch (e) {
      _logger.warning('Error getting Ethiopian assets from Firebase: $e');
      return [];
    }
  }

  // Generate Ethiopian assets using EthioData
  Future<List<Asset>> generateAndCacheEthiopianAssets() async {
    _logger.info('Generating Ethiopian market data');
    try {
      final ethioMarketData = EthioData.generateMockEthioMarketData();
      final ethiopianAssets = ethioMarketData
          .map((data) => Asset(
                name: data['name'] as String,
                symbol: data['symbol'] as String,
                price: data['price'] as double,
                change: data['change'] as double,
                changePercent: data['change'] as double,
                volume: data['volume'] as double,
                sector: data['sector'] as String,
                ownership: data['ownership'] as String,
                marketCap: data['marketCap'] as double,
                lastUpdated: DateTime.now(),
                dayHigh: data['dayHigh'] as double,
                dayLow: data['dayLow'] as double,
                openPrice: data['openPrice'] as double,
                lotSize: data['lotSize'] as int? ?? 1,
                tickSize: data['tickSize'] as double? ?? 0.05,
              ))
          .toList();

      // Cache the generated assets
      await saveEthiopianAssetsToCache(ethiopianAssets);

      return ethiopianAssets;
    } catch (e) {
      _logger.severe('Error generating Ethiopian assets: $e');
      return [];
    }
  }

  // Get market chart data
  Future<List<Map<String, dynamic>>> getMarketChartData() async {
    _logger.info('Getting market chart data');
    try {
      final sharedPrefs = await SharedPreferences.getInstance();
      final cachedData = sharedPrefs.getString('market_chart_data');
      final lastUpdate = sharedPrefs.getInt('chart_data_updated') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Use cached chart data if less than 1 hour old
      if (cachedData != null && now - lastUpdate < 3600000) {
        return List<Map<String, dynamic>>.from(json.decode(cachedData));
      }

      // Generate new chart data
      final chartData = _generateChartData();

      // Cache the chart data
      await sharedPrefs.setString('market_chart_data', json.encode(chartData));
      await sharedPrefs.setInt('chart_data_updated', now);

      return chartData;
    } catch (e) {
      _logger.warning('Error getting market chart data: $e');
      return _generateChartData();
    }
  }

  // Helper function to generate mock chart data
  List<Map<String, dynamic>> _generateChartData() {
    _logger.info('Generating mock chart data');
    final random = DateTime.now().millisecondsSinceEpoch;
    final baseValue = 1000.0 + (random % 200);
    final data = <Map<String, dynamic>>[];

    // Generate daily data for the past 30 days
    final now = DateTime.now();
    for (int i = 30; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final changePercent = ((random >> i) % 100) / 1000.0;
      final value = baseValue * (1 + (changePercent * i));

      data.add({
        'date': date.toIso8601String().substring(0, 10),
        'value': value,
        'volume': 1000000.0 + (random % 2000000),
      });
    }

    return data;
  }

  // Get Ethiopian assets from Firebase first, then cache
  Future<List<Asset>> fetchEthiopianAssets() async {
    try {
      _logger.info('Fetching Ethiopian assets from Firebase');
      final snapshot = await _database.ref('marketData/ethiopian').get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;

        // Skip metadata
        data.remove('_metadata');

        List<Asset> assets = [];
        data.forEach((key, value) {
          try {
            assets.add(Asset.fromMap(Map<String, dynamic>.from(value)));
          } catch (e) {
            _logger.warning('Error parsing Ethiopian asset data: $e');
          }
        });

        if (assets.isNotEmpty) {
          // Update local cache
          await saveEthiopianAssetsToCache(assets);
          return assets;
        }
      }

      // If no Firebase data, generate new
      return await generateAndCacheEthiopianAssets();
    } catch (e) {
      _logger.severe('Error fetching Ethiopian assets from Firebase: $e');

      // Fallback to cache or generate new
      final cachedAssets = await getCachedEthiopianAssets();
      if (cachedAssets.isNotEmpty) {
        return cachedAssets;
      }

      return await generateAndCacheEthiopianAssets();
    }
  }

  // Fetch news for a specific stock
  Future<List<Map<String, dynamic>>> fetchStockNews(String symbol) async {
    try {
      final snapshot = await _database.ref('news/stocks/$symbol').get();

      if (snapshot.exists) {
        final data = snapshot.value as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      }

      // Generate mock news if no data
      final mockNews = MockDataGenerator.generateNewsForStock(symbol);

      // Save to Firebase
      await _database.ref('news/stocks/$symbol').set(mockNews);

      return mockNews;
    } catch (e) {
      _logger.severe('Error fetching news for $symbol: $e');
      return MockDataGenerator.generateNewsForStock(symbol);
    }
  }

  // Fetch news by category directly from News API
  Future<List<Map<String, dynamic>>> fetchNews(
      {String category = 'business'}) async {
    _logger.info('Fetching news for category: $category');
    try {
      // First check if we have cached news in SharedPreferences
      final sharedPrefs = await SharedPreferences.getInstance();
      final cacheKey = 'news_cache_$category';
      final cachedNewsData = sharedPrefs.getString(cacheKey);
      final cacheTimestampKey = 'news_timestamp_$category';
      final cacheTimestamp = sharedPrefs.getInt(cacheTimestampKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Use cache if it's less than 30 minutes old
      if (cachedNewsData != null && now - cacheTimestamp < 1800000) {
        _logger.info('Using cached news data for category: $category');
        return List<Map<String, dynamic>>.from(json.decode(cachedNewsData));
      }

      // If no valid cache, fetch from News API
      _logger.info(
          'Fetching fresh news data from News API for category: $category');

      final params = {
        'apiKey': Env.newsApiKey,
        'category': category,
        'language': 'en',
        'pageSize': '20',
      };

      // Add Ethiopia as query to get more relevant results
      String url = '${Env.newsApiBaseUrl}/top-headlines?q=Ethiopia&';
      params.forEach((key, value) {
        url += '$key=$value&';
      });
      url = url.substring(0, url.length - 1); // Remove trailing &

      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'ok') {
          final articles = data['articles'] as List;

          // Transform to our format
          final newsList = articles
              .map((article) => {
                    'id':
                        'NEWS_${article['publishedAt']}_${article['source']['name']}',
                    'headline': article['title'],
                    'summary':
                        article['description'] ?? 'No description available',
                    'content': article['content'] ??
                        article['description'] ??
                        'No content available',
                    'publishDate': article['publishedAt'],
                    'source': article['source']['name'],
                    'imageUrl': article['urlToImage'] ??
                        'https://ethiotrading.com/default-news-image.png',
                    'url': article['url'],
                    'category': category,
                  })
              .toList();

          // Cache the results
          await sharedPrefs.setString(cacheKey, json.encode(newsList));
          await sharedPrefs.setInt(cacheTimestampKey, now);

          // Also store in Firebase for offline access
          try {
            await _database.ref('news/categories/$category').set(newsList);
          } catch (e) {
            _logger.warning('Failed to cache news in Firebase: $e');
          }

          return List<Map<String, dynamic>>.from(newsList);
        } else {
          throw Exception('News API returned status: ${data['status']}');
        }
      } else {
        throw Exception(
            'API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error fetching news from API for category $category: $e');

      // Try to get news from Firebase as backup
      try {
        final snapshot = await _database.ref('news/categories/$category').get();

        if (snapshot.exists) {
          _logger
              .info('Using news from Firebase backup for category: $category');
          final data = snapshot.value as List<dynamic>;
          return data.cast<Map<String, dynamic>>();
        }
      } catch (fbError) {
        _logger.warning('Failed to get news from Firebase: $fbError');
      }

      // If all else fails, return empty list
      return [];
    }
  }
}
