import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../data/mock_data.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final List<Map<String, dynamic>> _holdings = [];
  final List<Map<String, dynamic>> _transactions = [];
  double _totalValue = 0;
  double _todayGain = 0;
  double _totalGain = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _generateMockPortfolioData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LanguageProvider>(context, listen: false)
          .initializeLanguage();
    });
  }

  void _generateMockPortfolioData() {
    final portfolioData = MockPortfolio.generateMockPortfolioData();
    setState(() {
      _holdings
          .addAll(List<Map<String, dynamic>>.from(portfolioData['holdings']));
      _transactions.addAll(
          List<Map<String, dynamic>>.from(portfolioData['transactions']));
      _totalValue = portfolioData['totalValue'];
      _todayGain = portfolioData['todayGain'];
      _totalGain = portfolioData['totalGain'];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormatter =
        NumberFormat.currency(locale: 'am_ET', symbol: 'ETB', decimalDigits: 2);
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('portfolio')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: lang.translate('overview')),
            Tab(text: lang.translate('holdings')),
            Tab(text: lang.translate('history')),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(theme, currencyFormatter),
                _buildHoldingsTab(theme, currencyFormatter),
                _buildTransactionsTab(theme, currencyFormatter),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // Portfolio is selected
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: lang.translate('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.show_chart),
            label: lang.translate('market'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet),
            label: lang.translate('portfolio'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: lang.translate('profile'),
          ),
        ],
        onTap: (index) {
          if (index != 2) {
            // Navigate to the appropriate screen
            final routes = ['/home', '/market', '/portfolio', '/profile'];
            Navigator.pushReplacementNamed(context, routes[index]);
          }
        },
      ),
    );
  }

  Widget _buildOverviewTab(ThemeData theme, NumberFormat currencyFormatter) {
    final isPositiveTodayGain = _todayGain >= 0;
    final isPositiveTotalGain = _totalGain >= 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppTheme.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 26),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 26),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Portfolio Value',
                            style: theme.textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormatter.format(_totalValue),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildGainLossWidget(
                              'Today',
                              _todayGain,
                              isPositiveTodayGain,
                              theme,
                              currencyFormatter,
                            ),
                            _buildGainLossWidget(
                              'Total Return',
                              _totalGain,
                              isPositiveTotalGain,
                              theme,
                              currencyFormatter,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildPortfolioChart(theme),
                        const SizedBox(height: 16),
                        _buildDistributionChart(theme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGainLossWidget(String label, double value, bool isPositive,
      ThemeData theme, NumberFormat currencyFormatter) {
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
              currencyFormatter.format(value.abs()),
              style: theme.textTheme.titleMedium?.copyWith(
                color: isPositive ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(
          '${isPositive ? '+' : '-'}${(value.abs() / _totalValue * 100).toStringAsFixed(2)}%',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isPositive ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioChart(ThemeData theme) {
    final spots = List<FlSpot>.generate(
      30,
      (index) => FlSpot(
        index.toDouble(),
        _totalValue * (1 + (index / 100)),
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Portfolio Performance', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value % 7 == 0) {
                            return Text(
                              DateFormat.MMMd().format(DateTime.now().subtract(
                                  Duration(days: 30 - value.toInt()))),
                              style: theme.textTheme.bodySmall,
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                          show: true,
                          color:
                              theme.colorScheme.primary.withValues(alpha: 26)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionChart(ThemeData theme) {
    final sectors = <String, double>{};
    for (final holding in _holdings) {
      final asset = holding['asset'];
      final sector = asset.sector;
      sectors[sector] = (sectors[sector] ?? 0) + holding['value'];
    }

    final total = sectors.values.fold(0.0, (sum, value) => sum + value);
    final sectorPercentages = sectors.map(
      (sector, value) =>
          MapEntry(sector, (value / total * 100).roundToDouble()),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sector Distribution', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Column(
              children: sectorPercentages.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key, style: theme.textTheme.bodyMedium),
                          Text('${entry.value}%',
                              style: theme.textTheme.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: entry.value / 100,
                        backgroundColor:
                            theme.colorScheme.primary.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoldingsTab(ThemeData theme, NumberFormat currencyFormatter) {
    return ListView.builder(
      itemCount: _holdings.length,
      itemBuilder: (context, index) {
        final holding = _holdings[index];
        final asset = holding['asset'];
        final value = holding['value'];
        final gain = holding['gain'];
        final isPositive = gain >= 0;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(asset.name),
            subtitle: Text(asset.symbol),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormatter.format(value),
                  style: theme.textTheme.titleMedium,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isPositive ? Colors.green : Colors.red,
                      size: 12,
                    ),
                    Text(
                      currencyFormatter.format(gain.abs()),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionsTab(
      ThemeData theme, NumberFormat currencyFormatter) {
    return ListView.builder(
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        final asset = transaction['asset'];
        final isBuy = transaction['type'] == 'buy';
        final amount = transaction['price'] * transaction['quantity'];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isBuy
                  ? Colors.green.withValues(alpha: 26)
                  : Colors.red.withValues(alpha: 26),
              child: Icon(
                isBuy ? Icons.add : Icons.remove,
                color: isBuy ? Colors.green : Colors.red,
              ),
            ),
            title: Text(asset.name),
            subtitle: Text(
              DateFormat.yMMMd().add_jm().format(transaction['timestamp']),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormatter.format(amount),
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  '${transaction['quantity']} shares @ ${currencyFormatter.format(transaction['price'])}',
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
