import 'package:flutter/material.dart';
import '../models/news_article.dart';
import '../services/news_service.dart';

class NewsProvider with ChangeNotifier {
  final NewsService _newsService = NewsService();
  List<NewsArticle> _allNews = [];
  List<NewsArticle> _featuredNews = [];
  List<NewsArticle> _marketNews = [];
  List<NewsArticle> _economyNews = [];
  bool _isLoading = false;
  String _error = '';
  DateTime _lastFetched = DateTime(1900);

  // Getters
  List<NewsArticle> get allNews => _allNews;
  List<NewsArticle> get featuredNews => _featuredNews;
  List<NewsArticle> get marketNews => _marketNews;
  List<NewsArticle> get economyNews => _economyNews;
  bool get isLoading => _isLoading;
  String get error => _error;

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
  Future<void> fetchNews() async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      // Fetch all news
      final news = await _newsService.fetchAndCacheNews();

      // Update state
      _allNews = news;
      _lastFetched = DateTime.now();

      // Extract featured news (first 5)
      _featuredNews = news.take(5).toList();

      // Categorize news
      _categorizeNews();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load news: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Categorize news by keywords
  void _categorizeNews() {
    // Market news contains keywords related to stock market
    _marketNews = _allNews.where((article) {
      final text = '${article.title} ${article.description}'.toLowerCase();
      return text.contains('stock') ||
          text.contains('market') ||
          text.contains('share') ||
          text.contains('trading') ||
          text.contains('investment');
    }).toList();

    // Economy news contains keywords related to economy
    _economyNews = _allNews.where((article) {
      final text = '${article.title} ${article.description}'.toLowerCase();
      return text.contains('economy') ||
          text.contains('economic') ||
          text.contains('growth') ||
          text.contains('gdp') ||
          text.contains('inflation') ||
          text.contains('policy') ||
          text.contains('finance');
    }).toList();
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

  // Refresh news data
  Future<void> refreshNews() async {
    await fetchNews();
  }
}
