import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:ui';
import '../data/ethio_data.dart';
import '../utils/ethiopian_utils.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import 'stock_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late List<Map<String, dynamic>> _marketData;
  late bool _isMarketOpen;
  late Timer _refreshTimer;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _marketData = EthioData.generateMockEthioMarketData();
    _isMarketOpen = EthiopianMarketHours.isMarketOpen();

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationController.forward();

    // Auto refresh market data every 30 seconds if market is open
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isMarketOpen) {
        _refreshMarketData();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _refreshMarketData() async {
    setState(() {
      _marketData = EthioData.generateMockEthioMarketData();
      _isMarketOpen = EthiopianMarketHours.isMarketOpen();
    });
  }

  Widget _buildMarketOverview(ThemeData theme, LanguageProvider lang) {
    final marketIndex = _calculateMarketIndex();
    final isPositive = marketIndex['change'] > 0;
    final marketStats = EthioData.getMarketStatistics(_marketData);

    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppTheme.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.translate('market_index'),
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              EthiopianCurrencyFormatter.format(
                                  marketIndex['value']),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  isPositive
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color: isPositive ? Colors.green : Colors.red,
                                  size: 16,
                                ),
                                Text(
                                  '${isPositive ? '+' : ''}${marketIndex['change'].toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    color:
                                        isPositive ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        _buildMarketStatusBadge(theme, lang),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildMarketStats(theme, marketStats, lang),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarketStats(
      ThemeData theme, Map<String, dynamic> stats, LanguageProvider lang) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildStatItem(
          theme,
          lang.translate('volume'),
          EthiopianCurrencyFormatter.formatVolume(stats['totalVolume']),
          Icons.bar_chart,
        ),
        _buildStatItem(
          theme,
          lang.translate('advancers'),
          stats['advancers'].toString(),
          Icons.trending_up,
          color: Colors.green,
        ),
        _buildStatItem(
          theme,
          lang.translate('decliners'),
          stats['decliners'].toString(),
          Icons.trending_down,
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatItem(
      ThemeData theme, String label, String value, IconData icon,
      {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (color ?? theme.colorScheme.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color ?? theme.colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketStatusBadge(ThemeData theme, LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isMarketOpen
            ? Colors.green.withValues(alpha: 0.1)
            : theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isMarketOpen
              ? Colors.green.withValues(alpha: 0.3)
              : theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isMarketOpen ? Colors.green : theme.colorScheme.error,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            lang.translate(_isMarketOpen ? 'market_open' : 'market_closed'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: _isMarketOpen ? Colors.green : theme.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectorPerformance(ThemeData theme, LanguageProvider lang) {
    final sectors = _calculateSectorPerformance();
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                lang.translate('sector_performance'),
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
      ),
    );
  }

  Widget _buildTopMovers(ThemeData theme, LanguageProvider lang) {
    final gainers = List.from(_marketData)
      ..sort(
          (a, b) => (b['change'] as double).compareTo(a['change'] as double));
    final losers = List.from(_marketData)
      ..sort(
          (a, b) => (a['change'] as double).compareTo(b['change'] as double));

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                lang.translate('top_movers'),
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

  Widget _buildNotificationsScreen(ThemeData theme, LanguageProvider lang) {
    final notifications = [
      {
        'type': 'order',
        'title': 'Order Executed',
        'message':
            'Your buy order for 100 shares of EABL has been executed at ETB 167.00',
        'time': DateTime.now().subtract(const Duration(minutes: 5)),
        'read': false,
      },
      {
        'type': 'market',
        'title': 'Market Alert',
        'message': 'Market is now open for trading',
        'time': DateTime.now().subtract(const Duration(hours: 2)),
        'read': true,
      },
      {
        'type': 'price',
        'title': 'Price Alert',
        'message': 'EABL has reached your target price of ETB 170.00',
        'time': DateTime.now().subtract(const Duration(days: 1)),
        'read': true,
      },
    ];

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              lang.translate('no_notifications'),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        final isRead = notification['read'] as bool;

        IconData getNotificationIcon() {
          switch (notification['type']) {
            case 'order':
              return Icons.receipt_long;
            case 'market':
              return Icons.analytics;
            case 'price':
              return Icons.price_change;
            default:
              return Icons.notifications;
          }
        }

        return FadeInUp(
          duration: Duration(milliseconds: 200 + (index * 50)),
          child: Card(
            elevation: isRead ? 0 : 2,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isRead
                    ? theme.colorScheme.surfaceContainerHighest
                    : theme.colorScheme.primary.withAlpha(26), // 0.1 * 255
                child: Icon(
                  getNotificationIcon(),
                  color: isRead
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              title: Text(
                notification['title'] as String,
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification['message'] as String,
                    style: GoogleFonts.spaceGrotesk(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    EthiopianUtils.timeAgo(
                        notification['time'] as DateTime, lang),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              trailing: !isRead
                  ? Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : null,
              onTap: () {
                setState(() {
                  notification['read'] = true;
                });
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) =>
                      _buildNotificationDetails(notification, theme, lang),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationDetails(Map<String, dynamic> notification,
      ThemeData theme, LanguageProvider lang) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                child: Icon(
                  notification['type'] == 'order'
                      ? Icons.receipt_long
                      : notification['type'] == 'market'
                          ? Icons.analytics
                          : Icons.price_change,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  notification['title'] as String,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                EthiopianUtils.timeAgo(notification['time'] as DateTime, lang),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            notification['message'] as String,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          if (notification['type'] == 'order')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to order details
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                lang.translate('view_order_details'),
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('home')),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      '3',
                      style: TextStyle(
                        color: theme.colorScheme.onError,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(
                      title: Text(lang.translate('notifications')),
                    ),
                    body: _buildNotificationsScreen(theme, lang),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshMarketData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildMarketOverview(theme, lang),
            const SizedBox(height: 16),
            _buildMarketChart(theme, lang),
            const SizedBox(height: 16),
            _buildTopMovers(theme, lang),
            const SizedBox(height: 16),
            _buildSectorPerformance(theme, lang),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketChart(ThemeData theme, LanguageProvider lang) {
    final List<FlSpot> spots = List.generate(24, (index) {
      return FlSpot(index.toDouble(),
          _marketData[index % _marketData.length]['price'] as double);
    });

    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lang.translate('market_trend'),
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
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
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
