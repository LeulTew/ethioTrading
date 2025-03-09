import 'dart:math';
import '../models/asset.dart';
import '../models/user_profile.dart';
import '../utils/ethiopian_utils.dart';

class MockDataGenerator {
  static final Random _random = Random();

  static List<Asset> generateMockAssets() {
    final companies = [
      ('Commercial Bank of Ethiopia', 'CBE', 'Bank', 'State', 850.0, 50000000),
      ('Awash Bank', 'AWB', 'Bank', 'Private', 780.0, 30000000),
      ('Dashen Bank', 'DSH', 'Bank', 'Private', 670.0, 25000000),
      (
        'Ethiopian Insurance Corporation',
        'EIC',
        'Insurance',
        'State',
        450.0,
        20000000
      ),
      ('Nyala Insurance', 'NYAL', 'Insurance', 'Private', 380.0, 15000000),
      (
        'East African Holdings',
        'EAH',
        'Manufacturing',
        'Private',
        890.0,
        40000000
      ),
      ('Ethiopian Airlines', 'ETH', 'Transport', 'State', 1200.0, 100000000),
      ('Ethio Telecom', 'ET', 'Technology', 'State', 900.0, 80000000),
      ('Safaricom Ethiopia', 'SAF', 'Technology', 'Private', 700.0, 60000000),
      (
        'Ethiopian Agricultural Business Corporation',
        'EABC',
        'Agriculture',
        'State',
        600.0,
        70000000
      ),
      ('Midroc Gold', 'MDG', 'Mining', 'Private', 550.0, 20000000),
    ];

    return companies.map((company) {
      final basePrice = company.$5;
      final totalShares = company.$6;
      final maxChange = basePrice * 0.10; // Ethiopian market daily limit of 10%
      final change = (_random.nextDouble() * 2 - 1) * maxChange;
      final currentPrice = basePrice + change;
      final volume = _generateRealisticVolume(company.$3, basePrice);

      return Asset(
        name: company.$1,
        symbol: company.$2,
        sector: company.$3,
        ownership: company.$4,
        price: currentPrice,
        change: change,
        changePercent: (change / basePrice) * 100,
        volume: volume,
        marketCap: currentPrice * totalShares,
        lastUpdated: DateTime.now(),
        dayHigh: currentPrice + (_random.nextDouble() * maxChange),
        dayLow: currentPrice - (_random.nextDouble() * maxChange),
        openPrice: basePrice,
        lotSize: company.$3 == 'Bank' ? 10 : 1, // Banks trade in lots of 10
        tickSize: 0.05, // 5 cents minimum price movement
      );
    }).toList();
  }

  static double _generateRealisticVolume(String sector, double price) {
    // Base volume varies by sector
    final baseVolume = switch (sector) {
      'Bank' => 50000 + _random.nextInt(50000),
      'Insurance' => 30000 + _random.nextInt(30000),
      'Manufacturing' => 40000 + _random.nextInt(40000),
      'Transport' => 20000 + _random.nextInt(20000),
      'Technology' => 35000 + _random.nextInt(35000),
      'Agriculture' => 40000 + _random.nextInt(40000),
      'Mining' => 30000 + _random.nextInt(30000),
      _ => 15000 + _random.nextInt(15000),
    };

    // Adjust volume based on price (inverse relationship)
    final priceAdjustment = 1000 / price;
    return baseVolume * priceAdjustment;
  }

  static UserProfile generateMockUserProfile() {
    return UserProfile(
      userId: 'ETH${_random.nextInt(99999).toString().padLeft(5, '0')}',
      username: 'EthioTrader${_random.nextInt(999)}',
      email: 'trader${_random.nextInt(999)}@ethiotrading.com',
      profilePictureUrl: 'https://ethiotrading.com/default-profile.png',
      tradingPreferences: {
        'defaultOrderType': 'market',
        'defaultQuantity': 10,
        'notifications': {
          'priceAlerts': true,
          'newsAlerts': true,
          'tradeConfirmations': true,
        },
      },
      watchlist: {
        'symbols': ['CBE', 'AWB', 'ETH', 'ET'],
        'lastUpdated': DateTime.now().toIso8601String(),
      },
      phoneNumber:
          '+251${_random.nextInt(999999999).toString().padLeft(9, '0')}',
      address: 'Addis Ababa, Ethiopia',
      bankAccountNumber: _generateMockBankAccount(),
      isVerified: true,
      tradingLevel: 'intermediate',
      availableBalance: 100000 + _random.nextDouble() * 900000,
    );
  }

  static String _generateMockBankAccount() {
    final bankCode = _random.nextInt(999).toString().padLeft(3, '0');
    final branchCode = _random.nextInt(999).toString().padLeft(3, '0');
    final accountNumber = _random.nextInt(9999999).toString().padLeft(7, '0');
    return '$bankCode$branchCode$accountNumber';
  }
  
  // Generate mock news for a specific stock symbol
  static List<Map<String, dynamic>> generateNewsForStock(String symbol) {
    final now = DateTime.now();
    final news = <Map<String, dynamic>>[];
    
    // Company name based on symbol
    String companyName = '';
    switch (symbol) {
      case 'CBE':
        companyName = 'Commercial Bank of Ethiopia';
        break;
      case 'AWB':
        companyName = 'Awash Bank';
        break;
      case 'DSH':
        companyName = 'Dashen Bank';
        break;
      case 'EIC':
        companyName = 'Ethiopian Insurance Corporation';
        break;
      case 'ETH':
        companyName = 'Ethiopian Airlines';
        break;
      case 'ET':
        companyName = 'Ethio Telecom';
        break;
      case 'AAPL':
        companyName = 'Apple Inc.';
        break;
      case 'MSFT':
        companyName = 'Microsoft Corporation';
        break;
      case 'AMZN':
        companyName = 'Amazon.com Inc.';
        break;
      case 'TSLA':
        companyName = 'Tesla Inc.';
        break;
      case 'GOOGL':
        companyName = 'Alphabet Inc.';
        break;
      default:
        companyName = symbol;
    }
    
    // Generate 5-10 news items
    final newsCount = 5 + _random.nextInt(6);
    for (int i = 0; i < newsCount; i++) {
      final daysAgo = _random.nextInt(30);
      final hoursAgo = _random.nextInt(24);
      final minutesAgo = _random.nextInt(60);
      final publishDate = now.subtract(Duration(
        days: daysAgo,
        hours: hoursAgo,
        minutes: minutesAgo,
      ));
      
      // Generate headline based on symbol
      String headline;
      String content;
      String source;
      String imageUrl;
      bool isPremium = _random.nextBool() && _random.nextBool(); // 25% chance
      
      // Select random source
      final sources = [
        'Ethiopian Business Journal',
        'Addis Fortune',
        'Capital Ethiopia',
        'The Reporter Ethiopia',
        'Ethiopian Herald',
        'Bloomberg',
        'Reuters',
        'Financial Times'
      ];
      source = sources[_random.nextInt(sources.length)];
      
      // Generate random image URL
      final imageId = 1000 + _random.nextInt(1000);
      imageUrl = 'https://picsum.photos/id/$imageId/800/450';
      
      // Generate headline and content based on company type
      final isPositive = _random.nextBool();
      final changePercent = (5 + _random.nextInt(20)).toString();
      
      if (daysAgo < 7) { // Recent news more likely to be about earnings
        if (isPositive) {
          headline = '$companyName reports $changePercent% increase in quarterly profit';
          content = '$companyName announced a $changePercent% increase in quarterly profit, exceeding analyst expectations. The company attributed the strong performance to increased customer demand and strategic investments in new markets. Executives expressed optimism about continued growth in the coming quarters.';
        } else {
          headline = '$companyName shares drop after disappointing earnings report';
          content = '$companyName shares fell after the company reported earnings below analyst expectations. The company cited challenging market conditions and increased competition as factors affecting performance. Management outlined plans to address these challenges through cost-cutting measures and strategic realignment.';
        }
      } else { // Older news more likely to be about general business
        final newsTypes = [
          'announces new partnership with',
          'plans expansion into',
          'appoints new CEO',
          'launches innovative product in',
          'faces regulatory scrutiny over',
          'completes acquisition of',
          'invests in sustainable initiatives',
          'restructures operations to improve efficiency',
        ];
        
        final newsType = newsTypes[_random.nextInt(newsTypes.length)];
        headline = '$companyName $newsType${newsType.endsWith('with') || newsType.endsWith('into') || newsType.endsWith('over') ? ' major industry player' : ''}';
        content = 'In a strategic move, $companyName $newsType${newsType.endsWith('with') || newsType.endsWith('into') || newsType.endsWith('over') ? ' a major industry player' : ''}. This development is expected to strengthen the company\'s market position and create new opportunities for growth. Industry analysts view this as a significant step for the company\'s long-term strategy.';
      }
      
      news.add({
        'id': 'NEWS_${symbol}_${i}_${publishDate.millisecondsSinceEpoch}',
        'headline': headline,
        'summary': '${content.substring(0, content.length > 100 ? 100 : content.length)}...',
        'content': content,
        'publishDate': publishDate.toIso8601String(),
        'source': source,
        'imageUrl': imageUrl,
        'relatedSymbols': [symbol],
        'isPremium': isPremium,
        'url': 'https://ethiotrading.com/news/${symbol.toLowerCase()}/${publishDate.millisecondsSinceEpoch}',
      });
    }
    
    // Sort by publish date (newest first)
    news.sort((a, b) => DateTime.parse(b['publishDate']).compareTo(DateTime.parse(a['publishDate'])));
    
    return news;
  }
}

class MockPortfolio {
  static Map<String, dynamic> generateMockPortfolioData() {
    final random = Random();
    final assets = MockDataGenerator.generateMockAssets();
    double totalValue = 0;
    double totalGain = 0;

    final holdings = assets.take(5).map((asset) {
      final quantity = (50 + random.nextInt(950)).toDouble();
      final value = quantity * asset.price;
      final avgPrice = asset.price * (1 - (random.nextDouble() * 0.1));
      final gain = (asset.price - avgPrice) * quantity;

      totalValue += value;
      totalGain += gain;

      return {
        'asset': asset,
        'quantity': quantity,
        'value': value,
        'avgPrice': avgPrice,
        'gain': gain,
        'lastUpdated':
            DateTime.now().subtract(Duration(minutes: random.nextInt(60))),
      };
    }).toList();

    // Generate realistic transaction history
    final transactions = _generateRealisticTransactions(assets, holdings);

    return {
      'holdings': holdings,
      'transactions': transactions,
      'totalValue': totalValue,
      'totalGain': totalGain,
      'todayGain': _calculateTodayGain(holdings),
      'metadata': {
        'lastUpdated': DateTime.now().toIso8601String(),
        'currency': 'ETB',
        'marketStatus': EthiopianMarketHours.getMarketStatus(),
      }
    };
  }

  static List<Map<String, dynamic>> _generateRealisticTransactions(
      List<Asset> assets, List<Map<String, dynamic>> holdings) {
    final random = Random();
    final transactions = <Map<String, dynamic>>[];
    final now = DateTime.now();

    // Generate recent transactions based on holdings
    for (final holding in holdings) {
      final asset = holding['asset'] as Asset;
      final quantity = holding['quantity'] as double;

      // Split total quantity into multiple buy transactions
      double remainingQuantity = quantity;
      while (remainingQuantity > 0) {
        final txnQuantity = min(
          remainingQuantity,
          random.nextDouble() * 100 + 50,
        );
        remainingQuantity -= txnQuantity;

        transactions.add({
          'asset': asset,
          'type': 'buy',
          'quantity': txnQuantity,
          'price': asset.price * (1 + (random.nextDouble() * 0.1 - 0.05)),
          'timestamp': now.subtract(Duration(
            days: random.nextInt(30),
            hours: random.nextInt(24),
            minutes: random.nextInt(60),
          )),
        });
      }

      // Add some sell transactions
      if (random.nextBool()) {
        final sellQuantity = quantity * (random.nextDouble() * 0.3);
        transactions.add({
          'asset': asset,
          'type': 'sell',
          'quantity': sellQuantity,
          'price': asset.price * (1 + (random.nextDouble() * 0.1 - 0.05)),
          'timestamp': now.subtract(Duration(
            days: random.nextInt(15),
            hours: random.nextInt(24),
            minutes: random.nextInt(60),
          )),
        });
      }
    }

    // Sort transactions by timestamp
    transactions.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    return transactions;
  }

  static double _calculateTodayGain(List<Map<String, dynamic>> holdings) {
    double todayGain = 0;
    for (final holding in holdings) {
      final asset = holding['asset'] as Asset;
      final quantity = holding['quantity'] as double;
      todayGain += quantity * (asset.price - (asset.openPrice ?? asset.price));
    }
    return todayGain;
  }
}

class MockData {
  List<Map<String, dynamic>> getEthiopianMarketData() {
    return [
      {
        'symbol': 'COBE',
        'name': 'Commercial Bank of Ethiopia',
        'price': 52.5,
        'change': 1.2,
        'changePercent': 2.34,
        'volume': 120000.0,
        'marketCap': 8500000000.0,
        'sector': 'Banking',
        'ownership': 'Public',
      },
      {
        'symbol': 'EABL',
        'name': 'Ethiopian Agricultural Business Limited',
        'price': 128.75,
        'change': -0.85,
        'changePercent': -0.66,
        'volume': 75000.0,
        'marketCap': 5250000000.0,
        'sector': 'Agriculture',
        'ownership': 'Private',
      },
      {
        'symbol': 'ETINS',
        'name': 'Ethiopian Insurance Corporation',
        'price': 84.30,
        'change': 0.55,
        'changePercent': 0.66,
        'volume': 65000.0,
        'marketCap': 3800000000.0,
        'sector': 'Insurance',
        'ownership': 'Mixed',
      },
      {
        'symbol': 'ETAIR',
        'name': 'Ethiopian Airlines Group',
        'price': 324.50,
        'change': 4.25,
        'changePercent': 1.32,
        'volume': 42000.0,
        'marketCap': 12500000000.0,
        'sector': 'Transportation',
        'ownership': 'Public',
      },
      {
        'symbol': 'ETTEL',
        'name': 'Ethio Telecom',
        'price': 145.75,
        'change': -2.25,
        'changePercent': -1.52,
        'volume': 90000.0,
        'marketCap': 15000000000.0,
        'sector': 'Telecommunications',
        'ownership': 'Public',
      },
      {
        'symbol': 'ETSUGAR',
        'name': 'Ethiopian Sugar Corporation',
        'price': 37.20,
        'change': 0.40,
        'changePercent': 1.09,
        'volume': 55000.0,
        'marketCap': 2800000000.0,
        'sector': 'Consumer Staples',
        'ownership': 'Public',
      },
      {
        'symbol': 'ETCON',
        'name': 'Ethiopian Construction Works Corporation',
        'price': 65.80,
        'change': -1.20,
        'changePercent': -1.79,
        'volume': 38000.0,
        'marketCap': 4200000000.0,
        'sector': 'Construction',
        'ownership': 'Public',
      },
    ];
  }
}
