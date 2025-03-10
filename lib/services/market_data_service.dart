import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import '../models/asset.dart';
import '../config/env.dart';
import '../data/ethio_data.dart' as ethio_data;

class MarketDataService {
  final _logger = Logger('MarketDataService');

  // Free API endpoints for stock data now use constants from env.dart
  static const String _finnhubBaseUrl = Env.finnhubBaseUrl;
  static const String _alphaVantageBaseUrl = Env.alphaVantageBaseUrl;

  // API keys from environment configuration
  final String _finnhubApiKey;
  final String _alphaVantageApiKey;

  // Constructor with API key handling
  MarketDataService()
      : _finnhubApiKey = Env.finnhubApiKey,
        _alphaVantageApiKey = Env.alphaVantageApiKey {
    _logger.info('MarketDataService initialized');
    _validateApiKeys();
  }

  // Validate API keys are available and not empty
  void _validateApiKeys() {
    if (_finnhubApiKey.isEmpty) {
      _logger.warning('Finnhub API key is not configured properly');
    }

    if (_alphaVantageApiKey.isEmpty) {
      _logger.warning('Alpha Vantage API key is not configured properly');
    }
  }

  // Fetch real-time stock data for international markets - API ONLY
  Future<List<Asset>> fetchInternationalStocks() async {
    _logger.info('Fetching international stock data');
    List<Asset> assets = [];

    try {
      // Fetch top symbols dynamically from Finnhub instead of using hardcoded list
      final symbols = await _getPopularStockSymbols();
      _logger.info('Fetched ${symbols.length} stock symbols to query');

      if (symbols.isEmpty) {
        _logger
            .warning('No symbols retrieved from API, cannot fetch stock data');
        return [];
      }

      // First try Alpha Vantage for each symbol
      for (final symbol in symbols) {
        try {
          _logger.info('Fetching data for $symbol from Alpha Vantage');
          final asset = await _fetchStockFromAlphaVantage(symbol);
          if (asset != null) {
            assets.add(asset);
            _logger.info('Successfully fetched data for $symbol');
          } else {
            // Try Finnhub as fallback for this symbol
            final finnhubAsset = await _fetchStockFromFinnhub(symbol);
            if (finnhubAsset != null) {
              assets.add(finnhubAsset);
              _logger
                  .info('Successfully fetched data for $symbol from Finnhub');
            }
          }
          await Future.delayed(
              const Duration(milliseconds: 500)); // Rate limiting
        } catch (e) {
          _logger.warning('Error fetching data for $symbol: $e');
        }
      }

      _logger.info('Fetched ${assets.length} international stocks');
      return assets;
    } catch (e) {
      _logger.severe('Error fetching international stocks: $e');
      return [];
    }
  }

  // Dynamically get popular stock symbols from Finnhub API
  Future<List<String>> _getPopularStockSymbols() async {
    try {
      // Use token in query parameter instead of header to avoid CORS issues
      final url =
          '$_finnhubBaseUrl/stock/symbol?exchange=US&token=$_finnhubApiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> symbolsData = json.decode(response.body);

        // Filter to get popular, high-volume stocks - take first 15
        final popularSymbols = symbolsData
            .where((symbol) =>
                symbol['type'] == 'Common Stock' && symbol['currency'] == 'USD')
            .take(15)
            .map((symbol) => symbol['symbol'] as String)
            .toList();

        _logger
            .info('Retrieved ${popularSymbols.length} popular stock symbols');
        return popularSymbols;
      } else {
        _logger.warning('Failed to get stock symbols: ${response.statusCode}');
        _logger.warning('Response: ${response.body}');
        return [];
      }
    } catch (e) {
      _logger.severe('Error getting stock symbols: $e');
      return [];
    }
  }

  // Fetch stock data from Alpha Vantage API
  Future<Asset?> _fetchStockFromAlphaVantage(String symbol) async {
    // Skip API call if key is not configured
    if (_alphaVantageApiKey.isEmpty) {
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

          // Get company profile to get additional info
          final companyUrl =
              '$_alphaVantageBaseUrl?function=OVERVIEW&symbol=$symbol&apikey=$_alphaVantageApiKey';
          final companyResponse = await http.get(Uri.parse(companyUrl));
          Map<String, dynamic> companyData = {};

          if (companyResponse.statusCode == 200) {
            companyData = json.decode(companyResponse.body);
          }

          final price = double.parse(quote['05. price']);
          final openPrice = double.parse(quote['02. open']);
          final highPrice = double.parse(quote['03. high']);
          final lowPrice = double.parse(quote['04. low']);
          final changePercent =
              double.parse(quote['10. change percent'].replaceAll('%', ''));
          final change = double.parse(quote['09. change']);
          final volume = double.parse(quote['06. volume']);

          // Use API data for market cap if available, otherwise calculate from volume
          final marketCap = (companyData['MarketCapitalization'] != null)
              ? double.tryParse(
                      companyData['MarketCapitalization'].toString()) ??
                  (price * volume)
              : (price * volume);

          return Asset(
            name: companyData['Name'] ?? symbol,
            symbol: symbol,
            sector: companyData['Sector'] ?? 'Unknown',
            ownership: 'Public',
            price: price,
            change: change,
            changePercent: changePercent,
            volume: volume,
            marketCap: marketCap,
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

    return null;
  }

  // Updated Finnhub API request using query parameter instead of header
  Future<Asset?> _fetchStockFromFinnhub(String symbol) async {
    if (_finnhubApiKey.isEmpty) {
      return null;
    }

    try {
      // Use token as query parameter instead of header
      final quoteUrl =
          '$_finnhubBaseUrl/quote?symbol=$symbol&token=$_finnhubApiKey';
      final profileUrl =
          '$_finnhubBaseUrl/stock/profile2?symbol=$symbol&token=$_finnhubApiKey';

      final responses = await Future.wait([
        http.get(Uri.parse(quoteUrl)),
        http.get(Uri.parse(profileUrl)),
      ]);

      if (responses[0].statusCode == 200) {
        // Log successful response for debugging
        _logger.info('Successfully received quote data for $symbol');

        final quoteData = json.decode(responses[0].body);

        // If we get a response but the second request failed, still create an asset with partial data
        Map<String, dynamic> profileData = {};
        if (responses[1].statusCode == 200) {
          profileData = json.decode(responses[1].body);
          _logger.info('Successfully received profile data for $symbol');
        } else {
          _logger.warning(
              'Failed to get profile for $symbol: HTTP ${responses[1].statusCode}');
        }

        // Check if we have valid data
        if (quoteData.containsKey('c') && quoteData['c'] != null) {
          return Asset(
            symbol: symbol,
            name: profileData.isNotEmpty && profileData['name'] != null
                ? profileData['name']
                : symbol,
            price: (quoteData['c'] as num).toDouble(),
            change: quoteData['d'] != null
                ? (quoteData['d'] as num).toDouble()
                : 0.0,
            changePercent: quoteData['dp'] != null
                ? (quoteData['dp'] as num).toDouble()
                : 0.0,
            volume: quoteData['v'] != null
                ? (quoteData['v'] as num).toDouble()
                : 0.0,
            sector:
                profileData.isNotEmpty && profileData['finnhubIndustry'] != null
                    ? profileData['finnhubIndustry']
                    : 'Unknown',
            ownership: 'Public',
            marketCap: profileData.isNotEmpty &&
                    profileData['marketCapitalization'] != null
                ? (profileData['marketCapitalization'] as num).toDouble() *
                    1000000
                : quoteData['v'] != null && quoteData['c'] != null
                    ? (quoteData['v'] as num).toDouble() *
                        (quoteData['c'] as num).toDouble()
                    : 0.0,
            lastUpdated: DateTime.now(),
            dayHigh: quoteData['h'] != null
                ? (quoteData['h'] as num).toDouble()
                : 0.0,
            dayLow: quoteData['l'] != null
                ? (quoteData['l'] as num).toDouble()
                : 0.0,
            openPrice: quoteData['o'] != null
                ? (quoteData['o'] as num).toDouble()
                : 0.0,
            lotSize: 1,
            tickSize: 0.01,
          );
        } else {
          _logger.warning('Invalid quote data format for $symbol: $quoteData');
        }
      } else {
        _logger.warning(
            'Failed to fetch Finnhub data for $symbol: ${responses[0].statusCode}');
      }
    } catch (e) {
      _logger.warning('Error in _fetchStockFromFinnhub for $symbol: $e');
    }
    return null;
  }

  // Get stock details including company profile, financials, etc.
  Future<Map<String, dynamic>> getStockDetails(String symbol,
      {required bool isInternational}) async {
    _logger.info('Fetching detailed data for $symbol');

    if (!isInternational) {
      // For Ethiopian stocks, ONLY use ethio_data
      final ethiopianStocks =
          ethio_data.EthioData.generateMockEthioMarketData();
      return ethiopianStocks.firstWhere(
        (stock) => stock['symbol'] == symbol,
        orElse: () => throw Exception('Stock not found'),
      );
    }

    // For international stocks, try to get from API only
    Map<String, dynamic> details = {};
    if (_finnhubApiKey.isEmpty) {
      _logger
          .warning('Finnhub API key not configured, returning empty details');
      return details;
    }

    try {
      // Use token in query parameter instead of header
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

    if (_finnhubApiKey.isEmpty) {
      _logger.warning(
          'Finnhub API key not configured, returning empty historical data');
      return candles;
    }

    try {
      // Token in query parameter
      final url =
          '$_finnhubBaseUrl/stock/candle?symbol=$symbol&resolution=$resolution&from=$from&to=$to&token=$_finnhubApiKey';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['s'] == 'ok') {
          _logger.info('Successfully fetched historical data for $symbol');
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
        _logger
            .warning('Failed to fetch historical data: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error fetching historical data for $symbol: $e');
    }

    return candles;
  }

  // Fixed implementation for getting market data
  Future<List<Map<String, dynamic>>> getMarketData(
      {required bool isInternational}) async {
    if (!isInternational) {
      // For Ethiopian market, ONLY use ethio_data
      return ethio_data.EthioData.generateMockEthioMarketData();
    }

    // For international market, use API with proper authentication
    try {
      // Token in query parameter
      final response = await http.get(
        Uri.parse(
            '$_finnhubBaseUrl/stock/symbol?exchange=US&token=$_finnhubApiKey'),
      );

      if (response.statusCode == 200) {
        _logger.info('Successfully fetched market symbols data');
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        _logger.warning('Failed to load market data: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      _logger.severe('Error connecting to market data service: $e');
      return [];
    }
  }

  // Fixed sector performance API call
  Future<List<Map<String, dynamic>>> getSectorPerformance(
      {required bool isInternational}) async {
    if (!isInternational) {
      // For Ethiopian sectors, calculate from ethio_data ONLY
      final ethiopianStocks =
          ethio_data.EthioData.generateMockEthioMarketData();
      final sectorPerformance = <String, List<double>>{};

      for (final stock in ethiopianStocks) {
        final sector = stock['sector'] as String;
        sectorPerformance.putIfAbsent(sector, () => []);
        sectorPerformance[sector]!.add(stock['change'] as double);
      }

      return sectorPerformance.entries.map((entry) {
        return {
          'sector': entry.key,
          'performance':
              entry.value.reduce((a, b) => a + b) / entry.value.length,
        };
      }).toList();
    }

    // For international sectors, use API with proper authentication
    try {
      // Token in query parameter
      final response = await http.get(
        Uri.parse('$_finnhubBaseUrl/stock/sectors?token=$_finnhubApiKey'),
      );

      if (response.statusCode == 200) {
        _logger.info('Successfully fetched sector performance data');
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data.entries
            .map((entry) => {
                  'sector': entry.key,
                  'performance': double.tryParse(entry.value.toString()) ?? 0.0,
                })
            .toList();
      } else {
        _logger.warning(
            'Failed to load sector performance: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      _logger.severe('Error connecting to market data service: $e');
      return [];
    }
  }
}
