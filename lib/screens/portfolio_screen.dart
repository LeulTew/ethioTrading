import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../data/mock_data.dart';
import '../providers/language_provider.dart';
// Removed unused import: '../providers/portfolio_provider.dart'
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../models/asset.dart';
import 'package:google_fonts/google_fonts.dart';

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
  List<Asset> _purchasedAssets = [];
  double _totalValue = 0;
  double _todayGain = 0;
  double _totalGain = 0;
  bool _isLoading = true;
  int _selectedTimeRange = 1; // 0: 1D, 1: 1W, 2: 1M, 3: 3M, 4: 1Y, 5: ALL

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _generateMockPortfolioData();
    _loadPurchasedAssets();

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
    });
  }

  Future<void> _loadPurchasedAssets() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      try {
        // In a real app, fetch the purchased assets from the portfolio provider
        // For now, we'll just set _isLoading to false
        // final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);
        // _purchasedAssets = await portfolioProvider.getPurchasedAssets();

        // Simulate loading purchased assets
        await Future.delayed(const Duration(milliseconds: 500));

        // Mock purchased assets - this would come from the portfolio provider in a real app
        _purchasedAssets = [];
      } catch (e) {
        debugPrint('Error loading purchased assets: $e');
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormatter =
        NumberFormat.currency(locale: 'am_ET', symbol: 'ETB', decimalDigits: 2);
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      // Remove the app bar to eliminate the back button
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme, lang),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TabBar(
                controller: _tabController,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurface
                    .withAlpha(60), // Fixed: 0.6 -> 60
                indicatorColor: theme.colorScheme.primary,
                tabs: [
                  Tab(text: lang.translate('overview')),
                  Tab(text: lang.translate('holdings')),
                  Tab(text: lang.translate('history')),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(theme, currencyFormatter, lang),
                        _buildHoldingsTab(theme, currencyFormatter, lang),
                        _buildTransactionsTab(theme, currencyFormatter, lang),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            lang.translate('portfolio'),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.sync, color: theme.colorScheme.primary),
                onPressed: () {
                  setState(() => _isLoading = true);
                  _loadPurchasedAssets();
                },
                tooltip: lang.translate('refresh'),
              ),
              IconButton(
                icon: Icon(Icons.more_vert, color: theme.colorScheme.primary),
                onPressed: () => _showOptionsMenu(context, lang),
                tooltip: lang.translate('more_options'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu(BuildContext context, LanguageProvider lang) {
    final theme = Theme.of(context);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          MediaQuery.of(context).size.width - 40, 80, 20, 0),
      items: [
        PopupMenuItem(
          value: 'export',
          child: Row(
            children: [
              Icon(Icons.download, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(lang.translate('export_portfolio')),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(lang.translate('portfolio_settings')),
            ],
          ),
        ),
      ],
      elevation: 8,
    ).then((value) {
      if (value == 'export') {
        // Export portfolio functionality
      } else if (value == 'settings') {
        // Portfolio settings functionality
      }
    });
  }

  Widget _buildOverviewTab(
      ThemeData theme, NumberFormat currencyFormatter, LanguageProvider lang) {
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
                  color: Colors.black.withAlpha(25), // Fixed: 0.1 -> 25
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
                    color: Colors.white.withAlpha(25), // Fixed: 0.1 -> 25
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.translate('portfolio_value'),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormatter.format(_totalValue),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildGainLossWidget(
                              lang.translate('today'),
                              _todayGain,
                              isPositiveTodayGain,
                              theme,
                              currencyFormatter,
                            ),
                            _buildGainLossWidget(
                              lang.translate('total_return'),
                              _totalGain,
                              isPositiveTotalGain,
                              theme,
                              currencyFormatter,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTimeRangeSelector(theme, lang),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildPortfolioChart(theme, lang),
          const SizedBox(height: 20),
          _buildDistributionChart(theme, lang),

          // Display purchased assets section if available
          if (_purchasedAssets.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildPurchasedAssetsSection(theme, currencyFormatter, lang),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector(ThemeData theme, LanguageProvider lang) {
    final ranges = ['1D', '1W', '1M', '3M', '1Y', 'ALL'];

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38), // Fixed: 0.15 -> 38
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: List.generate(ranges.length, (index) {
          final isSelected = index == _selectedTimeRange;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTimeRange = index;
                  // Update chart data based on selected time range
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  ranges[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? AppTheme.primaryGradient.first
                        : Colors.white,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGainLossWidget(String label, double value, bool isPositive,
      ThemeData theme, NumberFormat currencyFormatter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            color: Colors.white.withAlpha(230), // Fixed: 0.9 -> 230
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              isPositive ? Icons.arrow_upward : Icons.arrow_downward,
              color: isPositive ? Colors.greenAccent : Colors.redAccent,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              currencyFormatter.format(value.abs()),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isPositive ? Colors.greenAccent : Colors.redAccent,
              ),
            ),
          ],
        ),
        Text(
          '${isPositive ? '+' : '-'}${(value.abs() / _totalValue * 100).toStringAsFixed(2)}%',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            color: isPositive ? Colors.greenAccent : Colors.redAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioChart(ThemeData theme, LanguageProvider lang) {
    final spots = List<FlSpot>.generate(
      30,
      (index) => FlSpot(
        index.toDouble(),
        _totalValue * (1 + (index / 100) * (0.5 + math.Random().nextDouble())),
      ),
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.translate('portfolio_performance'),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
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
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat.MMMd().format(DateTime.now()
                                    .subtract(
                                        Duration(days: 30 - value.toInt()))),
                                style: GoogleFonts.spaceGrotesk(fontSize: 10),
                              ),
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
                          color: theme.colorScheme.primary
                              .withAlpha(25)), // Fixed: 0.1 -> 25
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

  Widget _buildDistributionChart(ThemeData theme, LanguageProvider lang) {
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.translate('sector_distribution'),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: sectorPercentages.entries.map((entry) {
                final color = _getSectorColor(entry.key, theme);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                lang.translate(entry.key.toLowerCase()),
                                style: GoogleFonts.spaceGrotesk(),
                              ),
                            ],
                          ),
                          Text('${entry.value}%',
                              style: GoogleFonts.spaceGrotesk()),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: entry.value / 100,
                          backgroundColor:
                              color.withAlpha(25), // Fixed: 0.1 -> 25
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 8,
                        ),
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

  Color _getSectorColor(String sector, ThemeData theme) {
    switch (sector) {
      case 'Banking':
        return Colors.blue;
      case 'Technology':
        return Colors.purple;
      case 'Manufacturing':
        return Colors.orange;
      case 'Transport':
        return Colors.green;
      case 'Energy':
        return Colors.red;
      case 'Telecommunication':
        return Colors.teal;
      default:
        return theme.colorScheme.primary;
    }
  }

  Widget _buildPurchasedAssetsSection(
      ThemeData theme, NumberFormat currencyFormatter, LanguageProvider lang) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.translate('purchased_assets'),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_purchasedAssets.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    lang.translate('no_purchased_assets'),
                    style: GoogleFonts.spaceGrotesk(
                      color: theme.colorScheme.onSurface
                          .withAlpha(153), // Fixed: 0.6 -> 153
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _purchasedAssets.length,
                itemBuilder: (context, index) {
                  final asset = _purchasedAssets[index];
                  // In a real app you would get these values from the portfolio data
                  final price = asset.price;
                  const quantity = 10; // Mock value
                  final value = price * quantity;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      asset.name,
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '$quantity ${lang.translate('shares')} @ ${asset.formattedPrice}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyFormatter.format(value),
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          asset.formattedChangePercent,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            color:
                                asset.change >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoldingsTab(
      ThemeData theme, NumberFormat currencyFormatter, LanguageProvider lang) {
    if (_holdings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 48,
              color:
                  theme.colorScheme.primary.withAlpha(128), // Fixed: 0.5 -> 128
            ),
            const SizedBox(height: 16),
            Text(
              lang.translate('no_holdings'),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface
                    .withAlpha(178), // Fixed: 0.7 -> 178
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _holdings.length,
      itemBuilder: (context, index) {
        final holding = _holdings[index];
        final asset = holding['asset'];
        final value = holding['value'];
        final gain = holding['gain'];
        final isPositive = gain >= 0;
        final quantity = holding['quantity'];

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon or logo
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary
                            .withAlpha(178), // Fixed: 0.7 -> 178
                        theme.colorScheme.primary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      asset.symbol.substring(0, 1),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Asset details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asset.name,
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '$quantity ${lang.translate('shares')}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface
                              .withAlpha(178), // Fixed: 0.7 -> 178
                        ),
                      ),
                    ],
                  ),
                ),
                // Value and change
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormatter.format(value),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: isPositive ? Colors.green : Colors.red,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${isPositive ? "+" : ""}${currencyFormatter.format(gain)} (${(gain / (value - gain) * 100).toStringAsFixed(2)}%)',
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
      ThemeData theme, NumberFormat currencyFormatter, LanguageProvider lang) {
    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color:
                  theme.colorScheme.primary.withAlpha(128), // Fixed: 0.5 -> 128
            ),
            const SizedBox(height: 16),
            Text(
              lang.translate('no_transactions'),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface
                    .withAlpha(178), // Fixed: 0.7 -> 178
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        final asset = transaction['asset'];
        final isBuy = transaction['type'] == 'buy';
        final amount = transaction['price'] * transaction['quantity'];
        final date = transaction['timestamp'];

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: isBuy
                  ? Colors.green.withAlpha(25) // Fixed: 0.1 -> 25
                  : Colors.red.withAlpha(25), // Fixed: 0.1 -> 25
              child: Icon(
                isBuy ? Icons.add : Icons.remove,
                color: isBuy ? Colors.green : Colors.red,
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  asset.name,
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  currencyFormatter.format(amount),
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat.yMMMd().add_jm().format(date),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface
                            .withAlpha(178), // Fixed: 0.7 -> 178
                      ),
                    ),
                    Text(
                      '${transaction['quantity']} ${lang.translate('shares')} @ ${currencyFormatter.format(transaction['price'])}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface
                            .withAlpha(178), // Fixed: 0.7 -> 178
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () {
              // Show transaction details
            },
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
