import 'package:flutter/material.dart';
import '../utils/ethiopian_utils.dart';
import '../data/ethio_data.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Map<String, dynamic>> _holdings = [];
  final List<Map<String, dynamic>> _transactions = [];
  double _totalValue = 0;
  double _todayGain = 0;
  double _totalGain = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _generateMockPortfolioData();
  }

  void _generateMockPortfolioData() {
    final marketData = EthioData.generateMockEthioMarketData();

    // Generate holdings
    for (var i = 0; i < 5; i++) {
      final stock = marketData[i];
      final quantity = (10 + i * 5).toDouble();
      final value = quantity * stock['price'];

      _holdings.add({
        ...stock,
        'quantity': quantity,
        'value': value,
        'avgPrice': stock['price'] - (stock['price'] * stock['change'] / 100),
      });
    }

    // Generate transactions
    final transactionTypes = ['buy', 'sell'];
    for (var i = 0; i < 10; i++) {
      final stock = marketData[i % marketData.length];
      final type = transactionTypes[i % 2];
      final quantity = (5 + i).toDouble();
      final price = stock['price'] - (i * 2);

      _transactions.add({
        ...stock,
        'type': type,
        'quantity': quantity,
        'price': price,
        'date': DateTime.now().subtract(Duration(days: i)),
        'total': quantity * price,
      });
    }

    // Calculate portfolio metrics
    _totalValue = _holdings.fold(0, (sum, holding) => sum + holding['value']);
    _todayGain = _holdings.fold(
        0,
        (sum, holding) =>
            sum +
            (holding['price'] - holding['avgPrice']) * holding['quantity']);
    _totalGain = _holdings.fold(
        0,
        (sum, holding) =>
            sum +
            (holding['price'] - holding['avgPrice']) * holding['quantity']);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ፖርትፎሊዮ'), // Portfolio in Amharic
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'አጠቃላይ'), // Overview
            Tab(text: 'ንብረቶች'), // Holdings
            Tab(text: 'ግብይቶች'), // Transactions
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(theme),
          _buildHoldingsTab(theme),
          _buildTransactionsTab(theme),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(ThemeData theme) {
    final isPositiveTodayGain = _todayGain >= 0;
    final isPositiveTotalGain = _totalGain >= 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ጠቅላላ እሴት',
                      style: theme.textTheme.titleMedium), // Total Value
                  const SizedBox(height: 8),
                  Text(
                    EthiopianCurrencyFormatter.format(_totalValue),
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildGainLossWidget(
                        'የዛሬ ለውጥ', // Today's Change
                        _todayGain,
                        isPositiveTodayGain,
                        theme,
                      ),
                      _buildGainLossWidget(
                        'ጠቅላላ ለውጥ', // Total Change
                        _totalGain,
                        isPositiveTotalGain,
                        theme,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('የንብረት ስርጭት',
              style: theme.textTheme.titleLarge), // Asset Distribution
          const SizedBox(height: 16),
          _buildDistributionChart(theme),
        ],
      ),
    );
  }

  Widget _buildGainLossWidget(
      String label, double value, bool isPositive, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              isPositive ? Icons.arrow_upward : Icons.arrow_downward,
              color: isPositive ? Colors.green : Colors.red,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              EthiopianCurrencyFormatter.format(value.abs()),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isPositive ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDistributionChart(ThemeData theme) {
    final sectors = <String, double>{};
    for (final holding in _holdings) {
      final sector = holding['sector'] as String;
      sectors[sector] = (sectors[sector] ?? 0) + holding['value'];
    }

    return Column(
      children: sectors.entries.map((entry) {
        final percentage = (entry.value / _totalValue * 100).toStringAsFixed(1);
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: (entry.value / _totalValue * 100).round(),
                  child: Container(
                    height: 24,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Expanded(
                  flex: 100 - (entry.value / _totalValue * 100).round(),
                  child: Text('$percentage% ${entry.key}'),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildHoldingsTab(ThemeData theme) {
    return ListView.builder(
      itemCount: _holdings.length,
      itemBuilder: (context, index) {
        final holding = _holdings[index];
        final gainLoss =
            (holding['price'] - holding['avgPrice']) * holding['quantity'];
        final isPositive = gainLoss >= 0;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(holding['name']),
            subtitle: Text(
                '${holding['quantity'].toStringAsFixed(0)} አክሲዮኖች'), // shares
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  EthiopianCurrencyFormatter.format(holding['value']),
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  '${isPositive ? '+' : ''}${EthiopianCurrencyFormatter.format(gainLoss)}',
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionsTab(ThemeData theme) {
    return ListView.builder(
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        final isBuy = transaction['type'] == 'buy';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isBuy
                  ? Colors.green.withAlpha((0.1 * 255).round())
                  : Colors.red.withAlpha((0.1 * 255).round()),
              child: Icon(
                isBuy ? Icons.add : Icons.remove,
                color: isBuy ? Colors.green : Colors.red,
              ),
            ),
            title: Text(transaction['name']),
            subtitle: Text(
              '${transaction['quantity'].toStringAsFixed(0)} አክሲዮኖች @ ${EthiopianCurrencyFormatter.format(transaction['price'])}',
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  EthiopianCurrencyFormatter.format(transaction['total']),
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  transaction['date'].toString().split(' ')[0],
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
