import 'package:flutter/material.dart';
import '../data/ethio_data.dart';
import '../utils/ethiopian_utils.dart';
import 'stock_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<Map<String, dynamic>> _marketData;
  late bool _isMarketOpen;

  @override
  void initState() {
    super.initState();
    _marketData = EthioData.generateMockEthioMarketData();
    _isMarketOpen = EthiopianMarketHours.isMarketOpen();
  }

  Widget _buildMarketOverview(ThemeData theme) {
    final marketIndex = _calculateMarketIndex();
    final isPositive = marketIndex['change'] > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'የኢትዮጵያ ገበያ አመልካች', // Ethiopian Market Index
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      EthiopianCurrencyFormatter.format(marketIndex['value']),
                      style: theme.textTheme.headlineSmall,
                    ),
                    Text(
                      '${isPositive ? '+' : ''}${marketIndex['change'].toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: isPositive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isMarketOpen
                        ? Colors.green.withAlpha((0.1 * 255).round())
                        : Colors.grey.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isMarketOpen ? Icons.circle : Icons.circle_outlined,
                        size: 12,
                        color: _isMarketOpen ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        EthiopianMarketHours.getMarketStatus(),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectorPerformance(ThemeData theme) {
    final sectors = _calculateSectorPerformance();
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'የዘርፍ አፈጻጸም', // Sector Performance
              style: theme.textTheme.titleLarge,
            ),
          ),
          ...sectors.entries.map((entry) {
            final isPositive = entry.value > 0;
            return ListTile(
              title: Text(entry.key),
              trailing: Text(
                '${isPositive ? '+' : ''}${entry.value.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopMovers(ThemeData theme) {
    final gainers = List.from(_marketData)
      ..sort(
          (a, b) => (b['change'] as double).compareTo(a['change'] as double));
    final losers = List.from(_marketData)
      ..sort(
          (a, b) => (a['change'] as double).compareTo(b['change'] as double));

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'ከፍተኛ እንቅስቃሴ ያላቸው', // Top Movers
              style: theme.textTheme.titleLarge,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...gainers
                    .take(3)
                    .map((stock) => _buildStockCard(stock, theme, true)),
                ...losers
                    .take(3)
                    .map((stock) => _buildStockCard(stock, theme, false)),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStockCard(
      Map<String, dynamic> stock, ThemeData theme, bool isGainer) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StockDetailScreen(stockData: stock),
        ),
      ),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(left: 16),
        child: Card(
          color: theme.colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stock['symbol'],
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  EthiopianCurrencyFormatter.format(stock['price']),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${stock['change'] >= 0 ? '+' : ''}${stock['change'].toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: stock['change'] >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, double> _calculateSectorPerformance() {
    final sectorPerformance = <String, List<double>>{};

    for (final stock in _marketData) {
      final sector = stock['sector'] as String;
      sectorPerformance.putIfAbsent(sector, () => []);
      sectorPerformance[sector]!.add(stock['change'] as double);
    }

    return Map.fromEntries(
      sectorPerformance.entries.map(
        (entry) => MapEntry(
          entry.key,
          entry.value.reduce((a, b) => a + b) / entry.value.length,
        ),
      ),
    );
  }

  Map<String, dynamic> _calculateMarketIndex() {
    double totalValue = 0;
    double totalChange = 0;

    for (final stock in _marketData) {
      totalValue += stock['price'] as double;
      totalChange += stock['change'] as double;
    }

    return {
      'value': totalValue,
      'change': totalChange / _marketData.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('መነሻ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('የማሳወቂያ ባህሪ በቅርብ ጊዜ ይጨመራል'),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _marketData = EthioData.generateMockEthioMarketData();
            _isMarketOpen = EthiopianMarketHours.isMarketOpen();
          });
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildMarketOverview(theme),
            const SizedBox(height: 16),
            _buildTopMovers(theme),
            const SizedBox(height: 16),
            _buildSectorPerformance(theme),
          ],
        ),
      ),
    );
  }
}
