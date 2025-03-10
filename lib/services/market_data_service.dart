import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import '../models/asset.dart';
import '../config/env.dart';

class MarketDataService {
  final _logger = Logger('MarketDataService');

  // Free API endpoints for stock data now use constants from env.dart
  static const String _finnhubBaseUrl = Env.finnhubBaseUrl;
  static const String _alphaVantageBaseUrl = Env.alphaVantageBaseUrl;

  // API keys from environment configuration
  final String _finnhubApiKey;
  final String _alphaVantageApiKey;

  // List of international stocks to track - Enhanced with more variety
  static const List<String> _internationalSymbols = [
    'AAPL', // Apple
    'MSFT', // Microsoft
    'GOOGL', // Alphabet/Google
    'AMZN', // Amazon
    'META', // Meta/Facebook
    'TSLA', // Tesla
    'NVDA', // NVIDIA
    'JPM', // JPMorgan Chase
    'V', // Visa
    'JNJ', // Johnson & Johnson
    'BABA', // Alibaba Group
    'TSM', // Taiwan Semiconductor
    'WMT', // Walmart
    'KO', // Coca-Cola
    'DIS', // Disney
  ];

  // Constructor with API key handling
  MarketDataService()
      : _finnhubApiKey = Env.finnhubApiKey,
        _alphaVantageApiKey = Env.alphaVantageApiKey {
    _logger.info('MarketDataService initialized');
    _validateApiKeys();
  }

  // Validate API keys are available and not empty
  void _validateApiKeys() {
    if (_finnhubApiKey.isEmpty || _finnhubApiKey == 'YOUR_API_KEY_HERE') {
      _logger.warning('Finnhub API key is not configured properly');
    }

    if (_alphaVantageApiKey.isEmpty ||
        _alphaVantageApiKey == 'YOUR_API_KEY_HERE') {
      _logger.warning('Alpha Vantage API key is not configured properly');
    }
  }

  // Fetch real-time stock data for international markets
  Future<List<Asset>> fetchInternationalStocks() async {
    _logger.info('Fetching international stock data');
    List<Asset> assets = [];

    try {
      // Try Alpha Vantage first as it has better CORS support
      for (final symbol in _internationalSymbols) {
        try {
          final asset = await _fetchStockFromAlphaVantage(symbol);
          if (asset != null) {
            assets.add(asset);
          }
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          _logger.warning(
              'Error fetching data for $symbol from Alpha Vantage: $e');

          // Fallback to Finnhub if Alpha Vantage fails
          try {
            final finnhubAsset = await _fetchStockFromFinnhub(symbol);
            if (finnhubAsset != null) {
              assets.add(finnhubAsset);
            }
          } catch (finnhubError) {
            _logger.warning(
                'Error fetching data for $symbol from Finnhub: $finnhubError');
          }
        }
      }

      _logger.info('Fetched ${assets.length} international stocks');
    } catch (e) {
      _logger.severe('Error fetching international stocks: $e');
    }

    // If we couldn't get any real data, use fallback data
    if (assets.isEmpty) {
      assets = _generateFallbackStockData();
      _logger.info('Using fallback stock data since API requests failed');
    }

    return assets;
  }

  // Fallback method to generate mock data when API fails
  List<Asset> _generateFallbackStockData() {
    return _internationalSymbols.map((symbol) {
      final basePrice = _getBasePrice(symbol);
      final change = (basePrice * (_getRandomValue() * 0.1)).round() / 100;
      final price = basePrice + change;

      return Asset(
        name: _getCompanyName(symbol),
        symbol: symbol,
        sector: _getSector(symbol),
        ownership: 'Public',
        price: price,
        change: change,
        changePercent: (change / basePrice) * 100,
        volume: _getBaseVolume(symbol) * (0.8 + _getRandomValue() * 0.4),
        marketCap: price * _getBaseShares(symbol),
        lastUpdated: DateTime.now(),
        dayHigh: price * (1 + _getRandomValue() * 0.03),
        dayLow: price * (1 - _getRandomValue() * 0.03),
        openPrice: basePrice,
        lotSize: 1,
        tickSize: 0.01,
      );
    }).toList();
  }

  double _getRandomValue() {
    return (DateTime.now().millisecondsSinceEpoch % 100) / 100;
  }

  double _getBasePrice(String symbol) {
    switch (symbol) {
      case 'AAPL':
        return 175.0;
      case 'MSFT':
        return 350.0;
      case 'GOOGL':
        return 130.0;
      case 'AMZN':
        return 140.0;
      case 'META':
        return 300.0;
      case 'TSLA':
        return 220.0;
      case 'NVDA':
        return 450.0;
      case 'JPM':
        return 145.0;
      case 'V':
        return 250.0;
      case 'JNJ':
        return 155.0;
      case 'BABA':
        return 85.0;
      case 'TSM':
        return 130.0;
      case 'WMT':
        return 60.0;
      case 'KO':
        return 60.0;
      case 'DIS':
        return 90.0;
      default:
        return 100.0;
    }
  }

  double _getBaseVolume(String symbol) {
    switch (symbol) {
      case 'AAPL':
        return 55000000;
      case 'MSFT':
        return 25000000;
      case 'GOOGL':
        return 20000000;
      case 'AMZN':
        return 30000000;
      case 'META':
        return 22000000;
      case 'TSLA':
        return 100000000;
      case 'NVDA':
        return 40000000;
      default:
        return 10000000 + (_getRandomValue() * 10000000);
    }
  }

  double _getBaseShares(String symbol) {
    switch (symbol) {
      case 'AAPL':
        return 16000000000;
      case 'MSFT':
        return 7500000000;
      case 'GOOGL':
        return 13000000000;
      case 'AMZN':
        return 10000000000;
      case 'META':
        return 2500000000;
      case 'TSLA':
        return 3200000000;
      default:
        return 1000000000 + (_getRandomValue() * 5000000000);
    }
  }

  String _getSector(String symbol) {
    switch (symbol) {
      case 'AAPL':
      case 'MSFT':
      case 'GOOGL':
      case 'META':
      case 'NVDA':
      case 'TSM':
        return 'Technology';
      case 'AMZN':
      case 'WMT':
        return 'Retail';
      case 'TSLA':
        return 'Automotive';
      case 'JPM':
      case 'V':
        return 'Financial';
      case 'JNJ':
        return 'Healthcare';
      case 'BABA':
        return 'E-commerce';
      case 'KO':
        return 'Consumer Goods';
      case 'DIS':
        return 'Entertainment';
      default:
        return 'International';
    }
  }

  // Fetch stock data from Alpha Vantage API
  Future<Asset?> _fetchStockFromAlphaVantage(String symbol) async {
    // Skip API call if key is not configured
    if (_alphaVantageApiKey.isEmpty ||
        _alphaVantageApiKey == 'YOUR_API_KEY_HERE') {
      _logger
          .warning('Alpha Vantage API key not configured, skipping API call');
      return null;
    }

    final url =
        '$_alphaVantageBaseUrl?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$_alphaVantageApiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey('Global Quote') &&
            data['Global Quote'] != null &&
            data['Global Quote'].isNotEmpty) {
          final quote = data['Global Quote'];

          final price = double.parse(quote['05. price']);
          final openPrice = double.parse(quote['02. open']);
          final highPrice = double.parse(quote['03. high']);
          final lowPrice = double.parse(quote['04. low']);
          final changePercent =
              double.parse(quote['10. change percent'].replaceAll('%', ''));
          final change = double.parse(quote['09. change']);
          final volume = double.parse(quote['06. volume']);

          return Asset(
            name: _getCompanyName(symbol),
            symbol: symbol,
            sector: _getSector(symbol),
            ownership: 'Public',
            price: price,
            change: change,
            changePercent: changePercent,
            volume: volume,
            marketCap: price * _getBaseShares(symbol), // Estimated market cap
            lastUpdated: DateTime.now(),
            dayHigh: highPrice,
            dayLow: lowPrice,
            openPrice: openPrice,
            lotSize: 1,
            tickSize: 0.01,
          );
        } else {
          _logger.warning(
              'Unexpected data format from Alpha Vantage for $symbol: $data');
        }
      } else {
        _logger.warning(
            'Failed to fetch data for $symbol: HTTP ${response.statusCode}');
      }
    } catch (e) {
      _logger.warning('Error fetching Alpha Vantage data for $symbol: $e');
    }

    // Return null if we couldn't fetch valid data
    return null;
  }

  Future<Asset?> _fetchStockFromFinnhub(String symbol) async {
    if (_finnhubApiKey.isEmpty || _finnhubApiKey == 'YOUR_API_KEY_HERE') {
      return null;
    }

    try {
      final quoteUrl =
          '$_finnhubBaseUrl/quote?symbol=$symbol&token=$_finnhubApiKey';
      final profileUrl =
          '$_finnhubBaseUrl/stock/profile2?symbol=$symbol&token=$_finnhubApiKey';

      final headers = {
        'Access-Control-Allow-Origin': '*',
        'Accept': 'application/json',
      };

      final responses = await Future.wait([
        http.get(Uri.parse(quoteUrl), headers: headers),
        http.get(Uri.parse(profileUrl), headers: headers),
      ]);

      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        final quoteData = json.decode(responses[0].body);
        final profileData = json.decode(responses[1].body);

        return Asset(
          symbol: symbol,
          name: profileData['name'] ?? _getCompanyName(symbol),
          price: (quoteData['c'] as num).toDouble(),
          change: (quoteData['d'] as num).toDouble(),
          changePercent: (quoteData['dp'] as num).toDouble(),
          volume: (quoteData['v'] as num).toDouble(),
          sector: profileData['finnhubIndustry'] ?? _getSector(symbol),
          ownership: 'Public',
          marketCap: profileData['marketCapitalization'] != null
              ? (profileData['marketCapitalization'] as num).toDouble() *
                  1000000
              : 0.0,
          lastUpdated: DateTime.now(),
          dayHigh: (quoteData['h'] as num).toDouble(),
          dayLow: (quoteData['l'] as num).toDouble(),
          openPrice: (quoteData['o'] as num).toDouble(),
          lotSize: 1,
          tickSize: 0.01,
        );
      }
    } catch (e) {
      _logger.warning('Error in _fetchStockFromFinnhub for $symbol: $e');
    }
    return null;
  }

  // Helper method to get company names
  String _getCompanyName(String symbol) {
    switch (symbol) {
      case 'AAPL':
        return 'Apple Inc.';
      case 'MSFT':
        return 'Microsoft Corporation';
      case 'GOOGL':
        return 'Alphabet Inc.';
      case 'AMZN':
        return 'Amazon.com Inc.';
      case 'META':
        return 'Meta Platforms Inc.';
      case 'TSLA':
        return 'Tesla Inc.';
      case 'NVDA':
        return 'NVIDIA Corporation';
      case 'JPM':
        return 'JPMorgan Chase & Co.';
      case 'V':
        return 'Visa Inc.';
      case 'JNJ':
        return 'Johnson & Johnson';
      case 'BABA':
        return 'Alibaba Group Holding Ltd.';
      case 'TSM':
        return 'Taiwan Semiconductor Manufacturing Co.';
      case 'WMT':
        return 'Walmart Inc.';
      case 'KO':
        return 'Coca-Cola Company';
      case 'DIS':
        return 'Walt Disney Company';
      default:
        return symbol;
    }
  }

  // Get stock details including company profile, financials, etc.
  Future<Map<String, dynamic>> getStockDetails(String symbol) async {
    _logger.info('Fetching detailed data for $symbol');
    Map<String, dynamic> details = {};

    if (_finnhubApiKey.isEmpty || _finnhubApiKey == 'YOUR_API_KEY_HERE') {
      _logger
          .warning('Finnhub API key not configured, returning empty details');
      return details;
    }

    try {
      // Company profile from Finnhub
      final profileUrl =
          '$_finnhubBaseUrl/stock/profile2?symbol=$symbol&token=$_finnhubApiKey';
      final profileResponse = await http.get(Uri.parse(profileUrl));

      if (profileResponse.statusCode == 200) {
        final profileData = json.decode(profileResponse.body);
        details['profile'] = profileData;
      } else {
        _logger.warning(
            'Failed to fetch profile for $symbol: HTTP ${profileResponse.statusCode}');
      }

      // Basic financials from Finnhub
      final financialsUrl =
          '$_finnhubBaseUrl/stock/metric?symbol=$symbol&metric=all&token=$_finnhubApiKey';
      final financialsResponse = await http.get(Uri.parse(financialsUrl));

      if (financialsResponse.statusCode == 200) {
        final financialsData = json.decode(financialsResponse.body);
        details['financials'] = financialsData;
      } else {
        _logger.warning(
            'Failed to fetch financials for $symbol: HTTP ${financialsResponse.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error fetching stock details for $symbol: $e');
    }

    return details;
  }

  // Get historical price data for charts
  Future<List<Map<String, dynamic>>> getHistoricalData(
      String symbol, String resolution, int from, int to) async {
    _logger.info('Fetching historical data for $symbol');
    List<Map<String, dynamic>> candles = [];

    if (_finnhubApiKey.isEmpty || _finnhubApiKey == 'YOUR_API_KEY_HERE') {
      _logger.warning(
          'Finnhub API key not configured, returning empty historical data');
      return candles;
    }

    try {
      // Candle data from Finnhub
      final url =
          '$_finnhubBaseUrl/stock/candle?symbol=$symbol&resolution=$resolution&from=$from&to=$to&token=$_finnhubApiKey';

      final headers = {
        'Access-Control-Allow-Origin': '*',
        'Accept': 'application/json',
      };

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['s'] == 'ok') {
          final timestamps = List<int>.from(data['t']);
          final opens =
              List<double>.from(data['o'].map((e) => (e as num).toDouble()));
          final highs =
              List<double>.from(data['h'].map((e) => (e as num).toDouble()));
          final lows =
              List<double>.from(data['l'].map((e) => (e as num).toDouble()));
          final closes =
              List<double>.from(data['c'].map((e) => (e as num).toDouble()));
          final volumes =
              List<double>.from(data['v'].map((e) => (e as num).toDouble()));

          for (int i = 0; i < timestamps.length; i++) {
            candles.add({
              'timestamp': timestamps[i],
              'open': opens[i],
              'high': highs[i],
              'low': lows[i],
              'close': closes[i],
              'volume': volumes[i],
            });
          }
        } else {
          _logger.warning('Error in response from Finnhub: ${data['s']}');
        }
      } else {
        _logger.warning(
            'Failed to fetch historical data for $symbol: HTTP ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error fetching historical data for $symbol: $e');
    }

    return candles;
  }
}
