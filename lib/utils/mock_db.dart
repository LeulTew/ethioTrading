import 'dart:async';
import '../models/news_article.dart';
import '../models/asset.dart';

// Mock for Firebase Database
class MockFirebaseDatabase {
  static final MockFirebaseDatabase _instance =
      MockFirebaseDatabase._internal();
  final Map<String, dynamic> _data = {};

  factory MockFirebaseDatabase() {
    return _instance;
  }

  MockFirebaseDatabase._internal();

  static MockFirebaseDatabase get instance => _instance;

  MockDatabaseReference ref(String path) {
    return MockDatabaseReference(path, _data);
  }
}

// Mock for DatabaseReference
class MockDatabaseReference {
  final String _path;
  final Map<String, dynamic> _db;
  final List<StreamController<MockDatabaseEvent>> _controllers = [];

  MockDatabaseReference(this._path, this._db);

  MockDatabaseReference child(String path) {
    return MockDatabaseReference('$_path/$path', _db);
  }

  Stream<MockDatabaseEvent> get onValue {
    final controller = StreamController<MockDatabaseEvent>.broadcast();
    _controllers.add(controller);

    // Emit current value
    final value = _getDataAtPath();
    controller.add(MockDatabaseEvent(MockDataSnapshot(_path, value)));

    return controller.stream;
  }

  Stream<MockDatabaseEvent> get onChildChanged {
    final controller = StreamController<MockDatabaseEvent>.broadcast();
    _controllers.add(controller);
    return controller.stream;
  }

  Future<MockDataSnapshot> get() async {
    final data = _getDataAtPath();
    return MockDataSnapshot(_path, data);
  }

  Future<void> set(Map<String, dynamic> data) async {
    _setDataAtPath(data);
    _notifyListeners();
  }

  Future<void> update(Map<String, dynamic> data) async {
    final currentData = _getDataAtPath() ?? {};
    if (currentData is Map<String, dynamic>) {
      currentData.addAll(data);
      _setDataAtPath(currentData);
    } else {
      _setDataAtPath(data);
    }
    _notifyListeners();
  }

  // Helper to get data at current path
  dynamic _getDataAtPath() {
    List<String> segments =
        _path.split('/').where((s) => s.isNotEmpty).toList();
    dynamic current = _db;

    for (final segment in segments) {
      if (current is Map<String, dynamic> && current.containsKey(segment)) {
        current = current[segment];
      } else {
        return null;
      }
    }

    return current;
  }

  // Helper to set data at current path
  void _setDataAtPath(dynamic data) {
    List<String> segments =
        _path.split('/').where((s) => s.isNotEmpty).toList();

    if (segments.isEmpty) {
      if (data is Map<String, dynamic>) {
        _db.addAll(data);
      }
      return;
    }

    dynamic current = _db;
    for (int i = 0; i < segments.length - 1; i++) {
      final segment = segments[i];
      if (current is Map<String, dynamic>) {
        if (!current.containsKey(segment)) {
          current[segment] = <String, dynamic>{};
        }
        current = current[segment];
      }
    }

    if (current is Map<String, dynamic>) {
      current[segments.last] = data;
    }
  }

  // Notify listeners of changes
  void _notifyListeners() {
    final data = _getDataAtPath();
    for (final controller in _controllers) {
      controller.add(MockDatabaseEvent(MockDataSnapshot(_path, data)));
    }
  }

  // Clean up resources
  void dispose() {
    for (final controller in _controllers) {
      controller.close();
    }
    _controllers.clear();
  }
}

// Mock for DatabaseEvent
class MockDatabaseEvent {
  final MockDataSnapshot snapshot;

  MockDatabaseEvent(this.snapshot);
}

// Mock for DataSnapshot
class MockDataSnapshot {
  final dynamic _value;

  MockDataSnapshot(String path, this._value);

  dynamic get value => _value;

  bool get exists => _value != null;
}

// Extension methods to make Firebase Database mockable
extension MockableFirebaseDatabase on MockFirebaseDatabase {
  static MockFirebaseDatabase get instance => MockFirebaseDatabase.instance;
}

// Mock for NewsService
class MockNewsService {
  final List<NewsArticle> _articles = [];

  Future<List<NewsArticle>> fetchAndCacheNews() async {
    // Generate some mock news if empty
    if (_articles.isEmpty) {
      _generateMockNews();
    }
    return _articles;
  }

  Future<List<NewsArticle>> getBreakingNews() async {
    final allNews = await fetchAndCacheNews();
    return allNews.take(5).toList();
  }

  Future<List<NewsArticle>> getNewsByCategory(String category) async {
    final allNews = await fetchAndCacheNews();
    return allNews
        .where((article) =>
            article.title.toLowerCase().contains(category.toLowerCase()) ||
            article.description.toLowerCase().contains(category.toLowerCase()))
        .toList();
  }

  Future<List<NewsArticle>> searchNews(String query) async {
    final allNews = await fetchAndCacheNews();
    if (query.isEmpty) return allNews;

    return allNews
        .where((article) =>
            article.title.toLowerCase().contains(query.toLowerCase()) ||
            article.description.toLowerCase().contains(query.toLowerCase()) ||
            article.source.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  void _generateMockNews() {
    _articles.addAll([
      NewsArticle(
        title: 'Ethiopian Stock Exchange to Launch Digital Trading Platform',
        description:
            'The Ethiopian Stock Exchange announces new digital trading platform to modernize trading operations and increase accessibility.',
        url: 'https://example.com/news/1',
        imageUrl: 'https://example.com/images/trading_platform.jpg',
        source: 'Ethiopian Business Review',
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
        categories: ['Market', 'Technology'],
      ),
      NewsArticle(
        title: 'National Bank of Ethiopia Introduces New Monetary Policy',
        description:
            'The National Bank of Ethiopia has announced new monetary policy aimed at stabilizing inflation and supporting economic growth.',
        url: 'https://example.com/news/2',
        imageUrl: 'https://example.com/images/national_bank.jpg',
        source: 'Addis Fortune',
        publishedAt: DateTime.now().subtract(const Duration(hours: 8)),
        categories: ['Economy', 'Policy'],
      ),
      NewsArticle(
        title: 'Local Investment Firm Reports Record Growth',
        description:
            'One of Ethiopia\'s leading investment firms has reported record growth in the last quarter, with assets under management increasing by 25%.',
        url: 'https://example.com/news/3',
        imageUrl: 'https://example.com/images/investment.jpg',
        source: 'New Business Ethiopia',
        publishedAt: DateTime.now().subtract(const Duration(days: 1)),
        categories: ['Finance', 'Investment'],
      ),
      NewsArticle(
        title: 'Ethiopia\'s Coffee Exports Reach All-Time High',
        description:
            'Ethiopia\'s coffee exports have reached an all-time high, boosting the country\'s foreign exchange earnings significantly.',
        url: 'https://example.com/news/4',
        imageUrl: 'https://example.com/images/coffee.jpg',
        source: 'Ethiopian Business Review',
        publishedAt: DateTime.now().subtract(const Duration(days: 2)),
        categories: ['Commodities', 'Economy'],
      ),
      NewsArticle(
        title: 'New Regulations for Foreign Investment in Ethiopian Markets',
        description:
            'The Ethiopian Investment Commission has issued new regulations for foreign investment in the local stock market, aiming to attract international capital.',
        url: 'https://example.com/news/5',
        imageUrl: 'https://example.com/images/regulations.jpg',
        source: 'Addis Fortune',
        publishedAt: DateTime.now().subtract(const Duration(days: 3)),
        categories: ['Regulation', 'Market'],
      ),
    ]);
  }
}

// Mock for RealtimeMarketService
class MockRealtimeMarketService {
  late Function(Asset) onStockUpdate;
  late Function(bool) onMarketStatusChange;
  final List<Asset> _assets = [];
  final Map<String, StreamController<Asset>> _controllers = {};
  bool _isMarketOpen = true;

  MockRealtimeMarketService({
    required this.onStockUpdate,
    required this.onMarketStatusChange,
  }) {
    // Simulate market status updates
    Timer.periodic(const Duration(minutes: 30), (_) {
      final now = DateTime.now();
      _isMarketOpen = _isWithinTradingHours(now);
      onMarketStatusChange(_isMarketOpen);
    });
  }

  Future<void> initializeMarketData(List<Asset> initialAssets) async {
    _assets.clear();
    _assets.addAll(initialAssets);

    final now = DateTime.now();
    final isMarketOpen = _isWithinTradingHours(now);
    _isMarketOpen = isMarketOpen;
    onMarketStatusChange(isMarketOpen);

    if (isMarketOpen) {
      _startAutoPriceUpdates();
    }
  }

  void subscribeToStock(String symbol) {
    if (_controllers.containsKey(symbol)) return;

    final controller = StreamController<Asset>.broadcast();
    _controllers[symbol] = controller;

    // Find the asset and emit its current value
    final asset = _assets.firstWhere(
      (a) => a.symbol == symbol,
      orElse: () => _assets.first,
    );

    controller.add(asset);
    controller.stream.listen((asset) {
      onStockUpdate(asset);
    });
  }

  void unsubscribeFromStock(String symbol) {
    _controllers[symbol]?.close();
    _controllers.remove(symbol);
  }

  void subscribeToAllStocks() {
    for (final asset in _assets) {
      subscribeToStock(asset.symbol);
    }
  }

  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }

  bool _isWithinTradingHours(DateTime time) {
    // Ethiopian Stock Exchange trading hours: Monday-Friday, 9:00 AM - 3:00 PM
    final weekday = time.weekday;
    final hour = time.hour;

    if (weekday >= 1 && weekday <= 5) {
      // Monday to Friday
      if (hour >= 9 && hour < 15) {
        // 9 AM to 3 PM
        return true;
      }
    }
    return false;
  }

  void _startAutoPriceUpdates() {
    // Update prices every minute for simulation
    Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = DateTime.now();
      if (!_isWithinTradingHours(now)) {
        _isMarketOpen = false;
        onMarketStatusChange(false);
        timer.cancel();
        return;
      }

      // Update each asset
      for (int i = 0; i < _assets.length; i++) {
        final asset = _assets[i];

        // Randomly update price within daily limit rules
        final random = DateTime.now().millisecondsSinceEpoch % 100;
        double priceChange = 0;

        if (random < 45) {
          // Price increase (45% chance)
          priceChange = asset.price * (0.001 + (random % 10) / 1000);
        } else if (random < 90) {
          // Price decrease (45% chance)
          priceChange = -asset.price * (0.001 + (random % 10) / 1000);
        }
        // Otherwise no change (10% chance)

        // Calculate new price within daily limits
        double newPrice = asset.price + priceChange;
        if (asset.maxDailyPrice != null && newPrice > asset.maxDailyPrice!) {
          newPrice = asset.maxDailyPrice!;
        } else if (asset.minDailyPrice != null &&
            newPrice < asset.minDailyPrice!) {
          newPrice = asset.minDailyPrice!;
        }

        // Round to tickSize
        newPrice = (newPrice / asset.tickSize).round() * asset.tickSize;

        // Update if price has actually changed
        if (newPrice != asset.price) {
          final updatedAsset = asset.copyWithPrice(newPrice);
          _assets[i] = updatedAsset;

          // Notify listeners
          final controller = _controllers[asset.symbol];
          if (controller != null) {
            controller.add(updatedAsset);
          }

          // Call the global callback
          onStockUpdate(updatedAsset);
        }
      }
    });
  }
}
