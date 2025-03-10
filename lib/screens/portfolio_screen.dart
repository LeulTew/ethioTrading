import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/language_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/portfolio_provider.dart';
import '../providers/market_provider.dart';
import '../widgets/custom_bottom_nav.dart';
import 'package:google_fonts/google_fonts.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});
  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPortfolioData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LanguageProvider>(context, listen: false)
          .initializeLanguage();
    });
  }

  Future<void> _loadPortfolioData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final portfolioProvider =
        Provider.of<PortfolioProvider>(context, listen: false);
    final marketProvider = Provider.of<MarketProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      // Check mounted here before setting state
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to view your portfolio')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create a map of assets for quick lookup
      final allAssets = [
        ...marketProvider.ethiopianAssets,
        ...marketProvider.internationalAssets
      ];
      final marketAssets = {for (var asset in allAssets) asset.symbol: asset};

      // Load portfolio data
      await portfolioProvider.fetchPortfolio(marketAssets: marketAssets);
    } catch (e) {
      // Check mounted before showing SnackBar
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    // Check mounted again before setting state
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormatter =
        NumberFormat.currency(locale: 'am_ET', symbol: 'ETB', decimalDigits: 2);
    final lang = Provider.of<LanguageProvider>(context);
    final portfolioProvider = Provider.of<PortfolioProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lang.translate('portfolio'),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        automaticallyImplyLeading: false, // Prevent back button
        actions: [
          IconButton(
            icon: Icon(Icons.sync, color: theme.colorScheme.primary),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadPortfolioData();
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
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: lang.translate('overview')),
              Tab(text: lang.translate('holdings')),
              Tab(text: lang.translate('transactions')),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                constraints:
                                    const BoxConstraints(maxWidth: 600),
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lang.translate(
                                              'total_portfolio_value'),
                                          style: theme.textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          currencyFormatter.format(
                                              portfolioProvider.totalValue),
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            _buildGainLossWidget(
                                              lang.translate('today'),
                                              portfolioProvider.todayGain,
                                              portfolioProvider.todayGain >= 0,
                                              theme,
                                              currencyFormatter,
                                            ),
                                            _buildGainLossWidget(
                                              lang.translate('total'),
                                              portfolioProvider.totalGain,
                                              portfolioProvider.totalGain >= 0,
                                              theme,
                                              currencyFormatter,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildPortfolioChart(
                                  theme, lang, portfolioProvider),
                              const SizedBox(height: 24),
                              _buildDistributionChart(
                                  theme, lang, portfolioProvider),
                              if (portfolioProvider
                                  .purchasedAssets.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                _buildPurchasedAssetsSection(theme,
                                    currencyFormatter, lang, portfolioProvider),
                              ],
                            ],
                          ),
                        ),
                      ),
                _buildHoldingsTab(
                    theme, currencyFormatter, lang, portfolioProvider),
                _buildTransactionsTab(
                    theme, currencyFormatter, lang, portfolioProvider),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 2, // Portfolio is selected
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
          '${isPositive ? '+' : '-'}${(value.abs() / value * 100).toStringAsFixed(2)}%',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            color: isPositive ? Colors.greenAccent : Colors.redAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioChart(ThemeData theme, LanguageProvider lang,
      PortfolioProvider portfolioProvider) {
    final spots = List<FlSpot>.generate(
      30,
      (index) => FlSpot(
        index.toDouble(),
        portfolioProvider.totalValue *
            (1 + (index / 100) * (0.5 + math.Random().nextDouble())),
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

  Widget _buildDistributionChart(ThemeData theme, LanguageProvider lang,
      PortfolioProvider portfolioProvider) {
    final sectors = <String, double>{};
    for (final holding in portfolioProvider.holdings) {
      final asset = holding.asset;
      final sector = asset.sector;
      sectors[sector] = (sectors[sector] ?? 0) + holding.value;
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
      ThemeData theme,
      NumberFormat currencyFormatter,
      LanguageProvider lang,
      PortfolioProvider portfolioProvider) {
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
            if (portfolioProvider.purchasedAssets.isEmpty)
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
                itemCount: portfolioProvider.purchasedAssets.length,
                itemBuilder: (context, index) {
                  final asset = portfolioProvider.purchasedAssets[index];
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

  Widget _buildHoldingsTab(ThemeData theme, NumberFormat currencyFormatter,
      LanguageProvider lang, PortfolioProvider portfolioProvider) {
    if (portfolioProvider.holdings.isEmpty) {
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
      itemCount: portfolioProvider.holdings.length,
      itemBuilder: (context, index) {
        final holding = portfolioProvider.holdings[index];
        final asset = holding.asset;
        final value = holding.value;
        final gain = holding.gain;
        final isPositive = gain >= 0;
        final quantity = holding.quantity;

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

  Widget _buildTransactionsTab(ThemeData theme, NumberFormat currencyFormatter,
      LanguageProvider lang, PortfolioProvider portfolioProvider) {
    if (portfolioProvider.transactions.isEmpty) {
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
      itemCount: portfolioProvider.transactions.length,
      itemBuilder: (context, index) {
        final transaction = portfolioProvider.transactions[index];
        final asset = transaction.asset;
        final isBuy = transaction.type == 'buy';
        final amount = transaction.price * transaction.quantity;
        final date = transaction.timestamp;

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
                      '${transaction.quantity} ${lang.translate('shares')} @ ${currencyFormatter.format(transaction.price)}',
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
