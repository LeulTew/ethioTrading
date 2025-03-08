import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import '../models/asset.dart';
import '../config/env.dart';

class MarketDataService {
  final _logger = Logger('MarketDataService');

  // Free API endpoints for stock data
  static const String _finnhubBaseUrl = 'https://finnhub.io/api/v1';
  static const String _alphaVantageBaseUrl =
      'https://www.alphavantage.co/query';

  // API keys from environment configuration
  final String _finnhubApiKey = Env.finnhubApiKey;
  final String _alphaVantageApiKey = Env.alphaVantageApiKey;

  // List of international stocks to track
  static const List<String> _internationalSymbols = [
    'AAPL',
    'MSFT',
    'GOOGL',
    'AMZN',
    'META',
    'TSLA',
    'NVDA',
    'JPM',
    'V',
    'JNJ'
  ];

  MarketDataService() {
    _logger.info('MarketDataService initialized');
  }

  // Fetch real-time stock data for international markets
  Future<List<Asset>> fetchInternationalStocks() async {
    _logger.info('Fetching international stock data');
    List<Asset> assets = [];

    try {
      // Use Alpha Vantage for batch stock quotes (free tier allows limited requests)
      for (final symbol in _internationalSymbols) {
        try {
          final asset = await _fetchStockFromAlphaVantage(symbol);
          if (asset != null) {
            assets.add(asset);
          }
          // Add delay to respect API rate limits
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          _logger.warning('Error fetching data for $symbol: $e');
        }
      }
    } catch (e) {
      _logger.severe('Error fetching international stocks: $e');
    }

    return assets;
  }

  // Fetch stock data from Alpha Vantage API
  Future<Asset?> _fetchStockFromAlphaVantage(String symbol) async {
    final url =
        '$_alphaVantageBaseUrl?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$_alphaVantageApiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey('Global Quote') &&
            data['Global Quote'].isNotEmpty) {
          final quote = data['Global Quote'];

          final price = double.parse(quote['05. price']);
          final openPrice = double.parse(quote['02. open']);
          final highPrice = double.parse(quote['03. high']);
          final lowPrice = double.parse(quote['04. low']);
          final changePercent =
              double.parse(quote['10. change percent'].replaceAll('%', ''));

          return Asset(
            name: _getCompanyName(symbol),
            symbol: symbol,
            sector: 'International',
            ownership: 'Public',
            price: price,
            change: changePercent,
            changePercent: changePercent,
            volume: double.parse(quote['06. volume']),
            marketCap: 0.0, // Not provided in this API
            lastUpdated: DateTime.now(),
            dayHigh: highPrice,
            dayLow: lowPrice,
            openPrice: openPrice,
          );
        }
      }
    } catch (e) {
      _logger.warning('Error fetching Alpha Vantage data for $symbol: $e');
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
      default:
        return symbol;
    }
  }

  // Get stock details including company profile, financials, etc.
  Future<Map<String, dynamic>> getStockDetails(String symbol) async {
    _logger.info('Fetching detailed data for $symbol');
    Map<String, dynamic> details = {};

    try {
      // Company profile from Finnhub
      final profileUrl =
          '$_finnhubBaseUrl/stock/profile2?symbol=$symbol&token=$_finnhubApiKey';
      final profileResponse = await http.get(Uri.parse(profileUrl));

      if (profileResponse.statusCode == 200) {
        final profileData = json.decode(profileResponse.body);
        details['profile'] = profileData;
      }

      // Basic financials from Finnhub
      final financialsUrl =
          '$_finnhubBaseUrl/stock/metric?symbol=$symbol&metric=all&token=$_finnhubApiKey';
      final financialsResponse = await http.get(Uri.parse(financialsUrl));

      if (financialsResponse.statusCode == 200) {
        final financialsData = json.decode(financialsResponse.body);
        details['financials'] = financialsData;
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

    try {
      // Candle data from Finnhub
      final url =
          '$_finnhubBaseUrl/stock/candle?symbol=$symbol&resolution=$resolution&from=$from&to=$to&token=$_finnhubApiKey';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['s'] == 'ok') {
          final timestamps = List<int>.from(data['t']);
          final opens = List<double>.from(data['o']);
          final highs = List<double>.from(data['h']);
          final lows = List<double>.from(data['l']);
          final closes = List<double>.from(data['c']);
          final volumes = List<double>.from(data['v']);

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
        }
      }
    } catch (e) {
      _logger.severe('Error fetching historical data for $symbol: $e');
    }

    return candles;
  }
}
