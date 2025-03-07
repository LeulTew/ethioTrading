import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../models/news_article.dart';
import '../utils/mock_db.dart';

class NewsService {
  // Logger for debugging or future use
  final _logger = Logger('NewsService');

  NewsService() {
    // Initialize logging for future use
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen((record) {
      debugPrint('${record.level.name}: ${record.time}: ${record.message}');
    });

    _logger.info('NewsService initialized');
  }

  // Fetch news from sources and cache in Firebase
  Future<List<NewsArticle>> fetchAndCacheNews() async {
    _logger.info('Fetching news');
    final mockNewsService = MockNewsService();
    return mockNewsService.fetchAndCacheNews();
  }

  // Get breaking news (most recent 5 articles)
  Future<List<NewsArticle>> getBreakingNews() async {
    _logger.info('Getting breaking news');
    final mockNewsService = MockNewsService();
    return mockNewsService.getBreakingNews();
  }

  // Get news by category
  Future<List<NewsArticle>> getNewsByCategory(String category) async {
    _logger.info('Getting news by category: $category');
    final mockNewsService = MockNewsService();
    return mockNewsService.getNewsByCategory(category);
  }

  // Search news
  Future<List<NewsArticle>> searchNews(String query) async {
    _logger.info('Searching news with query: $query');
    final mockNewsService = MockNewsService();
    return mockNewsService.searchNews(query);
  }
}
