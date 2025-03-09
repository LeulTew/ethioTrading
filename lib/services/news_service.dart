import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import '../config/env.dart';
import '../models/news_article.dart';
import '../utils/mock_db.dart';

class NewsService {
  final _logger = Logger('NewsService');
  final _marketNewsCache = <NewsArticle>[];
  final _generalNewsCache = <NewsArticle>[];
  final _cacheExpirationDuration = const Duration(minutes: 15);
  DateTime? _lastMarketNewsFetch;
  DateTime? _lastGeneralNewsFetch;

  NewsService() {
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen((record) {
      debugPrint('${record.level.name}: ${record.time}: ${record.message}');
    });

    _logger.info('NewsService initialized');
  }

  Future<List<NewsArticle>> fetchAndCacheNews() async {
    _logger.info('Fetching news');

    // Try multiple news sources in order of preference
    List<NewsArticle> articles = [];

    // 1. First try NewsAPI
    if (Env.newsApiKey.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse(
              '${Env.newsApiBaseUrl}/top-headlines?category=business&language=en&apiKey=${Env.newsApiKey}'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> articlesData = data['articles'] ?? [];

          if (articlesData.isNotEmpty) {
            articles = articlesData
                .map((article) => NewsArticle(
                      title: article['title'] ?? 'No title',
                      description: article['description'] ?? 'No description',
                      url: article['url'] ?? '',
                      imageUrl: _validateImageUrl(article['urlToImage']),
                      source: (article['source'] != null)
                          ? article['source']['name'] ?? 'Unknown'
                          : 'Unknown',
                      publishedAt:
                          DateTime.tryParse(article['publishedAt'] ?? '') ??
                              DateTime.now(),
                    ))
                .toList();
            return articles;
          }
        }
      } catch (e) {
        _logger.warning('Error fetching from NewsAPI: $e');
        // Continue to next source
      }
    }

    // 2. Try Finnhub as backup
    if (Env.finnhubApiKey.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse(
              '${Env.finnhubBaseUrl}/news?category=general&token=${Env.finnhubApiKey}'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final List<dynamic> articlesData = json.decode(response.body);

          if (articlesData.isNotEmpty) {
            articles = articlesData
                .map((article) => NewsArticle(
                      title: article['headline'] ?? 'No title',
                      description: article['summary'] ?? 'No description',
                      url: article['url'] ?? '',
                      imageUrl: _validateImageUrl(article['image']),
                      source: article['source'] ?? 'Unknown',
                      publishedAt: DateTime.fromMillisecondsSinceEpoch(
                          (article['datetime'] ?? 0) * 1000),
                    ))
                .toList();
            return articles;
          }
        }
      } catch (e) {
        _logger.warning('Error fetching from Finnhub: $e');
        // Continue to next source
      }
    }

    // 3. Try Alpha Vantage as another backup
    if (Env.alphaVantageApiKey.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse(
              '${Env.alphaVantageBaseUrl}?function=NEWS_SENTIMENT&apikey=${Env.alphaVantageApiKey}&topics=financial_markets'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> feed = data['feed'] ?? [];

          if (feed.isNotEmpty) {
            articles = feed
                .map((article) => NewsArticle(
                      title: article['title'] ?? 'No title',
                      description: article['summary'] ?? 'No description',
                      url: article['url'] ?? '',
                      imageUrl: _validateImageUrl(article['banner_image']),
                      source: article['source'] ?? 'Unknown',
                      publishedAt:
                          DateTime.tryParse(article['time_published'] ?? '') ??
                              DateTime.now(),
                    ))
                .toList();
            return articles;
          }
        }
      } catch (e) {
        _logger.warning('Error fetching from Alpha Vantage: $e');
        // Fall back to mock data
      }
    }

    // 4. Finally, use mock data if all APIs fail
    _logger.info('All API attempts failed, using mock news data');
    return _getMockNewsArticles();
  }

  Future<List<NewsArticle>> getBreakingNews() async {
    _logger.info('Getting breaking news');

    final articles = await fetchAndCacheNews();
    return articles.take(5).toList();
  }

  Future<List<NewsArticle>> getNewsByCategory(String category) async {
    _logger.info('Getting news by category: $category');

    if (Env.useRealNewsData && Env.finnhubApiKey.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse(
              '${Env.finnhubBaseUrl}/news?category=$category&token=${Env.finnhubApiKey}'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final List<dynamic> articlesData = json.decode(response.body);

          return articlesData
              .map((article) => NewsArticle(
                    title: article['headline'] ?? 'No title',
                    description: article['summary'] ?? 'No description',
                    url: article['url'] ?? '',
                    imageUrl: article['image'] ?? '',
                    source: article['source'] ?? 'Unknown',
                    publishedAt: DateTime.fromMillisecondsSinceEpoch(
                        (article['datetime'] ?? 0) * 1000),
                  ))
              .toList();
        } else {
          _logger
              .warning('Failed to load category news: ${response.statusCode}');
          throw Exception(
              'Failed to load category news: ${response.statusCode}');
        }
      } catch (e) {
        _logger.severe('Error fetching category news: $e');
        return _getMockNewsArticlesByCategory(category);
      }
    } else {
      return _getMockNewsArticlesByCategory(category);
    }
  }

  Future<List<NewsArticle>> searchNews(String query) async {
    _logger.info('Searching news with query: $query');

    if (Env.useRealNewsData &&
        Env.finnhubApiKey.isNotEmpty &&
        query.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse(
              '${Env.finnhubBaseUrl}/news?category=general&token=${Env.finnhubApiKey}'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final List<dynamic> articlesData = json.decode(response.body);
          final filteredArticles = articlesData
              .where((article) =>
                  (article['headline'] as String?)
                          ?.toLowerCase()
                          .contains(query.toLowerCase()) ==
                      true ||
                  (article['summary'] as String?)
                          ?.toLowerCase()
                          .contains(query.toLowerCase()) ==
                      true)
              .toList();

          return filteredArticles
              .map((article) => NewsArticle(
                    title: article['headline'] ?? 'No title',
                    description: article['summary'] ?? 'No description',
                    url: article['url'] ?? '',
                    imageUrl: article['image'] ?? '',
                    source: article['source'] ?? 'Unknown',
                    publishedAt: DateTime.fromMillisecondsSinceEpoch(
                        (article['datetime'] ?? 0) * 1000),
                  ))
              .toList();
        } else {
          _logger.warning('Failed to search news: ${response.statusCode}');
          throw Exception('Failed to search news: ${response.statusCode}');
        }
      } catch (e) {
        _logger.severe('Error searching news: $e');
        return _searchMockNews(query);
      }
    } else {
      return _searchMockNews(query);
    }
  }

  Future<List<NewsArticle>> getStockNews(String symbol) async {
    try {
      final response = await http.get(
        Uri.parse('${Env.finnhubBaseUrl}/company-news'
            '?symbol=$symbol'
            '&from=${_getDateString(days: 7)}'
            '&to=${_getDateString()}'
            '&token=${Env.finnhubApiKey}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> newsData = json.decode(response.body);
        return newsData
            .take(10)
            .map((item) => NewsArticle(
                  title: item['headline'] ?? '',
                  description: item['summary'] ?? '',
                  url: item['url'] ?? '',
                  imageUrl: item['image'] ?? _getPlaceholderImage(symbol),
                  source: item['source'] ?? 'Market News',
                  publishedAt: DateTime.fromMillisecondsSinceEpoch(
                      (item['datetime'] as int) * 1000),
                ))
            .toList();
      }
    } catch (e) {
      _logger.warning('Error fetching stock news: $e');
    }
    return _getFallbackStockNews(symbol);
  }

  Future<List<NewsArticle>> getMarketNews() async {
    if (_shouldRefreshCache(_lastMarketNewsFetch)) {
      try {
        // First try NewsAPI for business news
        if (Env.newsApiKey.isNotEmpty) {
          final response = await http.get(
            Uri.parse(
                '${Env.newsApiBaseUrl}/top-headlines?category=business&language=en&apiKey=${Env.newsApiKey}'),
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final List<dynamic> articles = data['articles'] ?? [];

            if (articles.isNotEmpty) {
              _marketNewsCache.clear();
              _marketNewsCache.addAll(
                articles.take(20).map((item) => NewsArticle(
                      title: item['title'] ?? '',
                      description: item['description'] ?? '',
                      url: item['url'] ?? '',
                      imageUrl: _validateImageUrl(item['urlToImage']),
                      source: (item['source'] != null)
                          ? item['source']['name'] ?? ''
                          : '',
                      publishedAt:
                          DateTime.tryParse(item['publishedAt'] ?? '') ??
                              DateTime.now(),
                    )),
              );
              _lastMarketNewsFetch = DateTime.now();
              return _marketNewsCache;
            }
          }
        }

        // Then try Finnhub if NewsAPI fails
        if (Env.finnhubApiKey.isNotEmpty) {
          final response = await http.get(
            Uri.parse(
                '${Env.finnhubBaseUrl}/news?category=business&token=${Env.finnhubApiKey}'),
          );

          if (response.statusCode == 200) {
            final List<dynamic> newsData = json.decode(response.body);
            _marketNewsCache.clear();
            _marketNewsCache.addAll(
              newsData.take(20).map((item) => NewsArticle(
                    title: item['headline'] ?? '',
                    description: item['summary'] ?? '',
                    url: item['url'] ?? '',
                    imageUrl: _validateImageUrl(item['image']),
                    source: item['source'] ?? 'Market News',
                    publishedAt: DateTime.fromMillisecondsSinceEpoch(
                        (item['datetime'] as int) * 1000),
                  )),
            );
            _lastMarketNewsFetch = DateTime.now();
            return _marketNewsCache;
          }
        }
      } catch (e) {
        _logger.warning('Error fetching market news: $e');
        // Fall through to return existing cache or mock data
      }

      // If cache is empty after all API attempts failed, use mock data
      if (_marketNewsCache.isEmpty) {
        final mockNews = await _getMockNewsArticlesByCategory('business');
        _marketNewsCache.addAll(mockNews);
        _lastMarketNewsFetch = DateTime.now();
      }
    }
    return _marketNewsCache;
  }

  Future<List<NewsArticle>> getGeneralNews() async {
    if (_shouldRefreshCache(_lastGeneralNewsFetch)) {
      try {
        final response = await http.get(
          Uri.parse('${Env.alphaVantageBaseUrl}'
              '?function=NEWS_SENTIMENT'
              '&apikey=${Env.alphaVantageApiKey}'
              '&topics=financial_markets,economy'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> feed = data['feed'] ?? [];
          _generalNewsCache.clear();
          _generalNewsCache.addAll(
            feed.take(20).map((item) => NewsArticle(
                  title: item['title'] ?? '',
                  description: item['summary'] ?? '',
                  url: item['url'] ?? '',
                  imageUrl:
                      item['banner_image'] ?? _getPlaceholderImage('NEWS'),
                  source: item['source'] ?? 'Financial News',
                  publishedAt: DateTime.parse(item['time_published'] ??
                      DateTime.now().toIso8601String()),
                )),
          );
          _lastGeneralNewsFetch = DateTime.now();
        }
      } catch (e) {
        _logger.warning('Error fetching general news: $e');
      }
    }
    return _generalNewsCache;
  }

  String _getDateString({int days = 0}) {
    final date = DateTime.now().subtract(Duration(days: days));
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  bool _shouldRefreshCache(DateTime? lastFetch) {
    return lastFetch == null ||
        DateTime.now().difference(lastFetch) > _cacheExpirationDuration;
  }

  String _getPlaceholderImage(String identifier) {
    final random = DateTime.now().millisecondsSinceEpoch % 1000;
    return 'https://picsum.photos/seed/$identifier$random/800/400';
  }

  String _validateImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return 'https://picsum.photos/800/400?random=${DateTime.now().millisecondsSinceEpoch}';
    }
    return url;
  }

  List<NewsArticle> _getFallbackStockNews(String symbol) {
    return [
      NewsArticle(
        title: '$symbol Stock Analysis: Market Performance Review',
        description: 'A comprehensive analysis of $symbol\'s recent market '
            'performance and future outlook.',
        url: '',
        imageUrl: _getPlaceholderImage('${symbol}1'),
        source: 'Market Analysis',
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      NewsArticle(
        title: '$symbol Announces Quarterly Results',
        description: 'Latest quarterly results and financial performance '
            'highlights for $symbol.',
        url: '',
        imageUrl: _getPlaceholderImage('${symbol}2'),
        source: 'Financial Reports',
        publishedAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
    ];
  }

  Future<List<NewsArticle>> _getMockNewsArticles() async {
    final mockNewsService = MockNewsService();
    return mockNewsService.fetchAndCacheNews();
  }

  Future<List<NewsArticle>> _getMockNewsArticlesByCategory(
      String category) async {
    final mockNewsService = MockNewsService();
    return mockNewsService.getNewsByCategory(category);
  }

  Future<List<NewsArticle>> _searchMockNews(String query) async {
    final mockNewsService = MockNewsService();
    return mockNewsService.searchNews(query);
  }
}
