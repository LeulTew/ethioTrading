import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import '../models/asset.dart';
import '../config/env.dart';

class ApiService {
  final Logger _logger = Logger('ApiService');

  // Use API keys from environment file
  final String _alphaVantageApiKey = Env.alphaVantageApiKey;
  final String _finnhubApiKey = Env.finnhubApiKey;

  // Base URLs
  static const String _alphaVantageBaseUrl =
      'https://www.alphavantage.co/query';
  static const String _finnhubBaseUrl = 'https://finnhub.io/api/v1';

  // Fetch international market data using real APIs
  Future<List<Asset>> fetchInternationalMarketData() async {
    List<Asset> assets = [];

    try {
      // First try Alpha Vantage for top gainers/losers
      final alphaVantageAssets = await _fetchFromAlphaVantage();
      if (alphaVantageAssets.isNotEmpty) {
        assets.addAll(alphaVantageAssets);
      }

      // If we didn't get enough data, supplement with Finnhub data for major stocks
      if (assets.length < 5) {
        final majorSymbols = [
          'AAPL',
          'MSFT',
          'GOOGL',
          'AMZN',
          'TSLA',
          'META',
          'NFLX',
          'JPM'
        ];
        for (final symbol in majorSymbols) {
          try {
            final asset = await _fetchFromFinnhub(symbol);
            if (asset != null) {
              assets.add(asset);
            }
          } catch (e) {
            _logger.warning('Error fetching $symbol from Finnhub: $e');
          }
        }
      }
    } catch (e) {
      _logger.severe('Error fetching international market data: $e');
    }

    // If we still don't have data, use fallback data as a last resort
    if (assets.isEmpty) {
      _logger.warning('Using fallback international market data');
      return _getFallbackInternationalData();
    }

    return assets;
  }

  // Fetch data from Alpha Vantage
  Future<List<Asset>> _fetchFromAlphaVantage() async {
    try {
      final response = await http.get(Uri.parse(
          '$_alphaVantageBaseUrl?function=TOP_GAINERS_LOSERS&apikey=$_alphaVantageApiKey'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Combine gainers and losers
        final List<dynamic> gainers = data['top_gainers'] ?? [];
        final List<dynamic> losers = data['top_losers'] ?? [];
        final List<dynamic> combined = [...gainers, ...losers];

        // Convert to Asset objects
        return combined.map((item) {
          final price =
              double.tryParse(item['price'].toString().replaceAll('\$', '')) ??
                  0.0;
          final change = double.tryParse(
                  item['change_amount'].toString().replaceAll('\$', '')) ??
              0.0;
          final changePercent = double.tryParse(
                  item['change_percentage'].toString().replaceAll('%', '')) ??
              0.0;
          final volume =
              double.tryParse(item['volume'].toString().replaceAll(',', '')) ??
                  0.0;

          return Asset(
            symbol: item['ticker'] ?? '',
            name: item['ticker'] ?? '', // API doesn't provide full name
            price: price,
            change: change,
            changePercent: changePercent,
            volume: volume,
            marketCap: price * volume, // Approximate market cap
            sector: 'International',
            ownership: 'Public', // Default ownership for international stocks
          );
        }).toList();
      }
    } catch (e) {
      _logger.warning('Error fetching from Alpha Vantage: $e');
    }

    return [];
  }

  // Fetch individual stock data from Finnhub
  Future<Asset?> _fetchFromFinnhub(String symbol) async {
    try {
      // Get quote data
      final quoteResponse = await http.get(Uri.parse(
          '$_finnhubBaseUrl/quote?symbol=$symbol&token=$_finnhubApiKey'));

      // Get company profile for additional data
      final profileResponse = await http.get(Uri.parse(
          '$_finnhubBaseUrl/stock/profile2?symbol=$symbol&token=$_finnhubApiKey'));

      if (quoteResponse.statusCode == 200 &&
          profileResponse.statusCode == 200) {
        final quoteData = json.decode(quoteResponse.body);
        final profileData = json.decode(profileResponse.body);

        final currentPrice = quoteData['c'] ?? 0.0;
        final previousClose = quoteData['pc'] ?? 0.0;
        final change = currentPrice - previousClose;
        final changePercent =
            previousClose > 0 ? (change / previousClose) * 100 : 0.0;

        return Asset(
          symbol: symbol,
          name: profileData['name'] ?? symbol,
          price: currentPrice.toDouble(),
          change: change.toDouble(),
          changePercent: changePercent.toDouble(),
          volume: (quoteData['v'] ?? 0).toDouble(),
          marketCap: (profileData['marketCapitalization'] ?? 0).toDouble() *
              1000000, // Convert from millions
          sector: 'International',
          ownership: profileData['exchange'] ?? 'Public',
        );
      }
    } catch (e) {
      _logger.warning('Error fetching $symbol from Finnhub: $e');
    }

    return null;
  }

  // Fetch news data
  Future<List<Map<String, dynamic>>> fetchNews(
      {String category = 'business'}) async {
    try {
      // For Ethiopian news, we'll use mock data since there's no free API specifically for Ethiopian financial news
      if (category.toLowerCase() == 'ethiopian') {
        return _getFallbackNewsData('ethiopian');
      }

      // For international news, try to get real data
      final response = await http.get(Uri.parse(
          'https://finnhub.io/api/v1/news?category=general&token=$_finnhubApiKey'));

      if (response.statusCode == 200) {
        final List<dynamic> articles = json.decode(response.body);

        if (articles.isNotEmpty) {
          return articles
              .take(10)
              .map((article) => {
                    'title': article['headline'] ?? '',
                    'description': article['summary'] ?? '',
                    'url': article['url'] ?? '',
                    'urlToImage': article['image'] ?? '',
                    'publishedAt': article['datetime'] != null
                        ? DateTime.fromMillisecondsSinceEpoch(
                                article['datetime'] * 1000)
                            .toIso8601String()
                        : DateTime.now().toIso8601String(),
                    'source': article['source'] ?? '',
                  })
              .toList()
              .cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      _logger.warning('Error fetching news: $e');
    }

    // Return fallback news data
    return _getFallbackNewsData(category);
  }

  // Fallback international market data - only used if all APIs fail
  List<Asset> _getFallbackInternationalData() {
    return [
      Asset(
        symbol: 'AAPL',
        name: 'Apple Inc.',
        price: 175.50,
        change: 2.75,
        changePercent: 1.59,
        volume: 65000000,
        marketCap: 2850000000000,
        sector: 'International',
        ownership: 'Public',
      ),
      Asset(
        symbol: 'MSFT',
        name: 'Microsoft Corporation',
        price: 325.25,
        change: 5.50,
        changePercent: 1.72,
        volume: 28000000,
        marketCap: 2420000000000,
        sector: 'International',
        ownership: 'Public',
      ),
      Asset(
        symbol: 'GOOGL',
        name: 'Alphabet Inc.',
        price: 135.75,
        change: -1.25,
        changePercent: -0.91,
        volume: 18500000,
        marketCap: 1750000000000,
        sector: 'International',
        ownership: 'Public',
      ),
      Asset(
        symbol: 'AMZN',
        name: 'Amazon.com Inc.',
        price: 145.25,
        change: 3.25,
        changePercent: 2.29,
        volume: 32000000,
        marketCap: 1500000000000,
        sector: 'International',
        ownership: 'Public',
      ),
      Asset(
        symbol: 'TSLA',
        name: 'Tesla, Inc.',
        price: 225.50,
        change: -8.75,
        changePercent: -3.74,
        volume: 125000000,
        marketCap: 715000000000,
        sector: 'International',
        ownership: 'Public',
      ),
      Asset(
        symbol: 'META',
        name: 'Meta Platforms, Inc.',
        price: 315.25,
        change: 7.50,
        changePercent: 2.44,
        volume: 22000000,
        marketCap: 810000000000,
        sector: 'International',
        ownership: 'Public',
      ),
      Asset(
        symbol: 'NFLX',
        name: 'Netflix, Inc.',
        price: 425.75,
        change: 12.25,
        changePercent: 2.96,
        volume: 8500000,
        marketCap: 188000000000,
        sector: 'International',
        ownership: 'Public',
      ),
      Asset(
        symbol: 'JPM',
        name: 'JPMorgan Chase & Co.',
        price: 145.50,
        change: -2.25,
        changePercent: -1.52,
        volume: 12000000,
        marketCap: 425000000000,
        sector: 'International',
        ownership: 'Public',
      ),
    ];
  }

  // Fallback news data
  List<Map<String, dynamic>> _getFallbackNewsData(String category) {
    if (category.toLowerCase() == 'ethiopian') {
      return [
        {
          'title': 'Ethiopian Stock Exchange Set to Launch Next Year',
          'description':
              'The Ethiopian government has announced plans to launch the country\'s first stock exchange by the end of next year, marking a significant milestone in the nation\'s economic reform agenda.',
          'url': 'https://example.com/ethiopian-stock-exchange',
          'urlToImage':
              null, // Use null to show a placeholder instead of a broken image
          'publishedAt': '2023-05-15T09:30:00Z',
          'source': 'Ethiopian Financial Times',
        },
        {
          'title': 'Commercial Bank of Ethiopia Reports Record Profits',
          'description':
              'The Commercial Bank of Ethiopia (CBE) has reported record annual profits, highlighting the growing strength of the country\'s banking sector despite regional challenges.',
          'url': 'https://example.com/cbe-profits',
          'urlToImage':
              null, // Use null to show a placeholder instead of a broken image
          'publishedAt': '2023-05-10T14:15:00Z',
          'source': 'Addis Business',
        },
        {
          'title':
              'Ethiopian Airlines Expands Fleet with New Aircraft Purchase',
          'description':
              'Ethiopian Airlines, Africa\'s largest airline, has announced the purchase of 10 new aircraft, expanding its fleet to meet growing demand for air travel across the continent.',
          'url': 'https://example.com/ethiopian-airlines-expansion',
          'urlToImage':
              null, // Use null to show a placeholder instead of a broken image
          'publishedAt': '2023-05-08T11:45:00Z',
          'source': 'African Aviation News',
        },
        {
          'title': 'Ethiopia\'s Inflation Rate Drops to Single Digits',
          'description':
              'For the first time in three years, Ethiopia\'s inflation rate has dropped to single digits, signaling potential economic stabilization amid ongoing reforms.',
          'url': 'https://example.com/ethiopia-inflation',
          'urlToImage':
              null, // Use null to show a placeholder instead of a broken image
          'publishedAt': '2023-05-05T08:20:00Z',
          'source': 'East African Economic Review',
        },
        {
          'title': 'Foreign Investment in Ethiopia Reaches Five-Year High',
          'description':
              'Foreign direct investment in Ethiopia has reached a five-year high, with significant inflows in manufacturing, agriculture, and energy sectors.',
          'url': 'https://example.com/ethiopia-investment',
          'urlToImage':
              null, // Use null to show a placeholder instead of a broken image
          'publishedAt': '2023-05-03T16:10:00Z',
          'source': 'Global Investment Monitor',
        },
      ];
    } else {
      return [
        {
          'title': 'Global Markets Rally as Inflation Concerns Ease',
          'description':
              'Stock markets around the world rallied today as new data suggested inflation pressures might be easing, potentially allowing central banks to slow their rate hiking cycles.',
          'url': 'https://example.com/global-markets-rally',
          'urlToImage':
              null, // Use null to show a placeholder instead of a broken image
          'publishedAt': '2023-05-15T16:30:00Z',
          'source': 'Financial Times',
        },
        {
          'title': 'Tech Stocks Lead Market Gains Amid AI Optimism',
          'description':
              'Technology stocks led market gains today as investors remain optimistic about the potential of artificial intelligence to drive future growth and innovation.',
          'url': 'https://example.com/tech-stocks-ai',
          'urlToImage':
              null, // Use null to show a placeholder instead of a broken image
          'publishedAt': '2023-05-14T14:45:00Z',
          'source': 'Wall Street Journal',
        },
        {
          'title': 'Oil Prices Fall on Demand Concerns',
          'description':
              'Oil prices fell today as concerns about global demand outweighed production cuts announced by major oil-producing countries.',
          'url': 'https://example.com/oil-prices-fall',
          'urlToImage':
              null, // Use null to show a placeholder instead of a broken image
          'publishedAt': '2023-05-13T10:15:00Z',
          'source': 'Reuters',
        },
        {
          'title': 'Federal Reserve Signals Pause in Rate Hikes',
          'description':
              'The Federal Reserve has signaled a potential pause in its interest rate hiking cycle, citing progress in the fight against inflation and concerns about economic growth.',
          'url': 'https://example.com/fed-rate-pause',
          'urlToImage':
              null, // Use null to show a placeholder instead of a broken image
          'publishedAt': '2023-05-12T18:20:00Z',
          'source': 'Bloomberg',
        },
        {
          'title': 'European Markets Close Higher on Strong Earnings',
          'description':
              'European stock markets closed higher today, boosted by strong corporate earnings reports and positive economic data from the region.',
          'url': 'https://example.com/european-markets',
          'urlToImage':
              null, // Use null to show a placeholder instead of a broken image
          'publishedAt': '2023-05-11T17:05:00Z',
          'source': 'CNBC Europe',
        },
      ];
    }
  }
}
