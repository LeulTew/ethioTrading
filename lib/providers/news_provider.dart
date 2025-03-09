import 'package:flutter/foundation.dart';
import '../models/news_article.dart';
import '../services/news_service.dart';
import '../services/api_service.dart';

class NewsProvider with ChangeNotifier {
  final NewsService _newsService = NewsService();
  final ApiService _apiService;

  // Make collections final but maintain their mutability
  final List<NewsArticle> _articles = [];
  final List<NewsArticle> _allNews = [];
  final List<NewsArticle> _featuredNews = [];
  final List<NewsArticle> _marketNews = [];
  final List<NewsArticle> _economyNews = [];
  final Map<String, List<Map<String, dynamic>>> _newsByCategory = {};
  final DateTime _lastFetched = DateTime(1900);

  bool _isLoading = false;
  String? _error;

  NewsProvider({required ApiService apiService}) : _apiService = apiService;

  // Getters
  List<NewsArticle> get articles => _articles;
  List<NewsArticle> get allNews => _allNews;
  List<NewsArticle> get featuredNews => _featuredNews;
  List<NewsArticle> get marketNews => _marketNews;
  List<NewsArticle> get economyNews => _economyNews;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize news data
  Future<void> initializeNews() async {
    if (_shouldRefresh()) {
      await fetchNews();
    }
  }

  // Check if we should refresh the news
  bool _shouldRefresh() {
    final now = DateTime.now();
    // Refresh every 30 minutes
    return now.difference(_lastFetched).inMinutes > 30 || _allNews.isEmpty;
  }

  // Get breaking news
  Future<List<NewsArticle>> getBreakingNews() async {
    if (_isLoading) {
      // Wait for current fetch to complete if in progress
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _featuredNews;
    }

    if (_shouldRefresh()) {
      try {
        return await _newsService.getBreakingNews();
      } catch (e) {
        _error = 'Failed to load breaking news: $e';
        notifyListeners();
        return _featuredNews.isNotEmpty ? _featuredNews : [];
      }
    }

    return _featuredNews;
  }

  // Fetch news from service
  Future<void> fetchNews({String? category}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (category != null) {
        _articles.clear();
        _articles.addAll(await _newsService.getNewsByCategory(category));
      } else {
        _articles.clear();
        _articles.addAll(await _newsService.fetchAndCacheNews());
      }
    } catch (e) {
      _error = 'Failed to load news: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search news
  Future<List<NewsArticle>> searchNews(String query) async {
    if (query.isEmpty) return _allNews;

    // If we have local data and it's fresh, use it for search
    if (!_shouldRefresh()) {
      return _filterNewsByQuery(query);
    }

    // Otherwise fetch fresh data and search
    try {
      return await _newsService.searchNews(query);
    } catch (e) {
      _error = 'Search failed: $e';
      notifyListeners();
      return _filterNewsByQuery(query); // Fallback to local filtering
    }
  }

  // Filter news by query locally
  List<NewsArticle> _filterNewsByQuery(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _allNews.where((article) {
      return article.title.toLowerCase().contains(lowercaseQuery) ||
          article.description.toLowerCase().contains(lowercaseQuery) ||
          article.source.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Get news by category
  Future<List<NewsArticle>> getNewsByCategory(String category) async {
    switch (category.toLowerCase()) {
      case 'market':
        if (_marketNews.isNotEmpty) return _marketNews;
        break;
      case 'economy':
        if (_economyNews.isNotEmpty) return _economyNews;
        break;
      default:
        // Try to find by custom category
        try {
          return await _newsService.getNewsByCategory(category);
        } catch (e) {
          _error = 'Failed to load category: $e';
          notifyListeners();
          return [];
        }
    }

    // If we get here, refresh might be needed
    await fetchNews();
    return category.toLowerCase() == 'market' ? _marketNews : _economyNews;
  }

  // Fetch news for a specific category
  Future<void> fetchNewsForCategory({String category = 'business'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final news = await _apiService.fetchNews(category: category);
      _newsByCategory[category] = news;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get news by category
  List<Map<String, dynamic>> getNewsByCategoryFromApi(String category) {
    return _newsByCategory[category] ?? [];
  }

  // Clear all news data
  void clearNews() {
    _newsByCategory.clear();
    notifyListeners();
  }

  // Refresh news data
  Future<void> refreshNews() async {
    await fetchNews();
  }

  Future<List<NewsArticle>> getMarketNews() async {
    try {
      return await _newsService.getMarketNews();
    } catch (e) {
      _error = 'Failed to load market news: $e';
      return [];
    }
  }
}
