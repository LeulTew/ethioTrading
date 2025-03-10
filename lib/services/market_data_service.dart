import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import '../models/asset.dart';
import '../config/env.dart';
import '../data/ethio_data.dart' as ethio_data;
import 'package:flutter/foundation.dart' show kIsWeb;

class MarketDataService {
  final _logger = Logger('MarketDataService');
  final String _finnhubBaseUrl = Env.finnhubBaseUrl;
  final String _alphaVantageBaseUrl = Env.alphaVantageBaseUrl;
  final String _finnhubApiKey = Env.finnhubApiKey;
  final String _alphaVantageApiKey = Env.alphaVantageApiKey;

  // Predefined popular symbols to reduce API calls
  final List<String> _popularSymbols = [
    'AAPL',
    'MSFT',
    'GOOGL',
    'AMZN',
    'META',
    'TSLA',
    'NVDA',
    'JPM',
    'V',
    'WMT',
    'PG',
    'JNJ',
    'UNH',
    'HD',
    'BAC'
  ];

  MarketDataService() {
    _logger.info('MarketDataService initialized');
    _validateApiKeys();
  }

  void _validateApiKeys() {
    if (_finnhubApiKey.isEmpty) {
      _logger.warning('Finnhub API key is not configured properly');
    }
    if (_alphaVantageApiKey.isEmpty) {
      _logger.warning('Alpha Vantage API key is not configured properly');
    }
  }

  // Main method to fetch international stocks combining both APIs intelligently
  Future<List<Asset>> fetchInternationalStocks(
      {bool prioritizeAlphaVantage = false}) async {
    _logger
        .info('Fetching international stock data using combined API approach');
    _logger.info(
        'API priority: ${prioritizeAlphaVantage ? "Alpha Vantage" : "Finnhub"}');

    List<Asset> assets = [];

    // Add explicit source validation flag
    bool usedRealApiSource = false;

    try {
      // Expand popular symbols list to get more assets
      final symbols = [
        ..._popularSymbols,
        'NFLX',
        'INTC',
        'AMD',
        'DIS',
        'PYPL',
        'ADBE',
        'CSCO',
        'PEP',
        'CMCSA',
        'COST',
        'AVGO',
        'TXN',
        'QCOM',
        'TMUS',
        'AMGN',
        'SBUX',
        'GILD',
        'MDLZ',
        'ADP',
        'BKNG',
        'AMAT',
        'FISV',
        'CSX',
        'INTU',
        'ISRG'
      ];

      _logger.info('Using ${symbols.length} predefined popular stock symbols');

      // If prioritizing Alpha Vantage, try batch processing first
      if (prioritizeAlphaVantage) {
        try {
          _logger
              .info('Attempting Alpha Vantage batch fetch first (prioritized)');
          final batchAssets =
              await _fetchBatchQuotesFromAlphaVantage(symbols.take(5).toList());
          if (batchAssets.isNotEmpty) {
            assets.addAll(batchAssets);
            _logger.info(
                'Successfully fetched batch data from Alpha Vantage for ${batchAssets.length} symbols');

            // Mark these assets as coming from Alpha Vantage
            assets = assets
                .map((asset) => Asset(
                      symbol: asset.symbol,
                      name: asset.name,
                      price: asset.price,
                      change: asset.change,
                      changePercent: asset.changePercent,
                      volume: asset.volume,
                      sector: asset.sector,
                      ownership: "Alpha Vantage API", // Mark the source
                      marketCap: asset.marketCap,
                      lastUpdated: asset.lastUpdated,
                      dayHigh: asset.dayHigh,
                      dayLow: asset.dayLow,
                      openPrice: asset.openPrice,
                      lotSize: asset.lotSize,
                      tickSize: asset.tickSize,
                      isFavorite: asset.isFavorite,
                    ))
                .toList();

            return assets;
          }
        } catch (e) {
          _logger.warning('Alpha Vantage batch fetch failed: $e');
          // Continue to individual symbol processing
        }
      }

      // Process each symbol with the best API for the job based on priority
      for (final symbol in symbols) {
        try {
          Asset? asset;

          if (prioritizeAlphaVantage) {
            // Try Alpha Vantage first when prioritized
            asset = await _fetchStockFromAlphaVantage(symbol);

            // If Alpha Vantage fails, try Finnhub as fallback
            if (asset == null) {
              _logger.info(
                  'Alpha Vantage failed for $symbol, trying Finnhub as fallback');
              asset = kIsWeb
                  ? await _fetchStockFromFinnhubWithQueryParam(symbol)
                  : await _fetchStockFromFinnhub(symbol);
            }
          } else {
            // Default: Try Finnhub first
            if (!kIsWeb) {
              asset = await _fetchStockFromFinnhub(symbol);
            } else {
              asset = await _fetchStockFromFinnhubWithQueryParam(symbol);
            }

            // If Finnhub fails, try Alpha Vantage as fallback
            if (asset == null) {
              _logger.info('Finnhub failed for $symbol, trying Alpha Vantage');
              asset = await _fetchStockFromAlphaVantage(symbol);
            }
          }

          if (asset != null) {
            // Mark the source in the ownership field
            final source = prioritizeAlphaVantage
                ? (asset.ownership == "Public"
                    ? "Alpha Vantage API"
                    : asset.ownership)
                : (asset.ownership == "Public"
                    ? "Finnhub API"
                    : asset.ownership);

            assets.add(Asset(
              symbol: asset.symbol,
              name: asset.name,
              price: asset.price,
              change: asset.change,
              changePercent: asset.changePercent,
              volume: asset.volume,
              sector: asset.sector,
              ownership: source, // Mark the data source
              marketCap: asset.marketCap,
              lastUpdated: asset.lastUpdated,
              dayHigh: asset.dayHigh,
              dayLow: asset.dayLow,
              openPrice: asset.openPrice,
              lotSize: asset.lotSize,
              tickSize: asset.tickSize,
              isFavorite: asset.isFavorite,
            ));

            usedRealApiSource = true;
            _logger.info('Successfully fetched data for $symbol from $source');
          } else {
            _logger.warning('Failed to fetch data for $symbol from all APIs');
          }

          // Rate limiting to avoid API restrictions
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (e) {
          _logger.warning('Error fetching data for $symbol: $e');
        }
      }

      if (!usedRealApiSource && assets.isEmpty) {
        _logger.severe(
            'No international data could be fetched from any API source');
        throw Exception(
            'Failed to fetch international data from any API source');
      }

      _logger.info('Fetched ${assets.length} international stocks');
      return assets;
    } catch (e) {
      _logger.severe('Error fetching international stocks: $e');
      // Don't fall back to mock data - just return empty list
      return [];
    }
  }

  // Fetch batch quotes from Alpha Vantage (more efficient than individual calls)
  Future<List<Asset>> _fetchBatchQuotesFromAlphaVantage(
      List<String> symbols) async {
    if (_alphaVantageApiKey.isEmpty || symbols.isEmpty) {
      return [];
    }

    try {
      final symbolsStr = symbols.join(',');
      final url =
          '$_alphaVantageBaseUrl?function=BATCH_STOCK_QUOTES&symbols=$symbolsStr&apikey=$_alphaVantageApiKey';

      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey('Stock Quotes') && data['Stock Quotes'] is List) {
          List<Asset> assets = [];
          final quotes = data['Stock Quotes'] as List;

          for (var quote in quotes) {
            final symbol = quote['1. symbol'] as String;
            final price = double.tryParse(quote['2. price'] ?? '0') ?? 0.0;

            // Get additional company data if possible
            Asset? asset = await _enrichAssetWithCompanyData(Asset(
                symbol: symbol,
                name: symbol, // Will be enriched later
                price: price,
                change: 0.0, // Will be calculated if possible
                changePercent: 0.0, // Will be calculated if possible
                volume: double.tryParse(quote['3. volume'] ?? '0') ?? 0.0,
                sector: 'Unknown', // Will be enriched later
                ownership: 'Public',
                marketCap: 0.0, // Will be enriched later
                lastUpdated: DateTime.now(),
                dayHigh: price, // Temporary
                dayLow: price, // Temporary
                openPrice: price, // Temporary
                lotSize: 1,
                tickSize: 0.01));

            if (asset != null) {
              assets.add(asset);
            }
          }
          return assets;
        }
      }
      return [];
    } catch (e) {
      _logger.warning('Error in batch quotes from Alpha Vantage: $e');
      return [];
    }
  }

  // Fetch individual stock from Alpha Vantage
  Future<Asset?> _fetchStockFromAlphaVantage(String symbol) async {
    if (_alphaVantageApiKey.isEmpty) {
      _logger
          .warning('Alpha Vantage API key not configured, skipping API call');
      return null;
    }

    try {
      final url =
          '$_alphaVantageBaseUrl?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$_alphaVantageApiKey';

      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey('Global Quote') &&
            data['Global Quote'] != null &&
            data['Global Quote'].isNotEmpty) {
          final quote = data['Global Quote'];

          // Extract basic quote data
          final price = double.parse(quote['05. price']);
          final openPrice = double.parse(quote['02. open']);
          final highPrice = double.parse(quote['03. high']);
          final lowPrice = double.parse(quote['04. low']);
          final changePercent =
              double.parse(quote['10. change percent'].replaceAll('%', ''));
          final change = double.parse(quote['09. change']);
          final volume = double.parse(quote['06. volume']);

          // Create basic asset
          Asset asset = Asset(
              name: symbol, // Will be enriched later
              symbol: symbol,
              price: price,
              change: change,
              changePercent: changePercent,
              volume: volume,
              sector: 'Unknown', // Will be enriched later
              ownership: 'Public',
              marketCap: price * volume, // Estimate
              lastUpdated: DateTime.now(),
              dayHigh: highPrice,
              dayLow: lowPrice,
              openPrice: openPrice,
              lotSize: 1,
              tickSize: 0.01);

          // Try to enrich with company data
          return await _enrichAssetWithCompanyData(asset);
        }
      }
      return null;
    } catch (e) {
      _logger.warning('Error fetching Alpha Vantage data for $symbol: $e');
      return null;
    }
  }

  // Enrich an asset with additional company data
  Future<Asset?> _enrichAssetWithCompanyData(Asset asset) async {
    try {
      // Try to get company overview from Alpha Vantage
      final companyUrl =
          '$_alphaVantageBaseUrl?function=OVERVIEW&symbol=${asset.symbol}&apikey=$_alphaVantageApiKey';
      final companyResponse = await http
          .get(Uri.parse(companyUrl))
          .timeout(const Duration(seconds: 10));

      if (companyResponse.statusCode == 200) {
        final companyData = json.decode(companyResponse.body);

        if (companyData.containsKey('Name') && companyData['Name'] != null) {
          return Asset(
              name: companyData['Name'],
              symbol: asset.symbol,
              price: asset.price,
              change: asset.change,
              changePercent: asset.changePercent,
              volume: asset.volume,
              sector: companyData['Sector'] ?? 'Unknown',
              ownership: 'Public',
              marketCap:
                  double.tryParse(companyData['MarketCapitalization'] ?? '0') ??
                      (asset.price * asset.volume),
              lastUpdated: asset.lastUpdated,
              dayHigh: asset.dayHigh,
              dayLow: asset.dayLow,
              openPrice: asset.openPrice,
              lotSize: asset.lotSize,
              tickSize: asset.tickSize);
        }
      }

      // If we couldn't enrich, return the original asset
      return asset;
    } catch (e) {
      _logger.warning('Error enriching asset data for ${asset.symbol}: $e');
      // Return the original asset if enrichment fails
      return asset;
    }
  }

  // Fetch stock data from Finnhub API using headers (not for web)
  Future<Asset?> _fetchStockFromFinnhub(String symbol) async {
    if (_finnhubApiKey.isEmpty) {
      return null;
    }

    try {
      // Create headers with auth token
      final headers = {
        'X-Finnhub-Token': _finnhubApiKey,
        'Content-Type': 'application/json',
      };

      // Fetch quote and company profile data
      final quoteUrl = '$_finnhubBaseUrl/quote?symbol=$symbol';
      final profileUrl = '$_finnhubBaseUrl/stock/profile2?symbol=$symbol';

      // Make API requests with header authentication
      final quoteResponse = await http
          .get(Uri.parse(quoteUrl), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (quoteResponse.statusCode != 200) {
        _logger.warning(
            'Failed to fetch quote from Finnhub: ${quoteResponse.statusCode}');
        return null;
      }

      final quoteData = json.decode(quoteResponse.body);
      Map<String, dynamic> profileData = {};

      // Try to get profile data
      final profileResponse = await http
          .get(Uri.parse(profileUrl), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (profileResponse.statusCode == 200) {
        profileData = json.decode(profileResponse.body);
      }

      return _createAssetFromFinnhubData(symbol, quoteData, profileData);
    } catch (e) {
      _logger.warning('Error in _fetchStockFromFinnhub for $symbol: $e');
      return null;
    }
  }

  // Fetch stock data from Finnhub API using query parameters (for web to avoid CORS)
  Future<Asset?> _fetchStockFromFinnhubWithQueryParam(String symbol) async {
    if (_finnhubApiKey.isEmpty) {
      return null;
    }

    try {
      // Use token as query parameter to avoid CORS issues
      final quoteUrl =
          '$_finnhubBaseUrl/quote?symbol=$symbol&token=$_finnhubApiKey';
      final profileUrl =
          '$_finnhubBaseUrl/stock/profile2?symbol=$symbol&token=$_finnhubApiKey';

      final responses = await Future.wait([
        http.get(Uri.parse(quoteUrl)).timeout(const Duration(seconds: 10)),
        http.get(Uri.parse(profileUrl)).timeout(const Duration(seconds: 10)),
      ]);

      if (responses[0].statusCode != 200) {
        _logger.warning(
            'Failed to fetch quote with query param: ${responses[0].statusCode}');
        return null;
      }

      final quoteData = json.decode(responses[0].body);
      Map<String, dynamic> profileData = {};

      if (responses[1].statusCode == 200) {
        profileData = json.decode(responses[1].body);
      }

      return _createAssetFromFinnhubData(symbol, quoteData, profileData);
    } catch (e) {
      _logger.warning(
          'Error in _fetchStockFromFinnhubWithQueryParam for $symbol: $e');
      return null;
    }
  }

  // Helper method to create Asset from Finnhub data
  Asset? _createAssetFromFinnhubData(String symbol,
      Map<String, dynamic> quoteData, Map<String, dynamic> profileData) {
    if (!quoteData.containsKey('c') || quoteData['c'] == null) {
      return null;
    }

    return Asset(
      symbol: symbol,
      name: profileData.isNotEmpty && profileData['name'] != null
          ? profileData['name']
          : symbol,
      price: (quoteData['c'] as num).toDouble(),
      change: quoteData['d'] != null ? (quoteData['d'] as num).toDouble() : 0.0,
      changePercent:
          quoteData['dp'] != null ? (quoteData['dp'] as num).toDouble() : 0.0,
      volume: quoteData['v'] != null ? (quoteData['v'] as num).toDouble() : 0.0,
      sector: profileData.isNotEmpty && profileData['finnhubIndustry'] != null
          ? profileData['finnhubIndustry']
          : 'Unknown',
      ownership: 'Public',
      marketCap: profileData.isNotEmpty &&
              profileData['marketCapitalization'] != null
          ? (profileData['marketCapitalization'] as num).toDouble() * 1000000
          : quoteData['v'] != null && quoteData['c'] != null
              ? (quoteData['v'] as num).toDouble() *
                  (quoteData['c'] as num).toDouble()
              : 0.0,
      lastUpdated: DateTime.now(),
      dayHigh:
          quoteData['h'] != null ? (quoteData['h'] as num).toDouble() : 0.0,
      dayLow: quoteData['l'] != null ? (quoteData['l'] as num).toDouble() : 0.0,
      openPrice:
          quoteData['o'] != null ? (quoteData['o'] as num).toDouble() : 0.0,
      lotSize: 1,
      tickSize: 0.01,
    );
  }

  // Get historical price data using Alpha Vantage (better for this purpose)
  Future<List<Map<String, dynamic>>> getHistoricalData(
      String symbol, String timeframe, int from, int to) async {
    _logger.info('Fetching historical data for $symbol using Alpha Vantage');
    List<Map<String, dynamic>> candles = [];

    if (_alphaVantageApiKey.isEmpty) {
      _logger.warning('Alpha Vantage API key not configured');
      return candles;
    }

    try {
      // Map timeframe to Alpha Vantage function
      String function;
      String interval = "60min"; // default

      // Map the timeframe parameter to appropriate Alpha Vantage function
      switch (timeframe.toLowerCase()) {
        case "1d":
        case "day":
          function = "TIME_SERIES_INTRADAY";
          interval = "5min";
          break;
        case "1w":
        case "week":
          function = "TIME_SERIES_DAILY";
          break;
        case "1m":
        case "month":
          function = "TIME_SERIES_WEEKLY";
          break;
        default:
          function = "TIME_SERIES_DAILY";
      }

      String url =
          '$_alphaVantageBaseUrl?function=$function&symbol=$symbol&apikey=$_alphaVantageApiKey';
      if (function == "TIME_SERIES_INTRADAY") {
        url += '&interval=$interval';
      }

      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Process result based on the function type
        final timeSeriesKey = data.keys
            .firstWhere((key) => key.contains("Time Series"), orElse: () => "");

        if (timeSeriesKey.isNotEmpty && data[timeSeriesKey] is Map) {
          final timeSeries = data[timeSeriesKey] as Map;

          // Convert data to uniform format
          timeSeries.forEach((dateStr, values) {
            // Parse timestamp
            final dateTime = DateTime.parse(dateStr);
            final timestamp = dateTime.millisecondsSinceEpoch ~/ 1000;

            // Only include data within requested range
            if (timestamp >= from && timestamp <= to) {
              candles.add({
                'timestamp': timestamp,
                'open': double.parse(values['1. open'] ?? '0'),
                'high': double.parse(values['2. high'] ?? '0'),
                'low': double.parse(values['3. low'] ?? '0'),
                'close': double.parse(values['4. close'] ?? '0'),
                'volume': double.parse(values['5. volume'] ?? '0'),
              });
            }
          });

          // Sort by timestamp in ascending order
          candles.sort((a, b) =>
              (a['timestamp'] as int).compareTo(b['timestamp'] as int));
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

  // Get stock details - use Finnhub and Alpha Vantage together for comprehensive data
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

    // For international stocks, combine Finnhub and Alpha Vantage data
    Map<String, dynamic> details = {};

    // Try Finnhub first for company profile and basic financials
    if (_finnhubApiKey.isNotEmpty) {
      try {
        // Use query param authentication for web compatibility
        final profileUrl =
            '$_finnhubBaseUrl/stock/profile2?symbol=$symbol&token=$_finnhubApiKey';
        final financialsUrl =
            '$_finnhubBaseUrl/stock/metric?symbol=$symbol&metric=all&token=$_finnhubApiKey';

        final responses = await Future.wait([
          http.get(Uri.parse(profileUrl)),
          http.get(Uri.parse(financialsUrl)),
        ]);

        if (responses[0].statusCode == 200) {
          details['profile'] = json.decode(responses[0].body);
        }

        if (responses[1].statusCode == 200) {
          details['financials'] = json.decode(responses[1].body);
        }
      } catch (e) {
        _logger.warning('Error fetching Finnhub details for $symbol: $e');
      }
    }

    // Add Alpha Vantage data for more comprehensive information
    if (_alphaVantageApiKey.isNotEmpty) {
      try {
        // Company overview (detailed fundamentals)
        final overviewUrl =
            '$_alphaVantageBaseUrl?function=OVERVIEW&symbol=$symbol&apikey=$_alphaVantageApiKey';
        final response = await http.get(Uri.parse(overviewUrl));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          // Only add if we got actual data (not empty object)
          if (data.containsKey('Symbol')) {
            details['fundamentals'] = data;
          }
        }
      } catch (e) {
        _logger.warning('Error fetching Alpha Vantage details for $symbol: $e');
      }
    }

    return details;
  }

  // Get sector performance data - use Alpha Vantage for this as it's more reliable
  Future<List<Map<String, dynamic>>> getSectorPerformance(
      {required bool isInternational}) async {
    if (!isInternational) {
      // For Ethiopian sectors, calculate from ethio_data
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

    // For international sectors, use Alpha Vantage
    if (_alphaVantageApiKey.isEmpty) {
      _logger.warning('Alpha Vantage API key not configured');
      return [];
    }

    try {
      final url =
          '$_alphaVantageBaseUrl?function=SECTOR&apikey=$_alphaVantageApiKey';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Convert Alpha Vantage sector data format
        List<Map<String, dynamic>> sectorData = [];

        // Typically contains ranges like "Rank A: Real-Time Performance"
        data.forEach((key, value) {
          if (key.contains("Rank") && value is Map) {
            // Take the most recent timeframe (usually real-time)
            value.forEach((sector, performance) {
              // Parse percentage string to double
              double perf =
                  double.tryParse(performance.toString().replaceAll('%', '')) ??
                      0.0;

              sectorData.add({
                'sector': sector,
                'performance': perf,
                'timeframe': key,
              });
            });

            // Only process the first time frame
            return;
          }
        });

        return sectorData;
      } else {
        _logger.warning('Failed to fetch sector data: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error fetching sector performance: $e');
    }

    return [];
  }
}
