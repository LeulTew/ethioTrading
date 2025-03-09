// lib/data/ethio_data.dart

import 'dart:math' show Random, min;
import 'dart:async';

class EthioData {
  static final Random _random = Random();
  static Timer? _marketDataTimer;
  static List<Map<String, dynamic>> _lastMarketData = [];
  static final StreamController<List<Map<String, dynamic>>>
      _marketDataController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  static Stream<List<Map<String, dynamic>>> get marketDataStream =>
      _marketDataController.stream;

  static void startMarketDataStream() {
    _marketDataTimer?.cancel();
    _marketDataTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _lastMarketData = generateMockEthioMarketData();
      _marketDataController.add(_lastMarketData);
    });
  }

  static void stopMarketDataStream() {
    _marketDataTimer?.cancel();
    _marketDataTimer = null;
  }

  static List<Map<String, dynamic>> generateMockEthioMarketData() {
    return [
      // Banks
      _createMarketData('Commercial Bank of Ethiopia', 'CBE', 850.20, _random,
          'Bank', 'State', 5000000),
      _createMarketData(
          'Awash Bank', 'AWB', 780.45, _random, 'Bank', 'Private', 2500000),
      _createMarketData(
          'Dashen Bank', 'DSH', 670.80, _random, 'Bank', 'Private', 2000000),
      _createMarketData('Bank of Abyssinia', 'BOA', 620.70, _random, 'Bank',
          'Private', 1800000),
      _createMarketData(
          'Wegagen Bank', 'WB', 590.30, _random, 'Bank', 'Private', 1500000),

      // State Enterprises
      _createMarketData('Ethiopian Airlines Group', 'EAL', 4500.75, _random,
          'Transport', 'State', 10000000),
      _createMarketData(
          'Ethio Telecom', 'ET', 900.00, _random, 'Telecom', 'State', 8000000),
      _createMarketData('Ethiopian Electric Power', 'EEP', 1250.50, _random,
          'Utility', 'State', 6000000),

      // Manufacturing
      _createMarketData('East African Holdings', 'EAH', 890.30, _random,
          'Manufacturing', 'Private', 3000000),
      _createMarketData('Habesha Breweries', 'HAB', 627.00, _random,
          'Manufacturing', 'Private', 2200000),
      _createMarketData('National Cement', 'NC', 589.00, _random,
          'Manufacturing', 'Private', 2100000),

      // Agricultural
      _createMarketData('Ethiopian Coffee Export', 'ECEX', 355.50, _random,
          'Agriculture', 'Private', 1200000),
      _createMarketData('Ethio Sugar Corporation', 'ESC', 289.90, _random,
          'Agriculture', 'State', 1800000),
      _createMarketData('ELFORA Agro-Industry', 'EAI', 420.15, _random,
          'Agriculture', 'Private', 1400000),
    ];
  }

  static Map<String, dynamic> _createMarketData(
      String name,
      String symbol,
      double basePrice,
      Random random,
      String sector,
      String ownership,
      int baseVolume) {
    // Calculate daily price movement within Ethiopian market rules (+/- 10% max)
    final maxMove = basePrice * 0.10;
    final change = (random.nextDouble() * maxMove * 2) - maxMove;
    final currentPrice = basePrice + change;

    // Generate realistic volume based on company size and price movement
    final volumeMultiplier = 1.0 + (change.abs() / basePrice);
    final volume = (baseVolume * volumeMultiplier).round();

    // Calculate market cap
    final marketCap = currentPrice * volume;

    // Generate previous day's data for technical analysis
    final prevClose = basePrice;
    final prevHigh = prevClose * (1 + random.nextDouble() * 0.05);
    final prevLow = prevClose * (1 - random.nextDouble() * 0.05);
    final prevVolume = baseVolume * (0.8 + random.nextDouble() * 0.4);

    // Calculate technical indicators
    final sma20 = _calculateSMA(currentPrice, 20);
    final ema20 = _calculateEMA(currentPrice, prevClose, 20);
    final rsi = _calculateRSI(currentPrice, prevClose);
    final macd = _calculateMACD(currentPrice, prevClose);
    final bollingerBands = _calculateBollingerBands(currentPrice, 20);

    return {
      'name': name,
      'symbol': symbol,
      'price': currentPrice,
      'change': (change / basePrice) * 100,
      'volume': volume,
      'marketCap': marketCap,
      'sector': sector,
      'ownership': ownership,
      'currency': 'ETB',
      'lastUpdated': DateTime.now().toString(),
      'dayHigh': currentPrice + (random.nextDouble() * maxMove),
      'dayLow': currentPrice - (random.nextDouble() * maxMove),
      'openPrice': basePrice,
      'lotSize': sector == 'Bank' ? 10 : 1,
      'tickSize': 0.05,
      'prevClose': prevClose,
      'prevHigh': prevHigh,
      'prevLow': prevLow,
      'prevVolume': prevVolume,
      'technicalIndicators': {
        'sma20': sma20,
        'ema20': ema20,
        'rsi': rsi,
        'macd': macd,
        'bollingerBands': bollingerBands,
      },
      'orderBook': _generateOrderBook(currentPrice, baseVolume.toDouble()),
      'tradeHistory':
          _generateTradeHistory(currentPrice, baseVolume.toDouble()),
    };
  }

  static double _calculateSMA(double currentPrice, int period) {
    // Simplified SMA calculation for mock data
    return currentPrice * (0.95 + _random.nextDouble() * 0.1);
  }

  static double _calculateEMA(
      double currentPrice, double prevClose, int period) {
    // Simplified EMA calculation
    final multiplier = 2 / (period + 1);
    return (currentPrice - prevClose) * multiplier + prevClose;
  }

  static double _calculateRSI(double currentPrice, double prevClose) {
    // Simplified RSI calculation
    final change = currentPrice - prevClose;
    final gain = change > 0 ? change : 0;
    final loss = change < 0 ? -change : 0;
    return 100 - (100 / (1 + (gain / loss)));
  }

  static Map<String, double> _calculateMACD(
      double currentPrice, double prevClose) {
    // Simplified MACD calculation
    final macdLine = _calculateEMA(currentPrice, prevClose, 12) -
        _calculateEMA(currentPrice, prevClose, 26);
    final signalLine = _calculateEMA(macdLine, prevClose, 9);
    final histogram = macdLine - signalLine;

    return {
      'macdLine': macdLine,
      'signalLine': signalLine,
      'histogram': histogram,
    };
  }

  static Map<String, double> _calculateBollingerBands(
      double price, int period) {
    // Simplified Bollinger Bands calculation
    final sma = _calculateSMA(price, period);
    final standardDeviation = price * 0.02; // Simplified standard deviation

    return {
      'middle': sma,
      'upper': sma + (standardDeviation * 2),
      'lower': sma - (standardDeviation * 2),
    };
  }

  static Map<String, List<Map<String, dynamic>>> _generateOrderBook(
      double currentPrice, double volume) {
    final bids = <Map<String, dynamic>>[];
    final asks = <Map<String, dynamic>>[];

    // Generate 10 levels of bids and asks
    for (var i = 0; i < 10; i++) {
      final bidPrice = currentPrice * (1 - 0.001 * (i + 1));
      final askPrice = currentPrice * (1 + 0.001 * (i + 1));
      final bidVolume =
          (volume * (0.1 - i * 0.005) * (0.8 + _random.nextDouble() * 0.4))
              .toDouble();
      final askVolume =
          (volume * (0.1 - i * 0.005) * (0.8 + _random.nextDouble() * 0.4))
              .toDouble();

      bids.add({
        'price': bidPrice,
        'volume': bidVolume,
        'total': bidPrice * bidVolume,
      });

      asks.add({
        'price': askPrice,
        'volume': askVolume,
        'total': askPrice * askVolume,
      });
    }

    return {
      'bids': bids,
      'asks': asks,
    };
  }

  static List<Map<String, dynamic>> _generateTradeHistory(
      double currentPrice, double volume) {
    final trades = <Map<String, dynamic>>[];
    final now = DateTime.now();

    // Generate last 20 trades
    for (var i = 0; i < 20; i++) {
      final priceChange = ((_random.nextDouble() * 2) - 1) * 0.001;
      final tradePrice = currentPrice * (1 + priceChange);
      final tradeVolume = volume * (0.01 + _random.nextDouble() * 0.02);
      final tradeTime =
          now.subtract(Duration(minutes: (i * 5 + _random.nextInt(5)).toInt()));

      trades.add({
        'price': tradePrice,
        'volume': tradeVolume,
        'total': tradePrice * tradeVolume,
        'time': tradeTime.toString(),
        'type': _random.nextBool() ? 'buy' : 'sell',
      });
    }

    return trades;
  }

  static Map<String, dynamic> getMarketDepthAnalysis(
      Map<String, dynamic> orderBook) {
    double totalBidVolume = 0;
    double totalAskVolume = 0;
    double weightedBidPrice = 0;
    double weightedAskPrice = 0;

    for (final bid in orderBook['bids']) {
      totalBidVolume += bid['volume'];
      weightedBidPrice += bid['price'] * bid['volume'];
    }

    for (final ask in orderBook['asks']) {
      totalAskVolume += ask['volume'];
      weightedAskPrice += ask['price'] * ask['volume'];
    }

    final averageBidPrice = weightedBidPrice / totalBidVolume;
    final averageAskPrice = weightedAskPrice / totalAskVolume;
    final spread = averageAskPrice - averageBidPrice;
    final bidAskRatio = totalBidVolume / totalAskVolume;

    return {
      'totalBidVolume': totalBidVolume,
      'totalAskVolume': totalAskVolume,
      'averageBidPrice': averageBidPrice,
      'averageAskPrice': averageAskPrice,
      'spread': spread,
      'bidAskRatio': bidAskRatio,
      'marketPressure': bidAskRatio > 1 ? 'buying' : 'selling',
    };
  }

  static Map<String, dynamic> getMarketMomentumAnalysis(
      List<Map<String, dynamic>> marketData) {
    int strongBuy = 0;
    int buy = 0;
    int neutral = 0;
    int sell = 0;
    int strongSell = 0;

    for (final stock in marketData) {
      final indicators = stock['technicalIndicators'];
      final price = stock['price'];
      final rsi = indicators['rsi'];
      final macd = indicators['macd'];
      final bb = indicators['bollingerBands'];

      // Simplified technical analysis scoring
      int score = 0;

      // RSI analysis
      if (rsi < 30) {
        score += 2;
      } else if (rsi < 40) {
        score += 1;
      } else if (rsi > 70) {
        score -= 2;
      } else if (rsi > 60) {
        score -= 1;
      }

      // MACD analysis
      if (macd['histogram'] > 0 && macd['macdLine'] > macd['signalLine']) {
        score += 1;
      } else if (macd['histogram'] < 0 &&
          macd['macdLine'] < macd['signalLine']) {
        score -= 1;
      }

      // Bollinger Bands analysis
      if (price < bb['lower']) {
        score += 2;
      } else if (price > bb['upper']) {
        score -= 2;
      }

      // Categorize based on total score
      if (score >= 3) {
        strongBuy++;
      } else if (score > 0) {
        buy++;
      } else if (score == 0) {
        neutral++;
      } else if (score > -3) {
        sell++;
      } else {
        strongSell++;
      }
    }

    return {
      'strongBuy': strongBuy,
      'buy': buy,
      'neutral': neutral,
      'sell': sell,
      'strongSell': strongSell,
      'totalStocks': marketData.length,
      'marketSentiment':
          _calculateMarketSentiment(strongBuy, buy, neutral, sell, strongSell),
    };
  }

  static String _calculateMarketSentiment(
      int strongBuy, int buy, int neutral, int sell, int strongSell) {
    final bullishScore = (strongBuy * 2 + buy) - (strongSell * 2 + sell);

    if (bullishScore >= 5) return 'strongly_bullish';
    if (bullishScore > 2) return 'bullish';
    if (bullishScore >= -2) return 'neutral';
    if (bullishScore > -5) return 'bearish';
    return 'strongly_bearish';
  }

  // Market Sectors
  static List<String> getSectors() {
    return [
      'Bank',
      'Transport',
      'Telecom',
      'Utility',
      'Agriculture',
      'Manufacturing'
    ];
  }

  // Ethiopian Calendar Utility
  static Map<String, dynamic> getEthiopianDate() {
    // Add 7 years and 8 months to get approximate Ethiopian date
    final now = DateTime.now();
    final ethYear = now.year + 7;
    final ethMonth = now.month + 8;

    return {
      'year': ethYear,
      'month': ethMonth > 12 ? ethMonth - 12 : ethMonth,
      'day': now.day,
      'monthName': _getEthiopianMonth(ethMonth > 12 ? ethMonth - 12 : ethMonth),
    };
  }

  static String _getEthiopianMonth(int month) {
    final months = [
      'Meskerem',
      'Tikimt',
      'Hidar',
      'Tahsas',
      'Tir',
      'Yekatit',
      'Megabit',
      'Miazia',
      'Ginbot',
      'Sene',
      'Hamle',
      'Nehase',
      'Pagume'
    ];
    return months[month - 1];
  }

  // Amharic Translation Map with additional translations
  static Map<String, String> getAmharicTranslations() {
    return {
      // Basic navigation and common terms
      'market': 'ገበያ',
      'portfolio': 'ፖርትፎሊዮ',
      'profile': 'መገለጫ',
      'settings': 'ቅንብሮች',
      'home': 'መነሻ',
      'buy': 'ግዛ',
      'sell': 'ሽጥ',
      'price': 'ዋጋ',
      'change': 'ለውጥ',
      'volume': 'መጠን',
      'chart': 'ቻርት',
      'news': 'ዜና',
      'watchlist': 'ዝርዝር',
      'analysis': 'ጥናት',

      // Sectors
      'bank': 'ባንክ',
      'agriculture': 'እርሻ',
      'manufacturing': 'ማምረቻ',
      'transport': 'ትራንስፖርት',
      'telecom': 'ቴሌኮም',
      'utility': 'አገልግሎት',
      'technology': 'ቴክኖሎጂ',
      'automotive': 'አውቶሞቲቭ',
      'financial': 'የፋይናንስ',
      'healthcare': 'ጤና',
      'consumer_cyclical': 'የሸማቾች',
      'e-commerce': 'ኢ-ኮሜርስ',
      'all_sectors': 'ሁሉም ዘርፎች',

      // Ownership types
      'state': 'መንግስታዊ',
      'private': 'የግል',

      // Market UI elements
      'market_summary': 'የገበያ ማጠቃለያ',
      'gainers': 'አሸናፊዎች',
      'losers': 'ተሸናፊዎች',
      'search_markets': 'ገበያዎችን ይፈልጉ',
      'search_stocks': 'አክሲዮኖችን ይፈልጉ',
      'all': 'ሁሉም',
      'ethiopian': 'ኢትዮጵያዊ',
      'international': 'ዓለም አቀፍ',
      'market_open': 'ገበያ ክፍት ነው',
      'market_closed': 'ገበያ ተዘግቷል',
      'add_to_watchlist': 'ወደ ዝርዝር ያክሉ',
      'remove_from_favorites': 'ከዝርዝር ያስወግዱ',
      'notifications': 'ማሳወቂያዎች',
      'clear_all': 'ሁሉንም አጽዳ',
      'advanced_filters': 'የላቀ ማጣሪያ',
      'refresh_data': 'መረጃን አድስ',
      'market_settings': 'የገበያ ቅንብሮች',

      // Time ranges
      '1d': '1ቀ',
      '1w': '1ሳ',
      '1m': '1ወ',
      '3m': '3ወ',
      '1y': '1ዓ',
      'All': 'ሁሉም',

      // Market status
      'opens_at': 'ይከፈታል በ',
      'closes_at': 'ይዘጋል በ',
      'closed_until': 'ዝግ እስከ',
      'trading_hours': 'የንግድ ሰዓታት',
    };
  }

  // Get shorter market status for mobile screens
  static String getShortMarketStatus() {
    final now = DateTime.now();
    final hour = now.hour;

    // Ethiopian markets are typically 9:00 AM to 3:00 PM, Monday to Friday
    if (now.weekday < DateTime.monday || now.weekday > DateTime.friday) {
      return "ዝግ እስከ ሰኞ 9:00";
    }

    if (hour < 9) {
      // Before market opens
      return "9:00 ላይ ይከፈታል";
    } else if (hour >= 15) {
      // After market closes
      if (now.weekday == DateTime.friday) {
        return "ዝግ እስከ ሰኞ 9:00";
      } else {
        return "ዝግ እስከ 9:00";
      }
    } else {
      // Market is open
      return "ይዘጋል 15:00";
    }
  }

  // Market Statistics
  static Map<String, dynamic> getMarketStatistics(
      List<Map<String, dynamic>> marketData) {
    double totalMarketCap = 0;
    double totalVolume = 0;
    int advancers = 0;
    int decliners = 0;
    int unchanged = 0;

    for (final stock in marketData) {
      totalMarketCap += stock['marketCap'];
      totalVolume += stock['volume'];

      if (stock['change'] > 0) {
        advancers++;
      } else if (stock['change'] < 0) {
        decliners++;
      } else {
        unchanged++;
      }
    }

    return {
      'totalMarketCap': totalMarketCap,
      'totalVolume': totalVolume,
      'advancers': advancers,
      'decliners': decliners,
      'unchanged': unchanged,
      'marketBreadth': advancers / (decliners == 0 ? 1 : decliners),
    };
  }

  static Map<String, double> getSectorWeights(
      List<Map<String, dynamic>> marketData) {
    final sectorTotals = <String, double>{};
    double totalMarketCap = 0;

    for (final stock in marketData) {
      final sector = stock['sector'];
      sectorTotals[sector] = (sectorTotals[sector] ?? 0) + stock['marketCap'];
      totalMarketCap += stock['marketCap'];
    }

    return Map.fromEntries(
      sectorTotals.entries.map(
        (entry) => MapEntry(entry.key, (entry.value / totalMarketCap) * 100),
      ),
    );
  }

  // Get sectors with proper Amharic translations
  static Map<String, String> getSectorsWithTranslations() {
    return {
      'Bank': 'ባንክ',
      'Transport': 'ትራንስፖርት',
      'Telecom': 'ቴሌኮም',
      'Utility': 'ኃይል አገልግሎት',
      'Agriculture': 'እርሻ',
      'Manufacturing': 'ማምረቻ',
    };
  }

  static void _updateMarketDepthAfterTrade(
    String symbol,
    String side,
    double price,
    double quantity,
  ) {
    final stockIndex =
        _lastMarketData.indexWhere((stock) => stock['symbol'] == symbol);
    if (stockIndex == -1) return;

    final orderBook = _lastMarketData[stockIndex]['orderBook'];
    final orders = side == 'buy' ? orderBook['asks'] : orderBook['bids'];

    // Match orders
    var remainingQuantity = quantity;
    for (var i = 0; i < orders.length && remainingQuantity > 0; i++) {
      final order = orders[i];
      if (side == 'buy' ? price >= order['price'] : price <= order['price']) {
        final matchedQuantity =
            min(remainingQuantity, (order['volume'] as num).toDouble());
        order['volume'] -= matchedQuantity;
        remainingQuantity -= matchedQuantity;

        // Add to trade history
        _lastMarketData[stockIndex]['tradeHistory'].insert(0, {
          'price': price,
          'volume': matchedQuantity,
          'total': price * matchedQuantity,
          'time': DateTime.now().toString(),
          'type': side,
        });
      }
    }

    // Remove filled orders
    orders.removeWhere((order) => order['volume'] <= 0);

    // Add remaining quantity as new order if limit order
    if (remainingQuantity > 0) {
      final newOrders = side == 'buy' ? orderBook['bids'] : orderBook['asks'];
      newOrders.add({
        'price': price,
        'volume': remainingQuantity,
        'total': price * remainingQuantity,
      });
      newOrders.sort((a, b) => side == 'buy'
          ? b['price'].compareTo(a['price'])
          : a['price'].compareTo(b['price']));
    }

    // Update market depth analysis
    _lastMarketData[stockIndex]['marketDepth'] =
        getMarketDepthAnalysis(orderBook);

    // Notify listeners
    _marketDataController.add(_lastMarketData);
  }

  static void executeTrade(Map<String, dynamic> tradeDetails) {
    final symbol = tradeDetails['symbol'];
    final side = tradeDetails['side'];
    final price = tradeDetails['price'];
    final quantity = tradeDetails['quantity'].toDouble();

    _updateMarketDepthAfterTrade(symbol, side, price, quantity);

    // Update stock price based on last trade
    final stockIndex =
        _lastMarketData.indexWhere((stock) => stock['symbol'] == symbol);
    if (stockIndex != -1) {
      final stock = _lastMarketData[stockIndex];
      stock['price'] = price;
      stock['volume'] += quantity;
      stock['change'] =
          ((price - stock['openPrice']) / stock['openPrice']) * 100;

      if (price > stock['dayHigh']) stock['dayHigh'] = price;
      if (price < stock['dayLow']) stock['dayLow'] = price;

      _marketDataController.add(_lastMarketData);
    }
  }

  static void addNotification(Map<String, dynamic> notification) {
    // Broadcast notification to all subscribers
    _marketDataController.add(_lastMarketData);
  }
}

// Ethiopian Market Hours utility class
class EthiopianMarketHours {
  static bool isMarketOpen() {
    final now = DateTime.now();
    final hour = now.hour;

    // Ethiopian markets are typically 9:00 AM to 3:00 PM, Monday to Friday
    return now.weekday >= DateTime.monday &&
        now.weekday <= DateTime.friday &&
        hour >= 9 &&
        hour < 15;
  }

  static String getFullMarketStatus() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;

    if (now.weekday < DateTime.monday || now.weekday > DateTime.friday) {
      return "Market closed until Monday 9:00 AM";
    }

    if (hour < 9) {
      final remainingHours = 9 - hour - 1;
      final remainingMinutes = 60 - minute;
      return "Market opens in $remainingHours:${remainingMinutes.toString().padLeft(2, '0')} at 9:00 AM";
    } else if (hour >= 15) {
      if (now.weekday == DateTime.friday) {
        return "Market closed until Monday 9:00 AM";
      } else {
        return "Market closed until tomorrow 9:00 AM";
      }
    } else {
      final remainingHours = 14 - hour;
      final remainingMinutes = 60 - minute;
      return "Market closes in $remainingHours:${remainingMinutes.toString().padLeft(2, '0')} at 3:00 PM";
    }
  }

  static String getShortMarketStatus() {
    final now = DateTime.now();
    final hour = now.hour;

    if (now.weekday < DateTime.monday || now.weekday > DateTime.friday) {
      return "Mon 9AM";
    }

    if (hour < 9) {
      return "9AM";
    } else if (hour >= 15) {
      if (now.weekday == DateTime.friday) {
        return "Mon 9AM";
      } else {
        return "9AM";
      }
    } else {
      return "3PM";
    }
  }
}
